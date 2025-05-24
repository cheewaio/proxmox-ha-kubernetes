#cloud-config
autoinstall:
  version: 1
  ssh:
    authorized-keys:
      - ${ssh_public_key}
    install-server: true
  storage:
    layout:
      name: direct
    swap:
      size: 0
  user-data:
    hostname: ${ssh_hostname}
    preserve_hostname: false
    system_info:
      default_user:
        name: ${ssh_username}
    ssh_pwauth: false
    timezone: ${vm_timezone}
  packages:
    - figlet
    - qemu-guest-agent
  late-commands:
    - curl https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch > /target/usr/local/bin/pfetch
    - chmod 755 /target/usr/local/bin/pfetch
    - |
      cat <<EOF > /target/etc/profile.d/motd.sh
      #!/bin/bash
      figlet "   \$(hostname -s)"; echo; /usr/local/bin/pfetch
      EOF
    - chmod 644 /target/etc/profile.d/motd.sh
    - sed -i 's/^\/swap.img/# \/swap.img/g' /target/etc/fstab
    - curtin in-target --target /target -- update-grub2
    - curtin in-target --target=/target -- apt update
    - curtin in-target --target=/target -- apt upgrade -y
