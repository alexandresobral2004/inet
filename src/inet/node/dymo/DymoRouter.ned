//
// This program is property of its copyright holder. All rights reserved.
//

package inet.node.dymo;

import inet.node.inet.WirelessHost;
import inet.routing.dymo.Dymo;

module DymoRouter extends WirelessHost
{
    parameters:
        @display("i=device/cellphone");
        forwarding = true;
        wlan[*].mgmtType = default("Ieee80211MgmtAdhoc");

    submodules:
        dymo: Dymo {
            @display("p=875,240");
        }

    connections:
        dymo.ipOut --> tn.in++;
        dymo.ipIn <-- tn.out++;
}
