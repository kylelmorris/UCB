#!/bin/bash
#

echo "Constant realtime transfer from Bacem server to local directory"
echo ""
echo "Please enter the server and remote directory (i.e. ftpuser5@169.229.244.80:/home/ftpuser5/Kyle/17Apr05/Frames/*)"
echo "Examples:"
echo "ftpuser5@169.229.244.80:/home/ftpuser5/Kyle/17Apr05/Frames/*"
echo "--rsh='ssh -p 1919' kmorris@epeius.qb3.berkeley.edu:/media/kmorris/KLM_8TB_ext4/Krios/17Feb24/Frames/*"
read remote
echo ""
echo "Please enter the local directory (i.e. .)"
read localdir
echo ""
echo "Remote directory: ${remote}"
echo "Local directory: ${local}"
echo ""
echo "Command will be:"
echo ""
echo "rsync -aP $remote $localdir"
echo ""
echo "Press Enter to continue, ctrl-c to quit"
read p

i="0"

while [ $i == 0 ] ; do
  command=$(echo "rsync -aP ${remote} ${localdir}")
  eval $command
done
