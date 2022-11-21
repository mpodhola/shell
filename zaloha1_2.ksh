#!/usr/bin/ksh
#
# Skript zazalohuje LPAR na NIM server
# V.Danhelka IBM 14.3.2006
#     zmena V.Danhelka IBM 21.7.2006 zaloha na dva nim servery
#     zmena M.Peffek IBM 16.10.2007 -p + dalsi 2 servery
#     zmena V.Danhelka IBM 18.12.2008 dalsich 6 serveru
#     zmena M.Podhola IBM 26.09.2012 pridani a odebrani serveru a predani nim s aix09 aix10 na aix27 aix28
#     zmena M.Podhola IBM 4.2.2013 pridani vytvoreni linku pro moznost mit zadefinovany source a predpripraveny spot .
#     zmena V.Danhelka 12.9.2014 doplneni serveru pro migraci
#     zmena V.Danhelka 16.6.2015 doplneni serveru pro migraci ipa/inp

#set -x

case "`uname -n`" in
  aix01|aix03|aix05|aix07|aix11|aix13|aix15|aix17|aix21|aix23|aix25|aix27|aix1p2|aix1t2|aix1i2|aix1p1|aix1t1|aix1i1)
     nimserver=aix28mng
     ;;
  aix02|aix04|aix06|aix08|aix12|aix14|aix16|aix18|aix22|aix24|aix26|aix28|aix2p2|aix2t2|aix2i2|aix1i2|aix2p1|aix2t1|aix2i1)
     nimserver=aix27mng
     ;;
  *)
     echo "!!!!! Chyba zalohy, chybne jmeno serveru !!!!!"
     exit 1
     ;;
esac

dat=`date +%Y%m%d`

[ -f /var/tmp/zalohanim.lock ] && exit 1
# test, aby se nespustil dvakrat

if [[ -n $1 ]]
then
   nohup $0 >/var/tmp/zalohanim.`uname -n`.log 2>&1 &
else

  trap "rm -f /var/tmp/zalohanim.lock" 0 1 2 3
  touch /var/tmp/zalohanim.lock

  [ ! -d /backup ] && mkdir /backup
  if ! mount ${nimserver}:/nimfs/backups/`uname -n` /backup
  then
    echo "!!!! Mount error !!!!"
    exit 1
  fi
  ulimit unlimited

#added by Michal Peffek 21. 9. 2007
  if mksysb -i -e -p /backup/new.mksysb.`uname -n`.$dat 
  then
    rm -f /backup/mksysb.*
    mv /backup/new.mksysb.`uname -n`.$dat /backup/mksysb.`uname -n`.$dat
  H=`hostname`  
ssh $nimserver ln -s /nimfs/backups/${H}/mksysb.${H}.$dat /nimfs/backups/${H}/mksysb.${H}
 fi 

  for i in `lsvg -o|grep -v rootvg`
    do lsvg -l  $i |awk '{ print $7 }' |grep ^/ > /etc/exclude.$i
    if savevg -ief /backup/new.savevg.$i.`uname -n`.$dat $i
    then
      rm -f /backup/savevg.$i.*
      mv /backup/new.savevg.$i.`uname -n`.$dat /backup/savevg.$i.`uname -n`.$dat
    fi
  done

  umount /backup 

fi
