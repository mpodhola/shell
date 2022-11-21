#!/bin/bash
#set -o xtrace
#set -o verbose

#zuzitkovano z filmlightiho backup scriptu, protoze jsme lini

# We need two log files, one is a combined error log over time for reference (pg_dumpall.log)
rollinglog=/var/log/mysqldump.log

# The other is the error log file for todays dump. pg_last_dump.log, stored alongside the backup
day=$(date +"%F")
bdir=/storage/backup_DB/
schema=$1

todayslog="$bdir/$schema.$day.errorlog"
op="$bdir/$schema.$day.sql.gz"

# check zda existuje soubor bdcheck v adresari backups, abychom overili, ze backupujeme na sitovy storage
#if [ -f $bdir/publisher.test ]
#  then
      # Remove the days error log to sidestep any perms issues.
      bash -c "rm -f \"$todayslog\""

      # Perform the export
      bash -c "(mysqldump --defaults-extra-file="/root/dbbackup.opt" $schema  | gzip > $op) 2> $todayslog";

      # Append the rolling log
      today=$(date)
      bash -c "echo \"==== Backup report from $(date) ====\" >> $rollinglog"

      # If there were no errors, write a calming report and remove the empty file,
      # otherwise append the errors to the rolling log, and leave the errorlog for fl-diag to find
      if [ -s "$todayslog" ]
        then
            bash -c "echo \"WARNING: backup may have failed with these errors:\" >> $rollinglog"
            bash -c "cat $todayslog >> $rollinglog"
        else
            bash -c "echo \"Backup completed without errors\" >> $rollinglog"
            bash -c "rm -f \"$todayslog\""
        fi

        # If there is anything in the error log file, the fl-diag test will fail.

#  else
#     /usr/bin/logger -t admin "Warning: backup directory does not exist: $bdir"
#fi
