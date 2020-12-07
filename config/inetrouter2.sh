sysctl net.ipv4.conf.all.forwarding=1
ip route add 192.168.0.0/16 via 192.168.252.2
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
iptables -t nat -A POSTROUTING ! -s 127.0.0.1 -j MASQUERADE

