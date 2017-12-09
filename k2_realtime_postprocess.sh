#!/bin/bash

# This script assumes that motioncor2 microgaphs are incoming to a directory named ./cor2
# Frames may be placed in ./Frames directory

#################################################################################
## Variables

# General
ext="*_noDW.mrc"	#File suffix and extension to use for linking micrographs

# Session monitoring
check=n			      #Check if scope if still writing micrographs?

# Particle extraction
angpix=0.893
extract_size=352
extract_bin=88		#Make the same as extract_size if no binning
mpiproc=4

# gctf
gctf="/usr/local/software/bin/gctf-v1.06"
showplot=y
gpu="0:0:1:1"

# gautomatch
file="*.mrc"	#File suffix and extension gautomatch will use
pickd=180

# 2D
run2d=n			#Set to y to run 2D averaging
mpiproc2d=12
gpu2d="0:0:1:1:2:2:3:3"
iteration2D=25
particled=220		#In Angstroms
maxsig=5		#No less than 5 for 2D, no less than 200 for 3D
minpart=20000 #Minimum particle number to have before proceeding with 2D averaging

#################################################################################

## Optional user variables, otherwise calculated

bg_radius=$(echo "scale=0; $extract_bin /2 * 0.75" | bc)

## Setup

mkdir -p Relion/Micrographs
mkdir -p Relion/CtfFind/Realtime/Micrographs
mkdir -p Relion/AutoPick/Realtime/Micrographs

## Main processing loop

cd Relion

while true ; do

  #Link up new micrographs
  printf "\nLinking new micrographs...\n"
  cd Micrographs
  ln -sf ../../cor2/${ext} .
  cd ..

  #Make micrographs ctf star file
  printf "\nMaking new micrographs star file, removing old...\n"
  rm -rf micrographs.star
  relion_star_loopheader rlnMicrographName > micrographs.star
  ls Micrographs/$ext >> micrographs.star
  #Print micrograph star file data
  relion_star_info.sh micrographs_all_gctf.star

  #Test if latest micrograph is greater than 20 mins old, suggesting scope problem
  if [ $check == "y" ]; then
    latest=$(ls Micrographs/*.mrc | tail -n 1)
    if [[ $(find ${latest} -mmin +20 -print) ]]; then
      printf "\n${latest}\nis older than 20 minutes\n"
      echo "Latest micrograph is >20 mins old! Suggest to check scope/focus" | mail -s "Krios problem? - automated message" kylelmorris@berkeley.edu
      #echo "Latest micrograph is >20 mins old! Suggest to check scope/focus" | mail -s "Krios problem? - automated message" dtoso@berkeley.edu
      exit
    else
      printf "\n${latest}\nis younger than 20 minutes, very good, continuing...\n"
    fi
  else
    echo "Not checking latest micrograph age, edit script if you want this checked."
  fi

  #Run gctf within relion
  #printf "\nRunning gctf with phase estimation using Relion\n"
  #mpirun -n 4 `which relion_run_ctffind_mpi` --i micrographs.star --o CtfFind/Realtime --CS 2.6 --HT 300 --AmpCnst 0.1 --XMAG 10000 --DStep $angpix --Box 512 --ResMin 30 --ResMax 2.3 --dFMin 3000 --dFMax 10000 --FStep 500 --dAst 100 --do_phaseshift  --phase_min 0 --phase_max 180 --phase_step 10 --use_gctf --gctf_exe $gctf --angpix $angpix --EPA --gpu "" --extra_gctf_options " --resH 2.3 --resL 15 --phase_shift_L 0.0 --phase_shift_H 180.0 --phase_shift_S 10 --phase_shift_T 1  " --only_do_unfinished > relion_run_ctffind.log
  #scp -r CtfFind/Realtime/micrographs_ctf.star micrographs_all_gctf.star

  #printf "\nRunning gctf with phase estimation as standalone\n"
  #cd CtfFind/Realtime/Micrographs
  #ln -sf ../../../Micrographs/*mrc .
  #cd ../../../
  #gctf-v1.06 --apix 0.893 --ac 0.1  --kV 300 --Cs 2.6 --phase_shift_L 0 --phase_shift_H 180 --phase_shift_T 2 --gid 0:1:2:3 --do_unfinished CtfFind/Realtime/Micrographs/*.mrc
  #gctf-v1.18 --apix 0.893 --ac 0.1  --kV 300 --Cs 2.6 --phase_shift_L 0 --phase_shift_H 180 --phase_shift_T 2 --gid 0 --do_EPA 1 --bfac 300 --do_validation 1 CtfFind/Realtime/Micrographs/*.mrc
  #scp -r CtfFind/Realtime/micrographs_ctf.star micrographs_all_gctf.star

  printf "\nRunning CTFFIND4 with phase estimation within Relion\n"
  `which relion_run_ctffind` --i Import/job001/micrographs.star --o CtfFind/job003/ --CS 2.6 --HT 300 --AmpCnst 0.1 --XMAG 10000 --DStep 0.893 --Box 512 --ResMin 30 --ResMax 5 --dFMin 1000 --dFMax 10000 --FStep 500 --dAst 100 --do_phaseshift  --phase_min 0 --phase_max 180 --phase_step 10 --ctffind_exe /usr/local/software/bin/ctffind4 --ctfWin -1 --is_ctffind4

  #plot phase evolution
  if [[ $showplot == "y" ]]; then
    killall eog
    relion_star_plot_metrics.sh micrographs_all_gctf.star
    eog relion_star_plot_all_data.png &
  else
    echo "Skipping phase plot display"
  fi

  #Gather defocus information
  #relion_star_printtable micrographs_all_gctf.star data_ _rlnDefocusU _rlnDefocusV _rlnPhaseShift > defocus.dat

  #Do autopicking with gautomatch
  cd AutoPick/Realtime/Micrographs
  ln -sf ../../../Micrographs/*.mrc .
  cd ../../..
  printf "\ngautomatch picking...\n"
  gautomatch --apixM $angpix --diameter $pickd --speed 2 --lp 35 --min_dist 150 AutoPick/Realtime/Micrographs/${file} --do_unfinished > gautomatch.log

  #Link automatch files into Micrograph directory
  cd Micrographs
  ln -sf ../AutoPick/Realtime/Micrographs/*automatch.star .
  cd ..
  #Link automatch files into CtfFind directory
  cd CtfFind/Realtime/Micrographs
  ln -sf ../../../AutoPick/Realtime/Micrographs/*automatch.star .
  cd ../../..
  #rsync automatch files into ManualPick directory for any manual editing
  mkdir -p ManualPick/Realtime/Micrographs
  cd ManualPick/Realtime/Micrographs
  rsync -aP ../../../AutoPick/Realtime/Micrographs/*automatch.star . > .automatch_rsync.log
  cd ../../..
  printf "\nCopied *automatch coordinates into ManualPick directory for inspection/editing\n"

  #Extract particles within Relion
  printf "\nRemoving old particles.star and extracting any new particles using Relion\n"
  rm -rf particles.star
  mpirun -n $mpiproc `which relion_preprocess_mpi` --i CtfFind/Realtime/micrographs_ctf.star --coord_dir . --coord_suffix _automatch.star --part_star ./particles.star --part_dir Extract/Realtime --extract --extract_size $extract_size --scale $extract_bin --norm --bg_radius $bg_radius --white_dust -1 --black_dust -1 --invert_contrast --only_extract_unfinished > relion_preprocess.log

  if [ -e particles.star ]; then
    printf "\nParticles.star exists, continuing...\n"
  else
    printf "\nSomething is wrong, particle extraction appears to have failed\n"
    exit
  fi

  #Particle count
  ptclno=$(relion_star_info.sh particles.star | grep "data lines" | awk {'print $8'})
  printf "\nParticle number is: $ptclno \n"
  classno=$(echo "scale=0; ${ptclno} / 500" | bc)
  printf "\nNumber of classes required for approx 500 ptcls per class: $classno \n"
  printf ""
  if [ $classno -gt 255 ] ; then

    classno=256
    printf "\nExceeded max allowed classes, defaulting to class: $classno \n"

  fi

  #Print particle star file data
  relion_star_info.sh particles.star

  #2D average particles within Relion
  if [ $run2d == "y" ] ; then

    mkdir -p Class2D/Realtime
    printf "\n2D averaging proceeding using Relion\n"

      if [ $ptclno -gt $minpart ] ; then
        printf "\nMinimum particle number reached, running 2D averaging...\n"
        #mpirun -n $mpiproc `which relion_refine_mpi` --o ./Class2D/Realtime/run --i ./particles.star --dont_combine_weights_via_disc --pool 3 --ctf  --iter $iteration2D --tau2_fudge 2 --particle_diameter $particled --K $classno --flatten_solvent --zero_mask --strict_highres_exp 15 --oversampling 1 --psi_step 12 --offset_range 5 --offset_step 2 --norm --scale  --j 1 --gpu "${gpu2d}"

        mpirun -n $mpiproc `which relion_refine_mpi` --o ./Class2D/Realtime/run --i ./particles.star --dont_combine_weights_via_disc --pool 3 --ctf  --iter $iteration2D --write_subsets 1 --subset_size 10000 --max_subsets 3 --maxsig $maxsig --tau2_fudge 2 --particle_diameter $particled --K $classno --flatten_solvent  --zero_mask --oversampling 1 --psi_step 12 --offset_range 5 --offset_step 2 --norm --scale --dont_check_norm --j 1 --gpu "${gpu2d}" #--strict_highres_exp 15
      else
        printf "\nNot running 2D averaging, minimum particle number not reached\n"
      fi

  else

    printf "\nNot running 2D averaging, edit script if you want to run\n"

  fi

  printf "\nSleeping for 2 sec before next iteration of post-processing...\n"
  sleep 2

done
