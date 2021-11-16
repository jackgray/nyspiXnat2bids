#!/bin/env bash

# USAGE: nii2bids.sh <project ID> <exam no.>

# bash ./get_user_info.sh 


# UNIVERSAL SERVICE SETUP
#.........................................
project_id=$1
single_exam_no=$2
project_path=/MRI_DATA/nyspi/${project_id}

# UID/GID setup for permissions handling
# Pull group ID from project_id (working_gid)
groupinfo=$(getent group ${project_id})
while IFS=$':' read -r -a tmp ; do
working_gid="${tmp[2]}"
userinfo="${tmp[3]}"
done <<< $groupinfo
username=$(whoami)
working_uid="$(id -u ${username})"
echo primary gid for ${project_id}: $working_gid
echo your uid: $working_uid

image_name=jackgray/nifti2bids:amd64latest
service_name=${project_id}_bidsprep_nii2bids_${single_exam_no}_${username}
#.........................................


######### MOUNT PATH DEFS #################################
bidsonlypath_doctor=${project_path}/derivatives/bidsonly 
bidsonlypath_container=/bidsonly 
rawdata_path_doctor=${project_path}/rawdata 
rawdata_path_container=/rawdata 
token_path_doctor=${project_path}/.tokens
token_path_container=/tokens
private_path_doctor=/MRI_DATA/.xnat/xnat2bids_private.pem
private_path_container=/xnat/xnat2bids_private.pem
###########################################################

docker service rm ${service_name}
docker pull ${image_name}

# NII2BIDS SERVICE
docker service create \
--detach \
-e project_id=${project_id} \
-e single_exam_no=${single_exam_no} \
-e working_gid=${working_gid} \
-e working_uid=${working_uid} \
--replicas 1 \
--reserve-memory 12GB \
--reserve-cpu 1 \
--mode replicated \
--restart-condition none \
--name=${service_name} \
--mount type=bind,source=${rawdata_path_doctor},destination=${rawdata_path_container} \
--mount type=bind,source=${bidsonlypath_doctor},destination=${bidsonlypath_container} \
--mount type=bind,source=${token_path_doctor},destination=${token_path_container},readonly=true \
--mount type=bind,source=${private_path_doctor},destination=${private_path_container},readonly=true \
${image_name};