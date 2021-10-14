#!/bin/bash
#Skript na instalace 2D stanic  v prostredi UPP pro Operacni systemy Centos 7.
#Martin Podhola 10.10.2018 pridany moznost instalace pluginu  BL4NUKE
# verze 1.0.0 pro centos 7.6
# verze 1.0.1 pridani cuda_10
# verze 1.0.2 zmena pro centos 7.9
# verze 1.0.3 uprava instalace cuda 11.3
# verze 1.1.0 pridani update z 7.6- 7.9, pridani installace Teradici, odebrani installu baselight for nuke

clear

cd "$(dirname "$0")"
SRCPATH=`pwd`
IFS=$'\n'
INSPATH="/mnt/vfxsoft"
INSHARE="vfxrepo:/vfxsoft"
OPTPATH="/opt"

KEENTOOLS="$INSPATH/Keentools"
REPOD="vfx.upp.repo"
SUBJECT=some-unique-id
VERSION=3.0.0
USAGE="Usage: command -hv args"
RVLF=RVLFloatLicenseSoftware-2.2-linux-x64-installer.run

sep()
{
echo "*********************"
}

testrv()
{
if [ "$RV" == "0" ]; then echo "OK."; else echo "PROBLEM!"; exit; fi
}

hungary() {
  #while true; do
  #    read -p "Stanice se bude nachazet v Madarsku Y / N ?" yn
  #    case $yn in
  #        [Yy]* ) HUNGARY="y"; break ;;
  #        [Nn]* ) HUNGARY="n"; break ;;
  #        * ) echo "Please answer yes or no.";;
  #    esac
  #done
read -r -p "Bude se stanice nachazet v Madarsku? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]];then
  HUNGARY=y
elif [[ "$response" =~ ^(no|n)$ ]]; then
  HUNGARY=n
else
  echo "fuck you!!!"
  exit 1
fi

}

###hostname
hostn()
{
#if [ ! -z "$HOSTNAME" ]; then
HOSTNAME=$OPTARG
sep
echo "HOSTNAME"
sep
echo -n "hostname na $HOSTNAME ... "
hostnamectl set-hostname $HOSTNAME  > /dev/null 2>&1; RV=$?; testrv
}

dhcp_hostname () {
echo "uprava network interfacu aby vracely dnsce jmena"
  for i in `ls /etc/sysconfig/network-scripts/ifcfg-en* `
  	do
  		t=`cat $i| grep DHCP_HOSTNAME| wc -l`
  		if [[ $t = 1 ]]; then
  			k=`cat $i| grep DHCP_HOSTNAME| awk -F "=" '{print $2}'`
  			if [[ $k -ne $HOSTNAME ]]; then
          echo "bylo zjisteno ze je spatny hostname u interface bude provedena naprava"
  				sed -i 's/$k/$HOSTNAME/g' $i
  				exit 0
  			fi
        echo "hostname u interfacu jsou v poradku neni treba nic upravovat"
        exit 0
  		else
          		echo "DHCP_HOSTNAME=$HOSTNAME" >> $i
              echo "byly zaneseny pozadovane parametry do konfiguracnich skriptu sitovych adapteru!"
  		fi
  	done
  exit 0
}

help () {
printf " -h [help]\n -v [version]\n -g [install gnome + vfxsoftware +bind do ldapu ]\n -n <set-hostname> [nastavi hostname]\n -N <path to nuke instalator> nebo <i> interaktivni mod [nainstaluje Nuka]\n -c [re-nainstaluje jen cuda drivery]\n -R [Nainstaluje RLVF clienta instalace je interaktivni je potreba zadat IP serveru ta je 192.168.2.24]\n -s [install server]\n -b [nainstaluje blender]\n -f [nainstaluje blackmagick fusion 9]\n -S [nainstaluje Saphiri]\n -K [nainstaluje keentools]\n -I [nainstaluje Instanteam]\n -U [upgraduje ze 7.6 -> 7.9]\n -t [prekopne interkativne do AD z LDAP je treba admin userid a passwd]\n -w [instaluje /reinstaluje wacom drivery]\n -m [nainstaluje mashlab]\n -x [nainstaluje Bokeh]\n -o [nainstaluje opticalflares profipresety plus cestu k presetum vyexportuje licence je treba udelat rucne]\n -e [nainstaluje render stroj]\n -a [nainstaluje Atom editor]\n -k [nainstaluje nomachine]\n"
}

version () {
echo "verze je $VERSION"
}


cuda () {
  sep
  VERSION=cuda-11.4
  RUNFILE=cuda_11.4.1_470.57.02_linux.run

  echo "Instalace Cuda drivers ... "
  #$INSPATH/cuda_8.0.61_375.26_linux.run --silent --driver --toolkit --samples > /dev/null 2>&1; RV=$?; testrv
  GDMUP=`systemctl status gdm | grep inactive |wc -l`
  if [[ GDMUP -ne 1 ]]; then
    echo "Bezi Xka nejprve je shutdownujte \"systemctl stop gdm\" a puste instalaci znova!"
  exit 1
  fi
    echo "kontrola zda li byly v minulosti nainstalovany cuda drivery"
    A=`find /usr/local -name "uninstall_cuda_*.pl"`
  if [ ! -z $A ]; then
    for i in $A ;do bash -c $i; done
  fi

    echo "zahajuji instalace noveho driveru!"
    $INSPATH/cuda/cuda_11/$RUNFILE --silent --driver --toolkit --samples > /dev/null 2>&1; RV=$?; testrv
    echo "zakladni driver byl nainstalovan"
    #$INSPATH/cuda/cuda_9/cuda_9.2.148.1_linux.run --silent --accept-eula
    #echo "patche byly nainstalovany"
    #cat /etc/profile.d/vfx.upp.sh | grep -e cuda-8.0 -e grep cuda-9.1
    #$INSPATH/cuda/cuda_10/cuda_10.1.105_418.39_linux.run --silent --driver --toolkit --samples > /dev/null 2>&1; RV=$?; testrv
    #echo "zakladni driver byl nainstalovan"
  #  $INSPATH/cuda/cuda_9/cuda_9.2.148.1_linux.run --silent --accept-eula

  #  echo "patche byly nainstalovany"
  echo "uprava variables prosim po skonceni reboot!"
  if  hostname| grep -E 'vfx[0-9][0-9][0-9]|eff[0-9][0-9][0-9][0-9]'; then
    SRC=vfx.upp.sh
  elif hostname|grep -E 'hu[0-9][0-9][0-9]'; then
    SRC=vfx.upp.hu.sh
  else
    echo "this is not production workstation by hostname $HOSTNAME it should be vfxXXX or huXXX "
    exit 1
  fi

  if cat /etc/profile.d/$SRC | grep $VERSION ; then
    echo "$VERSION je jiz v profilu uvedena!!"
    exit 0
  fi


    #B=`cat /etc/profile.d/$SRC | grep cuda| grep lib| awk -F ":" '{ print $2 }'`
    #B=`cat /etc/profile.d/$SRC | grep cuda | grep workgroups | awk '{print $2}'|  awk -F "/" '{print $9}'`
    #C=$VERSION
    #sed -i "s~${B}~${C}~g" /etc/profile.d/$SRC > /dev/null 2>&1; RV=$?; testrv

    #if [`cat /etc/profile.d/$SRC | grep cuda | grep workgroups | awk '{print $2}'|  awk -F "/" '{print $10}'` == "lib"];then
    #  sed -i "s~lib~lib64~g" /etc/profile.d/$SRC > /dev/null 2>&1; RV=$?; testrv
    #fi
    #D=`cat /etc/profile.d/$SRC | grep -ohe cuda-9.1 -e cuda-8.0 -e cuda-10.1`
    sed -i '/cuda/d' /etc/profile.d/$SRC
    echo "export LD_LIBRARY_PATH=/upp/upptools/workgroups/common/linux:/usr/local/$VERSION/lib64" >> /etc/profile.d/$SRC
    echo "export CUDA_HOME=/usr/local/$VERSION"  >> /etc/profile.d/$SRC




    #VYresit lib64!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #!!!!!!!!!!!!!!!
    #IMPORTATN!!!!!!!!!!!!!





  #  sed -i "s~${D}~${VERSION}~g" /etc/profile.d/$SRC > /dev/null 2>&1; RV=$?; testrv
    echo "uprava provedena v poradku!!! prosim prekontrolujte si /etc/profile.d/$SRC"

  sep
}

rvlf () {
sep
echo "Instalace RVLF licence clienta INTERAKTIV... "
$INSPATH/$RVLF
}


nukeins (){
  NPATH=$OPTARG
  K=`echo="i"`
  if [[ ! -d $NPATH ]]; then

    if [[ $NPATH -eq $K ]]; then
      #soft_mount
      PROMPT="vyberte verzi Nuka:"
      options=( $(ls $INSPATH/Nuke_inst | xargs -0) )
      PS3="$prompt "
      select opt in "${options[@]}" "Quit" ; do
        if (( REPLY == 1 + ${#options[@]} )) ; then
        exit

      elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo  "Vybraly jste moznost $REPLY verzi $opt"
        NPATH=$INSPATH/Nuke_inst/$opt
        $INSPATH/Nuke_linux_silet_installer.sh $NPATH > /dev/null 2>&1; RV=$?; testrv
        rlmm
        exit 0
       else
        echo "Spatna Moznost."
        exit 0
         fi
       done
    fi
    sep
    echo "zadali jste spatnou cestu k instalatoru"
    echo "exit"
    sep
    exit 0
  else
    sep
    echo "Instalace Nuka $NPATH ... "
    $INSPATH/Nuke_linux_silet_installer2.1.sh $NPATH > /dev/null 2>&1; RV=$?; testrv
    rlmm
    exit 0
  fi
}

rlmm (){
  FOUNDRY="foundry"
sep
echo "RLM"
sep
if [[ -f /usr/local/$FOUNDRY/RLM/foundry_serlic5.lic ]] && [[ -f /usr/local/$FOUNDRY/RLM/foundry_serlic7.lic ]]; then
  echo "RLM uz bylpridan pro to  neni treba instalatovat znova!"
exit 0
fi
echo -n "cp licence ... "
cp -rv "$INSPATH/$FOUNDRY" "/usr/local/"> /dev/null 2>&1; RV=$?; testrv
echo -n "chmod foundry ... "
chmod -R 755 "/usr/local/$FOUNDRY" > /dev/null 2>&1; RV=$?; testrv
cp $INSPATH/foundry_serlic?.lic /usr/local/$FOUNDRY/RLM/ > /dev/null 2>&1; RV=$?; testrv

}

roayal () {
sep
echo "RR do menu"
sep

  echo -n "royal do menu ... "
  if [ -f /usr/share/applications/rrcontrol.desktop ]; then
  echo "jiz existuje."
  else
  cp "$INSPATH/rrcontrol.desktop" "/usr/share/applications/" > /dev/null 2>&1; RV=$?; testrv
  fi

}

profiled () {
  sep
  echo "copy vfx.upp.sh do profile.d"
  sep
#while true; do
#    read -p "Stanice se bude nachazet v Madarsku ? Y / N" yn
#    case $yn in
#        [Yy]* ) WOKRGRP="vfx.upp.hu.sh"; break ;;
#        [Nn]* ) WOKRGRP="vfx.upp.sh"; break ;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done
if [ $HUNGARY == y ]; then
  WOKRGRP="vfx.upp.hu.sh"
elif [ $HUNGARY == n ]; then
  WOKRGRP="vfx.upp.sh"
else
  echo "error!!!!!"
  exit 1
fi


  echo -n "cp profile.d ... "
  cp "$INSPATH/$WOKRGRP" /etc/profile.d/ > /dev/null 2>&1; RV=$?; testrv
  echo -n "chmod profile.d ... "
  chmod 755 "/etc/profile.d/$WOKRGRP" > /dev/null 2>&1; RV=$?; testrv
}

installdesktop () {

TRG_DESKTOP="GNOME Desktop"

echo -n "instalace $TRG_DESKTOP... "
yum groupinstall -y $TRG_DESKTOP > /dev/null 2>&1; RV=$?; testrv
}

installdesktopapps () {
INST_LIST="$INSPATH/vfx.install79.txt"

for a in $(cat $INST_LIST); do
    echo -n "instalace $a ... "
    yum -y install $a > /dev/null 2>&1; RV=$?
    testrv
done
echo "installace kernel dvel uname -r"
yum install kernel-devel-uname-r == `cat /proc/version | awk '{print $3}'`; testrv
echo "Kopiruju icons"
mkdir /opt/icons
cp $INSPATH/ico/* /opt/icons/
cp $INSPATH/icons/* /usr/share/applications/ > /dev/null 2>&1; RV=$?

 }

installserver () {
SRV_LIST="$INSPATH/server.install.txt"
for a in $(cat $SRV_LIST); do
    echo -n "instalace $a ... "
    yum -y install $a > /dev/null 2>&1; RV=$?
    testrv
done
}

gnomes()
{
#case $DESKTOP in
#    "g")

    sep
    echo "GNOME PLUGINS"
    sep

    HOTCOR="$INSPATH/nohotleftcorner/"'nohotcorner@azuri.free.fr'
    echo -n "no-hot-conrers pro GNOME ... "
    if [ -r $HOTCOR ]; then
        yes | cp -fr "$HOTCOR" "/usr/share/gnome-shell/extensions/" > /dev/null 2>&1; RV=$?; testrv
        else
        echo "NENALEZEN!"
    fi
    #;;
#esac
}

vnc()
{

VNCSERVICE="vfx.vnc.service"
VNCPASS="vfx.vnc.pass"

sep
echo "VNC ACCESS"
sep

echo -n "cp service ... "
yes | cp -vf $INSPATH/$VNCSERVICE /lib/systemd/system/ > /dev/null 2>&1; RV=$?; testrv
echo -n "cp passfile ... "
yes | cp -vf $INSPATH/$VNCPASS /etc/ > /dev/null 2>&1; RV=$?; testrv
echo -n "service enable ... "
systemctl enable /lib/systemd/system/$VNCSERVICE > /dev/null 2>&1; RV=$?; testrv
echo -n "firwalld start ... "
systemctl start firewalld > /dev/null 2>&1; RV=$?; testrv
echo -n "firwalld rule ... "
firewall-cmd --permanent --zone=public --add-port=5900/tcp > /dev/null 2>&1; RV=$?; testrv
echo -n "firewalld reload ... "
firewall-cmd --reload > /dev/null 2>&1; RV=$?; testrv
}

xnview()
{
  XNVIEW="XnView"

sep
echo "XNVIEW"
sep


echo -n "copy do /opt ... "
if [ ! -d /opt/XnView ]; then
cp -r $INSPATH/$XNVIEW/opt / > /dev/null 2>&1; RV=$?; testrv
else
echo "jiz existuje."
fi

echo -n "copy do /usr ... "
if [ ! -d /usr/XnView ]; then
yes | cp -rf $INSPATH/$XNVIEW/usr / > /dev/null 2>&1; RV=$?; testrv
else
echo "jiz existuje."
fi

echo -n "ldconfig ... "
ldconfig /usr/lib/XnView/lib > /dev/null 2>&1; RV=$?; testrv
}

base_yum()
{
sep
echo "PRIDANI REPOZITARU"
sep

echo -n "yum rm repos ... "



RELEASE=`cat /etc/centos-release |awk '{print  $4}'`

case $RELEASE in
  "7.6.1810")
    mv /etc/yum.repos.d /etc/yum.repos.d_BACK7.6
    mkdir /etc/yum.repos.d
    ;;
  "7.9.2009")
    rm /etc/yum.repos.d/* ; RV=$?; testrv
    ;;
    * )
    echo "neznamy release!"
    exit 1
    ;;
 esac
case $RELEASE in
  7.9.2009|7.6.1810)
    CENTOS=/etc/yum.repos.d/srv-repos01.centos7.repo
    echo "[srv-repos01.centos.std.7.9.2009.repo]" > $CENTOS
    echo "name=SRV-REPOS01.UPP.CZ - CENTOS STD 7.9.2009 REPOSITORY" >> $CENTOS
    echo "baseurl=http://srv-repos01.upp.cz/repos/centos/7.9.2009/" >> $CENTOS
    echo "enabled=1" >> $CENTOS
    echo "gpgcheck=0" >> $CENTOS

    VFXLINUX=/etc/yum.repos.d/srv-repos01.vfxrepo.repo
    echo "[srv-repos01.vfxrepo.repo]" > $VFXLINUX
    echo "name=SRV-REPOS01.UPP.CZ - EPEL7 REPOSITORY" >> $VFXLINUX
    echo "baseurl=http://srv-repos01.upp.cz/repos/vfx_centos7.9/" >> $VFXLINUX
    echo "enabled=1" >> $VFXLINUX
    echo "gpgcheck=0" >> $VFXLINUX

    UPDATES=/etc/yum.repos.d/srv-repos01.centos_updates.repo
    echo "[srv-repos01.centos_updates.repo]" > $UPDATES
    echo "name=SRV-REPOS01.UPP.CZ - EPEL7 REPOSITORY" >> $UPDATES
    echo "baseurl=http://srv-repos01.upp.cz/repos/centos/7.9.2009_updates/mirror.karneval.cz/pub/centos/7.9.2009/updates/x86_64/Packages/" >> $UPDATES
    echo "enabled=1" >> $UPDATES
    echo "gpgcheck=0" >> $UPDATES

    EPEL=/etc/yum.repos.d/srv-repos01.elep7.repo
    echo "[srv-repos01.epel7.repo]" > $EPEL
    echo "name=SRV-REPOS01.UPP.CZ - EPEL7 REPOSITORY" >> $EPEL
    echo "baseurl=http://srv-repos01.upp.cz/repos/epel/Packages/" >> $EPEL
    echo "enabled=1" >> $EPEL
    echo "gpgcheck=0" >> $EPEL

    VFX=/etc/yum.repos.d/srv-repos01.custom.repo
    echo "[srv-repos01.centos.adds.7.9.2009.repo]" > $VFX
    echo "name=SRV-REPOS01.UPP.CZ - CENTOS ADS 7.9.2009 REPOSITORY" >> $VFX
    echo "baseurl=http://srv-repos01.upp.cz/repos/centos/7.9.2009.add" >> $VFX
    echo "enabled=1" >> $VFX
    echo "gpgcheck=0" >> $VFX


    NUX=/etc/yum.repos.d/srv-repos01.nux.repo
    echo "[srv-repos01.centos.nux.repo]" > $NUX
    echo "name=SRV-REPOS01.UPP.CZ - CENTOS nux 7.9.2009 REPOSITORY" >> $NUX
    echo "baseurl=http://srv-repos01.upp.cz/repos/nux/li.nux.ro/download/nux/dextop/el7/x86_64" >> $NUX
    echo "enabled=1" >> $NUX
    echo "gpgcheck=0" >> $NUX

    TERA=/etc/yum.repos.d/srv-repos01.teradici.repo
    echo "[srv-repos01.centos.teradici.repo]" > $TERA
    echo "name=SRV-REPOS01.UPP.CZ - CENTOS teradici 7.9.2009 REPOSITORY" >> $TERA
    echo "baseurl=http://srv-repos01.upp.cz/repos/teradici/downloads.teradici.com/rhel/stable" >> $TERA
    echo "enabled=1" >> $TERA
    echo "gpgcheck=0" >> $TERA

    echo "test"
       ;;
  * )
  echo "nemate spravnou verzi Centos 7.9 nebo 7.6 "
  exit 1
  ;;
  esac




echo -n "yum clean ... "
yum clean all > /dev/null 2>&1; RV=$?; testrv
echo -n "yum makecache ... "
yum makecache > /dev/null 2>&1; RV=$?; testrv
}

nfs_utils (){
echo -n "yum install nfs-utils ... "
yum -y install nfs-utils > /dev/null 2>&1; RV=$?; testrv
}

tcp_slots () {
echo "uprava nastaveni tcp_max_slot_table"
echo "sunrpc.tcp_max_slot_table_entries=128" >> /etc/sysctl.d/99-sysctl.conf
}

fstab_mount()
{

echo "FSTAB + MOUNTY"
sep

echo -n "rpcbind enable ..."
systemctl enable rpcbind > /dev/null 2>&1; RV=$?; testrv
echo -n "rpcbind start ... "
systemctl start rpcbind > /dev/null 2>&1; RV=$?; testrv

#while true; do
#    read -p "Stanice se bude nachazet v Madarsku Y / N ?" yn
#    case $yn in
#        [Yy]* ) FSTAB_LIST="$INSPATH/vfx.fstab.hu.txt"; break ;;
#        [Nn]* ) FSTAB_LIST="$INSPATH/vfx.fstab.txt"; break ;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done

if [[ "$HUNGARY" =~ ^(yes|y)$ ]]; then
  FSTAB_LIST="$INSPATH/vfx.fstab.hu.txt"
elif [[ $HUNGARY =~ ^(no|n)$ ]]; then
  FSTAB_LIST="$INSPATH/vfx.fstab.txt"
else
  echo "error!!!!!"
  exit 1
fi



for a in $(cat "$FSTAB_LIST"); do
    MDIR=$(echo $a | awk '{print $2}')
    MPOINT=$(echo $a | awk '{print $1}')

    echo -n "dir: $MDIR ... "
    if [ ! -d "$MDIR" ]; then
        echo -n "zakladam ... "
        mkdir -p $MDIR; RV=$?
        testrv
    else
        echo "jiz existuje."
    fi

    echo -n "fstab: $MPOINT ... "
    cat "/etc/fstab" | grep "$MPOINT" > /dev/null 2>&1; FSENTRY=$?
    if [ "$FSENTRY" == "1" ]; then
        echo -n "pridavam ... "
        echo $a >> /etc/fstab; RV=$?
        testrv
    else
        echo "jiz existuje"
    fi
done

echo -n "mount pridanych ... "
mount -a > /dev/null 2>&1; testrv
}

###vfxsoft mount
soft_mount()
{
sep
echo "MOUNT VFXSOFT"
sep

echo -n "mkdir $INSPATH ..."
if [ ! -d "$INSPATH" ]; then mkdir -p $INSPATH > /dev/null 2>&1; RV=$?; testrv; else echo "jiz existuje"; fi
echo -n "mount $INSHARE ..."
MNTBOOL=$(mount | grep "$INSHARE" > /dev/null ; echo $?)
if [ "$MNTBOOL" == "0" ]; then echo "jiz existuje"; else mount $INSHARE $INSPATH > /dev/null 2>&1; RV=$?; testrv; fi
}

genarts (){
  echo "Instalace SapphireOFX-7"
  sep
cd    $INSPATH/Genarts
yum -y localinstall SapphireOFX-7.080-1.x86_64.rpm
#yum -y localinstall SapphireOFX-2019.020-1.0.x86_64.rpm
cat Sapphire-OFX.lic | grep HOST >> /usr/genarts/rlm/Sapphire-OFX.lic
sep
testrv
}

keentools () {
echo "Instalace Geotreker"
  sep
  PROMPT="vyberte verzi Nuka pro ktereho chcete installovat Geotreker:"
  options=( $(ls $KEENTOOLS | xargs -0) )
  PS3="$prompt "
  select opt in "${options[@]}" "Quit" ; do
    if (( REPLY == 1 + ${#options[@]} )) ; then
    exit

  elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
    echo  "Vybraly jste moznost $REPLY verzi $opt"
cd $KEENTOOLS/$opt
case $opt in
     KEENTOOLS_1.3.0_LINUX_NUKE10.5)
	NV=Nuke10.5v4
	;;
     KEENTOOLS_1.3.0_LINUX_NUKE11.0)
	NV=Nuke11.0v4
	;;
     KEENTOOLS_1.3.2_LINUX_NUKE11.1)
	NV=Nuke11.1v2
  ;;
      *)
      echo "fuck up"
exit 1
esac
./$opt.sh --target /usr/local/$NV/plugins/
    exit 0
   else
    echo "Spatna Moznost."
    exit 0
     fi
   done
}


selinux_disable () {
echo -n "selinux disable ... "
SELINUX=$(grep "SELINUX=" /etc/selinux/config | grep -v \#)
case $SELINUX in
    "SELINUX=disabled")
        echo "jiz vypnuto"
        ;;
    "SELINUX=enforcing")
        sed -i 's/SELINUX\=enforcing/SELINUX\=disabled/' /etc/selinux/config; RV=$?; testrv
        ;;
     *)
        echo "PROBLEM!"; exit
esac
}
blender (){
  #BLENDER="blender/blender-2.81a-linux-glibc217-x86_64.tar.bz2"
  BLENDER=blender/blender-2.82-linux64.tar.xz
mkdir /usr/local/Blender/ && tar -xf $INSPATH/$BLENDER -C /usr/local/Blender/ > /dev/null && cp $INSPATH/blender/blender.desktop /usr/share/applications/ > /dev/null 2>&1; RV=$?; testrv
}

fusion (){
$INSPATH/blackmagick/Blackmagic_Fusion_Linux_9.0.1_installer.run -i
}

bview()
{
BVIEW="Bview-15.1.run"
sep
echo "BVIEW"
sep

echo -n "install do $OPTPATH ... "
$INSPATH/$BVIEW --destination $OPTPATH/ > /dev/null 2>&1; RV=$?; testrv

echo -n "link do bin ... "
if [ ! -h /bin/bview ]; then
BVIEW_TRG=$(echo $BVIEW |sed "s/.run//")
ln -s $OPTPATH/$(ls $OPTPATH/ | grep $BVIEW_TRG)/Contents/bin/bview /bin/bview; RV=$?; testrv
else
echo "jiz existuje."
fi

echo -n "polozka do menu ... "
if [ -f /usr/share/applications/bview.desktop ]; then
echo "jiz existuje."
else
cp "$INSPATH/bview.desktop" "/usr/share/applications/" > /dev/null 2>&1; RV=$?; testrv
fi
}

mashlab () {
echo "instalace mashlabu "
yum -y localinstall $INSPATH/meshlab/levmar-2.5-6.sdl7.x86_64.rpm > /dev/null 2>&1; RV=$?; testrv
yum -y localinstall $INSPATH/meshlab/meshlab-1.3.2-10.sdl7.x86_64.rpm > /dev/null 2>&1; RV=$?; testrv
echo "mashlab uspesne nainstalovan!"



}

bokeh () {
BETA=$INSPATH/Bokeh/
BPATH=$OPTARG
#  K=`echo="i"`
#  if [[ ! -d $BPATH ]]; then
      #soft_mount
      PROMPT="vyberte verzi Bokehu k verzi Nuka:"
      options=( $(ls $BETA | xargs -0) )
      PS3="$prompt "
      select opt in "${options[@]}" "Quit" ; do
        if (( REPLY == 1 + ${#options[@]} )) ; then
        exit

      elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo  "Vybraly jste moznost $REPLY verzi $opt"
        if [ ! -d /opt/$opt ]; then
        cp -r $BETA/$opt /opt/ && echo "export peregrinel_LICENSE=5053@serlicw01" >> /etc/profile.d/vfx.upp.sh

        #gawk -i inplace 'NR <= 1 {print $0":/opt/Bokeh-v1.4.3_Nuke11.1-linux64"} NR >1 {print $0}'  /etc/profile.d/upp.vfx.sh
        #gawk -i inplace  '/NUKE_PATH/ {print $0":/opt/Bokeh-v1.4.3_Nuke11.1-linux64"} {print $0}'  /etc/profile.d/upp.vfx.sh
        #TT=`cat /etc/profile.d/vfx.upp.sh|grep $opt |wc -l`
        #if [ $TT -eq 0 ]; then
           gawk -v opti=$opt '/NUKE_PATH=/ {print $0":/opt/opti"} !/NUKE_PATH=/ {print $0}'  /etc/profile.d/vfx.upp.sh > /etc/profile.d/tmp && mv /etc/profile.d/tmp /etc/profile.d/vfx.upp.sh
        #fi
        echo "plugin bokeh byl nainstalovan ted jen logout & login usera a viiiiii jedem"
        exit 0
      else
        echo " Tato verze byla jiz nainstalovana!! pro to nic nedelema!!! SORY JAKO Asi to nainstaloval Kalousek!!!"
        exit 0
      fi
       else
        echo "Spatna Moznost."
        exit 0
         fi
       done
    #fi


}
bokeh2 () {

  if [ ! -d  /var/PeregrineLabs ]; then
    mkdir -p /var/PeregrineLabs/rlm/
    chmod +x /var/PeregrineLabs
    printf "HOST serlic5.upp.cz 5054\nISV peregrinel" >> /var/PeregrineLabs/rlm/bohkeh.lic
    chmod +r /var/PeregrineLabs/rlm/bohkeh.lic
    echo "licence file crated!"
  else
    echo "jiz zalicencovano!"
  fi
}



opticalfl () {

printf "Instalace Opticalflares je jen castecna  jelikoz je treba s nuka vygenerovat HW ID po spusteni OF a pak s videocopilot \n stranek stahnout licencni soubor a ulozit ho uzivately do /opt/Opticalflares/ \n "
if [ ! -d /opt/Opticalflares ]; then
  cp -rf $INSPATH/Opticalflares/ /opt/
#  TEST=`cat /etc/profile.d/vfx.upp.sh | grep OPTICAL|wc -l`
#  if [ $TEST -eq 0 ]; then
    echo "export OPTICAL_FLARES_PRESET_PATH=/opt/Opticalflares/OF/OF" >> /etc/profile.d/vfx.upp.sh
    echo "export OPTICAL_FLARES_LICENSE_PATH=/opt/Opticalflares/" >> /etc/profile.d/vfx.upp.sh
#  fi
  exit 0
else
  echo "Opticalflares jiz byly nainstalovany zkontrolujte licencni soubor v /opt/Opticalflares"
  exit 0
fi
}


nvidia()
{
sep
echo "NVIDIA - PRE"
sep

echo -n "nouveau-off.conf ... "
if [ -f "/etc/modprobe.d/nouveau-off.conf" ]; then
    echo "jiz existuje."
else
    echo "vytvarim."
    echo -n "nouveau-off.conf create ... "
    touch "/etc/modprobe.d/nouveau-off.conf" > /dev/null 2>&1; RV=$?; testrv
    echo -n "nouveau-off.conf edit ..."
    echo 'blacklist nouveau' > "/etc/modprobe.d/nouveau-off.conf"; RV=$?; testrv
fi
}


usbs_off()
{
sep
echo "USB STORAGE OFF"
sep

echo -n "usb-storage.conf ... "
if [ -f "/etc/modprobe.d/usb-storage.conf" ]; then
    echo "jiz existuje."
else
    echo "vytvarim."
    echo -n "usb-storage.conf create ... "
    touch "/etc/modprobe.d/usb-storage.conf" > /dev/null 2>&1; RV=$?; testrv
    echo -n "usb-storage.conf edit ..."
    echo 'install usb-storage /bin/true' > "/etc/modprobe.d/usb-storage.conf"; RV=$?; testrv
fi
}

wacom()
{
  WACOM="inputwacom"
sep
echo "WACOM DRIVERS"
sep
if [[ -d /opt/inputwacom ]]; then
  echo "mazu neaktualni drivery"
  rm -rf /opt/inputwacom
fi
echo -n "copy do /opt ... "
RV=$(yes | cp -rf "$INSPATH/$WACOM" "/opt/" > /dev/null 2>&1; echo $?); testrv
cd "/opt/$WACOM"

echo -n "./configure ... "
./configure > /dev/null 2>&1; RV=$?; testrv
echo -n "make ... "
make > /dev/null 2>&1; RV=$?; testrv
echo -n "make install ... "
make install > /dev/null 2>&1; RV=$?; testrv
}

tester()
{
echo "tester"
}

dracut_set()
{
echo -n "dracut initramfs... "
dracut /boot/initramfs-$(uname -r).img $(uname -r) --force > /dev/null 2>&1; RV=$?; testrv
}
privilidge (){

  if [ "$(id -u)" != "0" ]; then
   echo "Jedine pod root" 1>&2
   exit 1
fi
}


instanteam () {
 ALPHA=$OPTARG
 if [[  ALPHA -eq s ]]; then
 TPATH=$INSPATH/Instant_team/Instant_Team_6-x86_64.AppImage
 T=Instant_Team_6-x86_64.AppImage
 LNAME=`echo "$T"|awk -F "." '{print $1}'`
 if [ ! -d /opt/$LNAME ]; then
        mkdir /opt/$LNAME
 fi
 cp $TPATH /opt/$LNAME
 cp $INSPATH/instant_team_ico/instantteam.ico /opt/$LNAME
        APP_DIR=/usr/share/applications
        LUNCHER=$APP_DIR/Instant_Team_6-x86_64.desktop
        echo "[Desktop Entry]" > $LUNCHER
        echo "Name=$LNAME" >> $LUNCHER
        echo "Comment=\"\"" >> $LUNCHER
        echo "Exec=\"/opt/$LNAME/Instant_Team_6-x86_64.AppImage\"" >> $LUNCHER
        echo "Terminal=false" >> $LUNCHER
        echo "Icon=/opt/$LNAME/instantteam.ico" >> $LUNCHER
        echo "Type=Application" >> $LUNCHER
        echo "MimeType=application/x-instantteam-rl;" >> $LUNCHER
        echo "Categories=Qt;Office;ProjectManagement;" >> $LUNCHER
        sep
        echo "uspesne nainstalovano"
        exit 0


  else


 APP_DIR=/usr/share/applications
  PROMPT="vyberte verzi Instanteamu:"
      options=( $(ls $INSPATH/Instant_team | xargs -0) )
      PS3="$prompt "
      select opt in "${options[@]}" "Quit" ; do
        if (( REPLY == 1 + ${#options[@]} )) ; then
        exit

      elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo  "Vybraly jste moznost $REPLY verzi $opt"
        TPATH=$INSPATH/Instant_team/$opt
        T="$opt"
        LNAME=`echo "$T"|awk -F "." '{print $1}'`
	if [ ! -d /opt/$LNAME ]; then
        mkdir /opt/$LNAME
	fi
        cp $TPATH /opt/$LNAME
        cp $INSPATH/instant_team_ico/instantteam.ico /opt/$LNAME
        LUNCHER=$APP_DIR/$opt.desktop
        echo "[Desktop Entry]" > $LUNCHER
        echo "Name=$LNAME" >> $LUNCHER
        echo "Comment=\"\"" >> $LUNCHER
        echo "Exec=\"/opt/$LNAME/$opt\"" >> $LUNCHER
        echo "Terminal=false" >> $LUNCHER
        echo "Icon=/opt/$LNAME/instantteam.ico" >> $LUNCHER
        echo "Type=Application" >> $LUNCHER
        echo "MimeType=application/x-instantteam-rl;" >> $LUNCHER
        echo "Categories=Qt;Office;ProjectManagement;" >> $LUNCHER
        sep
        echo "uspesne nainstalovano"
        exit 0
      else
       echo "Spatna Moznost."
       exit 0
        fi
      done
fi
}

toglobal (){
  echo "preklopeni s LDAP do AD"
  $INSPATH/to_globalupp.sh
}

opt () {
  echo "vytvarim slozky pro Ncache a Nlocal pokud uz nejsou!"
  if [ ! -d /opt/ncache ]; then mkdir /opt/ncache;fi
  if [ ! -d /opt/nlocal ]; then mkdir /opt/nlocal;fi
  echo "pokud neni kopiruji skripty do opt binu"
  if [ ! -d /opt/bin ]; then
   cp -r $INSPATH/bin /opt/
   chmod -R +x /opt/bin
  fi
}

greylog () {
  echo "Setup graylog connection for syslog! And restart rsyslog service"
echo "*.* @192.168.3.112:5014;RSYSLOG_SyslogProtocol23Format" > /etc/rsyslog.d/90-greylogcollect.conf
  systemctl status rsyslog > /dev/null 2>&1; RV=$?; testrv
}



#bl_nuke () {
#  DI=`cat /proc/driver/nvidia/version | 390.87| wc -l`
#  if [ $DI -eq 0 ]; then
#printf "priprava instalace Baselight for Nuke\n Pozor skript zastavi graficke prostredi kuli reinstalu driveru na grafiku!!\n Pro to jej nikdy nepoustejte s GUI!!!!!\n Jste si jisti?\n pokud date No tak koncite\n"
#  select yn in "Yes" "No"; do
#    case $yn in
#        Yes ) break;;
#        No ) exit 0;;
#    esac
#done
#echo "nyni vypnem GUI"
#systemctl stop gdm > /dev/null 2>&1; RV=$?; testrv
#echo "instalace NVIDIA driveru"
#echo "zabere to nakej cas"
#$INSPATH/NVIDIA/NVIDIA-Linux-x86_64-390.87.run -q -a -n -X -s
#echo "hotovo driver nainstalovan!"
#fi
#echo "Instalace baselight pro Nuka je treba vybrat verzi"
#options=( $(ls $INSPATH/baselight_for_nuke/ | xargs -0) )
#PS3="$prompt "
#select opt in "${options[@]}" "Quit" ; do
#  if (( REPLY == 1 + ${#options[@]} )) ; then
#  exit

#elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
#  echo  "Vybraly jste moznost $REPLY verzi $opt"
#   $INSPATH/baselight_for_nuke/$opt/install-nuke --accept-licence > /dev/null 2>&1; RV=$?; testrv
#   #gawk -i inplace  '/NUKE_PATH/ {print $0":/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_1:/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_2"} {print $0}'  /etc/profile.d/upp.vfx.sh
#   TV=`cat /etc/profile.d/vfx.upp.sh | grep $opt |wc -l`
#   if [ $TV -eq 0 ]; then
#     gawk '/NUKE_PATH=/ {print $0":/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_1:/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_2"}  !/NUKE_PATH=/ { print $0}'  /etc/profile.d/vfx.upp.sh > /etc/profile.d/tmp && mv /etc/profile.d/tmp /etc/profile.d/vfx.upp.sh
#   fi
#   echo "vse ok"
#   printf "je treba reboot jste ted pro?"
#   select yn in "Yes" "No"; do
#     case $yn in
#         Yes ) init 6 ; break;;
#         No ) exit 0;;
#     esac
# done
# else
#  echo "Spatna Moznost."
#  exit 0
#   fi
# done


#}

rsmb () {
  echo "Probehne interaktivni instalace clienta licencniho programu jako server prosim zadjte serlic5"
$INSPATH/rsmb/RVLFloatLicenseSoftware-2.3-linux-x64-installer.run

}

atom () {
cd $INSPATH/Atom/
yum localinstall -y atom.x86_64.rpm  > /dev/null 2>&1; RV=$?; testrv

}

nomachine () {
cd $INSPATH/
yum localinstall -y nomachine_6.9.2_1_x86_64.rpm > /dev/null 2>&1; RV=$?; testrv
    u="remote"
    useradd $u
    echo "user $u added successfully!"
    echo $u:$u"Ab123456789." | chpasswd
    echo "Password for user $u changed successfully"

 firewall-cmd --permanent --add-port=4000/tcp --add-port=4000/udp  > /dev/null 2>&1; RV=$?; testrv
 firewall-cmd --reload

sed -i "s/#EnableFileTransfer both/EnableFileTransfer none/g" /usr/NX/etc/node.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/#EnableUSBSharing both/EnableUSBSharing none/g" /usr/NX/etc/node.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/#EnableNetworkSharing both/EnableNetworkSharing none/g" /usr/NX/etc/node.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/#EnablePrinterSharing both/EnablePrinterSharing none/g" /usr/NX/etc/node.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/#EnableDiskSharing both/EnableDiskSharing none/g" /usr/NX/etc/node.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/EnableSmartcardSharing 1/EnableSmartcardSharing 0/g" /usr/NX/etc/node.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/#DisplayServerVideoCodec vp8/DisplayServerVideoCodec h264/g" /usr/NX/etc/node.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/#EnableNetworkBroadcast 1/EnableNetworkBroadcast 0/g" /usr/NX/etc/server.cfg > /dev/null 2>&1; RV=$?; testrv
sed -i "s/#EnableScreenBlanking 0/EnableScreenBlanking 1/g" /usr/NX/etc/server.cfg > /dev/null 2>&1; RV=$?; testrv
systemctl restart nxserver.service > /dev/null 2>&1; RV=$?; testrv

}

update_sys(){
RELEASE=`cat /etc/centos-release |awk '{print  $4}'`
case $RELEASE in
  "7.6.1810" )
  yum makecache
  yum  update -y --skip-broken   RV=$?; testrv
  yum install -y libXScrnSaver.x86_64
  echo "####################################"
  echo "Aktualni verze: "
  cat /etc/centos-release
  exit 0
  ;;
  "7.9.2009" )
  echo "Jiz  verze 7.9 nainstalovana!"
  exit 0
  ;;
  * )
  echo "wrong release!"
  exit 1
  ;;
esac
}

cp_launchers() {
echo "kopiruji launchery pro Nuke, HieroPlayer, Blender "
cp $INSPATH/Nuke_UPP.desktop /usr/share/applications/ > /dev/null 2>&1; RV=$?; testrv
cp $INSPATH/NukeX_UPP.desktop /usr/share/applications/ > /dev/null 2>&1; RV=$?; testrv
cp $INSPATH/NukeStudio_UPP.desktop /usr/share/applications/ > /dev/null 2>&1; RV=$?; testrv
cp $INSPATH/HieroPlayer_UPP.desktop /usr/share/applications/ > /dev/null 2>&1; RV=$?; testrv
cp $INSPATH/Blender_UPP.desktop /usr/share/applications/ > /dev/null 2>&1; RV=$?; testrv


}



# --- Option processing --------------------------------------------
privilidge
while getopts ":vhgn:N:cRsbfKSI:Utwmxork" optname
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
      "g")
      hungary
      base_yum
      nfs_utils
      soft_mount
      tcp_slots
      fstab_mount
      installdesktop
      installdesktopapps
      fstab_mount
      selinux_disable
      toglobal
      profiled
      vnc
      bview
      xnview
      usbs_off
      nvidia
      gnomes
      cp_launchers
      dracut_set
      wacom
      instanteam
      roayal
      opt
      bokeh2
      greylog
        ;;
      "n")
      hostn
      dhcp_hostname
      ;;
      "N")
      soft_mount
      nukeins
      ;;
      "c")
      soft_mount
      cuda
      ;;
      "R")
      soft_mount
      rvlf
      ;;
      "s")
      base_yum
      nfs_utils
      soft_mount
      installserver
      greylog
      ;;
      "e")
      HUNGARY=n
      base_yum
      nfs_utils
      soft_mount
      installserver
      profiled
      toglobal
      fstabmount
      roayal
      nukeins
      greylog
      ;;
      "b")
      soft_mount
      blender
      ;;
      "f")
      soft_mount
      fusion
      ;;
      "K")
      soft_mount
      keentools
      ;;
      "S")
      soft_mount
      genarts
      ;;
      "I")
      soft_mount
      instanteam
      ;;
      "t")
      soft_mount
      toglobal
      ;;
      "w")
      soft_mount
      wacom
      ;;
      "m")
      soft_mount
      mashlab
      ;;
      "x")
      soft_mount
      bokeh2
      ;;
      "o")
      soft_mount
      opticalfl
      ;;
      "r")
      soft_mount
      rsmb
      ;;
      "a")
      soft_mount
      atom
      ;;
      "k")
      soft_mount
      nomachine
      ;;
      "U")
      soft_mount
      base_yum
      update_sys
      installdesktopapps
      ;;
	     *)
        echo "Nezname parmetry prosim opakujte znova -h"
        exit 0;
        ;;
    esac
  done
shift $(($OPTIND - 1))
