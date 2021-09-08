#!/bin/bash

help () {
printf "parametr <-t> spusti interaktivni prohledavani projektu a vygeneruje promazavaci skript na slozky back u shotu,\n soubory *.nk~, *.nk.autosave Poustejte ho jako prvni!!!\n parametr <-s> vytvori promazavaci skript aby zanechal poslednich 5 pouzitejch zaberu\n <-r> vytvori promazavaci skript na slozku renders v skriptech a pta se pokud <y> jede interaktivne a zanechal poslednich 4 rendery ve slozce pokud <n> tak generuje mazaci skript bez ptani a nenecha nic \n <-p> vytvori promazavaci skript aby promazal v shotech projekce a pta se pokud <y> tak vygenerovany skript zanecha poslednich 4 projekce a jede interaktivne pokud <n> tak vygeneruje skript co smaze vse z projekci !! \n <-f> vygeneruje skript co procisti kompletne shots krom skriptu projekci a renderu \n Parametr <-R> vygeneruje mazaci skript na zbytetk projektu jako jsou shared elements atp. \n "

}

pocetverzi () {

while ! [[ $cislo =~ ^[0-9]*$ ]] || [ -z $cislo ];
do
        echo "zadejte pocet verzi ktere chcete nechat : "
        read cislo
done


}


#Prom mazani v podslozce shots
defaults_shot () {

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
pocetverzi
}




#Pro mazani ve slozce projektu
defaults_project () {

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
        DEFAULT_PROJECT_PATH=/upp/servers/$STORAGE/VFXstore/PROJECTS/${PROJECT}
        ls $DEFAULT_PROJECT_PATH
	break
       #else
       # echo "Spatna Moznost."
       # exit 0
       #  fi
       done

}





#Mazani nuk skriptu tilda cili autosevu
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




#Mazani shotu  nukovejch skriptu a nechani poslednich 5 prakticky na nic!!
shots_cleaning () {
SHOTDEL=$PWD/shotsdel.sh
if [ -f $SHOTDEL ]; then echo "" > $SHOTDEL;fi
#printf "#!/bin/bash\n#mazaci skript pro projekt $STORAGE_PROJECT\n je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci Y/y\n" >> $SHOTDEL
echo "!!!!!!POZOR!!!!!! aby to fungovalo v poradku je treba pustit nejprve s parametrem -t a promozat bordel!!!!!!!"
echo "#!/bin/bash" >> $SHOTDEL
echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $SHOTDEL
echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci y/n\""  >> $SHOTDEL
for i in $(ls $DEFAULT_SHOT_PATH|xargs -0 ); do
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




#Mazani renderu s parametrem "p" maze postupne a nechava poslednich 5 renderu je to pro zivej projekt kterej je potreba promazat
render_cleaning () {
SHOTDEL=$PWD/renders_del_${PROJECT}.sh
if [ -f $SHOTDEL ]; then echo "" > $SHOTDEL;fi



echo "Budem nechvat poslednich $cislo renderu <y> nebo mazem vse <n> ? y/n "
read K
case $K in
			y)
      #printf "#!/bin/bash\n#mazaci skript pro projekt $STORAGE_PROJECT\n je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci Y/y\n" >> $SHOTDEL
      #echo "!!!!!!POZOR!!!!!! aby to fungovalo v poradku je treba pustit nejprve s parametrem -t a promozat bordel!!!!!!!"
      echo "#!/bin/bash" >> $SHOTDEL
      echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $SHOTDEL
      echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani renderu!!! pomoci y/n\""  >> $SHOTDEL
      for i in $(ls $DEFAULT_SHOT_PATH|xargs -0 );
      do
        #echo "ls -ldn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 " >> $SHOTDEL
	      #echo "find $DEFAULT_SHOT_PATH/$i -type f -exec ls {} \;|tail -n +5
	      echo "ls -dt $DEFAULT_SHOT_PATH/$i/2d/renders/* | sort -k9 -V| head -n -$cislo" >> $SHOTDEL
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
	      echo "ls -dt $DEFAULT_SHOT_PATH/$i/2d/renders/* | sort -k9 -V| head -n -$cislo | xargs rm -rfv"  >> $SHOTDEL
	      echo "" >> $SHOTDEL
	      echo "#########################################################" >> $SHOTDEL
	      echo "" >> $SHOTDEL
       done
      ;;

			n)
      echo "#!/bin/bash" >> $SHOTDEL
	    echo "echo \"Mazem komplet 2d renders ze vsech skriptu!!!\"" >> $SHOTDEL
	    for i in $(ls $DEFAULT_SHOT_PATH|xargs );
	    do
	     echo "rm -rfv $DEFAULT_SHOT_PATH/$i/2d/renders/*" >> $SHOTDEL
		   echo "" >> $SHOTDEL
	     echo "#########################################################" >> $SHOTDEL
	     echo "" >> $SHOTDEL
      done
      ;;
			*)
			echo "neznamy parametr y/n!!!!"
			exit 1
			;;
	esac


echo "exit 0" >> $SHOTDEL
chmod +x $SHOTDEL
echo " skritp se  nachazi: $SHOTDEL"
}






#Jako u Renderu maze poslednich 5 s pamarametrem "p" jinak maze vsechno
projections_cleaning () {
SHOTDEL=$PWD/projection_del_${PROJECT}.sh
if [ -f $SHOTDEL ]; then echo "" > $SHOTDEL;fi

pocetverzi;

echo "Budem nechvat poslednich 5 projekci <y> nebo mazem vse <n> ? y/n "
read K
case $K in
			y)
       #printf "#!/bin/bash\n#mazaci skript pro projekt $STORAGE_PROJECT\n je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci Y/y\n" >> $SHOTDEL
       #echo "!!!!!!POZOR!!!!!! aby to fungovalo v poradku je treba pustit nejprve s parametrem -t a promozat bordel!!!!!!!"
       echo "#!/bin/bash" >> $SHOTDEL
       echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $SHOTDEL
       echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani renderu!!! pomoci y/n\""  >> $SHOTDEL
       for i in $(ls $DEFAULT_SHOT_PATH|xargs -0 );
        do
         #echo "ls -ldn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 " >> $SHOTDEL
	       #echo "find $DEFAULT_SHOT_PATH/$i -type f -exec ls {} \;|tail -n +5
	       echo "ls -dt $DEFAULT_SHOT_PATH/$i/projection/* | sort -k9 -V| head -n -$cislo" >> $SHOTDEL
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
	       echo "ls -dt $DEFAULT_SHOT_PATH/$i/projection/* | sort -k9 -V| head -n -$cislo| xargs rm -rfv"  >> $SHOTDEL
	       echo "" >> $SHOTDEL
	       echo "#########################################################" >> $SHOTDEL
	       echo "" >> $SHOTDEL
        done
      ;;
			n)
	     echo "#!/bin/bash" >> $SHOTDEL
	     echo "echo \"Mazem komplet 2d projection ze vsech skriptu!!!\"" >> $SHOTDEL
	     for i in $(ls $DEFAULT_SHOT_PATH|xargs );
	      do
		     echo "rm -rfv $DEFAULT_SHOT_PATH/$i/2d/projection/*" >> $SHOTDEL
		     echo "" >> $SHOTDEL
		     echo "#########################################################" >> $SHOTDEL
		     echo "" >> $SHOTDEL
	      done
      ;;
			*)
			echo "spatna moznost bud y/n !!!!"
			exit 1
			;;
esac

echo "exit 0" >> $SHOTDEL
chmod +x $SHOTDEL
echo " skritp se  nachazi: $SHOTDEL"
}




dailies_cleaning () {
SHOTDEL=$PWD/dailies_del_${PROJECT}.sh
if [ -f $SHOTDEL ]; then echo "" > $SHOTDEL;fi

echo "Budem nechvat poslednich 5 dailies <y> nebo mazem vse <n> ? y/n "
read K
case $K in
			y)
      #printf "#!/bin/bash\n#mazaci skript pro projekt $STORAGE_PROJECT\n je treba po kazdem zaberu potvrdit dalsi mazani!!! pomoci Y/y\n" >> $SHOTDEL
      #echo "!!!!!!POZOR!!!!!! aby to fungovalo v poradku je treba pustit nejprve s parametrem -t a promozat bordel!!!!!!!"
      echo "#!/bin/bash" >> $SHOTDEL
      echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $SHOTDEL
      echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani dailies!!! pomoci y/n\""  >> $SHOTDEL
      for i in $(ls $DEFAULT_SHOT_PATH|xargs -0 );
      do
        #echo "ls -ldn $DEFAULT_SHOT_PATH/$i/*| tail -n -5 " >> $SHOTDEL
	      #echo "find $DEFAULT_SHOT_PATH/$i -type f -exec ls {} \;|tail -n +5
	      echo "ls -dt $DEFAULT_SHOT_PATH/$i/dailies/* | sort -k9 -V| head -n -$cislo" >> $SHOTDEL
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
	      echo "ls -dt $DEFAULT_SHOT_PATH/$i/dailies/* | sort -k9 -V| head -n -$cislo | xargs rm -rfv"  >> $SHOTDEL
	      echo "" >> $SHOTDEL
	      echo "#########################################################" >> $SHOTDEL
	      echo "" >> $SHOTDEL
       done
      ;;

			n)
      echo "#!/bin/bash" >> $SHOTDEL
	    echo "echo \"Mazem komplet 2d dailies ze vsech skriptu!!!\"" >> $SHOTDEL
	    for i in $(ls $DEFAULT_SHOT_PATH|xargs );
	    do
	     echo "rm -rfv $DEFAULT_SHOT_PATH/$i/dailies/*" >> $SHOTDEL
		   echo "" >> $SHOTDEL
	     echo "#########################################################" >> $SHOTDEL
	     echo "" >> $SHOTDEL
      done
      ;;
			*)
			echo "neznamy parametr y/n!!!!"
			exit 1
			;;
	esac


echo "exit 0" >> $SHOTDEL
chmod +x $SHOTDEL
echo " skritp se  nachazi: $SHOTDEL"
}














#Promaze ostatni veci v shotech krome renderu a krome projekci a scriptu
full_shots () {
FULLDEL=$PWD/full_del_${PROJECT}.sh
if [ -f $FULLDEL ]; then echo "" > $FULLDEL;fi
echo "#!/bin/bash" >> $FULLDEL
echo "echo \"#mazaci skript pro projekt ${STORAGE}_${PROJECT}\"" >> $FULLDEL
echo "echo \"Je treba po kazdem zaberu potvrdit dalsi mazani renderu!!! pomoci y/n\""  >> $FULLDEL

for i in $(ls $DEFAULT_SHOT_PATH|xargs  -0); do
	#echo "printf \" mazem  $DEFAULT_SHOT_PATH/$i/3d/ \n mazem  $DEFAULT_SHOT_PATH/$i/matte/ \n mazem $DEFAULT_SHOT_PATH/$i/2d/precomp/ \n  mazem $DEFAULT_SHOT_PATH/$i/2d/retouch/ \n mazem $DEFAULT_SHOT_PATH/$i/2d/roto/ \n mazem $DEFAULT_SHOT_PATH/$i/2d/showreel/ \n mazem $DEFAULT_SHOT_PATH/$i/2d/temp \n  mazem $DEFAULT_SHOT_PATH/$i/2d/track \n  mazem $DEFAULT_SHOT_PATH/$i/dailies \n mazem $DEFAULT_SHOT_PATH/$i/elements \n mazem $DEFAULT_SHOT_PATH/$i/matchmove/objects/ \n mazem  $DEFAULT_SHOT_PATH/$i/matchmove/proof \n mazem  $DEFAULT_SHOT_PATH/$i/mp/sources \n mazem  $DEFAULT_SHOT_PATH/$i/offline \n mazem  $DEFAULT_SHOT_PATH/$i/packages/ \n mazem  $DEFAULT_SHOT_PATH/$i/projection/ \n mazem  $DEFAULT_SHOT_PATH/$i/qt_to_client/ \n \""
	 #echo "echo \"Mazem nebo Koncime!!!!????? y/n \"" >> $SHOTDEL
  #echo "read K" >> $SHOTDEL
  #echo "case \$K in" >> $SHOTDEL
          #echo "y) break" >> $SHOTDEL
          #echo ";;" >> $SHOTDEL
          #echo "n) echo \"koncime\" && exit 0" >> $SHOTDEL
          #echo ";;" >> $SHOTDEL
          #echo "*) echo \"fuck your forest bastardo y nebo n !!!!\"" >> $SHOTDEL
          #echo ";;" >> $SHOTDEL
  #echo "esac" >> $SHOTDEL

echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/3d/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/2d/matte/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/2d/precomp/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/2d/retouch/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/2d/roto/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/2d/showreel/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/2d/temp/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/2d/track/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/dailies/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/elements/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/matchmove/objects/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/matchmove/proof/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/mp/sources/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/offline/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/packages/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/projection/*" >> $FULLDEL
echo "rm -rfv $DEFAULT_SHOT_PATH/${i}/qt_to_client/*" >> $FULLDEL
echo "" >> $SHOTDEL
echo "#########################################################" >> $SHOTDEL
echo "" >> $SHOTDEL
done
}




#Promaze projekt krom skriptu jako shared elementy refernce atp...
rest () {
	FULLDEL_PROJECT=$PWD/full_del_project_${PROJECT}.sh
echo "rm -rfv $DEFAULT_PROJECT_PATH/shared_elements/2d/elements/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/shared_elements/3dslapcomp/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/shared_elements/packages/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/references/camera_info/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/references/concepts/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/references/countsheets*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/references/offline_cut/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/references/others/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/references/recent_cut/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/references/shots/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/scans/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/cinesync/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/dailies/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/io/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/office/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/people/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/projection/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/supervisor/*" >> $FULLDEL_PROJECT
echo "rm -rfv $DEFAULT_PROJECT_PATH/videocomment/*" >> $FULLDEL_PROJECT


chmod +x $FULLDEL_PROJECT
echo " skritp se  nachazi: $FULLDEL_PROJECT"


}



# --- Option processing --------------------------------------------
while getopts ":htsrpdfR" optname
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
      defaults_shot
      tildashots
        ;;
			"s")
			defaults_shot
			shots_cleaning
				;;
			"r")
			defaults_shot
			render_cleaning
				;;
			"p")
			defaults_shot
			projections_cleaning
			;;
			"d")
			defaults_shot
			dailies_cleaning
			;;
			"f")
			defaults_shot
			full_shots
			;;
			"R")
			defaults_project
			rest
			;;
	    *)
      echo "Nezname parmetry prosim opakujte znova -h"
      exit 0;
      ;;
    esac
  done
shift $(($OPTIND - 1))
