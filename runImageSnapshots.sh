#! /bin/sh
# Copyright (c) 2011-2015 by Vertica, an HP Company.  All rights reserved.
# Creates backup configuration from template for a full Hard Link Local backup


# defaults
imageFile="./images.conf"
user=$(whoami)
userArg="-U $user"
pwd="none"
pwdArg="-w $pwd"
clusterName=""

function show_help {
   echo "$0 -c clusterName [-U dbUser] [-w dbPassword]"
   echo "	-c clusterName	A name to identify the cluster - used to label the AWS images"
   echo "	-U dbUser	Database username - defaults to OS user ($user)"
   echo "	-w dbPassword	Password for user - defaults to none"
   exit 0
}

while getopts "h?U:u:w:P:p:C:c:" opt; do
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
   C|c)
      clusterName="$OPTARG"
      ;;
   esac
done

# We need a name for the cluster so we can label the images
if [ -z "$clusterName" ]; then
   echo "Please specify a name for the cluster, using the -c clusterName argument"
   exit 1
fi

#initialize image name file
timestamp=$(date +%Y%m%d%H%M)
echo "#Image IDs and names for cluster $clusterName - $timestamp" > $imageFile

# Create Image Snapshot for each cluster node instance
nodes=$(vsql $userArg $pwdArg -qAt -c "select node_address from nodes")
for node in $nodes
do
   node_name=$(vsql $userArg $pwdArg -qAt -c "select node_name from nodes where node_address = '$node'")
   instId=$(ssh $node curl -s http://169.254.169.254/latest/meta-data/instance-id);
   imageName="${clusterName}.${node_name}.${timestamp}"
   echo "$node_name ($node) ($instId) => Creating new backup image: $imageName"
   imageId=$(aws --output=text ec2 create-image --instance-id $instId --no-reboot --name $imageName --description "Cluster backup image: Cluster ($clusterName) Node ($node_name) Timestamp ($timestamp)")
   echo "$imageId $imageName" >> $imageFile
done


