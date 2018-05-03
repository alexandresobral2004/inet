//
// This program is property of its copyright holder. All rights reserved.
//

package inet.examples.wireless.wiredandwirelesshostswithap;

import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.ethernet.Eth100M;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.inet.WirelessHost;
import inet.node.wireless.AccessPoint;
import inet.physicallayer.ieee80211.packetlevel.Ieee80211ScalarRadioMedium;
import inet.visualizer.contract.IIntegratedVisualizer;

network WiredAndWirelessHostsWithAP
{
    submodules:
        visualizer: <default("IntegratedCanvasVisualizer")> like IIntegratedVisualizer if hasVisualizer() {
            parameters:
                @display("p=100,210;is=s");
        }
        configurator: Ipv4NetworkConfigurator {
            parameters:
                assignDisjunctSubnetAddresses = false;
                @display("p=100,70;is=s");
        }
        radioMedium: Ieee80211ScalarRadioMedium {
            parameters:
                @display("p=100,140;is=s");
        }
        wirelessHost1: WirelessHost {
            parameters:
                @display("p=250,100");
        }
        wiredHost1: StandardHost {
            parameters:
                @display("p=400,190");
        }
        wiredHost2: StandardHost {
            parameters:
                @display("p=700,100");
        }
        router: Router {
            parameters:
                @display("p=550,100");
        }
        accessPoint: AccessPoint {
            parameters:
                @display("p=400,100");
        }
    connections:
        accessPoint.ethg++ <--> Eth100M <--> router.ethg++;
        wiredHost1.ethg++ <--> Eth100M <--> accessPoint.ethg++;
        wiredHost2.ethg++ <--> Eth100M <--> router.ethg++;
}
