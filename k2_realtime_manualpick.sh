#!/bin/sh

mkdir -p ManualPick/Realtime/Micrographs

relion_manualpick  --i CtfFind/Realtime/micrographs_ctf.star --pickname automatch --odir ManualPick/Realtime/ --angpix 1.146 --scale 0.25 --lowpass -1 --sigma_contrast 3 --black 0 --white 0 --lowpass 20 --ctf_scale 1  --particle_diameter 300 --allow_save &
