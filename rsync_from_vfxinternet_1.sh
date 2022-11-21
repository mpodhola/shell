#!/bin/bash
#rsync pro vfxinternet
# 17.9.2018 - Martin Podhola
#LOCK=/tmp/upp.lock
LOCK_NAME="rsync_vfxinternet"
LOCK_DIR='/tmp/'${LOCK_NAME}.lock
PID_FILE=${LOCK_DIR}'/'${LOCK_NAME}'.pid'



umask 077
mkuser_file () {
ssh root@192.168.129.25 ls /home/ | grep -vw a | xargs > /tmp/users_onvfxinternet
}

mkstore_dirs () {
USERFILE=/tmp/users_onvfxinternet
DESTDIR=/upp/servers/vfxstore/VFXstore/FROM_INTERNET/VFXINTERNET
#DESTDIR=/tmp/test/
for i in $(cat $USERFILE); do
  if [ ! -d $DESTDIR/$i ]; then
    echo "vytvarim"
    mkdir $DESTDIR/$i
    chown $i:ldapusers $DESTDIR/$i
    #chmod 700 $DESTDIR/$i
  fi
done
}

rsync_data_from_internet () {
USERFILE=/tmp/users_onvfxinternet
  for i in $(cat $USERFILE ); do
    DESTTDIR=/upp/servers/vfxstore/VFXstore/FROM_INTERNET/VFXINTERNET/$i
    # DESTTDIR=/tmp/test/$i
    rsync  --remove-source-files -chavzP root@192.168.129.25:/home/$i/transfer/ $DESTTDIR
    chmod 700 $DESTTDIR
  done
}

#if  [ -f $LOCK ]; then exit 1; fi
#touch $LOCK

if mkdir ${LOCK_DIR} 2>/dev/null; then
  # If the ${LOCK_DIR} doesn't exist, then start working & store the ${PID_FILE}
  echo $$ > ${PID_FILE}


mkuser_file
mkstore_dirs
rsync_data_from_internet

#rm $LOCK

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
