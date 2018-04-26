//
// Copyright (C) 2012 OpenSim Ltd
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


package inet.examples.internetcloud.cloudandhosts;

import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.StandardHost;
import inet.node.internetcloud.InternetCloud;
import ned.DatarateChannel;


network CloudAndHosts
{
    parameters:
        int numSenders;

    types:
        channel C extends DatarateChannel
        {
            delay = 10ms;
            datarate = 5Mbps;
        }
    submodules:
        configurator: Ipv4NetworkConfigurator {
            parameters:
                @display("p=100,70;is=s");
        }

        sender[numSenders]: StandardHost {
            @display("p=250,70,col,100");
        }
        recip: StandardHost {
            @display("p=550,70");
        }
        internet: InternetCloud {
            @display("p=400,70;is=l");
        }
    connections:
        recip.pppg++ <--> C <--> internet.pppg++;
        for i=0..numSenders-1 {
            sender[i].pppg++ <--> C <--> internet.pppg++;
        }
}

