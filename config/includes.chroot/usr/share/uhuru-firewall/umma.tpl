# Uhuru OS firewall - wasifu: umma (cafe, shule, mtandao wa pamoja) - hakuna kinachoingia bila ruhusa
table inet uhuru {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        ct state invalid drop
        iifname "lo" accept
        icmp type { echo-request, destination-unreachable, time-exceeded, parameter-problem } limit rate 10/second accept
        icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
        udp sport 67 udp dport 68 accept
        udp sport 547 udp dport 546 accept
        #CUSTOM#
    }
}
