#######################################
## VPS Deploy Version  1.1 |------>  ##
## 	    Author Chev Y. |	     ##
#######################################
#!/bin/bash
#
##Define Variables##
##GETLIST: programs for apt to install
##KILLLIST: programs for apt to remove
##Upload to /root and run ./deploy.sh
######################################
GETLIST="harden-servers apache2 php5 mysql-server secure-delete git openvpn"
KILLLIST="popularity-contest zeitgeist zeitgeist-core"
CONFDIR="/root/deploy/conf"
DEPLOG="/root/deploy/deploy.log"
########################################
##Error Messages##
SSHERROR1='SSH Configuration Error'
SSHERROR2='ERROR SETTING PUBKEY'
SSHERROR3='ERROR Restarting ssh daemon!'
FWERROR1='Error enabling firewall!'
FWERROR2='Error opening port or port already open.'
AptError1='Error updating system!'
userERROR="Cannot cd to /home/$username"
#######################################
RIGHT_NOW=$(date +"%x %r %Z")

function disp_HELP()
{

echo -e "
##########################################################
## VPSDEPLOY Version 1.1				##
## QuicklySecure and Configure a VPS server		##
## Getting root pws by email sucks. This script is	##
## intended to reduce the vulnerability window. 	##
## Copy this directory with desired ssh_config and	##
## authorized_keys file in /conf dir to VPS.		##
## Then just execute it and follow the promps!		##
##########################################################
"

}

function config_USER()
{
	touch $DEPLOG && echo $RIGHT_NOW >> $DEPLOG
	echo "Specify credentials." 	#Username+Password of admin user

	read -p "Enter username : " username
	read -s -p "Enter password : " password

					# Encrpyts the password variable with perl
	pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
	echo "Done."
	echo "Go...! Setting up a user, ssh key and the firewall!"
	echo "$username" /etc/passwd >/dev/null
		useradd -m -p password $username
		[ $? -eq 0 ] && echo "User $username has been added to system!" || echo "Adduser Fail!"
}

function config_SSH()
{

cd /etc/ssh || echo $SSHERROR1
mv sshd_config sshd_config.orig || echo $SSHERROR1 	  # Backup sshd original
cp -p $CONFDIR/sshd_config /etc/ssh/sshd_config || echo $SSHERROR1 # Preserve permissions&
						  	#copy sshd_config
						  	# Copies pub key to admin's ~/.ssh:
cd /home/$username || echo $userERROR

if [ ! -d /home/$username/.ssh ]; then
    mkdir .ssh && cp -p $CONFDIR/authorized_keys /home/$username/.ssh/authorized_keys || echo $SSHERROR1
else
   cp -p $CONFDIR/authorized_keys /home/$username/.ssh/authorized_keys || echo $SSHERROR2
fi

chmod 600 /home/$username/.ssh/authorized_keys 				# Ensures integrity of permissions
chmod 700 /home/$username/.ssh
chown -R $username:$username /home/$username		# Make sure all config files are owned by user
}

function config_FW()
{

apt-get install ufw -y -qq > /dev/null			# Ensure ufw is installed
echo "Specify port number for incoming ssh connections" #port for ufw to open for ssh
read SHPORT
ufw allow $SHPORT >> $DEPLOG || echo $FWERROR2 >> $DEPLOG			# Open configured ssh port
ufw allow 22 || echo $FWERROR2							# Don't break our current session
										#(change port if different than 22)
echo "Now will enable firewall and ssh.  After server is updated, the firewall "
echo "will disable itself for 120 seconds to ensure you don't get locked out."


ufw enable >> $DEPLOG || echo $FWERROR1 >> $DEPLOG
service ssh restart >> $DEPLOG || echo $SSHERROR3 >> $DEPLOG 			# Reload our new configuration

echo Done. Server is secure. Now updating software...Please try to login as $username on port $SHPORT with your private key.
}

function update_SYS()
{
	echo "Performing System Updates..." # Update repos&software

apt-get update -qq && apt-get upgrade -y -qq >> $DEPLOG || echo $AptError1 >> $DEPLOG

	echo "Now installing: $GETLIST..."

apt-get install -y -qq $GETLIST || echo "Error installing some  program(s)" >> $DEPLOG # Install/Remove desired programs
	echo "Removing programs: $KILLLIST"
apt-get remove -y -qq $KILLLIST || echo "Kill list error!" >> $DEPLOG ;
}

function dont_KILL()
{
ufw disable >> $DEPLOG	# In case something goes wrong and you get locked out
sleep 120		# Disable UFW for a 2 min window so you can log in,
ufw enable >> $DEPLOG		# then reenable it. (Should not happen)
}

disp_HELP
config_USER
config_SSH
config_FW
update_SYS
dont_KILL

exit
