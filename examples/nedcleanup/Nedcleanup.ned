//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

package inet.examples.nedcleanup;
import inet.applications.netperfmeter.NetPerfMeterHost;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.aodv.AodvRouter;
import inet.node.ethernet.Eth100M;
import inet.node.ethernet.EtherSwitch;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.internetcloud.InternetCloud;
import inet.physicallayer.ieee80211.packetlevel.Ieee80211ScalarRadioMedium;
import inet.transportlayer.sctp.SctpNatRouter;


//
// TODO documentation
//
network NedcleanupNetwork
{
    submodules:
        standardHost: StandardHost {
            @display("p=212,97");
        }
        configurator: Ipv4NetworkConfigurator {
            @display("p=108,23");
        }
        radioMedium: Ieee80211ScalarRadioMedium {
            @display("p=322,23");
        }
        standardHost1: StandardHost {
            @display("p=430,97");
        }
        aodvRouter: AodvRouter {
            @display("p=165,330");
        }
        router: Router {
            @display("p=251,217");
        }
        etherSwitch: EtherSwitch {
            @display("p=363,216");
        }
        standardHost2: StandardHost {
            @display("p=108,223");
        }
        internet: InternetCloud {
            @display("p=313,307");
        }
        standardHost3: StandardHost {
            @display("p=455,294");
        }
    connections:
        standardHost.ethg++ <--> Eth100M <--> standardHost1.ethg++;
        standardHost.pppg++ <--> Eth100M <--> standardHost1.pppg++;
        standardHost.ethg++ <--> Eth100M <--> standardHost1.ethg++;
        standardHost1.pppg++ <--> Eth100M <--> standardHost.pppg++;
        router.ethg++ <--> Eth100M <--> etherSwitch.ethg++;
        router.ethg++ <--> Eth100M <--> etherSwitch.ethg++;
        standardHost2.ethg++ <--> Eth100M <--> internet.ethg++;
        internet.ethg++ <--> Eth100M <--> standardHost3.ethg++;
}

//
// TODO documentation
//
network NetPerfMeterHostNetwork
{
    @display("bgb=432,221");
    submodules:
        configurator: Ipv4NetworkConfigurator {
            @display("p=103,48");
        }
        radioMedium: Ieee80211ScalarRadioMedium {
            @display("p=319,47");
        }
        netPerfMeterHost: NetPerfMeterHost {
            @display("p=103,145");
        }
        netPerfMeterHost1: NetPerfMeterHost {
            @display("p=322,145");
        }
    connections:
        netPerfMeterHost.ethg++ <--> Eth100M <--> netPerfMeterHost1.ethg++;
}

//
// TODO documentation
//
network SctpNatRouterNetwork
{
    submodules:
        sctpNatRouter: SctpNatRouter {
            @display("p=145,153");
        }
        sctpNatRouter1: SctpNatRouter {
            @display("p=362,153");
        }
        configurator: Ipv4NetworkConfigurator {
            @display("p=103,48");
        }
        radioMedium: Ieee80211ScalarRadioMedium {
            @display("p=319,47");
        }
    connections:
        sctpNatRouter.ethg++ <--> Eth100M <--> sctpNatRouter1.ethg++;
}

