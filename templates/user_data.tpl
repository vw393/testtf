From nobody Fri Dec  9 00:31:04 2016
Content-Type: multipart/mixed; boundary="====BOUNDARY===="
MIME-Version: 1.0

--====BOUNDARY====
MIME-Version: 1.0
Content-Type: text/cloud-config; charset="us-ascii"

#cloud-config

groups:
- ${login_name}: [${login_name}]

disable_root: 1
ssh_pwauth: 0

syslog_fix_perms: ~

users:
- name: ${login_name}
  gecos: ${login_name} user
  primary_group: ${login_name}
  homedir: /home/${login_name}
  lock_passwd: true
  sudo: ALL=(ALL) NOPASSWD:ALL
  groups: [wheel]
  ssh_authorized_keys: [${ssh_keys}]

bootcmd:
- /usr/sbin/setenforce 0

write_files:
- path: /etc/selinux/config
  owner: root:root
  permissions: '0400'
  encoding: b64
  content: |
    U0VMSU5VWD1kaXNhYmxlZApTRUxJTlVYVFlQRT10YXJnZXRlZAo=
- path: /root/.lvm-pvs.json
  owner: root:root
  permissions: '0400'
  content: |
    ${json_pvs}
- path: /root/.lvm-lvs.json
  owner: root:root
  permissions: '0400'
  content: |
    ${json_lvs}
- path: /sbin/configure-lvm.sh
  owner: root:root
  permissions: '0755'
  encoding: b64
  content: |
    ${lvm_setup}

package_update: true
packages:
- lvm2
- lvm2-libs
- lvm2-dbusd
- lvm2-lockd
- nvme-cli
- jq
- unzip

runcmd:
- /usr/sbin/setenforce 0
- hostnamectl set-hostname ${fqdn}
- yum install -y https://s3.eu-west-1.amazonaws.com/amazon-ssm-eu-west-1/latest/linux_amd64/amazon-ssm-agent.rpm
- systemctl enable amazon-ssm-agent
- systemctl restart amazon-ssm-agent
- cd /var/tmp && curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && unzip awscliv2.zip && ./aws/install
- /sbin/configure-lvm.sh

--====BOUNDARY====--
