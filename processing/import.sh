#!/bin/bash

# exit when any command fails
set -e

echo "preparing database..."

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w \
    -c "DROP DATABASE IF EXISTS ${DATABASE_NAME};" \
    -c "COMMIT;" \
    -c "CREATE DATABASE ${DATABASE_NAME} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w -d ${DATABASE_NAME} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" \
    -c "CREATE EXTENSION IF NOT EXISTS hstore;" \
    -c "ALTER DATABASE ${DATABASE_NAME} SET postgis.backend = geos;"

echo "done"
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w -d ${DATABASE_NAME} \
    -c "SELECT PostGIS_full_version();"

aws s3 cp s3://${GIS_DATA_BUCKET}/data/pbf/${IMPORT_FILE} osmdata.osm.pbf --no-progress
du -h osmdata.osm.pbf
aws s3 cp s3://${GIS_DATA_BUCKET}/imposm/mapping.yaml mapping.yaml --no-progress
imposm import -mapping mapping.yaml -read osmdata.osm.pbf -overwritecache -write -optimize -connection 'postgis://'${POSTGIS_USER}':'${PGPASSWORD}'@'${POSTGIS_HOSTNAME}'/'${DATABASE_NAME}'?prefix=NONE'
echo "all done"
