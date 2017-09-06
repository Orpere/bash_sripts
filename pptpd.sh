#!/bin/bash
#######################
#Author:Orlando       #
#release:0            #
#date: 6/9/17         #
#revision: 01         #
#######################
apt-get update && apt-get -y upgrade 
apt-get -y install pptpd 
LOCAL=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
INTER=`ip route get "$DNS1" | awk 'NR==2 {print $1}' RS="dev"`
PUBLIC=`dig +short myip.opendns.com @resolver1.opendns.com`
DNS1="8.8.8.8"
DNS2="8.8.4.4"
echo > /etc/pptpd.conf
ifconfig 
cat << EOF >> /etc/pptpd.conf
#start of custom file
#logwtmp
option /etc/ppp/options.pptpd
localip $LOCAL   # local vpn IP 
remoteip 192.168.1.100-200  # ip range for connections please feel free to chose your range 
listen $PUBLIC 
#end of custom file
EOF

#add clients 
echo 'usernameForuser1 *  setpassword1here  *' >> /etc/ppp/chap-secrets


echo > /etc/ppp/options.pptpd
cat << EOF >> /etc/ppp/options.pptpd
#custom settings for a simple fast pptp server
ms-dns $DNS1
ms-dns $DNS2
lock
name pptpd
require-mschap-v2
# Require MPPE 128-bit encryption
# (note that MPPE requires the use of MSCHAP-V2 during authentication)
require-mppe-128
EOF

#Enable network forwarding in /etc/sysctl.conf
#sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' > vi /etc/sysctl.conf
#sysctl -p

# Accept all packets via ppp* interfaces (for example, ppp0)
iptables -A INPUT -i ppp+ -j ACCEPT
iptables -A OUTPUT -o ppp+ -j ACCEPT

# Accept incoming connections to port 1723 (PPTP)
iptables -A INPUT -p tcp --dport 1723 -j ACCEPT

# Accept GRE packets
iptables -A INPUT -p 47 -j ACCEPT
iptables -A OUTPUT -p 47 -j ACCEPT

# Enable IP forwarding
iptables -F FORWARD
iptables -A FORWARD -j ACCEPT

# Enable NAT for $INTER  ppp* interfaces

iptables -t nat -A POSTROUTING -o $INTER -j MASQUERADE
iptables -t nat -A POSTROUTING -o ppp+ -j MASQUERADE


iptables-save -c 


service pptpd restart

  

