#!/usr/local/bin/bash
#BSD verze syncovani upptools
#Martin Podhola 15.10.2018 - vytvoreno
#
#
#
########################################
LOCK_NAME="rsync_upptools"
LOCK_DIR='/tmp/'${LOCK_NAME}.lock
PID_FILE=${LOCK_DIR}'/'${LOCK_NAME}'.pid'
MAILTO="ws@upp.cz"
LOG=$0.log

if [ "$1" == "-v" ]; then VERB=1; else VERB=0; fi

sep()
{
if [ "$VERB" -eq 1 ]; then echo '***********************'; fi
}

v()
{
if [ "$VERB" -eq 1 ]; then echo $MSG; fi
}

l()
{
DATE=$(date "+%m-%d-%y %H-%M-%S")
echo "$DATE --- $MSG" >> $LOG
}

mailme()
{
echo "$MSG - RV=$RV" | mailx -s "UPPTOOLS02 rsync - ERROR" $MAILTO
}


error_quit()
{
sep; echo "ERROR!"; echo "MSG = $MSG"
if [ ! -z $RV ]; then echo "RV = $RV"; fi
sep; exit
}

rv()
{
RV=$1; if [ -z $2 ]; then ARG="0"; else ARG=$2; fi
test $RV -ne $ARG && error_quit
}





if mkdir ${LOCK_DIR} 2>/dev/null; then
  # If the ${LOCK_DIR} doesn't exist, then start working & store the ${PID_FILE}
  echo $$ > ${PID_FILE}

##BEH
MSG='***********************'; l
MSG="RSYNC UPPTOOLS vs LOCAL"; l; v; sep

#definovani zdroje a cile
SOURCE="/upptools_org2"
TARGET="/upptools"

#definovani podslozek pro synchronizace
WG="workgroups"
TL="tools"
SU="support"

#testovani zda li zdroj a cil je pripojen
MNTED=$(mount | grep $SOURCE > /dev/null 2>&1; echo $?)

#MNTED=$(mount | grep $SOURCE |wc -l)
#MNTED=$(df | grep $SOURCE| wc -l)
if [ "$MNTED" -ne 0 ]; then RV=$MNTED; MSG="$SOURCE nepripojen"; v; l; error_quit; else MSG="$SOURCE - OK"; v; l; fi
if [ ! -d "$TARGET" ]; then MSG="$TARGET nenalezen"; v; l; error_quit; else MSG="$TARGET - OK"; v; l; fi

FC1=$(ls $SOURCE/tools/|wc -l)
#FC2=$(ls $SOURCE/workgroups/|wc -l)
if [ $FC1 -eq 0 ]; then RV=$MNTED; MSG="$SOURCE nepripojen korektne"; v; l; error_quit; else MSG="$SOURCE - OK"; v; l; fi



ROPTIONS=(
    -azK
    -p
    --chmod=ugo+rwx
    #--exclude=.snapshot
    #--exclude=.DS_Store
    #--exclude='.Trash*'
    #--exclude=_trash
    #--exclude=.TemporaryItems
    #--inplace
    --delete
)
if [ "$VERB" -eq 1 ]; then ROPTIONS+=("-v"); fi

for a in $SOURCE/$WG $SOURCE/$TL $SOURCE/$SU; do
sep; MSG="START - rsync ${ROPTIONS[@]} $a $TARGET"; v; l; sep
rsync ${ROPTIONS[@]} $a $TARGET; rv $?
MSG="RSYNC - OK"; v; l
#echo
done

  rm -rf ${LOCK_DIR}
  exit
else
  if [ -f ${PID_FILE} ] && kill -0 $(cat ${PID_FILE}) 2>/dev/null; then
    # Confirm that the process file exists & a process
    # with that PID is truly running.
    echo "Running [PID "$(cat ${PID_FILE})"]" >&2
    exit
  else
    # If the process is not running, yet there is a PID file--like in the case
    # of a crash or sudden reboot--then get rid of the ${LOCK_DIR}
    rm -rf ${LOCK_DIR}
    exit
  fi
fi
