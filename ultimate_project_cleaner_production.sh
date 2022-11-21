#!/bin/bash

help () {
printf "parametr -t spusti interaktivni prohledavani projektu a promaze slozky back,\n soubory *.nk~, *.nk.autosave Poustejte ho jako prvni!!!\n parametr -s vytvori promazavaci skript aby zanechal poslednich 5 pouzitejch zaberu\n -r vytvori promazavaci skript aby zanechal poslednich 4 renderu \n -p vytvori promazavaci skript aby zanechal poslednich 4 projekci\n"

}

defaults () {

echo "Vyberte storrage vfxstore1 (1) vfxstore2 (2) ? r(1/2) "
read S
case $S in
	1) STORAGE="vfxstore"
	;;
	2) STORAGE="vfxstore2"
     	;;
	*) echo "fuck your forest bastardo!!!!";exit 1
	;;
esac
echo "$STORAGE"


      PROMPT="vyberte nazev projektu na $STORAGE:"
      options=( $(ls /upp/servers/$STORAGE/VFXstore/PROJECTS/ |xargs -0  ) )
      PS3="$prompt "
      select opt in "${options[@]}" "Quit" ; do
        #if ( REPLY == 1 + ${#options[@]} ) ; then
        #exit
	#elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then

        echo  "Vybraly jste moznost $REPLY projekt $opt na $STORAGE"
        PROJECT=$opt
	if [ $PROJECT == "Quit" ]; then exit 0;fi
        DEFAULT_SHOT_PATH=/upp/servers/$STORAGE/VFXstore/PROJECTS/${PROJECT}/shots
        ls $DEFAULT_SHOT_PATH
	break
       #else
       # echo "Spatna Moznost."
       # exit 0
       #  fi
       done

}
       tildashots () {

TILDA_SHOTS=$DEFAULT_SHOT_PATH/*/2d/scripts/comp/*.nk~
TILDEL=$PWD/vystup_tilda_del_${STORAGE}_${PROJECT}.sh

if [ -f $PWD/vystup_tilda_del_${STORAGE}_${PROJECT}.sh ]; then echo "" > $TILDEL;fi
find $TILDA_SHOTS -type f -exec readlink -f {} \;| tee |awk '{ print "rm -fv " $0}' >> $TILDEL
echo "List souboru ke smazani je krome vypisu na TTY i v souboru $TILDEL prosim overit pred spustenim generovaneho skriptu a smazanim !!!"
chmod +x $TILDEL

###########################
ASDEL=$PWD/delete_autosave_${STORAGE}_${PROJECT}.sh
AUTOSAVE_SHOTS=$DEFAULT_SHOT_PATH/*/2d/scripts/comp/*.autosave

if [ -f $ASDEL ]; then echo "" > $ASDEL;fi
find $AUTOSAVE_SHOTS -type f -exec readlink -f {} \;| tee |awk '{ print "rm -fv " $0}' >> $ASDEL
echo "List souboru ke smazani je krome vypisu na TTY i v souboru $ASDEL prosim overit pred spustenim generovaneho skriptu a smazanim !!!"
chmod +x $ASDEL

###########################
BACKDEL=$PWD/delete_backups_${STORAGE}_${PROJECT}.sh
BACK_SHOTS=$DEFAULT_SHOT_PATH/*/2d/scripts/comp/back
if [ -f $BACKDEL ]; then echo "" > $BACKDEL;fi
find $BACK_SHOTS -type d -exec readlink -f {} \;| tee |awk '{ print "rm -rfv " $0}' >> $BACKDEL
echo "List souboru ke smazani je krome vypisu na TTY i v souboru $BACKDEL prosim overit pred spustenim generovaneho skriptu a smazanim !!!"
chmod +x $BACKDEL
exit 0
}

shots_cleaning () {
SHOTDEL=$PWD/shotsdel.sh
if [ -f $SHOTDEL ]; then echo "" > $SHOTDEL;fi
#printf "#!/bin/bash\n#mazaci skript pro projekt $STORAGE_PROJECT\n je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci Y/y\n" >> $SHOTDEL
echo "!!!!!!POZOR!!!!!! aby to fungovalo v poradku je treba pustit nejprve s parametrem -t a promozat bordel!!!!!!!"
echo "#!/bin/bash" >> $SHOTDEL
echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $SHOTDEL
echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci y/n\""  >> $SHOTDEL
for i in $(ls $DEFAULT_SHOT_PATH|xargs  -0 ); do
        #echo "ls -ldn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 " >> $SHOTDEL
	#echo "find $DEFAULT_SHOT_PATH/$i -type f -exec ls {} \;|tail -n +5
	echo "ls -dt $DEFAULT_SHOT_PATH/$i/2d/scripts/comp/* | sort -k9 -V| head -n -5 | awk '{print $9}'" >> $SHOTDEL
	  echo "echo \"Mazem nebo Koncime!!!!????? y/n \"" >> $SHOTDEL
  echo "read K" >> $SHOTDEL
  echo "case \$K in" >> $SHOTDEL
          echo "y) break" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
          echo "n) echo \"koncime\" && exit 0" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
          echo "*) echo \"fuck your forest bastardo y nebo n !!!!\"" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
  echo "esac" >> $SHOTDEL
	#echo "ls -dn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 | xargs rm -fv" >> $SHOTDEL
	echo "ls -dt $DEFAULT_SHOT_PATH/$i/2d/scripts/comp/* | sort -k9 -V| head -n -5 | awk '{print $9}'| xargs rm -fv"  >> $SHOTDEL
	echo "" >> $SHOTDEL
	echo "#########################################################" >> $SHOTDEL
	echo "" >> $SHOTDEL
done
chmod +x $SHOTDEL
echo " skritp se  nachazi: $SHOTDEL"
}

render_cleaning () {
SHOTDEL=$PWD/renders_del_${PROJECT}.sh
if [ -f $SHOTDEL ]; then echo "" > $SHOTDEL;fi
#printf "#!/bin/bash\n#mazaci skript pro projekt $STORAGE_PROJECT\n je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci Y/y\n" >> $SHOTDEL
#echo "!!!!!!POZOR!!!!!! aby to fungovalo v poradku je treba pustit nejprve s parametrem -t a promozat bordel!!!!!!!"
echo "#!/bin/bash" >> $SHOTDEL
echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $SHOTDEL
echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani renderu!!! pomoci y/n\""  >> $SHOTDEL
for i in $(ls $DEFAULT_SHOT_PATH|xargs -0 ); do
        #echo "ls -ldn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 " >> $SHOTDEL
	#echo "find $DEFAULT_SHOT_PATH/$i -type f -exec ls {} \;|tail -n +5
	echo "ls -dt $DEFAULT_SHOT_PATH/$i/2d/renders/* | sort -k9 -V| head -n -4" >> $SHOTDEL
	  echo "echo \"Mazem nebo Koncime!!!!????? y/n \"" >> $SHOTDEL
  echo "read K" >> $SHOTDEL
  echo "case \$K in" >> $SHOTDEL
          echo "y) break" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
          echo "n) echo \"koncime\" && exit 0" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
          echo "*) echo \"fuck your forest bastardo y nebo n !!!!\"" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
  echo "esac" >> $SHOTDEL
	#echo "ls -dn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 | xargs rm -fv" >> $SHOTDEL
	echo "ls -dt $DEFAULT_SHOT_PATH/$i/2d/renders/* | sort -k9 -V| head -n -4 | xargs rm -rfv"  >> $SHOTDEL
	echo "" >> $SHOTDEL
	echo "#########################################################" >> $SHOTDEL
	echo "" >> $SHOTDEL
done
chmod +x $SHOTDEL
echo " skritp se  nachazi: $SHOTDEL"
}

projections_cleaning () {
SHOTDEL=$PWD/projection_del_${PROJECT}.sh
if [ -f $SHOTDEL ]; then echo "" > $SHOTDEL;fi
#printf "#!/bin/bash\n#mazaci skript pro projekt $STORAGE_PROJECT\n je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci Y/y\n" >> $SHOTDEL
#echo "!!!!!!POZOR!!!!!! aby to fungovalo v poradku je treba pustit nejprve s parametrem -t a promozat bordel!!!!!!!"
echo "#!/bin/bash" >> $SHOTDEL
echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $SHOTDEL
echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani renderu!!! pomoci y/n\""  >> $SHOTDEL
for i in $(ls $DEFAULT_SHOT_PATH|xargs -0 ); do
        #echo "ls -ldn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 " >> $SHOTDEL
	#echo "find $DEFAULT_SHOT_PATH/$i -type f -exec ls {} \;|tail -n +5
	echo "ls -dt $DEFAULT_SHOT_PATH/$i/projection/* | sort -k9 -V| head -n -4" >> $SHOTDEL
	  echo "echo \"Mazem nebo Koncime!!!!????? y/n \"" >> $SHOTDEL
  echo "read K" >> $SHOTDEL
  echo "case \$K in" >> $SHOTDEL
          echo "y) break" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
          echo "n) echo \"koncime\" && exit 0" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
          echo "*) echo \"fuck your forest bastardo y nebo n !!!!\"" >> $SHOTDEL
          echo ";;" >> $SHOTDEL
  echo "esac" >> $SHOTDEL
	#echo "ls -dn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 | xargs rm -fv" >> $SHOTDEL
	echo "ls -dt $DEFAULT_SHOT_PATH/$i/projection/* | sort -k9 -V| head -n -4| xargs rm -rfv"  >> $SHOTDEL
	echo "" >> $SHOTDEL
	echo "#########################################################" >> $SHOTDEL
	echo "" >> $SHOTDEL
done
chmod +x $SHOTDEL
echo " skritp se  nachazi: $SHOTDEL"
}


# --- Option processing --------------------------------------------
while getopts ":htsrp" optname
  do
    case "$optname" in
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
      "t")
      defaults
      tildashots
        ;;
			"s")
			defaults
			shots_cleaning
				;;
			"r")
			defaults
			render_cleaning
				;;
			"p")
			defaults
			projections_cleaning
				;;
	     *)
        echo "Nezname parmetry prosim opakujte znova -h"
        exit 0;
        ;;
    esac
  done
shift $(($OPTIND - 1))
