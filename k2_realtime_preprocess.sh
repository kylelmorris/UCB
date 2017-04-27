#!/bin/bash
#
#
############################################################################
#
# Author: "Kyle L. Morris"
# University of California Berkeley 2017
#
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
############################################################################

# TO DO #

# 1 - make file listing more robust
# 2 - See make_gctf_mic_star.com for making star file at end
# 3 - local ctf estimation???
#
#

############################################################################

#colors for echo
#echo -e "\e[92m test \e[0"  #green
#echo -e "\e[91m test \e[0"  #red
#echo -e "\e[0mm test \e[0"  #yellow

#http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

#User variables, change to suit your system
motioncor2exe=motioncor2
gctfexe=gctf-v1.06
gautoexe=gautomatch

#Clean up and make new queue and processed files
rm -rf .queue.dat
echo '' > .queue.dat
rm -rf .tmp.dat
rm -rf .processed.dat
echo '' > .processed.dat

#Useful information
echo ""
echo "##########################################################################"
echo -e "\033[1;34mRealtime preprocessing script for K2 data from Bacem Titan Krios\033[m"
echo -e "\033[1;34mAuthor: Kyle L Morris @ Hurley lab, UC Berkeley\033[m"
echo "##########################################################################"
echo -e "\033[1;37m"
echo "This script will look for new movies in the current working directory (cwd)."
echo "To avoid unexpected behaviour, ensure the cwd contains only incoming k2 movies."
echo ""
echo "When identified, preprocessing will be performed on them."
echo ""
echo "Preprocessing currently includes: motioncor2, gctf, gautomatch"
echo "*** realtime 2D averaging in development ***"
echo -e "\033[m"
echo "Notes:"
echo "This script can be stopped and restarted at any point, preprocessing will resume from where it left off."
echo "Movies are marked as 'processed' by presence of *_preprocess.log,"
echo "but you may also find the summary information in this log useful for micrograph screening."
echo ""
echo "Dependancies:"
echo "motioncor2, gctf-v1.06, gautomatch, Relion-2.0"
echo ""
echo "##########################################################################"
echo ""
echo 'Press Enter to continue...'
read p

#Look for previous settings and ask whether to sue these
if [[ -e .sniffsettings ]] ; then
  echo 'Previous settings found in current working directory...'
  echo ''
  cat .sniffsettings
  echo ''
  echo 'Would you like to use the previous settings? (y/n)'
  read p
  if [[ $p == y ]] ; then
    readsettings=1
  elif [[ $p == n ]] ; then
    readsettings=0
  else
    echo 'input not recognised, exiting...'
    exit
  fi
else
  echo 'No previous settings found... you should input these next...'
  echo ''
  readsettings=0
fi

#Load previous settings
if [[ $readsettings == 1 ]] ; then
  ext=$(grep ext: .sniffsettings | awk '{print $2}')
  cor2opt=$(grep cor2opt: .sniffsettings | awk '{$1=""}1' | awk '{$1=$1}1')
  gctfopt=$(grep gctfopt: .sniffsettings | awk '{$1=""}1' | awk '{$1=$1}1')
  gautoopt=$(grep gautoopt: .sniffsettings | awk '{$1=""}1' | awk '{$1=$1}1')
  displayopt=$(grep displayopt: .sniffsettings | awk '{$1=""}1' | awk '{$1=$1}1')

#Or ask for new settings
elif [[ $readsettings == 0 ]] ; then
  rm -rf .sniffsettings

  echo "##########################################################################"
  echo "User input..."
  echo "##########################################################################"
  echo ""
  echo "Enter file suffix and extension for new movies (i.e. ".tif", "_frames.tif" or ".mrcs"):"
  echo ''
  read p
  ext=$p
  echo 'ext:     '$p >> .sniffsettings
  echo ''
  echo "##########################################################################"
  echo ''

  echo "Enter your motioncor2 command options:"
  echo "Note that the executable, input, output and log file will be setup for you..."
  echo ''
  echo "Rapid whole frame alignment, 38 frames in ~30 sec on 3 gpu:"
  echo "-FtBin 2.0 -PixSize 0.573 -Bft 150 -kV 300 -FmDose 1.426 -Throw 2 -Gpu 0 1 2 3"
  echo ''
  echo "Thorough patch based alignment for final refinements, 38 frames in ~120 sec on 4 gpus:"
  echo "-FtBin 2.0 -PixSize 0.573 -Bft 150 -kV 300 -FmDose 1.426 -Throw 2 -Patch 5 5 -Iter 10 -Tol 0.5 -Gpu 0 1 2 3"
  echo ''
  read p
  cor2opt=$p
  echo 'cor2opt: '$p >> .sniffsettings
  echo ''
  echo "##########################################################################"
  echo ''

  echo "Enter your gctf command options:"
  echo "Note that the executable, input, output, EPA & validation will be setup for you..."
  echo ''
  echo "Suggested options:"
  echo "--apix 1.145 --kV 300 --Cs 2.6 --ac 0.1 --resH 3"
  echo ''
  read p
  gctfopt=$p
  echo 'gctfopt: '$p >> .sniffsettings
  echo ''
  echo "##########################################################################"
  echo ''

  echo "Enter your gautomatch command options:"
  echo ''
  echo "Suggested options good for a somewhat compact 280 A complex:"
  echo "--apixM 1.145 --diameter 250 --speed 2 --lp 35"
  echo ''
  read p
  gautoopt=$p
  echo 'gautoopt: '$p >> .sniffsettings
  echo ''
  echo "##########################################################################"
  echo ''

  echo "Enter your relion display options:"
  echo "Note that the executable, input, output, coordinates will be setup for you..."
  echo ''
  echo "Suggested options to display micrograph with picked coordinates:"
  echo "--scale 0.25 --angpix 1.145 --lowpass 35"
  echo ''
  read p
  displayopt=$p
  echo 'displayopt: '$p >> .sniffsettings
  echo ''
  echo "##########################################################################"
  echo ''
fi

#Check whether using tif or mrcs input
inext=$(echo $ext | grep tif)
if [ -z $inext ] ; then
  inext=M
fi

inext=$(echo $ext | grep mrc)
if [ -z $inext ] ; then
  inext=T
fi

if [[ $inext == T ]] ; then
  incom='-InTiff'
elif [[ $inext == T ]] ; then
  incom='--InMrc'
fi

echo "##########################################################################"
echo "Completed user input..."
echo "##########################################################################"
echo ''

#Show the user an example command and ask to continue
echo 'Example motioncor2 command will be as follows:'
echo "$ ${motioncor2exe} ${incom} example.${ext} -OutMrc example.mrc ${cor2opt} > example_cor2.log"
echo ''
echo 'Example gctf command will be as follows:'
echo "$ ${gctfexe} ${gctfopt} example.mrc --do_EPA --do_validation > example_gctf.log"
echo ''
echo 'Example gautomatch command will be as follows:'
echo "$ ${gautoexe} ${gautoopt} example.mrc > example_gauto.log"
echo ''
echo 'Example relion_display command will be as follows:'
echo "$ relion_display ${displayopt} --pick --coords example_gautomatch.star --i example.mrc &"
echo ''
echo 'If you are happy with the commands, press Enter to continue...'
read p
echo ''

#Repopulate .processed.dat list for files already worked on, judged by log files
ls *_preprocess.log > .tmp.dat
sed -i 's/_preprocess.log/.tif/g' .tmp.dat
sed -i -e 's/^/.\//' .tmp.dat
mv .tmp.dat .processed.dat

#########################################
####MAIN LOOP to search for new movies
#########################################
while true
do
  clear

  #Start processing timer
  start=$(date +%s)  # start time recorded in seconds

  #Helpful message
  echo -e "\e[92m===============================================================================\e[0m"
  echo 'Realtime K2 preprocessing'
  echo 'Kyle Morris @ Hurley Lab, UCB'
  echo -e "\e[92m===============================================================================\e[0m"
  echo $(date -u)
  echo -e "\e[92m===============================================================================\e[0m"
  echo "Monitoring for new movies..."
  echo ''
  echo 'Looking for *suffix.ext:   '$ext

  ##########################################################
  # TO DO: THIS NEEDS IMPROVING, SOMETIMES FILES ORDER IS WEIRD
  ##########################################################
  #Search for files
  ls ./*${ext} > .tmp.dat
  #Compare to .processed list to remove files already processed
  #awk 'NR==FNR{a[$0];next} !($0 in a)' .processed.dat .tmp.dat > .queue.dat
  comm -2 -3 <(sort .tmp.dat) <(sort .processed.dat) > .queue.dat

  #Queue statistics
  queueno=$(wc -l .queue.dat | awk '{print $1}')
  processedno=$(wc -l .processed.dat | awk '{print $1}')
  echo 'Number of files in queue:  '$queueno
  echo 'Number of files processed: '$processedno
  #echo 'To check gctf estimation values, in a new terminal run:'
  #echo 'grep -e Final -e "Resolution limit" *gctf.log'
  #echo ''
  echo -e "\e[92m===============================================================\e[0m"
  echo "Previous file:               ${name}"
  echo -e "\e[92m===============================================================\e[0m"
  echo "Defocus estimation:          ${defocus}"
  echo "Defocus res limit est:       ${reslimit}"
  echo "Defocus validation:"
  echo $ctfvalidation
  echo ''
  echo "Particles picked:            ${ptclno}"
  echo ""
  echo "Processing time was (total): ${runtime} (seconds)"
  echo ''
  ptcltot=$(wc -l *automatch.star | tail -n 1 | awk '{print $1}')
  echo "Particles picked, total:     ${ptcltot}"

  #Work on oldest file in queue and check off on done list
  file=$(sed -n 1p .queue.dat)
  name=${file%.*}
  #Such file name, many wow
  newfile=$name'_cor2.mrc'
  ctffile=$name'_cor2.ctf'
  micjpg=$name'_cor2.jpeg'
  ctfjpg=$name'_cor2_ctf.jpeg'
  cor2log=$name'_cor2.log'
  gctflog=$name'_cor2_gctf.log'
  gautolog=$name'_cor2_gauto.log'
  gautostar=$name'_cor2_automatch.star'
  preprocesslog=$name'_preprocess.log'

  echo -e "\e[92m===============================================================================\e[0m"
  echo 'Working on file:' ${file}
  echo -e "\e[92m===============================================================================\e[0m"

  if [[ -z $file ]] ; then
    echo 'Nothing in queue to work on...'
    echo ''
    sleep 2
  else
    #loop to check if file size is changing before processing
    while true ; do
      echo "File size stability check:"
      fsz1=$(ls -an ${file} | awk '{print $5}')
      echo $fsz1" K @ 0.33 sec"
      sleep 0.333
      fsz2=$(ls -an ${file} | awk '{print $5}')
      echo $fsz2" K @ 0.66 sec"
      sleep 0.333
      fsz3=$(ls -an ${file} | awk '{print $5}')
      echo $fsz3" K @ 1.00 sec"
      sleep 0.333
      if [[ ($fsz1 == $fsz2) && ($fsz2 == $fsz3) && ($fsz1 == $fsz3) ]]; then
        echo 'File size appears stable, very good, proceeding to process...'
        break
      else
        echo 'File size is changing, patiently assumung it is still being written to disk'
      fi
    done
    echo -e "\e[92m===============================================================================\e[0m"

    #rsync file transfer with rename
    #rsync -aP ${file} ${dir2}/${newfile}

    #Run motioncor2
    echo ''
    echo 'Running motioncor2...'
    echo ''
    echo "$ ""${motioncor2exe} ${incom} ${file} -OutMrc ${newfile} ${cor2opt} > $cor2log"
    echo ''
    echo "Output is redirected to the log file ${cor2log}"
    echo ''
    echo "Be patient, or check the log file with following command if you must...."
    echo ''
    echo "$ tail -f ${cor2log}"
    echo ''

    ${motioncor2exe} ${incom} ${file} -OutMrc ${newfile} ${cor2opt} > $cor2log

    echo -e "\e[92m===============================================================\e[0m"
    echo 'Done processing with motioncor2...'
    echo -e "\e[92m===============================================================\e[0m"
    grep -A 5 'Create aligned sum based upon full frame alignment.' $cor2log
    echo ''
    echo 'Creating quick look jpeg using imod mrc2tif...'

    #Uses imod mrc2tif package for quick look jpg
    mrc2tif -j ${newfile} ${micjpg}

    echo -e "\e[92m===============================================================\e[0m"
    echo ''
    #echo 'Taking a breather for 2 seconds...'
    #echo ''
    #sleep 2

    #Run gctf
    echo -e "\e[92m===============================================================\e[0m"
    echo 'Working on file:' ${newfile}
    echo -e "\e[92m===============================================================\e[0m"

    echo ''
    echo 'Running gctf-v0.50...'
    echo ''
    echo "$ ""${gctfexe} ${gctfopt} ${newfile} --do_EPA --do_validation > gctf.log"
    echo ''

    ${gctfexe} ${gctfopt} ${newfile} --do_EPA --do_validation > gctf.log

    #Kill display for next round
    killall relion_display

    echo -e "\e[92m===============================================================\e[0m"
    echo 'Done processing with gctf...'
    echo -e "\e[92m===============================================================\e[0m"
    echo ''
    #Report and store values
    echo 'Final ctf values:'
    grep -e Final gctf.log
    defocus=$(grep -e Final gctf.log | awk '{print $1,$2,$3}')
    grep -e 'Resolution limit' gctf.log
    reslimit=$(grep -e 'Resolution limit' gctf.log | awk '{print $7}')
    grep -A 6 'Differences from Original Values' gctf.log
    ctfvalidation=$(grep -A 6 'Differences from Original Values' gctf.log | tail -n 5 | awk '{print $1,$6}')
    echo 'Creating quick look jpeg using imod mrc2tif...'

    #Uses imod mrc2tif package for quick look jpg
    mrc2tif -j ${ctffile} ${ctfjpg}

    echo -e "\e[92m===============================================================\e[0m"
    echo ''
    #echo 'Taking a breather for 2 seconds...'
    #echo ''
    #sleep 2

    #Run gautomatch
    echo ''
    echo 'Running gautomatch...'
    echo ''
    echo "$ ""${gautoexe} ${gautoopt} ${newfile} > ${gautolog}"
    echo ''

    ${gautoexe} ${gautoopt} ${newfile} > ${gautolog}

    echo -e "\e[92m===============================================================\e[0m"
    echo 'Done processing with gautomatch...'
    echo -e "\e[92m===============================================================\e[0m"
    echo ''
    #Report and store values
    echo '# of gautomatch particle picks:'
    ptclno=$(wc -l $gautostar | awk '{print $1}')
    echo $ptclno
    echo ''

    if [[ -z $displayopt ]] ; then
      echo ""
      echo "Not displaying output sum and ctf..."
      echo ""
    else
      #Display micrograph and particle picks with relion display
      echo ''
      echo 'Displaying micrograph and particle picks using Relion-2.0...'
      echo ''
      echo "$ ""relion_display ${displayopt} --pick --coords ${gautostar} --i ${newfile} &"
      echo ''

      #### TO DO: THIS NEEDS PROCESSID CAPTURED SO CAN BE CLOSED FOR NEXT ROUND ####
      relion_display ${displayopt} --pick --coords  --i ${newfile} &

      ctfmrc=${ctffile%.*}"_ctf.mrc"
      ln -s ${ctffile} ${ctfmrc}
      echo ''
      echo "$ ""relion_display --i ${ctfmrc} --scale 0.5 &"
      echo ''
      relion_display --i ${ctfmrc} --scale 0.5 &
    fi

    echo -e "\e[92m===============================================================\e[0m"
    echo 'Done processing with gautomatch...'
    echo -e "\e[92m===============================================================\e[0m"
    echo ''

    #Mark file in .processed.dat as processed
    echo ${file} >> .processed.dat
    #Write summary log
    echo ${newfile} >> $preprocesslog
    echo ${defocus} >> $preprocesslog
    echo ${reslimit} >> $preprocesslog
    echo ${ctfvalidation} >> $preprocesslog
    echo ${ptclno} >> $preprocesslog
    echo "${runtime} (seconds)" >> $preprocesslog

    #Reset file name variable
    file=$(echo '')

    #End processing timer
    end=$(date +%s)  # end time recorded in seconds

    #Processing time report
    runtime=$((end-start))
    echo "Processing time was: ${runtime} (seconds)"
    echo ''

  fi
  clear
done
