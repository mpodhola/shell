#!/bin/#!/usr/bin/env bash
# Skriipt pro renderovani vicero zaberu v programu Nuke11XXX
# Martin Podhola 18.12.2018


help (){


printf " -h vypise help \n -g max gpu Y/N \n -n - cesta k binarce nuka  \n -s cesta k source davkovemu souboru \n -i interaktivni pusti jeden skript"
printf "Davkovy soubor by mel byt textak a to takto: co radek to plna cesta k nuke skriptu\n Dale je treba definovat export "
}


while getopts ":hg:n:c:m:s:i" optname
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
      "g")
      GPU_MAX="$OPTARG"
        ;;
      "n")
      NUKE_LAUNCH="$OPTARG"
      ;;
      "c")
      MAX_MEM="$OPTARG"
      ;;
      "m")
      MAX_THREDS="$OPTARG"
      ;;
      "s")
      SOURCE_FILE="$OPTARG"
      ;;
      "i")
      interaktiv
	     *)
        echo "Nezname parmetry prosim opakujte znova -h"
        exit 0;
        ;;
    esac
  done
shift $(($OPTIND - 1))

while read LINE ; do
  if [ ! -f $LINE ]
    echo "nemuzeme renderovat jelikoz ve vstupnim souboru je spatna cesta : $LINE"
    exit 1
  fi
  A=`cat $LINE | grep /usr/local/Nuke | wc -l`
  if [ $A -ne 1 ]; then
    echo "nejdna se o nukovskej skript! : $LINE"
    exit 1
  fi
FF=`cat $LINE | grep first_frame| awk '{print $2}'`
LF=`cat $LINE | grep last_frame| awk '{print $2}'`

if [ $GPU_MAX = "Y" ]; then
  GPU_NUMBER=`$NUKE_LAUNCH --gpulist |tail -n +3 | wc -l`
  ((TMP_GPU=`GPU_NUMBER -1`))
  GPU=(0..$TMP_GPU)
PF=`LF/GPU_NUMBER| bc -l`
NUMBER_CPU=`nproc`
FINAL_CPU=`echo "($NUMBER_CPU - 2)/$GPU_NUMBER"| bc`
TOTAL_MEM=`free -g | awk '{print $2}' | tail -n +2| head -1`
FINAL_MEM=`echo `
  for i in GPU[@]; do

fi

$NUKE_LAUNCH -
done < $SOURCE_FILE
