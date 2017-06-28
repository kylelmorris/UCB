# UCB real-time image processing

Scripts useful to EM related processes at UC Berkeley

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
Stop and start the script and you can continue without having to re-enter your program options

## Notes

36 frame movies from a K2 in superresolution counting can be completely processed^^ in approximately 120 seconds using 4x GTX 1070.

^^ including full frame and 5x5 patch alignement, particle picking, full frame and per particle ctf estimation without using relion_display at each preprocessing iteration.

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
