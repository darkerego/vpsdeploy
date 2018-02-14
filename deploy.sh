#!/bin/bash
# VPSDeploy Version 3.0
##################################################
# Custom Debian Install Script - Makes redundant
# installs just a little less, well-- redundant.
##################################################
#

# your default ssh key. script will use this if you dont specify another one
default_ssh_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbVnKeFFv4h69f0j+loVdVYE/3sFOX/CqE7th1/k4MoxHYABJX4jf/4734wk5U+FBjt8AKEXHKaZXsCT5pZxRRQ7SbLwcJvN5HfyKQrv2e+z0t9kP97C3YitUI43PrzRcAX8p/xqadDKdL6b3rpL37iwX6WKD5M/t0ljYqR3w35zHi0K8W4zPUq6ZY3HO7nDAMWyEwIKE97pCE31TLGiPPVKjYjtrM6ii+XimE1gKWyQ3jVlxKYBMkPrU2IH2ppBjykjPpmpfMO5DXR+dS7LNBL9389MPGOabqnPz3xv7Q4ZrufquJMCsDEBx262h0u04jAaYLbqaUakaKs0MO6yUt anon@hell'

# programs to install
GET_LIST='irssi secure-delete openvpn tor tor-arm git ufw htop whois mosquitto mosquitto-clients python-pip python3-pip'

install_stuff(){
if [[ ! -f "~/.done" ]] ; then 
sudo apt -y update ;\
sudo apt -y upgrade;\
sudo apt -y install $GET_LIST
if [[ ! -d /var/lib/dnscrypt ]] ; then
  sleep 1;\
  echo 'I will now install dnscrypt-proxy. Please follow the prompts.';\
  sleep 1;\
  cd /usr/local/src;\
  sudo git clone https://github.com/simonclausen/dnscrypt-autoinstall &&\
  cd dnscrypt-autoinstall &&\
  sudo ./dnscrypt-autoinstall || echo 'Error installing dnscrypt!'
else
  echo 'Already got dnscrypt...'
fi

sudo cp /etc/tor/torrc /etc/tor/torrc.orig
sudo cp /etc/tor/torrc /tmp/torrc && \
sudo bash -c " echo 'HiddenServiceDir /var/lib/tor/ssh_service' >>/tmp/torrc" &&\
sudo bash -c " echo 'HiddenServicePort 22 127.0.0.1:22' >>/tmp/torrc " &&\
sudo bash -c "cp /tmp/torrc /etc/tor/torrc" || exit 1

(sudo service tor restart >/dev/null 2>&1 || sudo service tor start) || (echo "Failed to start tor! Wtf?";exit 1) &&\
echo 'Your SSH .onion url:'
sleep 1;echo '..';sleep 1;echo '...';sleep 1
sudo cat '/var/lib/tor/ssh_service/hostname' 2>/dev/null >$HOME/onion;cat $HOME/onion;echo
echo 1>"~/.done"
sleep 1;echo '..';sleep 1;echo '...';sleep 1
fi
}

harden_ssh(){

echo "Hardening moduli..."
awk '$5 > 2000' /etc/ssh/moduli > "${HOME}/moduli"
if [[ $(wc -l "${HOME}/moduli") != "0" ]] ; then
  sudo mv "${HOME}/moduli" /etc/ssh/moduli
else
  echo "Creating moduli..."
  sudo ssh-keygen -G /etc/ssh/moduli.all -b 4096
  sudo ssh-keygen -T /etc/ssh/moduli.safe -f /etc/ssh/moduli.all
  sudo mv /etc/ssh/moduli.safe /etc/ssh/moduli
  sudo rm /etc/ssh/moduli.all
fi


echo "Creating host keys..."
cd /etc/ssh
sudo rm ssh_host_*key*
sudo ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N "" < /dev/null
sudo ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N "" < /dev/null

echo "Creating hardened config file"

echo "\
# Package generated configuration file
# See the sshd_config(5) manpage for details

# What ports, IPs and protocols we listen for
Port 22
# Use these options to restrict which interfaces/protocols sshd will bind to
#ListenAddress ::
ListenAddress 0.0.0.0:22
Protocol 2
# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
#Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 3600
ServerKeyBits 4096
AllowGroups ssh-users
# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:
LoginGraceTime 120
PermitRootLogin no
StrictModes yes

RSAAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile	%h/.ssh/authorized_keys

# harden crypto
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes

# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Change to no to disable tunnelled clear text passwords
PasswordAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no

#MaxStartups 10:30:60
#Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server -f auth -l info

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of 'PermitRootLogin without-password'.
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes" >/tmp/sshd_config

if [[ -f /tmp/sshd_config ]] ; then
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
  sudo mv /tmp/sshd_config /etc/ssh/sshd_config
  if [[ "$?" -eq "0" ]] ; then
    echo "Success!" ; return 0
  else 
   echo "Fail!" ; return 1 
  fi
fi
}


add_users(){

sudo groupadd ssh-users
unset users
unset added_one
echo "I need to know which users should be allowed to ssh in to this server."
while [[ -z "$users" ]] ; do
  echo "Please enter each user followed by a space in this format: 'user user2 user3'"
  read -p "Enter users : " users
done
for i in $(echo "$users") ; do
  if grep "^$i.*sh$" /etc/passwd >/dev/null 2>&1 ; then
    echo "Adding user $i to group ssh-users..."
    sudo usermod -a -G ssh-users $i && export added_one=true
  else
    echo "Error: $i is not a valid user account on this system!"
    read -p "Try again or add user to system? (y/n/add)  :" tryagain
    if [[ "$tryagain" == 'y' ]]; then
      read -p "Please enter a valid user account: " user_
      if [[ -n "$user_" ]] ; then 
        if grep "^$user_.*sh$" /etc/passwd >/dev/null 2>&1; then
          echo "User $user_ is valid!"
          sudo usermod -a -G ssh-users $i && export added_one=true
        fi
      fi
    
    elif [[ "$tryagain" == 'add' ]]; then
      if grep "^$i.*sh$" /etc/passwd >/dev/null 2>&1 ; then
        echo 'This account already exists!'
        sudo usermod -a -G ssh-users $i  &&  export added_one=true && echo " Successfully addeded $i"
      else
        #read -rsp "Enter password for user account $i : " thispw
        #echo 'Encrypting passsword...'
        #mkpasswd -V >/dev/null 2>&1 || sudo apt update && sudo apt -y -qq install whois
        #thispwd="$(mkpasswd -m sha-512 \"$thispw\")"
        #unset thispw
        #useradd -p "$thispwd" -s /bin/bash -G ssh-users $i
        adduser $i
        sudo usermod -a -G ssh-users $i
        if [[ $? -eq "0" ]] ; then
          echo "Success..."
        else
          echo 'Failed...'
        fi
      fi
    else
      echo 'Ok then'
   fi
fi
done
if $added_one ; then return 0 ; else return 1 ; fi
}

firewall_up(){
echo 'Hardening ssh...'
harden_ssh
for x in $(seq 1 5) ; do 
echo "Attempt $x/5 ..."
add_users && break ||\
 echo 'We need a valid user account. Try again!'
done
if $added_one ; then

  sudo ufw allow ssh
  sudo ufw enable
  echo 'SSH host keys have changed. You can safely ignore that warning.'
  read -p "Have you confirmed that you can log in with your public key? (yes/no)" I_am_not_an_idiot
  if ([[ $I_am_not_an_idiot == "yes" ]]||[[ $I_am_not_an_idiot == "y" ]]||[[ $I_am_not_an_idiot == "Y" ]]) ; then
    sudo service ssh restart
  else
    echo 'Remember to restart ssh after you have confirmed you can log in with your key!'
  fi
fi
}

conf_ssh(){
echo 'Configuring ssh'
mkdir ~/.ssh
chmod 700 ~/.ssh
read -p "Please paste your ssh key or press enter to use default" ssh_key
if [[ -n "$ssh_key" ]] ; then
  echo "$ssh_key" >~/.ssh/authorized_keys
else
  echo "$default_ssh_key" >~/.ssh/authorized_keys
fi
echo 'Contents of authorized_keys:'
cat ~/.ssh/authorized_keys

chmod 600 ~/.ssh/authorized_keys
ip=$(wget -qO-  ipecho.net/plain)>/dev/null &&\
echo "Success. You can now test logging in with ssh:";\
echo "       $ ssh -i ~/.ssh/<key file> -v $USER@$ip"||\
echo 'Temporary error. Try logging in with ssh key'

}

if [[ ! -f ~/.ssh/authorized_keys ]] ; then
conf_ssh
fi

echo 'Done, updating system and installing software'

which sudo >/dev/null 2>&1 &&\
if groups $USER|grep sudo >/dev/null 2>&1 ; then gotSudo='True' ;fi


if [[ "$gotSudo" != "True" ]]; then
  (export user=$USER
  su -c "apt -y update ;apt -y install sudo;usermod -a -G sudo $user"
  echo 'Please log out of ssh and in again, and rerun this script to finish.')
fi



install_stuff

firewall_up


