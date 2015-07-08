#! /bin/sh
# Copyright (c) 2011-2015 by Vertica, an HP Company.  All rights reserved.
# Creates backup configuration from template for a full Hard Link Local backup

configFile="./backupConfig.ini"

function show_help {
   echo "$0"
   exit 0
}

user=""
pwd=""
while getopts "h?" opt; do
   case "$opt" in
   h|\?)
      show_help
      exit 0
      ;;
   esac
done

if [ -f $configFile ]; then
   echo "Backup configuraton file $configFile not found! Please run mkBackupConfig.sh."
   exit 1
fi

vbr.py --task backup --config-file ./backupConfig.ini

