#!/bin/bash
umask 007
export NUKE_PATH=/upp/upptools/workgroups/nuke/production_11/
export HIERO_PLUGIN_PATH=$NUKE_PATH/hiero
export RR_ROOT=/upp/royalrender
export QT_QPA_FONTDIR=/upp/upptools/workgroups/common/linux/fonts
export LD_LIBRARY_PATH=/upp/upptools/workgroups/common/linux:/usr/local/cuda-9.1/lib
export OFX_PLUGIN_PATH=/usr/genarts/
export CUDA_HOME=/usr/local/cuda-9.1

/usr/local/Nuke11.1v4/Nuke11.1 --nukex -c 50G -m 25 -F 1-5 --gpu 0 -x 
/usr/local/Nuke11.1v4/Nuke11.1 --nukex -c 50G -m 25 -F 1-5 --gpu 1 -x
echo "bezi skript 1,2;"

