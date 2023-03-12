#!/bin/bash

# exit when any command fails
set -e
LOG_PREFIX="[### slice ###] "

df -h /

if [ -z ${LOCALHOST+x} ]; 
then 
    printf "${LOG_PREFIX}Downloading osm-data from s3://${GIS_DATA_BUCKET}/data/pbf/${SOURCE_FILE} ...\n"
    aws s3 cp s3://${GIS_DATA_BUCKET}/data/pbf/${SOURCE_FILE} osmdata.osm.pbf --no-progress

    printf "${LOG_PREFIX}Downloading poly-files from s3://${GIS_DATA_BUCKET}/poly ...\n"
    aws s3 cp s3://${GIS_DATA_BUCKET}/poly ./poly --recursive --no-progress

    printf "${LOG_PREFIX}Downloading additional files to be merged from s3://${GIS_DATA_BUCKET}/data/pbf ...\n"

    for MERGEFILE in ${MERGE_FILES} 
    do
#        printf "${LOG_PREFIX}${MERGEFILE}\n"
        aws s3 cp s3://${GIS_DATA_BUCKET}/data/pbf/${MERGEFILE} ${MERGEFILE} --no-progress
    done

else 
    # no aws operations when testing on localhost. Make sure all files are available (e.g. via docker volumes)
    printf "${LOG_PREFIX}LOCALHOST is set to '$LOCALHOST'\n"
    printf "${LOG_PREFIX}Current path: '$(pwd)'\n"
fi

# checking filesize
printf "${LOG_PREFIX}Size of '${SOURCE_FILE}': $(du -h osmdata.osm.pbf | awk '{print $1;}')\n"

# this script can slice with a given bbox or a set of .poly files
if [ -z ${POLY_FILES+x} ]; 
then 
    printf "${LOG_PREFIX}Slicing '${SOURCE_FILE}' with bbox ${LEFT},${BOTTOM},${RIGHT},${TOP}...\n"
    osmconvert osmdata.osm.pbf -b=${LEFT},${BOTTOM},${RIGHT},${TOP} -o=slice.osm.pbf -v=2
    printf "${LOG_PREFIX}ok\n\n"
else 
    collection=""
    for POLYFILE in ${POLY_FILES} 
    do
        printf "${LOG_PREFIX}Slicing '${SOURCE_FILE}' with polyfile '${POLYFILE}'...\n"
        osmconvert osmdata.osm.pbf -B=/tmp/poly/${POLYFILE}.poly --complete-multipolygons -o=${POLYFILE}.o5m -v=2
        printf "${LOG_PREFIX}Ok (${POLYFILE}.o5m $(du -h ${POLYFILE}.o5m | awk '{print $1;}'))\n\n"
        collection="${collection}${POLYFILE}.o5m "
    done

    collection="${collection}${MERGE_FILES} "
    printf "${LOG_PREFIX}Merging all slices (${collection})...\n"
    osmconvert ${collection} -o=slice.osm.pbf
fi

printf "${LOG_PREFIX}Size of result: $(du -h slice.osm.pbf | awk '{print $1;}')\n"

if [ -z ${LOCALHOST+x} ]; 
then 
    printf "${LOG_PREFIX}Uploading result to 's3://${GIS_DATA_BUCKET}/data/pbf/${OUT_FILE}'\n"
    aws s3 cp slice.osm.pbf s3://${GIS_DATA_BUCKET}/data/pbf/${OUT_FILE} --no-progress
else 
    printf "${LOG_PREFIX}Moving result to '${OUT_FILE}'\n"
    cp slice.osm.pbf /tmp/data/${OUT_FILE}
fi

printf "${LOG_PREFIX}All done\n\n"
