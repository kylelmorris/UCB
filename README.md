# UCB

Scripts useful to specific processes at UC Berkeley

## Features

#### Realtime motion correction, particle picking, whole micrograph and per particle ctf estimation 

#### Realtime output to the console and additional log files per movie stack with all the stats you need

#### No complicated installation
If motioncor2, gctf and gautomatch are locally installed then you’re set
#### No fuss
If you don’t enter options for a program then it will simply be skipped
#### Familiar set up
When asked, you enter options for the programs just as you would for standard command line execution
#### Your preprocessing progress is remembered
Stop and start the script and preprocessing will continue right where it left off
#### Your settings are remembered
Stop and start the script and you can continue to without having to re-enter your program options

## Set up
### k2_realtime_preprocess.sh & k2_realtime_data_transfer.sh

k2_realtime_preprocess.sh:
lines 42-44 need to be updated to reflect your local environment.

k2_realtime_data_transfer.sh:
set up ssh-keys from your local machine to the remote host before using

## Requirements

Tested with the following:
gctf-v1.06
gautomatch-v0.50
motioncor2-01-30-2017
