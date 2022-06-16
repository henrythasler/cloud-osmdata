#! /bin/bash

# install stuff
yum update -y > /startup.log
yum install dstat htop -y >> /startup.log
amazon-linux-extras install docker >> /startup.log
systemctl enable docker >> /startup.log
systemctl start docker >> /startup.log
usermod -a -G docker ec2-user >> /startup.log

# ATTENTION: bash variables syntax collide with terraform template variables. So bash variables have to be 'escaped' with '$$'

# setup swapfile
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

# mount EBS
volume="$(file -s ${device_name} | awk -F'[`|'\'']' '{print $2}')"  # get volume name from device
filesystem="$(file -s /dev/$${volume} | awk -F': ' '{print $2}')"  # check filesystem content

# create new filesystem if empty
if [ $${filesystem} == "data" ]
then
    mkfs -t xfs /dev/$${volume} >> /startup.log
fi
mkdir -p ${pgdata}

# setup automount on startup
cp /etc/fstab /etc/fstab.orig
# FIXME: replace ["|"] with something more strict
blkid="$(blkid | grep /dev/$${volume} | awk -F'["|"]' '{print $2}')" # extract blkid
echo "UUID=$${blkid}  ${pgdata} xfs defaults,nofail 0 2" >> /etc/fstab
mount -a

# grow data-filesystem to maximum available space
xfs_growfs ${pgdata} >> /startup.log

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

cat << 'EOF' > /opt/metrics.sh
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
EOF
chmod +x /opt/metrics.sh

# run metrics cron-job every minute
echo '0-59 * * * * /opt/metrics.sh' >> /var/spool/cron/root

# add another cron-job to monitor instance termination; in this case, a message is sent to a SNS topic
# ATTENTION: curl variable syntax also collides with terraform template variables. % have to be 'escaped' with '%%' 
cat << 'EOF' > /opt/watchdog.sh
#! /bin/bash

# check if the endpoint is available
response_code=$(curl --write-out "%%{http_code}\n" http://169.254.169.254/latest/meta-data/spot/instance-action --output /dev/null --silent)

# the endpoint is available, so something happened. Whatever it is, we send it out.
if (( $response_code == 200 )); then
    instance_action=$(curl http://169.254.169.254/latest/meta-data/spot/instance-action)
    aws sns publish --region ${region} --topic-arn ${watchdog_topic} --subject postgis-status --message $${instance_action}
fi
EOF
chmod +x /opt/watchdog.sh

# run watchdog cron-job every minute
echo '0-59 * * * * /opt/watchdog.sh' >> /var/spool/cron/root

service cron reload >> /startup.log
