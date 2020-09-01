# cloud-osmdata
Generalize and import openstreetmap-data into a postgis-database to create vector tiles with cloud-tileserver.

## Cost Overview

How much does is cost per month, to run the following database-server:

### Specs

Item | size
---|---
vCPU | `2` (2048 cpu units)
RAM | `1024 GB`
Storage | `40GB`
Region | `eu-central-1`
Usage | `100%`
OS | `Linux`
Database | `PostgeSQL`
Backup/Snapshots | `none`

### Monthly costs

Service | cost
---|---
EC2 `(t3a.micro+EBS)` | 11.58€ `(7.23€+4.35€)` 
RDS `(db.t3.micro+EBS)` | 19.06€ `(14.05€+5.01€)`
~~Fargate `(2vCPU, 4GB)`~~ | ~~83.13€ + x~~ (EBS NOT supported)
Aurora onDemand `(db.t3.medium)` | 68.38€
Aurora reserved 1y `(db.t3.medium)` | 52.37€
Aurora serverless `2 ACU, 4GB RAM, 40GB EBS` | 97.65€ `(eu-west-1)`

## Modules

### EC2

Host database on EC2 instance. Import with another EC2 instance.

### RDS (serverless)

Host database on Amazon RDS. Import with AWS Batch.

### localhost

Host local database with docker and docker-compose. Import also with docker containers.

## Ideas

- Aurora serverless

## References

### Linux

- [crontab guru](https://crontab.guru)
- [Common Cron Mistakes](http://www.alleft.com/sysadmin/common-cron-mistakes/)
- [How to expand an (xfs) EBS volume on AWS EC2](https://www.cloudinsidr.com/content/how-to-expand-an-xfs-ebs-volume-on-aws-ec2/)
- [Linux Command To Find the System Configuration And Hardware Information](https://www.cyberciti.biz/faq/linux-command-to-find-the-system-configuration-and-hardware-information/)
- [/proc/stat explained](https://www.linuxhowtos.org/System/procstat.htm)
- [How to use a here documents to write data to a file in bash script](https://www.cyberciti.biz/faq/using-heredoc-rediection-in-bash-shell-script-to-write-to-file/)

### PostgeSQL

- [postgres - Docker Official Images](https://hub.docker.com/_/postgres)
- [SHOW ALL; For checking the Configuration of Server ](https://www.dbrnd.com/2018/04/postgresql-show-all-for-checking-the-configuration-of-server/)

### AWS 

- [Making an Amazon EBS Volume Available for Use on Linux](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html)
- [Disk space for your jobs](https://bedford.io/projects/cli/doc/aws-batch.html)

### Terraform

- [Terraform – Mount EBS volume as part of user_data on an linux EC2 machine](http://www.sanjeevnandam.com/blog/ec2-mount-ebs-volume-during-launch-time)



