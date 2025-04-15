
# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo " This script must be run as root"
   exit 1
fi

# Prompt for new hostname
read -p "Enter new hostname: " NEW_HOSTNAME
hostnamectl set-hostname "$NEW_HOSTNAME"
echo " Hostname changed to $NEW_HOSTNAME"

# Install EPEL and Cockpit
echo " Installing epel-release and Cockpit..."
dnf install -y epel-release
dnf install -y cockpit

# Enable Cockpit
systemctl enable --now cockpit.socket
echo " Cockpit installed and running."

# Prompt for AD domain and credentials
read -p "Enter AD Username: " AD_USER

# Install required ad packages
echo "Installing AD packages"
dnf install -y realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools

#join domain
realm join --user=$AD_USER boulder.local

if [[ $? -ne 0 ]]; then
  echo " Failed to join domain. Please check credentials and network settings."
  exit 1
fi

echo " Joined to domain: boulder.local"

# Verify domain joined
realm list


# Only make the change if the line exists and is currently set to true
SSSD_FILE="/etc/sssd/sssd.conf"
  sudo sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
  sudo systemctl restart sssd
  echo " Updated 'use_fully_qualified_names' to false in $SSSD_FILE"

# Restart SSSD to apply change
sudo systemctl restart sssd


# Add group to sudoers
echo -e "\n# AD_Group\n%it-sysadmin-linux ALL=(ALL) ALL" | sudo tee -a /etc/sudoers

chmod 440 "$SUDOERS_FILE"

echo "Sudoers file created for group it-sysadmin-linux"

# Ending
echo "Script complete. You can test sudo with a domain user in it-sysadmin-linux."
echo " Add the node to https://10.12.75.186:9090 Cockpit"




