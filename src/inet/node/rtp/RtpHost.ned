// the original file was included in the ~Udp sockets example

package inet.node.rtp;

import inet.applications.rtpapp.RtpApplication;
import inet.node.inet.StandardHost;
import inet.transportlayer.rtp.Rtcp;
import inet.transportlayer.rtp.Rtp;
import ned.IdealChannel;


//
// TODO document!
//
module RtpHost extends StandardHost
{
    parameters:
        string profileName;
        string destinationAddress;
        int portNumber;
        double bandwidth;
        string fileName;
        int payloadType;
        hasUdp = true;
        @display("i=device/pc2");

    submodules:
        rtpApp: RtpApplication {
            parameters:
                profileName = profileName;
                destinationAddress = destinationAddress;
                portNumber = portNumber;
                bandwidth = bandwidth;
                fileName = fileName;
                payloadType = payloadType;
                @display("p=825,90");
        }
        rtp: Rtp {
            parameters:
                @display("p=975,90");
        }
        rtcp: Rtcp {
            parameters:
                @display("p=1125,90");
        }

    connections allowunconnected:
        // transport connections
        rtpApp.rtpOut --> rtp.appIn;
        rtpApp.rtpIn <-- rtp.appOut;

        rtp.udpOut --> at.in++;
        rtp.udpIn <-- at.out++;

        rtcp.udpOut --> at.in++;
        rtcp.udpIn <-- at.out++;

        rtp.rtcpOut --> IdealChannel --> rtcp.rtpIn;
        rtcp.rtpOut --> IdealChannel --> rtp.rtcpIn;
}

