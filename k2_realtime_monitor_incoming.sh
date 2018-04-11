#!/bin/bash
#

# Written by Kyle Morris, Hurley lab, 2018
# University of California, Berkeley

ext=$1
time=$2
email=$3
dir=$4
sleep=30

if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then

  echo ""
  echo "Variables empty, usage is $(basename ${0}) (1) (2) (3)"
  echo ""
  echo "(1) = File extension to monitor (i.e. tif, mrc, DW.mrc)"
  echo "(2) = Time (mins, if last file older than this, flag up a problem)"
  echo "(3) = Email notification address"
  echo "(4) = Directory to monitor (optional, default = current directory)"
  echo ""
  echo "This script assumes that incoming files are labelled in numerical sequential order"
  exit

fi

if [[ -z $dir ]] ; then
  dir=$(pwd)
else
  dir=$4
fi

echo ""
echo "$(basename ${0}) will monitor for incoming files with extension *${ext}"
echo "Notification will be sent to ${email}"
echo "If the incoming files are older than ${time} mins"
echo ""
echo "Directory: ${dir}"
echo ""
echo "This script assumes that incoming files are labelled in numerical sequential order"
echo ""
echo "Press Enter to continue or ctrl+c to quit..."
read p

i=0

while [[ $i == 0 ]] ; do

  #Test if latest micrograph is greater than 20 mins old, suggesting scope problem
  latest=$(ls ${dir}/*${ext} | tail -n 1)

    #Check file age is < user defined time
    if [[ $(find ${latest} -mmin +${time} -print) ]]; then
      printf "\nCurrent file: ${latest}\n\
      is older than ${time} minutes suggesting problem with scope/focus/transfer\n"
      printf "\nExiting and sending email alert to: ${email}\n\n"
      #Send email
      echo "Latest micrograph ${latest} is >${time} mins old! Suggest to check scope/focus" | \
      mail -s "Krios problem? - automated message" ${email}
      exit
    else
      printf "\nCurrent file: ${latest}\n\
      File was written in the last ${time} minutes, very good, continuing.\n\
      Script will check again in ${sleep} seconds...\n"
    fi

# Take a break for 30 seconds, you earnt it
sleep $sleep

done
