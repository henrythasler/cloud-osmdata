#!/bin/bash

# exit when any command fails
set -e

mkdir -p shp

if [ -z ${LOCALHOST+x} ]; 
then 
    aws s3 cp s3://${GIS_DATA_BUCKET}/${SHAPEFOLDER} ./shp --recursive --quiet
else 
    echo "LOCALHOST is set to '$LOCALHOST'"; 
    pwd
fi

printf "Done fetching shapefiles\n"
SOURCE="shp/${SHAPEFILE}"

function generalize_raster() {
    local source=${1}
    local target=${2}
    local resolution=${3}
    local grid=${4}

    printf "gdal_rasterize (${resolution}x${resolution}) to ${target}: "
    gdal_rasterize -init 255 -burn 0 -ot Byte -ts ${resolution} ${resolution} -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES ${source}.shp rasterized.tif

    # prepare vrt
    printf "  gdalbuildvrt: "
    gdalbuildvrt rasterized.vrt rasterized.tif

    # add blur https://gis.stackexchange.com/questions/20196/how-to-convert-geotiff-to-grayscale-and-add-gaussian-blur
    sed -i "s/SimpleSource/KernelFilteredSource/" rasterized.vrt
    sed -i "s/<KernelFilteredSource>/<KernelFilteredSource>\nKERNEL/" rasterized.vrt
    sed -i "s/KERNEL/<Kernel normalized=\"1\">\n<Size>5<\/Size>\n<Coefs>\nCOEFS\n<\/Coefs>\n<\/Kernel>/" rasterized.vrt
    sed -i "s/COEFS/0.0036630037 0.0146520147 0.0256410256 0.0146520147 0.0036630037\n \
    0.0146520147 0.0586080586 0.0952380952 0.0586080586 0.0146520147\n \
    0.0256410256 0.0952380952 0.1501831502 0.0952380952 0.0256410256\n \
    0.0146520147 0.0586080586 0.0952380952 0.0586080586 0.0146520147\n \
    0.0036630037 0.0146520147 0.0256410256 0.0146520147 0.0036630037/" rasterized.vrt

    # convert to shapefile
    printf "  gdal_contour: "
    gdal_contour -fl 128 -p rasterized.vrt raw.shp

    # use just water polygon
    ogr2ogr -fid 0 filtered.shp raw.shp

    # count grid features
    count=$(ogrinfo -ro -al -sql "SELECT COUNT(id) FROM ${grid}" /grids/${grid}.shp | grep "(Integer)" | grep -Eo "[0-9]+")
    printf "  slicing with grid (${count} features): "

    # slice resulting shapefile using grid
    ogr2ogr "${target}.shp" -clipsrc "/grids/${grid}.shp" -clipsrcwhere id=1 filtered.shp
    for (( j = 2; j <= $count; j++ )) 
    do
        if [ $(( $j % 10 )) -eq 0 ]; then
            printf "."
        fi
        ogr2ogr -append "${target}.shp" -clipsrc "/grids/${grid}.shp" -clipsrcwhere id=${j} filtered.shp
    done
    printf "  done\n"

    printf "  starting import into \"${SHAPE_DATABASE_NAME}\", table \"${target}\".\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS ${target};" 2>&1 >/dev/null \
        -c "COMMIT;" 2>&1 >/dev/null 
    shp2pgsql -s 3857 -I -g geometry ${target}.shp ${target} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
    # rm 
}

printf "generalizing ${ZOOMLEVELS} levels, starting with ${INITIALZOOM}\n"

for (( i = 0; i < ${ZOOMLEVELS}; i++ )) 
do  
    printf "${i} start\n"
    resolution=$((${RESOLUTION}*2**${i}))
    generalize_raster ${SOURCE} ${OUTPUT}$((${INITIALZOOM}+${i})) ${resolution} ${GRID}
    printf "${i} done\n"
done

printf "finished\n"

## show resulting database size
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "SELECT pg_size_pretty(pg_database_size('${SHAPE_DATABASE_NAME}')) as db_size;"