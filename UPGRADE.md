# How to upgrade the database

## Download a new PBF

1. Go to AWS Batch
2. Submit a new job
3. Enter name: `download_pbf`
4. Job Definition: `download_pbf:1`
5. Job Queue: `gisdata-batch`
6. Expand `Additional configuration`
7. Edit as follows:

Name | Value
---|---
DOWNLOAD_URL|http://download.geofabrik.de/europe-latest.osm.pbf
OBJECT_NAME|europe-latest.osm.pbf

9. Hit `Submit`
10. Go to the Batch Dashboard and wait until the job finishes (7min).

## Slice the region

1. Go to AWS Batch
2. Submit a new job
3. Enter name: `slice_europe_pbf`
4. Job Definition: `slice:9`
5. Job Queue: `gisdata-batch`
6. Expand `Additional configuration`
7. Edit as follows (use [geofabrik](tools.geofabrik.de/calc) to select bounds):

Name | Value
---|---
SOURCE_FILE|europe-latest.osm.pbf
OUT_FILE|germany-alps.osm.pbf
LEFT|8.7890625
BOTTOM|45.33670215
RIGHT|14.41406216
TOP|51.61801655

9. Hit `Submit`
10. Go to the Batch Dashboard and wait until the job finishes (30min).

## Import into Database

1. Go to AWS Batch
2. Submit a new job
3. Enter name: `import`
4. Job Definition: `import_into_database:14`
5. Job Queue: `gisdata-batch`
6. Expand `Additional configuration`
7. Edit as follows:

Name | Value
---|---
IMPORT_FILE|germany-alps.osm.pbf
POSTGIS_HOSTNAME| (get **internal** IP-address or hostname from EC2)

9. Hit `Submit`
10. Go to the Batch Dashboard and wait until the job finishes (1h 45min).

## Postprocessing

1. Go to AWS Batch
2. Submit a new job
3. Enter name: `postprocessing`
4. Job Definition: `postprocessing:6`
5. Job Queue: `gisdata-batch`
6. Expand `Additional configuration`
7. Edit as follows:

Name | Value
---|---
POSTGIS_HOSTNAME| (get **internal** IP-address or hostname from EC2)

9. Hit `Submit`
10. Go to the Batch Dashboard and wait until the job finishes (2h 30min).

## Clear Cache

1. go to S3, bucket `tiles.cyclemap.link`
2. delete folder `local`
3. go to CloudFront, origin `tiles.cyclemap.link` -> `Invalidations`
4. Create Invalidation: `/local/*`

