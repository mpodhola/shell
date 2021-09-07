#!/bin/bash
#Skript na instalace 2D stanic  v prostredi UPP pro Operacni systemy Centos 7.
#Martin Podhola 10.10.2018 pridany moznost instalace pluginu  BL4NUKE

#2.1.6 - nahrazeni  cuda 10 cuda 9 a odebrani podpory centos 7.3!

clear

cd "$(dirname "$0")"
SRCPATH=`pwd`
IFS=$'\n'
#SRCPATH="/tmpmnt/vfx.cent.install"
INSPATH="/mnt/vfxsoft"
INSHARE="vfxrepo:/vfxsoft"
OPTPATH="/opt"

INST_LIST="$INSPATH/vfx.install.txt"
SRV_LIST="$INSPATH/server.install.txt"
FSTAB_LIST="$INSPATH/vfx.fstab.txt"
SSSD="$INSPATH/sssd.conf"
KEENTOOLS="$INSPATH/Keentools"
WOKRGRP="vfx.upp.sh"
REPOD="vfx.upp.repo"
FOUNDRY="foundry"
WACOM="inputwacom"
BVIEW="Bview-15.1.run"
XNVIEW="XnView"
#DESKTOP=$1
#HOSTNAME=$2
VNCSERVICE="vfx.vnc.service"
VNCPASS="vfx.vnc.pass"
#NUKE="Nuke10.0v4"
SUBJECT=some-unique-id
VERSION=1.2.1
USAGE="Usage: command -hv args"
RVLF=RVLFloatLicenseSoftware-2.2-linux-x64-installer.run
BLENDER="blender/blender-2.81a-linux-glibc217-x86_64.tar.bz2"

sep()
{
echo "*********************"
}

opt () {
  echo "vytvarim slozky pro Ncache a Nlocal pokud uz nejsou!"
  if [ ! -d /opt/ncache ]; then mkdir /opt/ncache;fi
  if [ ! -d /opt/nlocal ]; then mkdir /opt/nlocal;fi
  if [ ! -d /opt/bin ]; then
   cp -r $INSPATH/bin /opt/
   chmod -R +x /opt/bin
  fi
}


testrv()
{
if [ "$RV" == "0" ]; then echo "OK."; else echo "PROBLEM!"; exit; fi
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
  for i in `ls /etc/sysconfig/network-scripts/ifcfg-en* | xargs`
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
printf " -h [help]\n -v [version]\n -g [install gnome + vfxsoftware +bind do ldapu ]\n -n <set-hostname> [nastavi hostname]\n -N <path to nuke instalator> nebo <i> interaktivni mod [nainstaluje Nuka]\n -c [re-nainstaluje jen cuda drivery]\n -R [Nainstaluje RLVF clienta instalace je interaktivni je potreba zadat IP serveru ta je 192.168.2.24]\n -s [install server]\n -b [nainstaluje blender]\n -f [nainstaluje blackmagick fusion 9]\n -S [nainstaluje Saphiri]\n -K [nainstaluje keentools]\n -I [nainstaluje Instanteam]\n -U [upgraduje ze 7.3 -> 7.4]\n -t [prekopne interkativne do AD z LDAP je treba admin userid a passwd]\n -w [instaluje /reinstaluje wacom drivery]\n -l [instaluje baselight pro nuka]\n -m [nainstaluje mashlab]\n -x [nainstaluje Bokeh]\n -o [nainstaluje opticalflares profipresety plus cestu k presetum vyexportuje licence je treba udelat rucne]\n -k [nainstaluje nomachine]\n"
}

version () {
echo "verze je $VERSION"
}


cuda () {
sep

VERSION=cuda-10.1
RUNFILE=cuda_10.1.243_418.87.00_linux.run

echo "Instalace Cuda drivers ... "
#$INSPATH/cuda_8.0.61_375.26_linux.run --silent --driver --toolkit --samples > /dev/null 2>&1; RV=$?; testrv
GDMUP=`systemctl status gdm | grep inactive |wc -l`
if [[ GDMUP -ne 1 ]]; then
  echo "Bezi Xka nejprve je shutdownujte \"systemctl stop gdm\" a puste instalaci znova!"
exit 1
fi
#RELEASED=`cat /etc/centos-release| awk '{print  $4}'`
#case $RELEASED in
#  7.4.1708 )
  echo "kontrola zda li byly v minulosti nainstalovany cuda drivery"
  A=`find /usr/local -name "uninstall_cuda_*.pl"`
if [ ! -z $A ]; then
  for i in $A ;do bash -c $i; done
fi
echo "zahajuji instalace noveho driveru!"
  $INSPATH/cuda/cuda_10/$RUNFILE --silent --driver --toolkit --samples > /dev/null 2>&1; RV=$?; testrv
  echo "zakladni driver byl nainstalovan"
  #$INSPATH/cuda/cuda_9/cuda_9.2.148.1_linux.run --silent --accept-eula
  #echo "patche byly nainstalovany"
  #cat /etc/profile.d/vfx.upp.sh | grep -e cuda-8.0 -e grep cuda-9.1
  #$INSPATH/cuda/cuda_10/cuda_10.1.105_418.39_linux.run --silent --driver --toolkit --samples > /dev/null 2>&1; RV=$?; testrv
  #echo "zakladni driver byl nainstalovan"
#  $INSPATH/cuda/cuda_9/cuda_9.2.148.1_linux.run --silent --accept-eula

#  echo "patche byly nainstalovany"
echo "uprava variables prosim po skonceni reboot!"
if  `hostname| grep vfx > /dev/null 2>&1` ; then
  SRC=vfx.upp.sh
elif `hostname|grep hu  > /dev/null 2>&1` ; then
  SRC=vfx.upp.hu.sh
else
  echo "this is not production workstation by hostname $HOSTNAME it should be vfxXXX or huXXX "
  exit 0
fi

if cat /etc/profile.d/$SRC | grep $VERSION ; then
  echo "$VERSION je jiz v profilu uvedena!!"
  exit 0
fi


  B=`cat /etc/profile.d/$SRC | grep cuda| grep lib| awk -F ":" '{ print $2 }'`
  C=/usr/local/$VERSION/lib64/
  sed -i "s~${B}~${C}~g" /etc/profile.d/$SRC > /dev/null 2>&1; RV=$?; testrv
  D=`cat /etc/profile.d/$SRC | grep -ohe cuda-9.1 -e cuda-8.0`
  sed -i "s~${D}~${VERSION}~g" /etc/profile.d/$SRC > /dev/null 2>&1; RV=$?; testrv
  echo "uprava provedena v poradku!!! prosim prekontrolujte si /etc/profile.d/$SRC"

#    ;;
#  *)
#  echo "spatna verze centosu"
#  exit 1
#  ;;
#esac
#$INSPATH/$CUDA --silent --driver --toolkit --samples > /dev/null 2>&1; RV=$?; testrv
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
    $INSPATH/Nuke_linux_silet_installer.sh $NPATH > /dev/null 2>&1; RV=$?; testrv
    rlmm
    exit 0
  fi
}

rlmm (){
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

#echo -n "nuke cp ... "
#cp -rv "$INSPATH/Nuke/$NUKE" "/usr/local/" > /dev/null 2>&1; RV=$?; testrv

#for a in $(ls "$INSPATH/Nuke/" | grep desktop); do
#echo -n "$a do menu ... "
#cp -rv "$INSPATH/Nuke/$a" "/usr/share/applications/" > /deyum -y installv/null 2>&1; RV=$?; testrv
#done
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

  echo -n "cp profile.d ... "
  cp "$INSPATH/$WOKRGRP" /etc/profile.d/ > /dev/null 2>&1; RV=$?; testrv
  echo -n "chmod profile.d ... "
  chmod 755 "/etc/profile.d/$WOKRGRP" > /dev/null 2>&1; RV=$?; testrv
}

installdesktop () {
echo -n "instalace $TRG_DESKTOP... "
yum groupinstall -y $TRG_DESKTOP > /dev/null 2>&1; RV=$?; testrv

    VFX=/etc/yum.repos.d/srv-repos01.vfx.repo
    echo "[srv-repos01.vfx.repo]" > $VFX
    echo "name=SRV-REPOS01.UPP.CZ - VFX REPOSITORY" >> $VFX
    echo "baseurl=http://srv-repos01.upp.cz/repos/vfx" >> $VFX
    echo "enabled=1" >> $VFX
    echo "gpgcheck=0" >> $VFX
yum makecache

for a in $(cat $INST_LIST); do
    echo -n "instalace $a ... "
    yum -y install $a > /dev/null 2>&1; RV=$?
    testrv
done
rm -f $VFX
yum makecache

echo "Kopiruju icons"
cp $INSPATH/icons/* /usr/share/applications/ > /dev/null 2>&1; RV=$?

 }

installserver () {
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

###yum zaklad + mate
base_yum()
{
sep
echo "YUM + DESKTOP"
sep

echo -n "yum rm repos ... "
rm /etc/yum.repos.d/* ; RV=$?; testrv


#for a in $(ls $SRCPATH/repos/|grep repo); do
#    echo -n "cp $a do etc ... "
#       if [ -f "/etc/yum.repos.d/$a" ]; then
#       echo "jiz existuje"
#       else
#       cp "$SRCPATH/repos/$a" "/etc/yum.repos.d/" > /dev/null 2>&1; RV=$?; testrv
#       fi
#done
RELEASE=`cat /etc/centos-release |awk '{print  $4}'`
case $RELEASE in
  7.3.1611)
    CENTOS=/etc/yum.repos.d/srv-repos01.centos7.repo
    echo "[srv-repos01.centos7.repo]" > $CENTOS
    echo "name=SRV-REPOS01.UPP.CZ - CENTOS7 REPOSITORY" >> $CENTOS
    echo "baseurl=http://srv-repos01.upp.cz/repos/centos/7/x86_64/" >> $CENTOS
    echo "enabled=1" >> $CENTOS
    echo "gpgcheck=0" >> $CENTOS

    EPEL=/etc/yum.repos.d/srv-repos01.elep7.repo
    echo "[srv-repos01.epel7.repo]" > $EPEL
    echo "name=SRV-REPOS01.UPP.CZ - EPEL7 REPOSITORY" >> $EPEL
    echo "baseurl=http://srv-repos01.upp.cz/repos/epel/7/x86_64/" >> $EPEL
    echo "enabled=1" >> $EPEL
    echo "gpgcheck=0" >> $EPEL

    VFX=/etc/yum.repos.d/srv-repos01.vfx.repo
    echo "[srv-repos01.vfx.repo]" > $VFX
    echo "name=SRV-REPOS01.UPP.CZ - VFX REPOSITORY" >> $VFX
    echo "baseurl=http://srv-repos01.upp.cz/repos/vfx" >> $VFX
    echo "enabled=1" >> $VFX
    echo "gpgcheck=0" >> $VFX
       ;;
  7.4.1708)
    CENTOS=/etc/yum.repos.d/srv-repos01.centos7.4.repo
    echo "[srv-repos01.centos7.4.repo]" > $CENTOS
    echo "name=SRV-REPOS01.UPP.CZ - CENTOS7 REPOSITORY" >> $CENTOS
    echo "baseurl=http://srv-repos01.upp.cz/repos/centos/7.4.1708/x86_64/" >> $CENTOS
    echo "enabled=1" >> $CENTOS
    echo "gpgcheck=0" >> $CENTOS

    EPEL=/etc/yum.repos.d/srv-repos01.elep7.repo
    echo "[srv-repos01.epel7.repo]" > $EPEL
    echo "name=SRV-REPOS01.UPP.CZ - EPEL7 REPOSITORY" >> $EPEL
    echo "baseurl=http://srv-repos01.upp.cz/repos/epel/7/x86_64/" >> $EPEL
    echo "enabled=1" >> $EPEL
    echo "gpgcheck=0" >> $EPEL

#    VFX=/etc/yum.repos.d/srv-repos01.vfx.repo
#    echo "[srv-repos01.vfx.repo]" > $VFX
#    echo "name=SRV-REPOS01.UPP.CZ - VFX REPOSITORY" >> $VFX
#    echo "baseurl=http://srv-repos01.upp.cz/repos/vfx" >> $VFX
#    echo "enabled=1" >> $VFX
#    echo "gpgcheck=0" >> $VFX
       ;;
  * )
  echo "nemate spravnou verzi Centosu bud 7.3 nebo 7.4"
  exit 1
  ;;
  esac




echo -n "yum clean ... "
yum clean all > /dev/null 2>&1; RV=$?; testrv
echo -n "yum makecache ... "
yum makecache > /dev/null 2>&1; RV=$?; testrv
echo -n "yum install nfs-utils ... "
yum -y install nfs-utils > /dev/null 2>&1; RV=$?; testrv
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


###ldap auth
#ldap()
# {
#sep
#echo "LDAP AUTH"
#sep
#echo -n "bind do ldapu ... "

#    authconfig \
#    --enableldap \
#    --enableldapauth \
#    --ldapserver="ldaps://ldap.upp.cz" \
#    --ldapbasedn="dn=uppdomain,dn=cz" \
#    --disableforcelegacy \
#    --enablesssd \
#    --enablesssdauth \
#    --enablelocauthorize \
#    --enableldaptls \
#    --enablemkhomedir \
#    --passalgo=md5 \
#    --update
#    RV=$?; testrv
#
#
#echo -n "cp sssd.conf ... "
#cp $SSSD /etc/sssd/; RV=$? > /dev/null 2>&1; testrv
#echo -n "sssd enable ... "
#systemctl enable sssd; > /dev/null 2>&1; RV=$?; testrv
#echo -n "sssd start ... "
#systemctl start sssd > /dev/null 2>&1; RV=$?; testrv

#}

blender (){
mkdir /usr/local/Blender/ && tar -xvjf $INSPATH/$BLENDER -C /usr/local/Blender/ > /dev/null && cp $INSPATH/blender/blender.desktop /usr/share/applications/ > /dev/null 2>&1; RV=$?; testrv
}

fusion (){
$INSPATH/blackmagick/Blackmagic_Fusion_Linux_9.0.1_installer.run -i
}

bview()
{
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
           gawk '/NUKE_PATH=/ {print $0":/opt/Bokeh-v1.4.3_Nuke11.1-linux64"} !/NUKE_PATH=/ {print $0}'  /etc/profile.d/vfx.upp.sh > /etc/profile.d/tmp && mv /etc/profile.d/tmp /etc/profile.d/vfx.upp.sh
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

#ntp_gate()
# {
#sep
#echo "NTPDATE"
#sep

#echo -n "gate do ntp.conf ... "
#if [ -f /etc/ntp.conf ]; then
#  cat /etc/ntp.conf | grep gate.upp.cz  > /dev/null 2>&1; TV=$?;
#  if [ $TV -eq 1 ]; then
#sed -i 's/server/\#server/g' /etc/ntp.conf
#echo "server gate.upp.cz" >> /etc/ntp.conf > /dev/null 2>&1; RV=$?; testrv
#echo "ntp prenastavno na gate"
#sep
#else
#  echo "ntp jiz nastaveno spravne"
#  sep
#fi
#else
#touch /etc/ntp.conf
#echo "server gate.upp.cz" > /etc/ntp.conf > /dev/null 2>&1; RV=$?; testrv
#echo "ntp nove nastaveno na gate"
#sep
#fi

#echo -n "timezone nastaveni ... "
#timedatectl set-timezone Europe/Prague > /dev/null 2>&1; RV=$?; testrv
#echo -n "ntpdate enable ... "
#systemctl enable ntpdate > /dev/null 2>&1; RV=$?; testrv
#echo -n "ntpdate start ... "
#systemctl start ntpdate > /dev/null 2>&1; RV=$?; testrv

#}


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
#chsssd () {
#echo "uprava SSSD pro generovani kerberos ticketu upravy sssd.conf "
#if [ -f /etc/sssd/sssd.conf ]; then
#cp /etc/sssd/sssd.conf /etc/sssd/cp_sssd.conf2  > /dev/null 2>&1; RV=$?; testrv
#echo "vytvoreni zalohy sssd.conf probehlo uspesne"
#fi
#cp $INSPATH/sssd.conf /etc/sssd/  > /dev/null 2>&1; RV=$?; testrv
#echo "prenstaveni sssd probehlo uspesne"
#systemctl restart sssd  > /dev/null 2>&1; RV=$?; testrv
#echo "byla restartovana sluzba sssd"
#systemctl status sssd  > /dev/null 2>&1; RV=$?; testrv
#sep
#exit 0

#}

upgradeos () {
echo "updatuje jen z Centos 7.3 --> 7.4"
RELEASES=`cat /etc/centos-release| awk '{print  $4}'`
if [[ $RELEASES = "7.3.1611" ]]; then
  rm /etc/yum.repos.d/*


    CENTOS=/etc/yum.repos.d/srv-repos01.centos7.4.repo
    echo "[srv-repos01.centos7.4.repo]" > $CENTOS
    echo "name=SRV-REPOS01.UPP.CZ - CENTOS7 REPOSITORY" >> $CENTOS
    echo "baseurl=http://srv-repos01.upp.cz/repos/centos/7.4.1708/x86_64/" >> $CENTOS
    echo "enabled=1" >> $CENTOS
    echo "gpgcheck=0" >> $CENTOS

    EPEL=/etc/yum.repos.d/srv-repos01.elep7.repo
    echo "[srv-repos01.epel7.repo]" > $EPEL
    echo "name=SRV-REPOS01.UPP.CZ - EPEL7 REPOSITORY" >> $EPEL
    echo "baseurl=http://srv-repos01.upp.cz/repos/epel/7/x86_64/" >> $EPEL
    echo "enabled=1" >> $EPEL
    echo "gpgcheck=0" >> $EPEL

    #VFX=/etc/yum.repos.d/srv-repos01.vfx.repo
    #echo "[srv-repos01.vfx.repo]" > $VFX
    #echo "name=SRV-REPOS01.UPP.CZ - VFX REPOSITORY" >> $VFX
    #echo "baseurl=http://srv-repos01.upp.cz/repos/vfx" >> $VFX
    #echo "enabled=1" >> $VFX
    #echo "gpgcheck=0" >> $VFX

    yum clean all > /dev/null 2>&1; RV=$?; testrv
    yum makecache > /dev/null 2>&1; RV=$?; testrv
    echo "upgrade begin!"
    yum -y update --skip-broken > /dev/null 2>&1; RV=$?; testrv
    echo "smazani novych nechtenych repozitaru"
    rm -f /etc/yum.repos.d/CentOS-* > /dev/null 2>&1; RV=$?; testrv
    yum makecache > /dev/null 2>&1; RV=$?; testrv
    echo "Instalace dconf-editoru pro upravu velikosti ikon Centos7.4 bug"
    yum -y install dconf-editor > /dev/null 2>&1; RV=$?; testrv
else
   echo " tady neni co upgradovat!!!"
    exit 0
fi

}
toglobal (){
  echo "preklopeni s LDAP do AD"
  $INSPATH/to_globalupp.sh
}

bl_nuke () {
  DI=`cat /proc/driver/nvidia/version | 390.87| wc -l`
  if [ $DI -eq 0 ]; then
printf "priprava instalace Baselight for Nuke\n Pozor skript zastavi graficke prostredi kuli reinstalu driveru na grafiku!!\n Pro to jej nikdy nepoustejte s GUI!!!!!\n Jste si jisti?\n pokud date No tak koncite\n"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit 0;;
    esac
done
echo "nyni vypnem GUI"
systemctl stop gdm > /dev/null 2>&1; RV=$?; testrv
echo "instalace NVIDIA driveru"
echo "zabere to nakej cas"
$INSPATH/NVIDIA/NVIDIA-Linux-x86_64-390.87.run -q -a -n -X -s
echo "hotovo driver nainstalovan!"
fi
echo "Instalace baselight pro Nuka je treba vybrat verzi"
options=( $(ls $INSPATH/baselight_for_nuke/ | xargs -0) )
PS3="$prompt "
select opt in "${options[@]}" "Quit" ; do
  if (( REPLY == 1 + ${#options[@]} )) ; then
  exit

elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
  echo  "Vybraly jste moznost $REPLY verzi $opt"
   $INSPATH/baselight_for_nuke/$opt/install-nuke --accept-licence > /dev/null 2>&1; RV=$?; testrv
   #gawk -i inplace  '/NUKE_PATH/ {print $0":/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_1:/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_2"} {print $0}'  /etc/profile.d/upp.vfx.sh
   TV=`cat /etc/profile.d/vfx.upp.sh | grep $opt |wc -l`
   if [ $TV -eq 0 ]; then
     gawk '/NUKE_PATH=/ {print $0":/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_1:/usr/local/filmlight/baselight-for-nuke11-5-1-10806/nuke11_2"}  !/NUKE_PATH=/ { print $0}'  /etc/profile.d/vfx.upp.sh > /etc/profile.d/tmp && mv /etc/profile.d/tmp /etc/profile.d/vfx.upp.sh
   fi
   echo "vse ok"
   printf "je treba reboot jste ted pro?"
   select yn in "Yes" "No"; do
     case $yn in
         Yes ) init 6 ; break;;
         No ) exit 0;;
     esac
 done
 else
  echo "Spatna Moznost."
  exit 0
   fi
 done


}

install_ffmpeg () {
    echo "instalace balicku ffmpeg"
     test1=`rpm -qa vlc|wc -l`
     if [ $test1 -ge 1 ];then
        yum -y remove vlc* ;

     #yum -y remove x265-libs-1.9-1.el7.nux.x86_64
     fi

    AWEL=/etc/yum.repos.d/srv-repos01.awel.repo
    echo "[srv-repos01.awel.repo]" > $AWEL
    echo "name=SRV-REPOS01.UPP.CZ - AWEL REPOSITORY" >> $AWEL
    echo "baseurl=http://srv-repos01.upp.cz/repos/awel" >> $AWEL
    echo "enabled=1" >> $AWEL
    echo "gpgcheck=0" >> $AWEL

    yum makecache  > /dev/null 2>&1; RV=$?; testrv
    yum -y install ffmpeg  > /dev/null 2>&1; RV=$?; testrv

    rm -f $AWEL
    yum makecache  > /dev/null 2>&1; RV=$?; testrv

    echo "balicek ffmpeg byl uspesne nainstalovan"

}


# --- Option processing --------------------------------------------
privilidge
while getopts ":vhgn:N:cRsbfKSI:Utwlmxok" optname
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
      TRG_DESKTOP="GNOME Desktop"
      base_yum
      soft_mount
      installdesktop
      install_ffmpeg
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
      dracut_set
      wacom
      instanteam
      roayal
      opt
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
      soft_mount
      installserver
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
#      "a")
#      soft_mount
#      chsssd
#      ;;
      "U")
      soft_mount
      upgradeos
      install_ffmpeg
      ;;
      "t")
      soft_mount
      toglobal
      ;;
      "w")
      soft_mount
      wacom
      ;;
      "l")
      soft_mount
      bl_nuke
      ;;
      "m")
      soft_mount
      mashlab
      ;;
      "x")
      soft_mount
      bokeh
      ;;
      "o")
      soft_mount
      opticalfl
      ;;
      "k")
      soft_mount
      nomachine
      ;;
	     *)
        echo "Nezname parmetry prosim opakujte znova -h"
        exit 0;
        ;;
    esac
  done
shift $(($OPTIND - 1))
#case $DESKTOP in
#    "k")
#    TRG_DESKTOP="KDE Plasma Workspaces"
#    ;;
#    "g")
#    TRG_DESKTOP="GNOME Desktop"
#    ;;
#    "x")
#    TRG_DESKTOP="Xfce"
#    ;;
#    "m")
#    TRG_DESKTOP="MATE Desktop"
#    ;;
#    *)
#    TRG_DESKTOP="GNOME Desktop"
#    ;;
#esac

#echo -n "instalace $TRG_DESKTOP... "
#yum groupinstall -y $TRG_DESKTOP > /dev/null 2>&1; RV=$?; testrv

#for a in $(cat $INST_LIST); do
#    echo -n "instalace $a ... "
#    yum -y install $a > /dev/null 2>&1; RV=$?
#    testrv
#done

#sep
#echo -n "instalace Xek ... "
#yum groupinstall -y "X Window system" > /dev/null 2>&1; RV=$?; testrv
#unlink /etc/systemd/system/default.target
#ln -s /lib/systemd/system/graphical.target /etc/systemd/system/default.target
