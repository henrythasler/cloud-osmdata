## pull container-image from AWS

`aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 324094553422.dkr.ecr.eu-central-1.amazonaws.com`

`docker pull 324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-server:latest`

`docker pull 324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest`

see https://medium.com/geekculture/how-to-locally-pull-docker-image-from-aws-ecr-ebebbb4c100

## Run database

`docker-compose run --rm --service-ports postgis`

## import data

`docker-compose run --rm import && docker-compose run --rm postprocessing`
