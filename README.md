# vpsdeploy.sh
#

Quickly secure and configure a new vps. Getting root passwords by email sucks, this script helps you quickly add a non-root user, an ssh key, a firewall, updates the repo lists and software, and then installs whatever software you define in the GET_LIST variable. Also set your default ssh key near the top of the script.

### Usage

1) Upload this script to your home dir on a fresh Debian 8 install <br>
2) Run the script <br>
3) Follow the prompts <br>

# Changelog V 3
* Litterally rewrote everything
* Automatically installs dnscrypt-proxy, nsa-proof's SSHD, does other cool stuff.
* It's just better.


# Changelog V 2.1
* Fixed error causing .ssh folder to appear in /home and not /home/$user
* Added fuctionality to automatically deteremine if this a Debian Jessie system, and only then ask to add Kali repos
# New in v 2.0
* Now you paste your pub key into the shell instaed of having to save it to the conf directory before running!
* No longer need to add your sshd_config to the conf dir either, the script will generate it for you! 


Changes in v 1.2
- Removed dont_KILL feature, as it's not necessary and was more of annoyance than anything else.
- The script actaully works now. (That' always good).
- Better error checking.
- Better portability accross distros.
