//
// Copyright (C) 2004 Andras Varga
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, see <http://www.gnu.org/licenses/>.
//

#include <stdio.h>
#include <string.h>

#include "inet/linklayer/ppp/PPP.h"

#include "inet/common/INETUtils.h"
#include "inet/common/ModuleAccess.h"
#include "inet/common/NotifierConsts.h"
#include "inet/common/ProtocolTag_m.h"
#include "inet/common/packet/chunk/BytesChunk.h"
#include "inet/common/lifecycle/NodeOperations.h"
#include "inet/common/queue/IPassiveQueue.h"
#include "inet/linklayer/common/Ieee802Ctrl.h"
#include "inet/linklayer/common/InterfaceTag_m.h"
#include "inet/networklayer/contract/IInterfaceTable.h"

namespace inet {

Define_Module(PPP);

simsignal_t PPP::txStateSignal = registerSignal("txState");
simsignal_t PPP::rxPkOkSignal = registerSignal("rxPkOk");
simsignal_t PPP::dropPkIfaceDownSignal = registerSignal("dropPkIfaceDown");
simsignal_t PPP::dropPkBitErrorSignal = registerSignal("dropPkBitError");
simsignal_t PPP::packetSentToLowerSignal = registerSignal("packetSentToLower");
simsignal_t PPP::packetReceivedFromLowerSignal = registerSignal("packetReceivedFromLower");
simsignal_t PPP::packetSentToUpperSignal = registerSignal("packetSentToUpper");
simsignal_t PPP::packetReceivedFromUpperSignal = registerSignal("packetReceivedFromUpper");

PPP::~PPP()
{
    cancelAndDelete(endTransmissionEvent);
}

void PPP::initialize(int stage)
{
    MACBase::initialize(stage);

    // all initialization is done in the first stage
    if (stage == INITSTAGE_LOCAL) {
        sendRawBytes = par("sendRawBytes");
        txQueue.setName("txQueue");
        endTransmissionEvent = new cMessage("pppEndTxEvent");

        txQueueLimit = par("txQueueLimit");

        numSent = numRcvdOK = numBitErr = numDroppedIfaceDown = 0;
        WATCH(numSent);
        WATCH(numRcvdOK);
        WATCH(numBitErr);
        WATCH(numDroppedIfaceDown);

        subscribe(POST_MODEL_CHANGE, this);

        emit(txStateSignal, 0L);

        // find queueModule
        queueModule = nullptr;

        if (par("queueModule").stringValue()[0]) {
            cModule *mod = getModuleFromPar<cModule>(par("queueModule"), this);
            if (mod->isSimple())
                queueModule = check_and_cast<IPassiveQueue *>(mod);
            else {
                cGate *queueOut = mod->gate("out")->getPathStartGate();
                queueModule = check_and_cast<IPassiveQueue *>(queueOut->getOwnerModule());
            }
        }

        // remember the output gate now, to speed up send()
        physOutGate = gate("phys$o");

        // we're connected if other end of connection path is an input gate
        bool connected = physOutGate->getPathEndGate()->getType() == cGate::INPUT;
        // if we're connected, get the gate with transmission rate
        datarateChannel = connected ? physOutGate->getTransmissionChannel() : nullptr;
    }
    else if (stage == INITSTAGE_LINK_LAYER) {
        // register our interface entry in IInterfaceTable
        registerInterface();

        // prepare to fire notifications
        notifDetails.setInterfaceEntry(interfaceEntry);

        // request first frame to send
        if (queueModule && 0 == queueModule->getNumPendingRequests()) {
            EV_DETAIL << "Requesting first frame from queue module\n";
            queueModule->requestPacket();
        }
    }
}

InterfaceEntry *PPP::createInterfaceEntry()
{
    InterfaceEntry *e = new InterfaceEntry(this);

    // data rate
    bool connected = datarateChannel != nullptr;
    double datarate = connected ? datarateChannel->getNominalDatarate() : 0;
    e->setDatarate(datarate);
    e->setCarrier(connected);

    // generate a link-layer address to be used as interface token for IPv6
    InterfaceToken token(0, getSimulation()->getUniqueNumber(), 64);
    e->setInterfaceToken(token);

    // MTU: typical values are 576 (Internet de facto), 1500 (Ethernet-friendly),
    // 4000 (on some point-to-point links), 4470 (Cisco routers default, FDDI compatible)
    e->setMtu(par("mtu").longValue());

    // capabilities
    e->setMulticast(true);
    e->setPointToPoint(true);

    return e;
}

void PPP::receiveSignal(cComponent *source, simsignal_t signalID, cObject *obj, cObject *details)
{
    MACBase::receiveSignal(source, signalID, obj, details);

    if (signalID != POST_MODEL_CHANGE)
        return;

    if (dynamic_cast<cPostPathCreateNotification *>(obj)) {
        cPostPathCreateNotification *gcobj = (cPostPathCreateNotification *)obj;
        if (physOutGate == gcobj->pathStartGate)
            refreshOutGateConnection(true);
    }
    else if (dynamic_cast<cPostPathCutNotification *>(obj)) {
        cPostPathCutNotification *gcobj = (cPostPathCutNotification *)obj;
        if (physOutGate == gcobj->pathStartGate)
            refreshOutGateConnection(false);
    }
    else if (datarateChannel && dynamic_cast<cPostParameterChangeNotification *>(obj)) {
        cPostParameterChangeNotification *gcobj = (cPostParameterChangeNotification *)obj;
        if (datarateChannel == gcobj->par->getOwner() && !strcmp("datarate", gcobj->par->getName()))
            refreshOutGateConnection(true);
    }
}

void PPP::refreshOutGateConnection(bool connected)
{
    Enter_Method_Silent();

    // we're connected if other end of connection path is an input gate
    if (connected)
        ASSERT(physOutGate->getPathEndGate()->getType() == cGate::INPUT);

    if (!connected) {
        if (endTransmissionEvent->isScheduled()) {
            cancelEvent(endTransmissionEvent);

            if (datarateChannel)
                datarateChannel->forceTransmissionFinishTime(SIMTIME_ZERO);
        }

        if (queueModule) {
            // Clear external queue: send a request, and received packet will be deleted in handleMessage()
            if (0 == queueModule->getNumPendingRequests())
                queueModule->requestPacket();
        }
        else {
            //Clear inner queue
            while (!txQueue.isEmpty()) {
                cMessage *msg = check_and_cast<cMessage *>(txQueue.pop());
                EV_ERROR << "Interface is not connected, dropping packet " << msg << endl;
                numDroppedIfaceDown++;
                emit(dropPkIfaceDownSignal, msg);
                delete msg;
            }
        }
    }

    cChannel *oldChannel = datarateChannel;
    // if we're connected, get the gate with transmission rate
    datarateChannel = connected ? physOutGate->getTransmissionChannel() : nullptr;
    double datarate = connected ? datarateChannel->getNominalDatarate() : 0;

    if (datarateChannel && !oldChannel)
        datarateChannel->subscribe(POST_MODEL_CHANGE, this);

    // update interface state if it is in use
    if (interfaceEntry) {
        interfaceEntry->setCarrier(connected);
        interfaceEntry->setDatarate(datarate);
    }

    if (queueModule && 0 == queueModule->getNumPendingRequests())
        queueModule->requestPacket();
}

void PPP::startTransmitting(cPacket *msg)
{
    // if there's any control info, remove it; then encapsulate the packet
    Packet *pppFrame = encapsulate(msg);

    // fire notification
    notifDetails.setPacket(pppFrame);
    emit(NF_PP_TX_BEGIN, &notifDetails);

    // send
    EV_INFO << "Transmission of " << pppFrame << " started.\n";
    emit(txStateSignal, 1L);
    emit(packetSentToLowerSignal, pppFrame);
    pppFrame->clearTags();
    if (sendRawBytes) {
        auto rawFrame = new Packet(pppFrame->getName(), pppFrame->peekBytes());
        send(rawFrame, physOutGate);
        delete pppFrame;
    }
    else
        send(pppFrame, physOutGate);

    ASSERT(datarateChannel == physOutGate->getTransmissionChannel());    //FIXME reread datarateChannel when changed

    // schedule an event for the time when last bit will leave the gate.
    simtime_t endTransmissionTime = datarateChannel->getTransmissionFinishTime();
    scheduleAt(endTransmissionTime, endTransmissionEvent);
    numSent++;
}

void PPP::handleMessage(cMessage *msg)
{
    if (!isOperational) {
        handleMessageWhenDown(msg);
        return;
    }

    if (msg == endTransmissionEvent) {
        // Transmission finished, we can start next one.
        EV_INFO << "Transmission successfully completed.\n";
        emit(txStateSignal, 0L);

        // fire notification
        notifDetails.setPacket(nullptr);
        emit(NF_PP_TX_END, &notifDetails);

        if (!txQueue.isEmpty()) {
            cPacket *pk = (cPacket *)txQueue.pop();
            startTransmitting(pk);
        }
        else if (queueModule && 0 == queueModule->getNumPendingRequests()) {
            queueModule->requestPacket();
        }
    }
    else if (msg->arrivedOn("phys$i")) {
        EV_INFO << "Received " << msg << " from network.\n";
        //TODO: if incoming gate is not connected now, then the link has benn deleted
        // during packet transmission --> discard incomplete packet.

        // fire notification
        notifDetails.setPacket(PK(msg));
        emit(NF_PP_RX_END, &notifDetails);

        msg->ensureTag<PacketProtocolTag>()->setProtocol(&Protocol::ppp);
        emit(packetReceivedFromLowerSignal, msg);

        // check for bit errors
        if (PK(msg)->hasBitError()) {
            EV_WARN << "Bit error in " << msg << endl;
            emit(dropPkBitErrorSignal, msg);
            numBitErr++;
            delete msg;
        }
        else {
            // pass up payload
            auto packet = check_and_cast<Packet *>(msg);
            const auto& pppHeader = packet->peekHeader<PppHeader>();
            const auto& pppTrailer = packet->peekTrailer<PppTrailer>();
            if (pppHeader == nullptr || pppTrailer == nullptr)
                throw cRuntimeError("Invalid PPP packet: PPP header or Trailer is missing");
            emit(rxPkOkSignal, packet);
            cPacket *payload = decapsulate(packet);
            numRcvdOK++;
            emit(packetSentToUpperSignal, payload);
            EV_INFO << "Sending " << payload << " to upper layer.\n";
            send(payload, "upperLayerOut");
        }
    }
    else {    // arrived on gate "upperLayerIn"
        EV_INFO << "Received " << msg << " from upper layer.\n";
        if (datarateChannel == nullptr) {
            EV_WARN << "Interface is not connected, dropping packet " << msg << endl;
            numDroppedIfaceDown++;
            emit(dropPkIfaceDownSignal, msg);
            delete msg;

            if (queueModule && 0 == queueModule->getNumPendingRequests())
                queueModule->requestPacket();
        }
        else {
            emit(packetReceivedFromUpperSignal, msg);

            if (endTransmissionEvent->isScheduled()) {
                // We are currently busy, so just queue up the packet.
                EV_DETAIL << "Received " << msg << " for transmission but transmitter busy, queueing.\n";

                if (txQueueLimit && txQueue.getLength() > txQueueLimit)
                    throw cRuntimeError("txQueue length exceeds %d -- this is probably due to "
                                        "a bogus app model generating excessive traffic "
                                        "(or if this is normal, increase txQueueLimit!)",
                            txQueueLimit);

                txQueue.insert(msg);
            }
            else {
                // We are idle, so we can start transmitting right away.
                startTransmitting(PK(msg));
            }
        }
    }
}

void PPP::refreshDisplay() const
{
    std::ostringstream buf;
    const char *color = "";

    if (datarateChannel != nullptr) {
        char datarateText[40];

        double datarate = datarateChannel->getNominalDatarate();
        if (datarate >= 1e9)
            sprintf(datarateText, "%gGbps", datarate / 1e9);
        else if (datarate >= 1e6)
            sprintf(datarateText, "%gMbps", datarate / 1e6);
        else if (datarate >= 1e3)
            sprintf(datarateText, "%gkbps", datarate / 1e3);
        else
            sprintf(datarateText, "%gbps", datarate);

        buf << datarateText << "\nrcv:" << numRcvdOK << " snt:" << numSent;

        if (numBitErr > 0)
            buf << "\nerr:" << numBitErr;

        if (endTransmissionEvent->isScheduled()) {
            color = txQueue.getLength() >= 3 ? "red" : "yellow";
        }
    }
    else {
        buf << "not connected\ndropped:" << numDroppedIfaceDown;
        color = "#707070";
    }
    getDisplayString().setTagArg("t", 0, buf.str().c_str());
    getDisplayString().setTagArg("i", 1, color);
}

Packet *PPP::encapsulate(cPacket *msg)
{
    auto packet = check_and_cast<Packet*>(msg);
    auto pppHeader = std::make_shared<PppHeader>();
    pppHeader->setProtocol(ProtocolGroup::pppprotocol.getProtocolNumber(msg->getMandatoryTag<PacketProtocolTag>()->getProtocol()));
    pppHeader->markImmutable();
    packet->pushHeader(pppHeader);
    auto pppTrailer = std::make_shared<PppTrailer>();
    pppTrailer->markImmutable();
    packet->pushTrailer(pppTrailer);
    packet->ensureTag<PacketProtocolTag>()->setProtocol(&Protocol::ppp);
    return packet;
}

cPacket *PPP::decapsulate(Packet *packet)
{
    const auto& pppHeader = packet->popHeader<PppHeader>();
    const auto& pppTrailer = packet->popTrailer<PppTrailer>();
    if (pppHeader == nullptr || pppTrailer == nullptr)
        throw cRuntimeError("Invalid PPP packet: PPP header or Trailer is missing");
    //TODO check CRC
    packet->ensureTag<InterfaceInd>()->setInterfaceId(interfaceEntry->getInterfaceId());

    auto protocol = ProtocolGroup::pppprotocol.getProtocol(pppHeader->getProtocol());
    packet->ensureTag<DispatchProtocolReq>()->setProtocol(protocol);
    packet->ensureTag<PacketProtocolTag>()->setProtocol(protocol);
    return packet;
}

void PPP::flushQueue()
{
    // code would look slightly nicer with a pop() function that returns nullptr if empty
    if (queueModule) {
        while (!queueModule->isEmpty()) {
            cMessage *msg = queueModule->pop();
            emit(dropPkIfaceDownSignal, msg);    //FIXME this signal lumps together packets from the network and packets from higher layers! separate them
            delete msg;
        }
        queueModule->clear();    // clear request count
        queueModule->requestPacket();
    }
    else {
        while (!txQueue.isEmpty()) {
            cMessage *msg = (cMessage *)txQueue.pop();
            emit(dropPkIfaceDownSignal, msg);    //FIXME this signal lumps together packets from the network and packets from higher layers! separate them
            delete msg;
        }
    }
}

void PPP::clearQueue()
{
    // code would look slightly nicer with a pop() function that returns nullptr if empty
    if (queueModule) {
        queueModule->clear();    // clear request count
        queueModule->requestPacket();
    }
    else {
        txQueue.clear();
    }
}

} // namespace inet
