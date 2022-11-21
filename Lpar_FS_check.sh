#!/usr/bin/ksh
#Martin Podhola IBM 22042016 
#Uprava skriptu puvodniho z roku 2012  pridano automaticke odesilani a predano na uzivatele csszadmin a zmena slozky pro logy

D=$(date +"%Y-%m-%d_%H%M")
DAT=$(date +"%d/%m/%Y")
CAS=$(date +"%T")
REPORT=/home/csszadm/Reporty/FS_check/Lpar_fs_report_${D}.txt
#HOSTNAME=`hostname`
touch /home/csszadm/tmp/tmp_fajl1
touch /home/csszadm/tmp/tmp_fajl2
TMPF=/home/csszadm/tmp/tmp_fajl1
TMPF2=/home/csszadm/tmp/tmp_fajl2
TMPF3=/home/csszadm/tmp/tmp_fajl3
ADRESY='reporty.cdu@cssz.cz'

echo '###################################################' > $REPORT
echo DATUM ${DAT} >> $REPORT
echo CAS ${CAS} >> $REPORT
echo '###################################################' >> $REPORT


for MACHINE in aix01mng  aix02mng aix03mng aix04mng  aix05mng  aix06mng aix11mng  aix12mng  aix13mng  aix14mng aix21mng aix22mng aix23mng aix24mng aix25mng aix26mng aix27mng aix28mng aix1p2mng aix2p2mng aix1t2mng aix2t2mng aix1i2mng aix2i2mng aix07mng aix08mng aix1p1mng aix2p1mng aix1t1mng aix2t1mng aix1i1mng aix2i1mng aix1i3mng aix2i3mng aix1t3mng aix2t3mng aix1p3mng aix2p3mng

#for MACHINE in aix03mng aix17mng aix15mng

do

	#print $MACHINE
	HOSTNAME=`ssh $MACHINE hostname`
	ssh $MACHINE df -g | grep dev | grep -v '/dev/dms' | awk '{print $1 " "$4 " " $7}' > $TMPF
	ssh $MACHINE df -g | grep dev | grep archive | awk '{print $1 " "$4 " " $7}' > $TMPF2
	
	if [ $MACHINE = aix01mng ] 
		then
			ssh aix01mng df -g | grep dev | grep oratmp | awk '{print $1 " "$4 " " $7}' > $TMPF3 
	fi
	
	echo '###################################################' >> $REPORT
	echo   $HOSTNAME 95\% >> $REPORT
	STAV=95
		while (( $STAV <= 100 ));
		do
		cat ${TMPF} | grep ${STAV} >> $REPORT
		#(( STAV ++ ))
		STAV=`expr $STAV + 1`
		done
	echo >> $REPORT
	echo '...................................................' >> $REPORT
	echo  $HOSTNAME archive 60\% >> $REPORT
	STAV2=60
        	while (( $STAV2 <= 100 ));
        	do
        	cat $TMPF2 | grep $STAV2 >> $REPORT
	if [ $HOSTNAME = aix01mng ] 
		then	
			cat $TMPF3  | grep $STAV2 >> $REPORT	
	fi
		#(( STAV2 ++ ))
		STAV2=`expr $STAV2 + 1`
		done
	echo >>$REPORT
	
	
	
	echo '...................................................' >> $REPORT
	ssh $MACHINE lsps -s >> $REPORT 

	rm $TMPF $TMPF2
done


echo '###################################################' >> $REPORT
echo 'END' >> $REPORT

#odesilani
cd /home/csszadm/Reporty/FS_check/

A=$(ls -t *.txt| head -1) 

uuencode $A $A  | mailx -s "Pravidelna statistika FS CDU ${D}" $ADRESY


#rm ${VYSTUP}

exit 0

