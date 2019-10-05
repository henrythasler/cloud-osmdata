#! /bin/bash

#  REMOVE BEFORE FLIGHT  #
device_name="/dev/sdc"   #
region="eu-central-1"    #
project="postgis-server" #
##########################

cpu_usage_percent=$({ head -n1 /proc/stat;sleep 1;head -n1 /proc/stat; } | awk '/^cpu /{u=$2-u;s=$4-s;i=$5-i;w=$6-w}END{print int(0.5+100*(u+s+w)/(u+s+i+w))}')
pgdata_free_storage_space=$(df --block-size=1 --output=avail ${device_name} | tail -n 1 | grep -o "[0-9]\+")
root_free_storage_space=$(df --block-size=1 --output=avail /dev/$(mount | sed -n "s|^/dev/\(.*\) on / .*|\1|p") | tail -n 1 | grep -o "[0-9]\+")

aws cloudwatch put-metric-data --region ${region} --dimensions Devices=${device_name} --metric-name FreeStorageSpace --namespace ${project} --value ${pgdata_free_storage_space} --unit Bytes --timestamp $(date -u +"\%Y-\%m-\%dT\%H:\%M:\%SZ")
aws cloudwatch put-metric-data --region ${region} --dimensions Volumes=$(mount | sed -n "s|^/dev/\(.*\) on / .*|\1|p") --metric-name FreeStorageSpace --namespace ${project} --value ${root_free_storage_space} --unit Bytes --timestamp $(date -u +"\%Y-\%m-\%dT\%H:\%M:\%SZ")
aws cloudwatch put-metric-data --region ${region} --dimensions CPU=overall --metric-name CPUUtilization --namespace ${project} --value ${cpu_usage_percent} --unit Percent --timestamp $(date -u +"\%Y-\%m-\%dT\%H:\%M:\%SZ")


printf "CPU-Load=${cpu_usage_percent}%%\n"
printf "pgdata_free_storage_space=${pgdata_free_storage_space} Bytes\n"
printf "root_free_storage_space=${root_free_storage_space} Bytes\n"
