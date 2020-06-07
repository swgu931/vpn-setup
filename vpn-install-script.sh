# install script for Open VPN


sudo apt update
sudo apt install openvpn

wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.7/EasyRSA-3.0.7.tgz
tar xvf EasyRSA-3.0.7.tgz


cd ~/EasyRSA-3.0.7/
cp vars.example vars
vim vars
---
set_var EASYRSA_REQ_COUNTRY    "KR"
set_var EASYRSA_REQ_PROVINCE   "SEOUL"
set_var EASYRSA_REQ_CITY       "SEOUL"
set_var EASYRSA_REQ_ORG        "XXxxxx"
set_var EASYRSA_REQ_EMAIL      "xxxxxx@xxx.com"
set_var EASYRSA_REQ_OU         "xxxxxxxx"
---


#=============== 1. Key & Certificate Creation for CA & VPN Server =====================

#0-1) CA server building
./easyrsa init-pki   

#0-2) CA creation
./easyrsa build-ca nopass # generating certificate & key for CA without password
                          # ca.crt, ca.key generated

#1-1)
./easyrsa gen-req vpn-host nopass  # generating certificate & key for individual machine
    # .gen, .key generated
#1.2)
./easyrsa sign-req server vpn-host    # vpn-host.crt generated

#1-3) generating Diffie-Hellman Key 
./easyrsa gen-dh 
  # DH parameters of size 2048 created at /home/ngle/EasyRSA-3.0.4/pki/dh.pem

#1-4) generating ta.key for server  (ta:tls authentication)
openvpn --genkey --secret ta.key

#1-5) copy to openvpn
sudo cp ~/EasyRSA-3.0.7/pki/ca.crt /etc/openvpn/
sudo cp ~/EasyRSA-3.0.7/pki/private/ca.key /etc/openvpn/
sudo cp ~/EasyRSA-3.0.7/pki/private/vpn-host.key /etc/openvpn/
sudo cp ~/EasyRSA-3.0.7/pki/issued/vpn-host.crt /etc/openvpn/
sudo cp ~/EasyRSA-3.0.7/pki/dh.pem /etc/openvpn/
sudo cp ~/EasyRSA-3.0.7/ta.key /etc/openvpn/





#======================= 2. OpenVPN Server Configuration ================

# 1) 이번엔 openVPN에 대한 설정입니다.
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gzip -d /etc/openvpn/server.conf.gz
sudo cp server.conf vpn-host.conf


# 2) server.conf 파일 설정
sudo vim /etc/openvpn/vpn-host.conf
-------
# Which TCP/UDP port should OpenVPN listen on?
# If you want to run multiple OpenVPN instances
# on the same machine, use a different port
# number for each one.  You will need to
# open up this port on your firewall.
port 1194

# TCP or UDP server?
;proto tcp
proto udp

;dev tap
dev tun


ca /etc/openvpn/ca.crt
cert /etc/openvpn/vpn-host.crt
key /etc/openvpn/vpn-host.key  # This file should be kept secret

# Diffie hellman parameters.
# Generate your own with:
#   openssl dhparam -out dh2048.pem 2048
dh /etc/openvpn/dh.pem

topology subnet

push "redirect-gateway def1 bypass-dhcp"

push "dhcp-option DNS 168.126.63.1"
push "dhcp-option DNS 168.126.63.2"

tls-auth /etc/openvpn/ta.key 0 # This file is secret
key-direction 0

cipher AES-256-CBC
auth SHA256


user nobody
group nogroup


explicit-exit-notify 0 # when you are using tcp
-----



# 3-2) openVPN server의 네트워크 설정을 변경
sudo vim /etc/sysctl.conf
---
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1
---

# 3-3) 확인
sudo sysctl -p

#============= End of 2. openVPN Server confiugaration //==============



#======================= 3. Firewall Configuration ================

# 1) check device interface
ip route | grep default
 # default via 192.168.1.1 dev enp3s0 proto dhcp metric 100 


# 2) ufw(방화벽) 설정을 열고 openVPN에서 사용할 roule을 추가합니다.

sudo vim /etc/ufw/before.rules
-----
#
# Rules that should be run before the ufw command line added rules. Custom
# rules should be added to one of these chains:
#   ufw-before-input
#   ufw-before-output
#   ufw-before-forward
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to enp3s0
-A POSTROUTING -s 10.8.0.0/8 -o enp3s0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
#
-----

# 3) /etc/default/ufw 파일을 열고 DEFAULT_FORWARD_POLICY찾아 ACCEPT로 수정합니다.
sudo vim /etc/default/ufw
-----
# Set the default forward policy to ACCEPT, DROP or REJECT.  Please note that
# if you change this you will most likely want to adjust your rules
DEFAULT_FORWARD_POLICY="ACCEPT"
-----

# 4) 앞서 openVPN의 port와 프로토콜을 변경해 줬기 때문에 방화벽(ufw)에도 적용해야 합니다.
   # openSSH도 추가해 줍니다.
sudo ufw allow 443/tcp
sudo ufw allow OpenSSH

sudo ufw disable
sudo ufw enable

# 5) starting openVPN : openVPN 실행시 설정 파일은 /etc/openvpn/server.conf 파일을 사용하기 위해 @server를 추가해 실행합니다.

sudo systemctl start openvpn@vpn-host
sudo systemctl status openvpn@vpn-host
ip addr show tun0
 
sudo systemctl enable openvpn@vpn-host # automatic restart after system reboot

#============== End of firewall setup // ====================

#tip)
sudo iptables -t nat -L -n -v



# =============== 4. client key & certificate creation ===============

# 1) 먼저 client 인증서를 모아둘 폴더를 하나 만들겠습니다.
mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
cd ~/EasyRSA-3.0.4/

# 이제 EasyRSA에서 vpn 계정에 대한 인증서를 만들어 줍니다.
# 2) # generting certificate for vpn account
./easyrsa gen-req vpn-cr nopass  
 # req: /home/ngle/EasyRSA-3.0.4/pki/reqs/vpn-host.req
 # key: /home/ngle/EasyRSA-3.0.4/pki/private/vpn-host.key

# 3) vpn-cr.key 파일로 인증서를 만들어 줍니다. request type은 client로 줍니다.
./easyrsa sign-req client vpn-cr
  # Certificate created at: /home/yg/EasyRSA-3.0.4/pki/issued/vpn-cr.crt

sudo cp ~/EasyRSA-3.0.7/pki/private/vpn-cr.key ~/client-configs/keys/
sudo cp ~/EasyRSA-3.0.7/pki/issued/vpn-cr.crt ~/client-configs/keys/

sudo cp ~/EasyRSA-3.0.7/ta.key ~/client-configs/keys/
sudo cp ~/EasyRSA-3.0.7/pki/ca.crt ~/client-configs/keys/

#========== End of certificate used in openVPN account for vpn-cr // ====


#============== 5. configuration for VPN Client ============================

# 1)
mkdir -p ~/client-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/client.conf

sudo vim ~/client-configs/client.conf
-----
# the firewall for the TUN/TAP interface.
;dev tap
dev tun


$ # The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
remote 112.220.105.114 443

# Are we connecting to a TCP or
# UDP server?  Use the same setting as
# on the server.
proto tcp
;proto udp

# Downgrade privileges after initialization (non-Windows only)
user nobody
group nogroup

# SSL/TLS parms.
# See the server config file for more
# description.  It's best to use
# a separate .crt/.key file pair
# for each client.  A single caClient 추가에 설정 구성을 잡도록 하겠습니다.
# file can be used for all clients.
#ca ca.crt
#cert client.crt
#key client.key

# Select a cryptographic cipher.
# If the cipher option is used on the server
# then you must also specify it here.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the ncp-cipher option in the manpage
cipher AES-256-CBC
auth SHA256

key-direction 1

# script-security 2
# up /etc/openvpn/update-resolv-conf
# down /etc/openvpn/update-resolv-conf
-----



#=============== 6. simple script for client account creation =========
sudo vi ~/client-configs/make_config.sh # newly creation

-----
#!/bin/bash

# First argument: Client identifier
KEY_DIR=~/client-configs/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/client.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn
-----
sudo chmod 700 ~/client-configs/make_config.sh

cd ~/client-configs
sudo ./make_config.sh vpn-cr

ls ~/client-configs/files/
 # vpn-cr.ovpn
 #.ovpn 파일은 client에서 vpn 접속시 필요합니다. VPN으로 접속하려는 로컬 컴퓨터나 모바일 디바이스에서 필요합니다.
 #.ovpn 파일은 암호화된 ftp(sftp)를 이용해 전달되어야 합니다.

sudo cp ~/client-configs/keys/ta.key ~/client-configs/files/
sudo chmod 644 ~/client-configs/files/ta.key 


#============= in other host ======================
sftp yg@112.220.105.114:client-configs/files/ta.key ~/Downloads/
sftp yg@112.220.105.114:client-configs/files/vpn-cr.ovpn ~/Downloads/
sftp yg@112.220.105.114:EasyRSA-3.0.7/pki//ca.crt ~/Downloads/


#마지막으로 외부에서 내부 openVPN server로 접속할 수 있도록 라우터의 port forwarding 설정을 아래와 같이 합니다.
#내부 openVPN server IP는 192.168.0.185입니다. 포트는 443으로 설정했죠.

