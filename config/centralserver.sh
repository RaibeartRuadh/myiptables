ip r del default
ip r add default via 192.168.0.1
yum install -y epel-release
yum install -y nginx
systemctl enable --now nginx

