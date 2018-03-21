#!/bin/bash
#

#Run this in a directory containing only *.mrc files and all the same dimensions

<<<<<<< HEAD
angpix="1.58"
=======
angpix="3.16"
>>>>>>> c5676af25043108b93ef3c0108278bf18e805146
cs="6.3"
V="120"

mkdir -p rawdata
mv *.mrc rawdata

mkdir -p bin2
<<<<<<< HEAD
source /usr/local/software/EMAN2/bin/activate
=======
source /mount/local/app/EMAN2/bin/activate
>>>>>>> c5676af25043108b93ef3c0108278bf18e805146
e2proc2d.py rawdata/*.mrc bin2/@.mrc --meanshrink 2

mkdir -p gauto
e2proc2d.py bin2/*.mrc gauto/@.mrc --mult=-1

source ~/.bashrc
