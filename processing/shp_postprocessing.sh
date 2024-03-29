#!/bin/bash

# exit when any command fails
set -e

function generalize() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-"TRUE"}
    printf "start public.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS public.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE public.${target} AS (SELECT gid, ST_CollectionExtract(ST_Multi(ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance}))), 3) AS geometry${columns} FROM public.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON public.${target} USING gist (geometry)" \
        -c "ANALYZE public.${target}"
    printf "public.${target} done\n"
}

function reduce_multi_to_points() {
    local source=${1}
    local target=${2}
    local columns=${3:-""}
    local filter=${4:-"TRUE"}
    printf "start public.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS public.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE public.${target} AS (SELECT ST_PointOnSurface(geometry) AS geometry, ROUND(ST_Area(Geography(ST_Transform(geometry, 4326))) / 1000^2) as area${columns} FROM (SELECT(dumped.geo_dump).geom AS geometry, * FROM (SELECT ST_Dump(geometry) AS geo_dump${columns} FROM public.${source} WHERE ${filter}) AS dumped) AS simple)" \
        -c "CREATE INDEX ON public.${target} USING gist (geometry)" \
        -c "ANALYZE public.${target}"
    printf "public.${target} ${GREEN}done${NC}\n"
}

### merge bathymetry data
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "DROP TABLE IF EXISTS public.bathymetry" 2>&1 >/dev/null \
    -c "CREATE TABLE public.bathymetry (gid serial primary key, depth int4, geometry geometry(MULTIPOLYGON, 3857))" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_k_200;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_j_1000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_i_2000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_h_3000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_g_4000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_f_5000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_e_6000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_d_7000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_c_8000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_b_9000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_a_10000;" \
    -c "CREATE INDEX ON public.bathymetry USING gist (geometry)" \
    -c "ANALYZE public.bathymetry"

### remove fragments
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_k_200;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_j_1000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_i_2000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_h_3000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_g_4000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_f_5000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_e_6000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_d_7000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_c_8000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_b_9000;" 2>&1 >/dev/null \
    -c "DROP TABLE IF EXISTS ne_10m_bathymetry_a_10000;" 2>&1 >/dev/null

generalize "bathymetry" "bathymetry_gen4" 2000 ", depth" &
generalize "bathymetry" "bathymetry_gen3" 8000 ", depth" &
wait
reduce_multi_to_points "ne_10m_admin_0_countries" "label_countries" ", sovereignt, labelrank, scalerank, min_label, abbrev, name_de, name_en" ""

### merge lake datasources
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "DROP TABLE IF EXISTS public.lakes" 2>&1 >/dev/null \
    -c "CREATE TABLE public.lakes (gid serial primary key, name varchar, subclass varchar, scalerank int8, minzoom float8, minlabel float8, geometry geometry(MULTIPOLYGON, 3857))" \
    -c "INSERT INTO public.lakes (name, subclass, scalerank, minzoom, minlabel, geometry) SELECT CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END, featurecla, scalerank, min_zoom, min_label, geometry FROM ne_10m_lakes;" \
    -c "INSERT INTO public.lakes (name, subclass, scalerank, minzoom, minlabel, geometry) SELECT CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END, featurecla, scalerank, min_zoom, min_label, geometry FROM ne_10m_lakes_europe;" \
    -c "CREATE INDEX ON public.lakes USING gist (geometry)" \
    -c "ANALYZE public.lakes"

### merge river datasources
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "DROP TABLE IF EXISTS public.rivers" 2>&1 >/dev/null \
    -c "CREATE TABLE public.rivers (gid serial primary key, name varchar, subclass varchar, scalerank int8, minzoom float8, minlabel float8, geometry geometry(MULTILINESTRING, 3857))" \
    -c "INSERT INTO public.rivers (name, subclass, scalerank, minzoom, minlabel, geometry) SELECT CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END, featurecla, scalerank, min_zoom, min_label, geometry FROM ne_10m_rivers_lake_centerlines;" \
    -c "INSERT INTO public.rivers (name, subclass, scalerank, minzoom, minlabel, geometry) SELECT CASE WHEN (name_de <> '') IS NOT FALSE THEN name_de WHEN (name_en <> '') IS NOT FALSE THEN name_en ELSE name END, featurecla, scalerank, min_zoom, min_label, geometry FROM ne_10m_rivers_europe;" \
    -c "CREATE INDEX ON public.rivers USING gist (geometry)" \
    -c "ANALYZE public.rivers"

### show resulting database size
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "SELECT pg_size_pretty(pg_database_size('${SHAPE_DATABASE_NAME}')) as db_size;"

printf "Shape postprocessing done\n"
