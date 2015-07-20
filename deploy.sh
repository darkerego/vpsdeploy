#!/bin/bash
##################################################
## 	VPS Deploy V 1.2 -- Author DarkerEgo  	##
##################################################
## Define Programs to install/uninstall here:
GETLIST="harden-servers apache2 php5 secure-delete git openvpn"
KILLLIST="popularity-contest zeitgeist zeitgeist-core"
########
cwd=$(pwd)
CONFDIR="$cwd/conf"
DEPLOG="$cwd/deploy.log"
username=$username
RIGHT_NOW=$(date +"%x %r %Z")
######################################
##Error Messages
SSHERROR1='SSH Configuration Error'
SSHERROR2='ERROR SETTING PUBKEY'
SSHERROR3='ERROR Restarting ssh daemon!'
FWERROR1='Error enabling firewall!'
FWERROR2='Error opening port or port already open.'
AptError1='Error updating system!'
confERROR="Can't find all the config files we need... place sshd_config and authorized_keys in /conf & rerun."
confERROR1="Make sure your sshd_config is in the 'conf' directory and rerun."
confERROR1="Make sure your authorized_keys is in the 'conf' directory and rerun."
#######################################

if [ ! -d $cwd/conf ]; then
mkdir conf
echo $confERROR1
exit
fi

if [ ! -f $cwd/conf/sshd_config ]; then
echo $confERROR
echo $confERROR1
exit
fi

if [ ! -f $cwd/conf/authorized_keys ]; then
echo $confERROR
echo $confERROR2
exit
fi

echo -e "
##########################################################
################# VPSDEPLOY Version 1.2 ##################
## A shell script that automates the configuration of	##
## a linux system. Originally intended to be used only	##
## on Debian-esc VPS systems, but should work on any 	##
## linux box. Put your authorized_keys and sshd_config	##
## file in the 'conf' directory. Upload to the target	##
## system, execute, follow the prompts, and done!	##
##########################################################
"


function config_USER(){
echo Configuring user...
touch $DEPLOG && echo $RIGHT_NOW >> $DEPLOG
echo "Specify credentials." #Username+Password of admin user
read -p "Enter username : " username
read -s -p "Enter password : " password
# Encrpyts the password variable with perl
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
echo "Done."
echo "Go...! Setting up a user, ssh key and the firewall!"
echo "$username" /etc/passwd >/dev/null
useradd -m -p password $username
[ $? -eq 0 ] && echo "User $username has been added to system!" || echo "Adduser Fail!"
#usermod -a -G sudo $username || echo 'Config sudo fail, do we have sudo?'
}


function config_SSH(){
echo "checking for home dir..."

if [ ! -d /home/$username ]; then
mkdir /home/$username
chown $username:$username /home/username
chmod 750 /home/username
fi

echo "checking for user/.ssh"

if [ ! -d /home/$username/.ssh ]; then
mkdir /home/$username/.ssh
chmod 700 /home/$username/.ssh
fi

echo copying keyfile to .ssh

cp -p $CONFDIR/authorized_keys /home/$username/.ssh/authorized_keys || echo $SSHERROR1

echo ensuring permissions

chmod 600 /home/$username/.ssh/authorized_keys # Ensures integrity of permissions
chmod 700 /home/$username/.ssh
chown -R $username:$username /home/$username	# Make sure all config files are owned by user

echo copying sshd file..

mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig || echo $SSHERROR1 # Backup sshd original
cp -p $CONFDIR/sshd_config /etc/ssh/sshd_config || echo $SSHERROR1 # Preserve permissions
service ssh reload
service ssh restart
}

function config_FW(){

apt-get install ufw -y -qq > /dev/null # Ensure ufw is installed
echo "Specify port number for incoming ssh connections" #port for ufw to open for ssh
read SHPORT
ufw allow in to any port $SHPORT proto tcp >> $DEPLOG || echo $FWERROR2 >> $DEPLOG	# Open configured ssh port
ufw allow in to any port 22 proto tcp || echo $FWERROR2	# Don't break our current session

echo "Now will enable firewall..."
ufw enable >> $DEPLOG || echo $FWERROR1 >> $DEPLOG
service ssh restart || service ssh start >> $DEPLOG || echo $SSHERROR3 >> $DEPLOG # Reload our new configuration

echo Done. Setting kernel tweaks...Please try to login as $username on port $SHPORT with your private key.
}


function tweak_KERN(){
echo "Settings sysctl tweaks..."
sysctl -w net.netfilter.nf_conntrack_timestamp=1
sysctl -w net.ipv4.conf.default.rp_filter=1
sysctl -w net.ipv4.conf.all.rp_filter=1
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv6.conf.all.accept_source_route=0
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w vm.swappiness=10
sysctl -w kernel.randomize_va_space=1
sysctl -w net.ipv4.conf.all.log_martians=1
sysctl -p >> $DEPLOG
}

function update_SYS()
{
echo "Performing System Updates..." # Update repos&software
apt-get update -qq && apt-get upgrade -y -qq >> $DEPLOG || echo $AptError1 >> $DEPLOG
echo "Now installing: $GETLIST..."
apt-get install -y -qq $GETLIST || echo "Error installing some program(s)" >> $DEPLOG # Install/Remove desired programs
echo "Removing programs: $KILLLIST"
apt-get remove -y -qq $KILLLIST || echo "Kill list error!" >> $DEPLOG
}




tweak_KERN
config_USER
config_SSH
config_FW
update_SYS

echo "All done!"

exit
