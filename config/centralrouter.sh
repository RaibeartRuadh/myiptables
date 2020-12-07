sysctl net.ipv4.conf.all.forwarding=1
ip r del default
ip r add default via 192.168.255.1
yum install -y epel-release
yum install -y nmap
yum install -y hping3
yum install -y mc
yum install -y nano
