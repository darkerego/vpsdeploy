#!/bin/bash
##########################################################
##      VPS Deploy V 1.3 -- Author Chev Y.              ##
##      https://github.com/darkerego                    ##
##########################################################
##########################################################
# A shell script that automates the configuration of     #
# a linux system. Originally intended to be used only    #
# on Debian-esc VPS systems, but should work on any      #
# linux box. Upload to the target system, execute,       #
# follow the prompts, and you're done.                   #
##########################################################
## Define Programs to install/uninstall here:
GETLIST="harden-servers apache2 php5 secure-delete git openvpn"
KILLLIST="popularity-contest zeitgeist zeitgeist-core"
########
cwd=$(pwd)
CONFDIR="$cwd/conf"
DEPLOG="$cwd/deploy.log"
username=$username
RIGHT_NOW=$(date +"%x %r %Z")
########
##Error Messages
error1="Error setting shell!"
SSHERROR1='SSH Configuration Error'
SSHERROR2='ERROR SETTING PUBKEY'
SSHERROR3='ERROR Restarting ssh daemon!'
FWERROR1='Error enabling firewall!'
FWERROR2='Error opening port or port already open.'
AptError1='Error updating system!'
erNoRoot="Must be ROOT to run this script"

# Now the script reads this data from the command line; inserts it into these files.

# For the future, maybe..
#fucntion log() 
#{
#  while read data
#  do
#      echo "[$(date +"%D %T")] $data" 
#  done
#}

if [[ $(whoami) != "root" ]];then
	echo erNoRoot
	exit1
fi


# Read u/p & add a user. If Y then add user to group sudo
 
function hello(){

echo -e "
##########################################################
#                #VpS_DeploY # Version 2.0#              #
# A shell script that automates the configuration of     #
# a linux system. Originally intended to be used only    #
# on Debian-esc VPS systems, but should work on any      #
# linux box. Upload to the target system, execute,       #
# follow the prompts, and you're done!                   #
##########################################################
# Version 2.0 - Changes:                                 #
# - Now reads ssh key and ssh options from shell so you  #
#   don't need to save them to file before running       #
##########################################################
"
if [ ! -d $cwd/conf ]; then
        mkdir conf
fi


echo "Ready...";sleep 1;echo "Set...";sleep 1;echo "GO!";echo
}
function config_USER(){
if [ $(id -u) -eq 0 ]; then
        echo "Specify credentials. (Username+Password of user we're about to add)"
	sleep 1
        #(echo VpsDeploy $RIGHT_NOW) > $DEPLOG
        read -p "Enter username : " username
        read -s -p "Enter password : " password
        echo "Configuring user..."
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
                echo "$username exists!"
                exit 1
        else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
                useradd -m -p $pass $username
                [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
                echo "Setting user shell to BASH..."
                usermod -s /bin/bash $username || echo $error1
 
                read -p "Should the user have sudo privileges? (Y/N) :" sudoYN
                        if [ "$sudoYN" == "Y" ]; then
                                usermod -a -G sudo $username || echo 'Config sudo fail, do we have sudo?'
                        else
                                 echo Standard account created.
                        fi
        fi
else
        echo $erNoRoot
        exit 2
fi

 
# Configure SSH
 
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
read -p "Specify port number for incoming ssh connections : " SHPORT
echo Port $SHPORT > $cwd/conf/sshd_config
cat <<EOF >> $cwd/conf/sshd_config
Port 22
#ListenAddress ::
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 60
PermitRootLogin no
StrictModes yes
#AllowUsers $user
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile      %h/.ssh/authorized_keys
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
#IgnoreUserKnownHosts yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication no
# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no
#MaxStartups 10:30:60
#Banner /etc/issue.net
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM no
EOF
 
 
echo
read -p "Paste your ssh public key here: " ssh_KEY;echo
echo $ssh_KEY > $CONFDIR/authorized_keys
 
cp -p $CONFDIR/authorized_keys /home/$username/.ssh/authorized_keys && echo SSH key installed... || echo $SSHERROR1
 
echo Ensuring correct permissions...
 
chmod 600 /home/$username/.ssh/authorized_keys # Ensures integrity of permissions
chmod 700 /home/$username/.ssh
chown -R $username:$username /home/$username    # Make sure all config files are owned by user
 
echo "Writing sshd_config to file.."
echo "Backing up original..."
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig || echo $SSHERROR1 # Backup sshd original
cp -p $CONFDIR/sshd_config /etc/ssh/sshd_config || echo $SSHERROR1 # Preserve permissions

service ssh restart || service ssh start
 
 
 
echo "Checking for ufw..."
apt-get install ufw -y -qq > /dev/null # Ensure ufw is installed
echo "Allowing ssh port $SHPORT ..."
ufw allow $SHPORT || echo $FWERROR2     # Open configured ssh port
ufw allow 22 || echo $FWERROR2  # Don't break our current session
 
echo "Now will enable firewall..."
ufw enable  || echo $FWERROR1 || ufw restart || echo $FWERROR1
service ssh restart || service ssh start  || echo $SSHERROR3  # Reload our new configuration
 
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
        sysctl -p
}
 
function update_SYS()
{
# Are we on Debian Jessie?

ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
JES="Debian Jessie"
askKali=false

if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    VER=$(cat /etc/debian_version)
elif [ -f /etc/redhat-release ]; then
    # TODO add code for Red Hat and CentOS here
echo;echo
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

for i in $OS $VER $ARCH;do echo $i;done

if [[ $OS == "Debian" ]];then
        if [[ $VER == "8" ]]; then
        askKali=true
        elif [[$VER == "8.1" ]];then
        askKali=true
        elif [[$VER == "8.2" ]];then
        askKali=true
        fi
fi

if [[ $askKali == "true" ]];then

	echo "It appears this is a Debian Jessie system...($OS $VER $ARCH) ";sleep 1
	read -p "Would you like to add the Kali Linux repos? (Y/N) :" kaliYn
	if [[ $kaliYn == "Y" ]];then
    		deb http://http.kali.org/kali sana main non-free contrib
    		deb http://security.kali.org/kali-security sana/updates main contrib non-free
    		deb-src http://http.kali.org/kali sana main non-free contrib
    		deb-src http://security.kali.org/kali-security sana/updates main contrib non-free
    		gpg --keyserver pgpkeys.mit.edu --recv-key ED444FF07D8D0BF6
    		gpg -a --export ED444FF07D8D0BF6| apt-key add -
 	fi
fi

echo "Performing System Updates..." # Update repos&software
apt-get update -y -q && apt-get upgrade -y -q  || echo $AptError1
echo "Now installing: $GETLIST..."
apt-get install -y -q $GETLIST || echo "Error installing some program(s)"  # Install/Remove desired programs
echo "Removing programs: $KILLLIST"
apt-get remove -y -q $KILLLIST || echo "Kill list error!"
}
 
 
 
 
hello | tee $DEPLOG
#config_USER | log >> $DEPLOG
#update_SYS | log >> $DEPLOG
#tweak_KERN | log >> $DEPLOG
config_USER | tee -a $DEPLOG
update_SYS | tee -a $DEPLOG
tweak_KERN | tee -a $DEPLOG
 
echo "All done!"
echo Log written to $deplog
 
exit 0
