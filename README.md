# vpsdeploy.sh
#
Quickly secure and configure a new vps. Getting root passwords by email sucks, this script helps you quickly add a non-root user, an ssh key, a firewall,
updates the repo lists and software, and then installs/removes whatever software you define in this GETLIST and KILLLIST variables.
Upload entire directory (deploy) to /root with desired sshd_config and authorized_keys file in the deploy/conf directory.

1) Generate your keys and sshd_config files.
2) Place them in the conf dir with 600 permissions
3) SSH into your new vps, upload deploy to /root
4) Execute with ./deploy.sh and follow the prompts.

Changes in v 1.2
- Removed dont_KILL feature, as it's not necessary and was more of annoyance than anything else.
- The script actaully works now. (That' always good).
- Better error checking.
- Better portability accross distros.

# conf
Create a directory called 'conf' and add the following customized files:
authorized_keys
sshd_config
