#!/bin/bash

echo "starting up..."
aws s3 cp s3://${GIS_DATA_BUCKET}/imposm/mapping.yaml mapping.yaml --no-progress
imposm import -mapping mapping.yaml -connection 'postgis://'${POSTGIS_USER}':'${PGPASSWORD}'@'${POSTGIS_HOSTNAME}'/'${DATABASE_NAME}'?prefix=NONE' -deployproduction
echo "all done"
