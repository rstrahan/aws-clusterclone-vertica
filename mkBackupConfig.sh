#! /bin/sh
# Copyright (c) 2011-2015 by Vertica, an HP Company.  All rights reserved.
# Creates backup configuration from template for a full Hard Link Local backup

# defaults
configFile="./backupConfig.ini"
pwdFile="./backupPasswd.ini"
user=$(whoami)
userArg="-U $user"
pwd="none"
pwdArg="-w $pwd"

function show_help {
   echo "$0 [-U dbUser] [-w dbPassword]"
   exit 0
}

while getopts "h?U:u:w:P:p:" opt; do
   case "$opt" in
   h|\?)
      show_help
      exit 0
      ;;
   U|u)
      user="$OPTARG"
      userArg="-U $OPTARG"
      ;;
   P|p|w)
      pwd="$OPTARG"
      pwdArg="-w $OPTARG"
      ;;
   esac
done

# Discover active database name
db=$(admintools -t show_active_db)
if [ -z "$db" ]; then
   echo "No database running. Please start database, and try again."
   exit 1
else
   echo "Active database: $db"
fi

# create backup config file for full database hardlink local backup
cat <<EOF > $configFile
[Misc]
snapshotName = backup_snapshot
restorePointLimit = 1
passwordFile = $pwdFile

[Database]
dbName = $db
dbUser = $user

[Transmission]
hardLinkLocal = True

[Mapping]
EOF
# Append backup config for each node, of the form:
# v_vmart_node0001 = 10.0.10.149:/vertica/data
vsql $userArg $pwdArg -qAt -c "select node_name || ' = ' || node_address || ':/vertica/data' from nodes" >> backupConfig.ini
[ $? == 0 ] || exit 1

# create password file, and restrict to owner rw
cat <<EOF > $pwdFile
[Passwords]
dbPassword = $pwd
EOF
chmod 600 $pwdFile

echo "Backup Config file created: $configFile"


