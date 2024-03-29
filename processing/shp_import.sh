#!/bin/bash

# exit when any command fails
set -e

# debug output
# set -x

mkdir -p shp
if [ -z ${LOCALHOST+x} ]; 
then 
    aws s3 cp s3://${GIS_DATA_BUCKET}/data/shp ./shp --recursive --quiet
else 
    echo "LOCALHOST is set to '$LOCALHOST'"; 
    pwd
fi
printf "Done fetching shapefiles\n"
### Setup database

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} \
    -c "CREATE DATABASE ${SHAPE_DATABASE_NAME} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;" \
    -c "COMMIT;" 2>&1 >/dev/null

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS hstore;" 2>&1 >/dev/null \
    -c "ALTER DATABASE ${SHAPE_DATABASE_NAME} SET postgis.backend = geos;" 2>&1 >/dev/null \
    -c "COMMIT;" 2>&1 >/dev/null

### Import all shapefiles in given folder
for folder in $(find ./shp/ -mindepth 1 -maxdepth 1 -type d) 
do
    for file in ${folder}/*.shp
    do
        if [[ ! -e "$file" ]]
        then 
            printf "No shapefiles found: %s\n" ${folder}
            continue
        fi

        table="$(basename -- ${file})"
        table=${table%.*}   # remove file extension
        printf "Processing shape ${table} (${file})\n" 
        
        psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} -c "DROP TABLE IF EXISTS ${table};" 2>&1 >/dev/null -c "COMMIT;" 2>&1 >/dev/null 

        ### auto-detect CRS. The tail-part is a bit hacky...
        #FIXME: find another solution to determine shapefile CRS
        crs=$(ogrinfo -ro -al -so ${file} | grep "EPSG" | tail -n1 | grep -Eo "[0-9]+")

        printf "CRS is ${crs}\n"

        # continue
        if [ ${crs} != "3857" ]
        then
            printf "Reprojecting from EPSG:${crs} to EPSG:3857\n"
            base=`basename $file .shp`

            mkdir -p 3857

            ogr2ogr -clipsrc -180.0 -85.06 180.0 85.06 -skipfailures -lco ENCODING=UTF-8 -t_srs EPSG:3857 ./3857/${base}.shp ${file} > /dev/null
            if [ $? -eq 0 ]
            then 
                shp2pgsql -s 3857 -I -g geometry ./3857/${base}.shp ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
            else
                printf "Failed Importing with source CRS\n"
                shp2pgsql -s ${crs} -I -g geometry ${file} ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
            fi
        else
            shp2pgsql -s ${crs} -I -g geometry ${file} ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
        fi
        printf "OK\n"
    done
done

### show resulting database size
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "SELECT pg_size_pretty(pg_database_size('${SHAPE_DATABASE_NAME}')) as db_size;"