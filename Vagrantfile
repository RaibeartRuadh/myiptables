# -*- mode: ruby -*-
# vim: set ft=ruby :
# RR

MACHINES = {
  :inetRouter => {
        :box_name => "centos/6",
        :net => [
                   {ip: '192.168.255.1', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
                ]
  },
  :centralRouter => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.255.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
                   {ip: '192.168.0.1', adapter: 3, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
                   {ip: '192.168.0.33', adapter: 4, netmask: "255.255.255.240", virtualbox__intnet: "hw-net"},
                   {ip: '192.168.0.65', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "mgt-net"},
                   {ip: '192.168.252.2', adapter: 6, netmask: "255.255.255.252", virtualbox__intnet: "router2-net"},
                ]
  },
  
  :centralServer => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.0.2', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
                ]
  },
  
  :inetRouter2 => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.252.1', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router2-net"},
                ]
  },
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.define boxname do |box|
        box.vm.box = boxconfig[:box_name]
        box.vm.host_name = boxname.to_s
        boxconfig[:net].each do |ipconf|
          box.vm.network "private_network", ipconf
        end
                if boxconfig.key?(:public)
          box.vm.network "public_network", boxconfig[:public]
        end
        box.vm.provision "shell", path: "config/sshconfig.sh"
        case boxname.to_s
        when "inetRouter"
          box.vm.provision :file do |file|
            file.source      = 'config/iptables'
            file.destination = '/home/vagrant/iptables'
          end          
          box.vm.provision "shell", run: "always", path: "config/inetrouter.sh"
 
        when "centralRouter"
          box.vm.provision :file do |file|
            file.source      = 'config/test.sh'
            file.destination = '/home/vagrant/test.sh'
            end             
          box.vm.provision "shell", run: "always", path: "config/centralrouter.sh"
        when "inetRouter2"
          box.vm.network "forwarded_port", guest: 8080, host: 8080
          box.vm.provision "shell", run: "always", path: "config/inetrouter2.sh"
        when "centralServer"
           box.vm.provision "shell", run: "always", path: "config/centralserver.sh"
          
          
        end
      end
  end
end

