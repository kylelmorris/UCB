#!/bin/bash
#

echo "Constant realtime transfer from Bacem server to local directory"
echo ""
echo "Please enter the server and remote directory (i.e. ftpuser5@169.229.244.80:/home/ftpuser5/Kyle/17Apr05/Frames/*)"
echo "Examples:"
echo "ftpuser5@bacemnet.qb3.berkeley.edu:/home/ftpuser5/path/to/frames/*"
echo "--rsh='ssh -p 1919' kmorris@server.qb3.berkeley.edu:/path/to/frames/*"
echo ""
read remote
echo $remote > .k2_realtime_data_transfer_remote
echo ""
echo "Please enter the local directory (i.e. .)"
echo ""
read localdir
echo $localdir > .k2_realtime_data_transfer_local
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
