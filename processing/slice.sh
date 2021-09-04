#!/bin/bash

# exit when any command fails
set -e

df -h /

if [ -z ${LOCALHOST+x} ]; 
then 
    echo "downloading s3://${GIS_DATA_BUCKET}/data/pbf/${SOURCE_FILE}..."
    aws s3 cp s3://${GIS_DATA_BUCKET}/data/pbf/${SOURCE_FILE} osmdata.osm.pbf --no-progress
else 
    echo "LOCALHOST is set to '$LOCALHOST'"; 
    pwd
fi
du -h osmdata.osm.pbf

if [ -z ${POLY_FILES+x} ]; 
then 
    echo "slicing ${SOURCE_FILE} with bbox ${LEFT},${BOTTOM},${RIGHT},${TOP}..."
    osmconvert osmdata.osm.pbf -b=${LEFT},${BOTTOM},${RIGHT},${TOP} -o=slice.osm.pbf -v=2
else 
    collection=""
    for POLYFILE in ${POLY_FILES} 
    do
        printf "slicing ${SOURCE_FILE} with polyfile '${POLYFILE}'...\n"
        osmconvert osmdata.osm.pbf -B=/tmp/poly/${POLYFILE}.poly --complete-multipolygons -o=${POLYFILE}.o5m -v=2
        printf "ok\n\n"
        collection="${collection}${POLYFILE}.o5m "
    done

    printf "Merging all slices (${collection})...\n"
    osmconvert ${collection} -o=slice.osm.pbf
fi

if [ -z ${LOCALHOST+x} ]; 
then 
    aws s3 cp slice.osm.pbf s3://${GIS_DATA_BUCKET}/data/pbf/${OUT_FILE} --no-progress
else 
    cp slice.osm.pbf /tmp/data/${OUT_FILE}
    pwd
fi

echo "all done"
