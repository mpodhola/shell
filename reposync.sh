#!/bin/bash


nuc_sync () {
cd /var/www/html/repos/nux/
rm -rf li.nux.ro
wget --recursive --no-parent http://li.nux.ro/download/nux/dextop/el7/x86_64/
cd /var/www/html/repos/nux/li.nux.ro/download/nux/dextop/el7/x86_64
createrepo --database ./
exit 0
}

update_sync () {
cd /var/www/html/repos/centos/7.9.2009_updates
rm -rf mirror.karneval.cz
wget --recursive --no-parent http://mirror.karneval.cz/pub/centos/7.9.2009/updates/x86_64/Packages/
cd /var/www/html/repos/centos/7.9.2009_updates/mirror.karneval.cz/pub/centos/7.9.2009/updates
createrepo --database ./
exit 0
}

help () {
printf "nuc : syncnce repo nuc\n up : syncne update\n help : vypise help \n"
}

case $1 in
  "nuc")
  nuc_sync
  ;;
  "up")
  update_sys
  ;;
  "help")
  help
  exit 0
  ;;
  *)
  help
  exit 1
  ;;
esac
