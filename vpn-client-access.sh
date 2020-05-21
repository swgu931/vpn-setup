# Access to VPN Server

# 0)
apt-get install openvpn

# 1) conf파일 설치
sftp yg@112.220.105.114:client-configs/files/ta.key ~/openvpn-client/
sftp yg@112.220.105.114:client-configs/files/client.ovpn ~/openvpn-client/
sftp yg@112.220.105.114:EasyRSA-3.0.7/pki//ca.crt ~/openvpn-client/


# 2) cd ~/openvpn-client
sudo openvpn --config client.ovpn


# 3) 접속확인 (in other terminal)
# ping 10.8.0.1

