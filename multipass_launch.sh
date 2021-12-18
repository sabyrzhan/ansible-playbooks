#!/bin/bash
multipass launch --name master -c 2 -m 2G --cloud-init ./cloud-init.yml &> /dev/null &
for i in {1..3}
do
 multipass launch --name node$i -c 2 -m 2G --cloud-init ./cloud-init.yml &> /dev/null &
done