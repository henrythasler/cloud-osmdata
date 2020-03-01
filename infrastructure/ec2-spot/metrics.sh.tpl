#! /bin/bash
cpu_usage_percent=$({ head -n1 /proc/stat;sleep 1;head -n1 /proc/stat; } | awk '/^cpu /{u=$2-u;s=$4-s;i=$5-i;w=$6-w}END{print 100*(u+s+w)/(u+s+i+w)}')
pgdata_free_storage_space=$(df --block-size=1 --output=avail ${device_name} | tail -n 1 | grep -o "[0-9]\+")
root_free_storage_space=$(df --block-size=1 --output=avail /dev/$(mount | sed -n "s|^/dev/\(.*\) on / .*|\1|p") | tail -n 1 | grep -o "[0-9]\+")
mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')

aws cloudwatch put-metric-data --region ${region} --dimensions Devices=${device_name} --metric-name FreeStorageSpace --namespace ${project} --value $${pgdata_free_storage_space} --unit Bytes --timestamp $(date -u +"%Y-%m-%dT%H:%M:%SZ")
aws cloudwatch put-metric-data --region ${region} --dimensions Volumes=$(mount | sed -n "s|^/dev/\(.*\) on / .*|\1|p") --metric-name FreeStorageSpace --namespace ${project} --value $${root_free_storage_space} --unit Bytes --timestamp $(date -u +"%Y-%m-%dT%H:%M:%SZ")
aws cloudwatch put-metric-data --region ${region} --dimensions CPU=overall --metric-name CPUUtilization --namespace ${project} --value $${cpu_usage_percent} --unit Percent --timestamp $(date -u +"%Y-%m-%dT%H:%M:%SZ")
aws cloudwatch put-metric-data --region ${region} --dimensions Memory=meminfo --metric-name MemFree --namespace ${project} --value $${mem_free} --unit Kilobytes --timestamp $(date -u +"%Y-%m-%dT%H:%M:%SZ")
aws cloudwatch put-metric-data --region ${region} --dimensions Memory=meminfo --metric-name MemTotal --namespace ${project} --value $${mem_total} --unit Kilobytes --timestamp $(date -u +"%Y-%m-%dT%H:%M:%SZ")
aws cloudwatch put-metric-data --region ${region} --dimensions Memory=meminfo --metric-name MemAvailable --namespace ${project} --value $${mem_avail} --unit Kilobytes --timestamp $(date -u +"%Y-%m-%dT%H:%M:%SZ")
