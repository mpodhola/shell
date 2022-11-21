#!/bin/bash

TDATE=$(date  "+%d_%m_%y")

mount 192.168.0.10:/mnt/interprax_pool/VM_BACKUP /vm_backup

sep()
{
echo "*********************" >> $log
}

testrv()
{
if [ "$RV" == "0" ]; then echo "OK."; else echo "PROBLEM!"; exit; fi
}

l()
{
DATE=$(date "+%m-%d-%y %H-%M-%S")
echo "$DATE --- $MSG" >> $log
}

log=/var/log/backup_vm.log

target=$(mount |grep 192.168.0.10 > /dev/null 2>&1;echo $?)
if [[ $target -eq 1 ]]; then
    MSG="backup storage je nepripojen zousim remount";l
    mount -a
    if [[ $? -eq 1 ]]; then
        MSG="remount se nepodaril zkontrolujte stav backup storage!";l
        exit 1
    fi
fi



vml=`virsh list | grep running | awk '{print $2}'| xargs`

for i in $vml
    do
        MSG="zaloha $i zahajena";sep;l
        for a in $(seq 1 1 10);
        do
            if  ! virsh shutdown $i  ; then
                    MSG="Virtual je vypnuty, zacinam kopirovat" ;l
                    if  cp /vm/$i.img /vm_backup/interprax_server_backups/; then
                    virsh dumpxml $i > /vm_backup/vm_xml/$i.xml;MSG="backup probehl uspesne byl zazalohovan jak disk tak i xml vm";l
                            virsh start $i ;MSG="virtual $i je znovu v provozu backup byl uspeny";l;sep
                          cd /vm_backup/interprax_server_backups/
                           tar -czvf  backup_${i}_${TDATE}.tar.gz ${i}.img
                           find /vm_backup/interprax_server_backups/ -mtime +7 -exec rm -f {} \;
			umount -lf /vm_backup
                    fi
                    exit;
                else sleep 10;
                    MSG="Virtual se nepodarilo vypnout, opakuji akci znovu $i" ;l;sep;
                    fi;
        done
    done
exit 0
