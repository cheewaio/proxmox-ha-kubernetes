# version=RHEL9

# Use text mode install
text

# Disable Initial Setup on first boot
firstboot --disable

# Keyboard layout
keyboard us

# System language
lang en_US.UTF-8

# Network information
network --bootproto=dhcp --device=link --activate
network --hostname=${ssh_hostname}
firewall --disabled

# SELinux configuration
selinux --permissive

# Do not configure the X Window System
skipx

# System timezone
timezone America/Toronto --utc

# Disable root password
rootpw --lock

# Add admin user
user --groups=wheel --name=${ssh_username} --lock --gecos=${ssh_username}
sshkey --username=${ssh_username} "${ssh_public_key}"

# System bootloader configuration
bootloader --location=mbr --boot-drive=sda

# Clear the Master Boot Record
zerombr

# Perform automatic partition with no swap
clearpart --all --initlabel
autopart --type=plain --noswap

# Reboot after successful installation
reboot

# Customize packages to install
%packages --ignoremissing --excludedocs
@^minimal-environment
qemu-guest-agent
sed
-iwl*firmware
%end

# Enable/disable the following services
services --enabled=sshd

# Post installation scripts
%post --interpreter /bin/bash

# Changing to VT 3 to watch for post-installation progress
exec < /dev/tty3 > /dev/tty3
/usr/bin/chvt 3
(

# cloud-init
dnf install -y cloud-init cloud-utils-growpart gdisk
cat <<EOF > /etc/cloud/cloud.cfg.d/99_pve.cfg
#cloud-config
system_info:
  default_user:
    name: ${ssh_username}
EOF

# Passwordless sudo for the admin user
echo "${ssh_username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${ssh_username} 

# Upgrade all packages
dnf upgrade -y --exclude=kernel*

# Setup motd
dnf install -y epel-release 
dnf install -y figlet
curl https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch > /usr/local/bin/pfetch
chmod 755 /usr/local/bin/pfetch
cat <<EOF > /etc/profile.d/motd.sh
#!/bin/bash
figlet "   \$(hostname -s)"; echo; /usr/local/bin/pfetch
EOF
chmod 644 /etc/profile.d/motd.sh

# Remove the package cache
dnf clean -y all

) 2>&1 | tee /root/post-install.log
/usr/bin/chvt 1

%end 
