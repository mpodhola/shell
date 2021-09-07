#!/bin/bash
# archivase studia projektu
# pro customizaci prosim zmente $source $target $period
# $source nastavuje co se bude backupovat  $target kam se to bude backupovat $period jak dlouho se bude snapshot drzet v tydnech
#martin podhola 17.4.2019
source=/opt/vfx151archiv/vfx151archiv/_NSTUDIO
target=/opt/nlocal/studio_backup/
period=4

lock_name="backup_studio"
lock_dir='/tmp/'${lock_name}.lock
pid_file==${lock_dir}'/'${lock_name}'.pid'
if mkdir ${lock_dir} 2>/dev/null; then
  # If the ${LOCK_DIR} doesn't exist, then start working & store the ${PID_FILE}
  echo $$ > ${pid_file}

rdiff-backup $source $target
rdiff-backup --remove-older-than ${period}W $target
else
  if [ -f ${pid_file} ] && kill -0 $(cat ${pid_file}) 2>/dev/null; then
    # Confirm that the process file exists & a process
    # with that PID is truly running.
    echo "Running [PID "$(cat ${pid_file})"]" >&2
    exit
  else
    # If the process is not running, yet there is a PID file--like in the case
    # of a crash or sudden reboot--then get rid of the ${LOCK_DIR}
    rm -rf ${lock_dir}
    exit
  fi
fi
