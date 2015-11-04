# vpsdeploy.sh
#

This version is for deploying Kali Linux/Debian Jessie servers for pentesting or whatever. Adds Kali repos during system updates. Obviously you should use this only on Debian 8 servers.

Quickly secure and configure a new vps. Getting root passwords by email sucks, this script helps you quickly add a non-root user, an ssh key, a firewall,
updates the repo lists and software, and then installs/removes whatever software you define in this GETLIST and KILLLIST variables.
Upload this script to /tmp or somewhere.

1) Generate your keys
2) Run the script
3) Follow the prompts

# New in v 2.0
* Now you paste your pub key into the shell instaed of having to save it to the conf directory before running!
* No longer need to add your sshd_config to the conf dir either, the script will generate it for you! 


Changes in v 1.2
- Removed dont_KILL feature, as it's not necessary and was more of annoyance than anything else.
- The script actaully works now. (That' always good).
- Better error checking.
- Better portability accross distros.
