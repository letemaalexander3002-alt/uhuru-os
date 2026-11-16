# Uhuru OS firewall - wasifu: nyumbani (mtandao wa nyumbani/ofisi unaoamini) - kompyuta za mtandao huo zinaruhusiwa (Uhuru Share kwa LAN)
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
        ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 } accept
        ip6 saddr { fe80::/10, fc00::/7 } accept
        #CUSTOM#
    }
}
