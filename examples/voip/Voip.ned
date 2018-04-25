//
// This program is property of its copyright holder. All rights reserved.
//

// Created: 2012-6-10 for project inet

package inet.examples.voip;

import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.StandardHost;
import inet.node.internetcloud.InternetCloud;
import ned.DatarateChannel;


//
// A generated network with star topology.
//
network Voip
{
    types:
        channel C extends DatarateChannel
        {
            datarate = 100Mbps;
            delay = 0.1us;
        }
    submodules:
        senderHost: StandardHost {
            parameters:
                @display("p=200,170");
        }
        receiverHost: StandardHost {
            parameters:
                @display("p=400,170");
        }
        configurator: Ipv4NetworkConfigurator {
            @display("p=100,70;is=s");
        }
        internetCloud: InternetCloud {
            @display("p=300,270");
        }
    connections:
        senderHost.pppg++ <--> C <--> internetCloud.pppg++;
        internetCloud.pppg++ <--> C <--> receiverHost.pppg++;
}
