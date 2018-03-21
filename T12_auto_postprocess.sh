#!/bin/bash
#

#Run this in a directory containing a T12_auto_preprocess.sh processed file system

angpix="3.16"
cs="6.3"
V="120"
<<<<<<< HEAD
mpiproc=3
extract_size=96
extract_bin=96
bg_radius=36
=======
gautomatch='/mount/local/app/Gautomatch/bin/Gautomatch-v0.53_sm_20_cu7.5_x86_64'
mpiproc=3
extract_size=192
extract_bin=192
bg_radius=72
>>>>>>> c5676af25043108b93ef3c0108278bf18e805146
maxsig=3
particled=300
classno=42

<<<<<<< HEAD
gctfexe='gctf-v1.06'
gautoexe='gautomatch'

=======
>>>>>>> c5676af25043108b93ef3c0108278bf18e805146
mkdir -p Relion/Micrographs
cd Relion/Micrographs
ln -s ../../bin2/*.mrc .
cd ..

#Make micrographs ctf star file
printf "\nMaking new micrographs star file, removing old...\n"
rm -rf micrographs.star
relion_star_loopheader rlnMicrographName > micrographs.star
ls Micrographs/*.mrc >> micrographs.star

<<<<<<< HEAD
mkdir -p CtfFind

printf "\nRunning gctf with phase estimation using Relion\n"
mpirun -n 4 `which relion_run_ctffind_mpi` --i micrographs.star --o CtfFind --CS ${cs} --HT ${V} --AmpCnst 0.1 --XMAG 10000 --DStep ${angpix} --Box 512 --ResMin 30 --ResMax 2.3 --dFMin 3000 --dFMax 10000 --FStep 500 --dAst 100 --use_gctf --gctf_exe ${gctfexe} --angpix ${angpix} --EPA --gpu "" --only_do_unfinished
=======
cd Relion

mkdir -p CtfFind

printf "\nRunning gctf with phase estimation using Relion\n"
mpirun -n 4 `which relion_run_ctffind_mpi` --i micrographs.star --o CtfFind --CS ${cs} --HT ${V} --AmpCnst 0.1 --XMAG 10000 --DStep ${angpix} --Box 512 --ResMin 30 --ResMax 2.3 --dFMin 3000 --dFMax 10000 --FStep 500 --dAst 100 --use_gctf --gctf_exe "/mount/local/app/bin/gctf-v1.06" --angpix ${angpix} --EPA --gpu "" --only_do_unfinished
>>>>>>> c5676af25043108b93ef3c0108278bf18e805146

scp -r CtfFind/micrographs_ctf.star micrographs_all_gctf.star

#Do autopicking with gautomatch
mkdir -p AutoPick/Micrographs
cd AutoPick/Micrographs
ln -sf ../../../gauto/*.mrc .
cd ../..
printf "\ngautomatch picking...\n"
<<<<<<< HEAD
$gautoexe --apixM $angpix --diameter 200 --lave_min -10.0 --lave_max 3.0 AutoPick/Micrographs/*.mrc --do_unfinished
=======
$gautomatch --apixM $angpix --diameter 200 --lave_min -10.0 --lave_max 3.0 AutoPick/Micrographs/*.mrc --do_unfinished
>>>>>>> c5676af25043108b93ef3c0108278bf18e805146

#Link automatch files into Micrograph directory
cd Micrographs
ln -sf ../AutoPick/Micrographs/*automatch.star .
cd ..
#Link automatch files into CtfFind directory
cd CtfFind/Micrographs
ln -sf ../../../AutoPick/Micrographs/*automatch.star .
cd ../..
#rsync automatch files into ManualPick directory for any manual editing
mkdir -p ManualPick/Micrographs
cd ManualPick/Micrographs
rsync -aP ../../AutoPick/Micrographs/*automatch.star .
cd ../..
printf "\nCopied *automatch coordinates into ManualPick directory for inspection/editing\n"

#Extract particles within Relion
printf "\nRemoving old particles.star and extracting any new particles using Relion\n"
rm -rf particles.star
  mpirun -n $mpiproc `which relion_preprocess_mpi` --i CtfFind/micrographs_ctf.star --coord_dir . --coord_suffix _automatch.star --part_star ./particles.star --part_dir ./Extract --extract --extract_size $extract_size --scale $extract_bin --norm --bg_radius $bg_radius --white_dust -1 --black_dust -1 --only_extract_unfinished

if [ -e particles.star ]; then
  printf "\nParticles.star exists, continuing...\n"
else
  printf "\nSomething is wrong, particle extraction appears to have failed\n"
  exit
fi

mkdir -p Class2D
#2D averaging
mpirun -n $mpiproc `which relion_refine_mpi` --o ./Class2D/run --i ./particles.star --dont_combine_weights_via_disc --pool 3 --ctf  --iter 25 --maxsig $maxsig --tau2_fudge 2 --particle_diameter $particled --K $classno --flatten_solvent  --zero_mask --oversampling 1 --psi_step 12 --offset_range 5 --offset_step 2 --norm --scale --dont_check_norm --ctf_intact_first_peak --j 1 --gpu ""

#Show classes
relion_display --i Class2D/run_it025_classes.mrcs
