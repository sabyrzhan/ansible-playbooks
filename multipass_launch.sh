#!/bin/bash
multipass launch --name master -c 2 -m 2G --cloud-init ./cloud-init.yml &> /dev/null &
echo 'Launched master!'
for i in {1..5}
do
 multipass launch --name node$i -c 2 -m 2G --cloud-init ./cloud-init.yml &> /dev/null &
 echo "Lanched node$i"
done