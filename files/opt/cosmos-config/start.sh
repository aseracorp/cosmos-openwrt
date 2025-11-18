#!/bin/bash

#set LED's to normal mode, startup
cd /opt/cosmos-config && ./init.sh

#start cosmos & set LED's to normal mode, normal operation
cd /opt/cosmos && ./start.sh