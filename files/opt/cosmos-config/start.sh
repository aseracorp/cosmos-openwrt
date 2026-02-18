#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>&1 2>&1
# Everything below will go to logread:



#set LED's to normal mode, startup
cd /opt/cosmos-config && ./init.sh

#start cosmos & set LED's to normal mode, normal operation
cd /opt/cosmos && ./start.sh