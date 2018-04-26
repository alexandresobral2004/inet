// Copyright (C) 2007 Faqir Zarrar Yousaf
// Communication Networks Institute
// University of Dortmund, Germany
// faqir.yousaf@uni-dortmund.de
//
// Copyright (C) 2004 Andras Varga
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//


package inet.examples.mobileipv6;

import inet.linklayer.ethernet.EtherHub;
import inet.networklayer.configurator.ipv6.Ipv6FlatNetworkConfigurator;
import inet.node.ipv6.Router6;
import inet.node.wireless.AccessPoint;
import inet.node.xmipv6.CorrespondentNode6;
import inet.node.xmipv6.HomeAgent6;
import inet.node.xmipv6.WirelessHost6;
import inet.physicallayer.ieee80211.packetlevel.Ieee80211ScalarRadioMedium;
import inet.visualizer.integrated.IntegratedVisualizer;


channel fiberline extends ned.DatarateChannel
{
    parameters:
        delay = 1us;
        datarate = 512Mbps;
}

channel ethernetline extends ned.DatarateChannel
{
    parameters:
        delay = 0.1us;
        datarate = 100Mbps;
}

network mIPv6Network
{
    parameters:
        int total_mn;
        int total_cn;
        **.mgmt.numChannels = 5;

        @display("bgb=799,698");
    submodules:
        configurator: Ipv6FlatNetworkConfigurator {
            parameters:
                @display("p=100,70;is=s");
        }
        radioMedium: Ieee80211ScalarRadioMedium {
            parameters:
                @display("p=100,140;is=s");
        }
        Home_Agent: HomeAgent6 {
            parameters:
                @display("p=250,300;i=abstract/router");
        }
        R_1: Router6 {
            parameters:
                @display("p=550,300");
        }
        R_2: Router6 {
            parameters:
                @display("p=400,400");
        }
        MN[total_mn]: WirelessHost6 {
            parameters:
                @display("p=400,100");
        }
        CN[total_cn]: CorrespondentNode6 {
            @display("p=250,600,row,300");
        }
        AP_Home: AccessPoint {
            parameters:
                @display("p=250,200;i=device/accesspoint");
        }
        AP_1: AccessPoint {
            parameters:
                @display("p=550,200;i=device/accesspoint");
        }
        hub: EtherHub {
            parameters:
                @display("p=400,500;i=device/hub");
        }
    connections allowunconnected:

                         //Home_Agent.ethOut++ --> ethernetline --> R_1.ethIn++;
                         //Home_Agent.ethIn++ <-- ethernetline <-- R_1.ethOut++;

        R_1.ethg++ <--> ethernetline <--> R_2.ethg++;

                                                       //R_2.ethOut++ --> ethernetline --> R_3.ethIn++;
                                                       //R_2.ethIn++ <-- ethernetline <-- R_3.ethOut++;

        Home_Agent.ethg$o++ --> ethernetline --> R_2.ethg$i++;
        Home_Agent.ethg$i++ <-- ethernetline <-- R_2.ethg$o++;

        for i=0..total_cn-1 {
            CN[i].ethg$o++ --> ethernetline --> hub.ethg$i++;
            CN[i].ethg$i++ <-- ethernetline <-- hub.ethg$o++;
        }

        hub.ethg++ <--> ethernetline <--> R_2.ethg++;

                                                    //R_1.ethOut++ --> ethernetline --> CN.ethIn++;
                                                    //R_1.ethIn++ <-- ethernetline <-- CN.ethOut++;

        AP_Home.ethg$o++ --> ethernetline --> Home_Agent.ethg$i++;
        AP_Home.ethg$i++ <-- ethernetline <-- Home_Agent.ethg$o++;

        AP_1.ethg++ <--> ethernetline <--> R_1.ethg++;

                                                        //AP_2.ethOut++ --> ethernetline --> R_2.ethIn++;
                                                        //AP_2.ethIn++ <-- ethernetline <-- R_2.ethOut++;

                                                        //AP_3.ethOut++ --> ethernetline --> R_3.ethIn++;
                                                        //AP_3.ethIn++ <-- ethernetline <-- R_3.ethOut++;

}

