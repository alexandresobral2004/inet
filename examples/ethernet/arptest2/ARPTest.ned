//
// Copyright (C) 2004 Emin Ilker Cetinbas (niw3@yahoo.com)
//
// This library is free software, you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation;
// either version 2 of the License, or any later version.
// The library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Lesser General Public License for more details.
//



package inet.examples.ethernet.arptest2;

import inet.linklayer.ethernet.EtherBus;
import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import ned.DatarateChannel;


network ARPTest
{
    types:
        channel ethline extends DatarateChannel
        {
            delay = 500ns;
            datarate = 10Mbps;
        }
    submodules:
        server: StandardHost {
            @display("p=775,50;i=device/server");
        }
        router8: Router {
            @display("p=775,150");
        }
        router7: Router {
            @display("p=625,150");
        }
        router6: Router {
            @display("p=475,150");
        }
        bus2: EtherBus {
            positions = "";
            propagationSpeed = 2e8 mps;
            @display("p=475,50;b=350,5");
        }
        router5: Router {
            @display("p=325,150");
        }
        bus1: EtherBus {
            positions = "";
            propagationSpeed = 2e8 mps;
            @display("p=475,248;b=500,5");
        }
        router4: Router {
            @display("p=700,350");
        }
        router3: Router {
            @display("p=550,350");
        }
        router2: Router {
            @display("p=400,350");
        }
        router1: Router {
            @display("p=250,350");
        }
        client: StandardHost {
            @display("p=100,350;i=device/laptop");
        }
        configurator: Ipv4NetworkConfigurator {
            @display("p=100,70;is=s");
        }
    connections:
        server.ethg++ <--> ethline <--> router8.ethg++;
        bus2.ethg++ <--> ethline <--> router5.ethg++;
        bus2.ethg++ <--> ethline <--> router6.ethg++;
        bus2.ethg++ <--> ethline <--> router7.ethg++;
        router8.ethg++ <--> ethline <--> router7.ethg++;
        bus1.ethg++ <--> ethline <--> router1.ethg++;
        bus1.ethg++ <--> ethline <--> router5.ethg++;
        bus1.ethg++ <--> ethline <--> router2.ethg++;
        bus1.ethg++ <--> ethline <--> router3.ethg++;
        bus1.ethg++ <--> ethline <--> router4.ethg++;
        client.ethg++ <--> ethline <--> router1.ethg++;
}

