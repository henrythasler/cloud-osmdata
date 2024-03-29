#!/bin/bash

# exit when any command fails
set -e

#defines
NC=''
RED=''
GREEN=''

### greate generalized tables
# ref: https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html
function generalize() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-"TRUE"}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})) AS geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

function generalize_buffer() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-"TRUE"}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT ST_MakeValid(ST_SimplifyPreserveTopology(ST_Buffer(ST_Buffer(geometry,2*${tolerance}), -2*${tolerance}), ${tolerance})) AS geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}


function generalize_hull() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-"TRUE"}
    local percent=${6:-0.99}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT ST_ConcaveHull(ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})), ${percent}, false) AS geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}


function merge_to_point() {
    local source1=${1}
    local source2=${2}
    local target=${3}
    local columns=${4:-""}
    local filter=${5:-"TRUE"}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT ST_PointOnSurface(geometry) AS geometry${columns} FROM import.${source1} WHERE ${filter} UNION ALL SELECT geometry${columns} FROM import.${source2} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

function reduce_to_point() {
    local source=${1}
    local target=${2}
    local columns=${3:-""}
    local filter=${4:-"TRUE"}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT ST_PointOnSurface(geometry) AS geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

function filter() {
    local source=${1}
    local target=${2}
    local columns=${3:-""}
    local filter=${4:-"TRUE"}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

function drop() {
    local table=${1}
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${table}" 2>&1 >/dev/null
}

# merge all features into one multigeometry
function merge() {
    local source=${1}
    local target=${2}
    local filter=${3:-"TRUE"}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT ST_LineMerge(ST_Collect(geometry)) FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

# cluster POIs
function cluster() {
    local source=${1}
    local target=${2}
    local distance=${3}
    local filter=${4:-"TRUE"}
    printf "start import.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT (array_agg(id))[1] as id, ST_Centroid(ST_Union(geometry)) as geometry,	count(id) as count,	class, subclass, (array_remove(array_agg(name), ''))[1] as name, (array_agg(ele))[1] as ele, (array_agg(access))[1] as access, (array_agg(religion))[1] as religion, (array_agg(parking))[1] as parking, (array_agg(subway))[1] as subway FROM( SELECT row_number() over () as id, geometry, name, class, subclass, ele, access, religion, parking, subway, ST_ClusterDBSCAN(geometry, ${distance}, 1) over () as cluster_id FROM import.${source} WHERE ${filter}) tmp GROUP BY class, subclass, cluster_id)" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

### main()

# buildings
filter "buildings_temp" "buildings" "" 
generalize "buildings" "buildings_gen14" 5 "" "ST_Area(geometry)>80"

# poi merge
merge_to_point "buildings_temp" "housenumbers_temp" "housenumbers" ", number, name_de, name_en, name" "(number <> '') IS NOT FALSE" &
merge_to_point "label_polygon" "label_points" "label" ", class, subclass, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name, ele, pop" &
merge_to_point "poi_polygon" "poi_points" "poi" ", class, subclass, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name, ele, access, parking, subway, religion" &
wait

# remove temporary tables
drop "buildings_temp"

# roads - prepare
filter "roads_temp" "roads" ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name" 
# remove temporary table
drop "roads_temp"

# roads - generalize
generalize "roads" "roads_gen15" 3 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "(service <=1) OR (ST_Length(geometry) > 50)" &
generalize "roads" "roads_gen14" 5 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "rank<=15 OR bridge OR (subclass IN ('path', 'track', 'footway', 'bridleway', 'service', 'cycleway', 'via_ferrata') AND ST_Length(geometry) > 100)" &
generalize "roads" "roads_gen13" 10 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "rank<=15 OR bridge OR (subclass IN ('path', 'track', 'footway', 'bridleway', 'service', 'cycleway', 'via_ferrata') AND ST_Length(geometry) > 200)" &
generalize "roads" "roads_gen12" 20 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "rank<=11 OR bridge OR (subclass='path' AND bicycle >= 3) OR (subclass IN ('track', 'service', 'cycleway') AND ST_Length(geometry) > 500) OR (subclass IN ('living_street', 'pedestrian', 'residential', 'unclassified') AND ST_Length(geometry) > 200)" &
wait
generalize "roads" "roads_gen11" 50 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "rank<=10" &
generalize "roads" "roads_gen10" 100 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "rank<=4" &
#generalize "roads" "roads_gen9" 200 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "rank<=3" &
generalize "roads" "roads_gen8" 400 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale, sac, ref" "rank<=3" &
wait

# landuse
filter "landuse_import" "landuse" ", class, subclass, area, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name"
generalize "landuse" "landuse_gen14" 5 ", class, subclass, name, area" "ST_Area(geometry)>1000" &
generalize "landuse" "landuse_gen13" 10 ", class, subclass, name, area" "ST_Area(geometry)>2000" &
wait

generalize_buffer "landuse_gen13" "landuse_gen12" 20 ", class, subclass, name, area" "ST_Area(geometry)>5000" &
generalize_buffer "landuse_gen13" "landuse_gen11" 50 ", class, subclass, name, area" "ST_Area(geometry)>50000" &
generalize_buffer "landuse_gen13" "landuse_gen10" 100 ", class, subclass, name, area" "ST_Area(geometry)>200000" &
wait
generalize_buffer "landuse_gen13" "landuse_gen9" 150 ", class, subclass, name, area" "ST_Area(geometry)>2000000" &
generalize_buffer "landuse_gen13" "landuse_gen8" 200 ", class, subclass, name, area" "ST_Area(geometry)>4000000" &
wait

# landcover
filter "landcover_import" "landcover" ", class, subclass, area, surface, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name"
generalize "landcover" "landcover_gen14" 5 ", class, subclass, surface, area, name" "ST_Area(geometry)>1000" &
generalize "landcover" "landcover_gen13" 10 ", class, subclass, surface, area, name" "ST_Area(geometry)>2000" &
wait

generalize_buffer "landcover_gen13" "landcover_gen12" 20 ", class, subclass, surface, area, name" "ST_Area(geometry)>5000" &
generalize_buffer "landcover_gen13" "landcover_gen11" 50 ", class, subclass, surface, area, name" "ST_Area(geometry)>50000" &
generalize_buffer "landcover_gen13" "landcover_gen10" 100 ", class, subclass, surface, area, name" "ST_Area(geometry)>200000" &
generalize_buffer "landcover_gen13" "landcover_gen9" 150 ", class, subclass, surface, area, name" "ST_Area(geometry)>2000000" &
generalize_buffer "landcover_gen13" "landcover_gen8" 200 ", class, subclass, surface, area, name" "ST_Area(geometry)>5000000" &
wait

# waterarea
generalize "waterarea" "waterarea_gen14" 5 ", class, subclass" "ST_Area(geometry)>1000" &
generalize "waterarea" "waterarea_gen13" 10 ", class, subclass" "ST_Area(geometry)>2000" &
wait

generalize "waterarea_gen13" "waterarea_gen12" 20 ", class, subclass" "ST_Area(geometry)>5000" &
generalize "waterarea_gen13" "waterarea_gen11" 50 ", class, subclass" "ST_Area(geometry)>50000" &
generalize "waterarea_gen13" "waterarea_gen10" 100 ", class, subclass" "ST_Area(geometry)>200000" &
generalize "waterarea_gen13" "waterarea_gen9" 200 ", class, subclass" "ST_Area(geometry)>2000000" &
generalize "waterarea_gen13" "waterarea_gen8" 250 ", class, subclass" "ST_Area(geometry)>5000000" &
wait

# waterway
generalize "waterway" "waterway_gen12" 20 ", class, subclass, tunnel, layer, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name" "ST_Length(geometry)>50" &
generalize "waterway" "waterway_gen10" 50 ", class, subclass, tunnel, layer, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name" "subclass IN('river', 'canal', 'stream') AND ST_Length(geometry)>200" &
generalize "waterway" "waterway_gen8" 100 ", class, subclass, tunnel, layer, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name" "subclass IN('river', 'canal') AND ST_Length(geometry)>400" &
wait

# transportation
generalize "transportation" "transportation_gen12" 20 ", class, subclass" "ST_Length(geometry)>50" &
generalize "transportation" "transportation_gen10" 50 ", class, subclass" "ST_Length(geometry)>100" &
generalize "transportation" "transportation_gen8" 100 ", class, subclass" "ST_Length(geometry)>200" &
wait

# manmade_lines
generalize "manmade_lines" "manmade_lines_gen13" 10 ", class, subclass" "subclass IN('taxiway', 'runway')"

# label filter
filter "label" "label_gen15" ", class, subclass, name, ele, pop" "subclass NOT IN('city', 'town')" &
filter "label" "label_gen14" ", class, subclass, name, ele, pop" "subclass NOT IN('city')" &
filter "label" "label_gen13" ", class, subclass, name, ele, pop" "subclass NOT IN('city', 'hamlet')" &
#filter "label" "label_gen12" ", class, subclass, name, ele, pop" "subclass NOT IN('hamlet')" &
wait
filter "label" "label_gen11" ", class, subclass, name, ele, pop" "subclass NOT IN('hamlet')" &
filter "label" "label_gen10" ", class, subclass, name, ele, pop" "subclass NOT IN('village', 'suburb', 'hamlet')" &
filter "label" "label_gen8" ", class, subclass, name, ele, pop" "subclass NOT IN('town', 'village', 'suburb', 'hamlet')" &
wait

# poi filter - high memory load, so no parallel processing.
cluster "poi" "poi_cluster_gen11" 300 "subclass IN('station', 'halt') AND subway=0"
cluster "poi" "poi_cluster_gen12" 160 "subclass IN('station', 'halt', 'alpine_hut', 'hotel', 'peak', 'pub', 'fast_food', 'restaurant', 'biergarten', 'hospital', 'shelter', 'camp_site', 'caravan_site')"
cluster "poi" "poi_cluster_gen13" 160 "subclass IN('station', 'halt', 'alpine_hut', 'hotel', 'peak', 'pub', 'fast_food', 'restaurant', 'biergarten', 'hospital', 'shelter', 'camp_site', 'caravan_site', 'bicycle')"
cluster "poi" "poi_cluster_gen14" 120 "subclass NOT IN('playground', 'viewpoint', 'information')"
cluster "poi" "poi_cluster_gen15" 80
cluster "poi" "poi_cluster_gen16" 40
cluster "poi" "poi_cluster_gen17" 20

# label waterarea preprocessing
# create_centerlines "waterarea" "lake_centerlines" "/media/ramdisk" ", class, subclass, ele, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name" "subclass = 'water' AND name <> '' AND ST_Area(geometry)>4000000"

reduce_to_point "waterarea" "label_waterarea" ", class, subclass, area, ele, CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END as name" "subclass NOT IN('riverbank', 'swimming_pool') AND ((name_de <> '') IS NOT FALSE OR (name_en <> '') IS NOT FALSE OR (name <> '') IS NOT FALSE)"

filter "label_waterarea" "label_waterarea_gen14" ", class, subclass, name, area, ele" "area>100000" &
filter "label_waterarea" "label_waterarea_gen12" ", class, subclass, name, area, ele" "area>1000000" &
filter "label_waterarea" "label_waterarea_gen10" ", class, subclass, name, area, ele" "area>10000000" &
filter "label_waterarea" "label_waterarea_gen8" ", class, subclass, name, area, ele" "area>100000000" &
wait

# merge cycleroutes into one layer for improved rendering of transparent lines
# merge "cycleroute" "cycleroute_merged"

# remove all temporary tables
drop "housenumbers_temp"
drop "label_polygon"
drop "label_points"
drop "poi_polygon"
drop "poi_points"
drop "landuse_import"
drop "landcover_import"

### show resulting database size
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
    -c "SELECT pg_size_pretty(pg_database_size('${DATABASE_NAME}')) as db_size;"

printf "${GREEN}Postprocessing done${NC}\n"
