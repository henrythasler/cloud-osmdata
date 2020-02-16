#!/bin/bash

# exit when any command fails
set -e

df -h /

echo "downloading s3://${GIS_DATA_BUCKET}/data/pbf/${SOURCE_FILE}..."
aws s3 cp s3://${GIS_DATA_BUCKET}/data/pbf/${SOURCE_FILE} osmdata.osm.pbf --no-progress
du -h osmdata.osm.pbf

echo "slicing ${SOURCE_FILE} with bbox ${LEFT},${BOTTOM},${RIGHT},${TOP}..."

osmconvert osmdata.osm.pbf -b=${LEFT},${BOTTOM},${RIGHT},${TOP} -o=slice.osm.pbf -v=2

aws s3 cp slice.osm.pbf s3://${GIS_DATA_BUCKET}/data/pbf/${OUT_FILE} --no-progress

echo "all done"
