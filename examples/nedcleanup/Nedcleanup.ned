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
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.aodv.AodvRouter;
import inet.node.ethernet.Eth100M;
import inet.node.inet.StandardHost;
import inet.physicallayer.ieee80211.packetlevel.Ieee80211ScalarRadioMedium;


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
    connections:
        standardHost.ethg++ <--> Eth100M <--> standardHost1.ethg++;
        standardHost.pppg++ <--> Eth100M <--> standardHost1.pppg++;
        standardHost.ethg++ <--> Eth100M <--> standardHost1.ethg++;
}

