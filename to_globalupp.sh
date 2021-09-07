#!/bin/bash
#set -x

# konfiguruje sssd proti AD domene global.upp.cz
# nastavi chrony proti AD serverum
# pouzivame jmeno.prijmeni (bez FQDN)
# UID,GID se bere z unix rozsireni AD
# vytvari home adresare
# default shell je /bin/bash

prefix='/etc'

ver=`rpm -q --queryformat '%{VERSION}' centos-release`
if [ "$ver" != "7" ]; then
   echo "Bad version OS (version 7 required)..."
   exit 1
fi

echo "Instalace potrebnych baliku"
yum install -y realmd oddjob oddjob-mkhomedir chrony sssd samba-common-tools krb5-workstation 

currentTimestamp=`date +%y-%m-%d-%H:%M:%S`

echo "Synchronizace casu"

# remove 'centos' clock source 
sed -i 's/^#server [0123].centos.pool.ntp.org/#&/' /etc/chrony.conf

# add AD clock source
echo server srv-upp01.global.upp.cz iburst >>/etc/chrony.conf

systemctl enable chronyd
systemctl restart chronyd

echo "Join do domeny global.upp.cz"
echo "Zadej username s pravy admina v AD ve tvaru jmeno.prijmeni:"
read ad_admin
echo "a ted to bude chvili trvat..."
realm join global.upp.cz --user=$ad_admin

if [ $? -eq 0 ]; then
    echo "Configure sssd.conf."
    sssdConfFile="$prefix/sssd/sssd.conf"
    sssdConfFileBackup=$sssdConfFile.$currentTimestamp.bak
    if [ -f "$sssdConfFile" ]; then
        echo backup $sssdConfFile to $sssdConfFileBackup
        cp $sssdConfFile $sssdConfFileBackup
    fi

    echo >$prefix/sssd/sssd.conf
    chmod 600 $prefix/sssd/sssd.conf

    cat > "$sssdConfFile" << EOF
[domain/global.upp.cz]
ad_domain = global.upp.cz
krb5_realm = GLOBAL.UPP.CZ
krb5_ccname_template = FILE:%d/krb5cc_%U_XXXXXX
realmd_tags = manages-system joined-with-samba
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = False
use_fully_qualified_names = False
fallback_homedir = /home/%u
access_provider = ad
debug_level = 0
dyndns_update_ptr = false

[sssd]
services = nss, pam
config_file_version = 2
domains = global.upp.cz

[nss]

[pam]

EOF
    rm -f /var/lib/sss/db/* 2>/dev/null
    echo "Restart SSSD"
    rpm -q systemd && systemctl restart sssd || service sssd restart
else
    echo "---------------------------------------------------"
    echo "Chyba prikazu join"
fi
