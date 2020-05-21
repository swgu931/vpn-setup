# file name : vpn-account-create.sh
# for adding vpn account

# =============== 1. client key & certificate creation ===============

# 1) 먼저 client 인증서를 모아둘 폴더를 하나 만들겠습니다.
mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
cd ~/EasyRSA-3.0.7/

# 이제 EasyRSA에서 vpn 계정에 대한 인증서를 만들어 줍니다.
# 2) # generting certificate for vpn account  (ex: vpn-cr == $1)
./easyrsa gen-req $1 nopass  
 # req: /home/ngle/EasyRSA-3.0.4/pki/reqs/vpn-host.req
 # key: /home/ngle/EasyRSA-3.0.4/pki/private/vpn-host.key

# 3) $1.key 파일로 인증서를 만들어 줍니다. request type은 client로 줍니다.
./easyrsa sign-req client $1
  # Certificate created at: /home/yg/EasyRSA-3.0.4/pki/issued/vpn-cr.crt

# 4) copy to ~/lient-configs/keys
sudo cp ~/EasyRSA-3.0.7/pki/private/$1.key ~/client-configs/keys/
sudo cp ~/EasyRSA-3.0.7/pki/issued/$1.crt ~/client-configs/keys/

sudo cp ~/EasyRSA-3.0.7/ta.key ~/client-configs/keys/
sudo cp ~/EasyRSA-3.0.7/pki/ca.crt ~/client-configs/keys/

#========== End of certificate used in openVPN account for vpn-cr // ====


cd ~/client-configs
sudo ./make_config.sh $1

ls ~/client-configs/files/
 # vpn-cr.ovpn
 #.ovpn 파일은 client에서 vpn 접속시 필요합니다. VPN으로 접속하려는 로컬 컴퓨터나 모바일 디바이스에서 필요합니다.
 #.ovpn 파일은 암호화된 ftp(sftp)를 이용해 전달되어야 합니다.

sudo cp ~/client-configs/keys/ta.key ~/client-configs/files/
sudo chmod 644 ~/client-configs/files/ta.key 


#============= in other host ======================
#sftp yg@112.220.105.114:client-configs/files/ta.key ~/Downloads/
#sftp yg@112.220.105.114:client-configs/files/vpn-cr.ovpn ~/Downloads/
#sftp yg@112.220.105.114:EasyRSA-3.0.7/pki//ca.crt ~/Downloads/
