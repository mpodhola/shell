#!/bin/bash
#backup skript
#Martin Podhola 21.9.2017 
#Zaloha upptools pomoci rdiff backupu plus archivace zaloh pomoci taru  zalohuje se 22x dene plus jednou za 14 dni v pondeli dojde ke kompletni archivaci a promazani starych zaloh.

DAY=`date +"%u"`
#HOUR=`date +"%k"`
DATE=`date +"%d_%m_%y"`
HM=`date +"%H_%M"`
WEEK=`date +%W`
if [ $((WEEK%2)) -eq 0 ]; then
       SUD=1
else
        SUD=0
fi

LOCK=/tmp/back.lock
SOURCE=/upptools
TARGET=/upptools_backup
OLD=/upptools_archive
LOG=/root/logs/backup_log_$DATE.log

if [ -f $LOCK ]; then 
	echo "`date +"%H_%M"` Zaloha jiz bezi existuje lock file" >$LOG
	exit 1

else
	touch $LOCK
	echo "`date +"%H_%M"` Zalohovaci uloha Upptools spustena" >$LOG

fi


for (( i=1; i<=22; i++ ))
do
HOUR=`date +"%k"`
if [ $SUD -eq 1 ] && [ $DAY -eq 1 ] && [ $HOUR -eq 3 ]; then
		echo "`date +"%H_%M"` supusteni zalohy + archivace + promazani starsich archivu a zaloh " >> $LOG
		rdiff-backup $SOURCE $TARGET
		echo "`date +"%H_%M"` Provedena zaloha upptools" >> $LOG
		echo "`date +"%H_%M"` Smazany archivy starsi nez 28 dni" >> $LOG
		find $OLD -mtime +28 -exec rm {} \;
                echo "`date +"%H_%M"` Provedeni archivace upptools" >> $LOG
		tar -cvzf $OLD/upptools_dayly_backup_$DAY_$WEEK.tar.gz $TARGET
                echo "`date +"%H_%M"` Provedena smazani zalohy upptools starsi jak 2 tydny" >> $LOG 
		rdiff-backup --remove-older-than 2W $TARGE
		echo "`date +"%H_%M"` Provedena zaloha upptools + archivace  + odmazani starich archivu a zaloh" >> $LOG
	else
        	echo "`date +"%H_%M"` Spustena zaloha upptools" >> $LOG
        	rdiff-backup $SOURCE $TARGET
        	echo "`date +"%H_%M"` Provedena zaloha upptools" >> $LOG
fi

sleep 1h
done
echo "`date +"%H_%M"` FIN `date` " >> $LOG
rm /tmp/back.lock
exit 0
