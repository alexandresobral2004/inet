package inet.examples.bgpv4.BgpOpen;


import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;


network BgpOpenMessageExample
{
    types:
        channel LINK_100 extends ned.DatarateChannel
        {
            parameters:
                delay = 0s;
                datarate = 100Mbps;
        }

    submodules:
        A: BGPRouterSimple {
            parameters:
                @display("p=250,80");
        }
        B: BGPRouterSimple {
            parameters:
                @display("p=400,80");
        }
        configurator: Ipv4NetworkConfigurator {
            @display("p=100,80;is=s");
            config = xmldoc("IPv4Config.xml");
            //assignAddresses = false;
            //assignDisjunctSubnetAddresses = false;
            addStaticRoutes = false;
            addDefaultRoutes = false;
            addSubnetRoutes = false;
        }
    connections:
        A.pppg++ <--> LINK_100 <--> B.pppg++;
}

