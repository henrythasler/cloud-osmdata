
## Run database

`docker-compose run --rm --service-ports postgis`

## import data

`docker-compose run --rm import && docker-compose run --rm postprocessing`
