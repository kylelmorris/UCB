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

/mount/local/app/Gautomatch/bin/Gautomatch-v0.53_sm_20_cu7.5_x86_64 --apixM $angpix --diameter 200 --lave_min -10.0 --lave_max 3.0 gauto/*.mrc

mkdir -p Relion/Micrographs
cd Relion/Micrographs
ln -s ../../bin2/*.mrc .
cd ..

#Make micrographs ctf star file
printf "\nMaking new micrographs star file, removing old...\n"
rm -rf micrographs.star
relion_star_loopheader rlnMicrographName > micrographs.star
ls Micrographs/*.mrc >> micrographs.star
