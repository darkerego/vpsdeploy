# vpsdeploy.sh
#
Quickly secure and configure a new vps. Getting root passwords by email sucks, this script helps you quickly add a non-root user, an ssh key, a firewall,
updates the repo lists and software, and then installs/removes whatever software you define in this GETLIST and KILLLIST variables.
Upload entire directory (deploy) to /root with desired sshd_config and authorized_keys file in the deploy/conf directory.

1) Generate your keys and sshd_config files.
2) Place them in the conf dir with 600 permissions
3) SSH into your new vps, upload deploy to /root
4) Execute with ./deploy.sh and follow the prompts.

After everything is locked down, the firewall will disable itself for 120 seconds to ensure you do not get locked out. This should not happen,
but better safe than sorry!
# conf
Create a directory called 'conf' and add the following customized files:
authorized_keys
sshd_config
