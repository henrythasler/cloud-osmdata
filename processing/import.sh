#!/bin/bash

# exit when any command fails
set -e

echo "preparing database..."

# disconnect clients
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w \
    -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${DATABASE_NAME}';"

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
sleep 1s
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w -d ${DATABASE_NAME} \
    -c "SELECT PostGIS_full_version();"

if [ -z ${LOCALHOST+x} ]; 
then 
    aws s3 cp s3://${GIS_DATA_BUCKET}/data/pbf/${IMPORT_FILE} osmdata.osm.pbf --no-progress
    aws s3 cp s3://${GIS_DATA_BUCKET}/imposm/mapping.yaml mapping.yaml --no-progress
else 
    echo "LOCALHOST is set to '$LOCALHOST'"; 
    pwd
fi

du -h osmdata.osm.pbf
imposm import -mapping mapping.yaml -read osmdata.osm.pbf -overwritecache -write -optimize -connection 'postgis://'${POSTGIS_USER}':'${PGPASSWORD}'@'${POSTGIS_HOSTNAME}'/'${DATABASE_NAME}'?prefix=NONE'
echo "all done"
