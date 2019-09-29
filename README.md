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

### docker

Host local database with docker and docker-compose. Import also with docker containers.

## Ideas

- Aurora serverless