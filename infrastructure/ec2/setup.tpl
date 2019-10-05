#! /bin/bash

# install stuff
yum update -y >> /startup.log
yum install dstat htop -y >> /startup.log
amazon-linux-extras install docker >> /startup.log
systemctl enable docker >> /startup.log
systemctl start docker >> /startup.log
usermod -a -G docker ec2-user >> /startup.log

# ATTENTION: bash variables syntax collide with terraform template variables. So bash variables have to be 'escaped' with '$$'

# mount EBS
volume="$(file -s ${device_name} | awk -F'[`|'\'']' '{print $2}')"  # get volume name from device
filesystem="$(file -s /dev/$${volume} | awk -F': ' '{print $2}')"  # check filesystem content
if [ $${filesystem} == "data" ]
then
    mkfs -t xfs /dev/$${volume} >> /startup.log
else 
    #xfs_growfs /pgdata >> /startup.log
fi
mkdir ${pgdata}
mount /dev/$${volume} ${pgdata}

# setup automount on startup
cp /etc/fstab /etc/fstab.orig
# FIXME: replace ["|"] with something more strict
blkid="$(blkid | grep /dev/$${volume} | awk -F'["|"]' '{print $2}')" # extract blkid
echo "UUID=$${blkid}  ${pgdata} xfs defaults,nofail 0 2" >> /etc/fstab

# start postgis container
$(aws ecr get-login --no-include-email --region ${region})
docker pull ${repository_url}:latest >> /startup.log
docker run -d --name ${project} \
    --restart always \
    -e POSTGRES_PASSWORD='${postgres_password}' \
    -e PGDATA=/pgdata \
    -v ${pgdata}:/pgdata \
    -p 5432:5432 \
    ${repository_url}:latest -c 'config_file=/etc/postgresql/postgresql.conf' >> /startup.log

# Cloudwatch metrics for disk usage
# setup crontab
if [ ! -f /var/spool/cron/root ]; then
    touch /var/spool/cron/root
    /usr/bin/crontab /var/spool/cron/root
fi

# run cron-job every minute
# EBS device
echo '0-59 * * * * (aws cloudwatch put-metric-data --region ${region} --dimensions Devices=${device_name} --metric-name FreeStorageSpace --namespace ${project} --value $(df --block-size=1 --output=avail ${device_name} | tail -n 1 | grep -o "[0-9]\+") --unit Bytes --timestamp $(date -u +"\%Y-\%m-\%dT\%H:\%M:\%SZ"))' >> /var/spool/cron/root
# Root Volume
echo '0-59 * * * * (aws cloudwatch put-metric-data --region ${region} --dimensions Volumes=$(mount | sed -n "s|^/dev/\(.*\) on / .*|\1|p") --metric-name FreeStorageSpace --namespace ${project} --value $(df --block-size=1 --output=avail /dev/$(mount | sed -n "s|^/dev/\(.*\) on / .*|\1|p") | tail -n 1 | grep -o "[0-9]\+") --unit Bytes --timestamp $(date -u +"\%Y-\%m-\%dT\%H:\%M:\%SZ"))' >> /var/spool/cron/root
service cron reload >> /startup.log
