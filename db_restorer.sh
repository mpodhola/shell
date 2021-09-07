#!/bin/bash
PATH=$PATH:/usr/local/xtrabackup/bin
#Restoring mysqldb
#Martin Podhola 12062018

DATE=`date +\%Y-\%m-\%d`
DATE2=`date +\%Y-\%m-\%d-\%H-\%M`
TMPDB=/backups/tmp
LOG=/var/log/partial_restore.log
CAS=`date`
#RESTOREFROM=$1
#RESTOREDAY=$2
#RESTOREHOUR=$3
#cleaning up tmp
help () {
printf "Skript na  restore databaze k danemu datu hodine. \n Skript provede restore podle pozadavku zastaveni a zpusteni vfxrestorer mysql! \n Spoustet skript se musi s parametry: \n -f databaze z ktere budete restorovat \"vfxdb01 nebo vfxdb02\" \n -d den ze kdy se bude restorovat format: YY-MM-DD \n -g hodina do ktere se bude restore provadet 1-23 \n"

}

sep()
{
echo "*********************" | tee > $LOG
}

testrv()
{
if [ "$RV" == "0" ]; then echo "OK."| tee >> $LOG; else echo "PROBLEM!"| tee >> $LOG; exit; fi
}



cleanup () {
  sep
  echo "$CAS" | tee >> $LOG
  echo "Clean up restore temp directory" | tee >> $LOG
A=`ls $TMPDB |wc -l`
if [ $A -gt 0 ]; then
  rm -rf $TMPDB/* > /dev/null 2>&1; RV=$?; testrv
fi
}
#copy actual backup to tmp


copy_backup () {
  echo "Cloning backup for partial restore" | tee >> $LOG
cp -rf /backups/$RESTOREFROM/${DATE}/FULL $TMPDB && echo "kopirovani fullbackupu OK!">> $LOG #&& cp -rf /backups/$RESTOREFROM/${DATE}/inc{1..$RESTOREHOUR} $TMPDB
echo "ttttt" >> $LOG
for i in $(seq 1 $RESTOREHOUR); do
echo "$i" >> $LOG
cp -rf /backups/$RESTOREFROM/${DATE}/inc$i $TMPDB ; echo "kopirovani inc$i bylo dokonceno" >> $LOG
done
}


restore()
{
            echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing the FULL backup" | tee >> $LOG
            xtrabackup --decompress --remove-original --parallel=4 --socket=/var/lib/mysql/mysql.sock --target-dir=$TMPDB/FULL
            echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing Done !!!"| tee >> $LOG

            echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing FULL Backup ..."| tee >> $LOG
            xtrabackup --prepare  --apply-log-only --socket=/var/lib/mysql/mysql.sock --target-dir=$TMPDB/FULL
            echo `date '+%Y-%m-%d %H:%M:%S:%s'`": FULL Backup Preparation Done!!!"| tee >> $LOG


            P=1
            while [ -d $TMPDB/inc$P ] && [ -d $TMPDB/inc$(($P+1)) ]
            do
                  echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$P"| tee >> $LOG
                  xtrabackup --decompress --remove-original --parallel=4 --socket=/var/lib/mysql/mysql.sock --target-dir=$TMPDB/inc$P
                  echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$P Done !!!"| tee >> $LOG

                  echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing incremental:$P" |tee >> $LOG
                  xtrabackup --prepare --apply-log-only --socket=/var/lib/mysql/mysql.sock --target-dir=$TMPDB/FULL --incremental-dir=$TMPDB/inc$P
                  echo `date '+%Y-%m-%d %H:%M:%S:%s'`": incremental:$P Preparation Done!!!"|tee >> $LOG
                  P=$(($P+1))
            done

            if [ -d $BACKUP_DIR/inc$P ]
            then
                echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing the last incremental:$P"| tee >> $LOG
                xtrabackup --decompress --remove-original --parallel=4 --socket=/var/lib/mysql/mysql.sock --target-dir=$TMPDB/inc$P
                echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing the last incremental:$P Done !!!"| tee >> $LOG

                echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing the last incremental:$P" | tee >> $LOG
                xtrabackup --prepare --target-dir=$BACKUP_DIR/FULL --socket=/var/lib/mysql/mysql.sock --incremental-dir=$TMPDB/inc$P
                echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Last incremental:$P Preparation Done!!!"|tee >> $LOG
            fi

}

copyfiles (){
#for a in $(seq 1 1 10);do
if  systemctl stop mysqld ; then
#systemctl stop mysqld

  sep;
  echo "mysql is down backuping old files" | tee >> $LOG
  tar -czvf /root/backupmysql_$DATE2.tar.gz /var/lib/mysql  > /dev/null 2>&1; RV=$?; testrv
  echo "copy backup to db"|tee >> $LOG
  cp -rf $TMPDB/FULL/ib* /var/lib/mysql/ && cp -rf $TMPDB/FULL/vfx /var/lib/mysql/ && cp -rf $TMPDB/FULL/fm_import /var/lib/mysql/ && cp -rf $TMPDB/FULL/redmine /var/lib/mysql/ && cp -rf $TMPDB/FULL/openfire /var/lib/mysql/
  chown -R mysql:mysql /var/lib/mysql
  echo "startdb" |tee >> $LOG
  systemctl start mysqld > /dev/null 2>&1; RV=$?; testrv
else
echo "DB se nepovedlo zastavit pro to konec!!" |tee >> $LOG
exit 1
fi

#done


}


while getopts ":vhf:d:g:" optname
  do
    case "$optname" in
      "v")
        version
        exit 0;
        ;;
      "h")
        help
        exit 0;
        ;;
      "?")
        echo "Unknown option $OPTARG"
        exit 0;
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        exit 0;
        ;;
      "f")
      RESTOREFROM=$OPTARG
        ;;
      "d")
      RESTOREDAY=$OPTARG

      ;;
      "g")
      RESTOREHOUR=$OPTARG
      ;;
	     *)
        echo "Nezname parmetry prosim opakujte znova -h"
        exit 0;
        ;;
    esac
  done
shift $(($OPTIND - 1))

cleanup
copy_backup
restore
copyfiles
exit 0
