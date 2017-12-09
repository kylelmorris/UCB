#!/bin/bash
#

#Run this in a directory containing only *.mrc files and all the same dimensions

angpix="3.16"
cs="6.3"
V="120"

mkdir -p rawdata
mv *.mrc rawdata

mkdir -p bin2
source /mount/local/app/EMAN2/bin/activate
e2proc2d.py rawdata/*.mrc bin2/@.mrc --meanshrink 2

mkdir -p gauto
e2proc2d.py bin2/*.mrc gauto/@.mrc --mult=-1

source ~/.bashrc
