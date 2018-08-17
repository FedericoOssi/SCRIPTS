# Extract environmental data 

Here we describe how to extract environmental information from raster layers in R for points and polygons. The specific example is especially suited if local environmental data needs to be extracted from a large raster layer. This script shows the functionality of several spatial functions such as [pgGetGeom](https://www.rdocumentation.org/packages/rpostgis/versions/1.4.0/topics/pgGetGeom), [pgGetBoundary](https://www.rdocumentation.org/packages/rpostgis/versions/1.4.0/topics/pgGetBoundary), [spTransform](https://www.rdocumentation.org/packages/sp/versions/1.3-1/topics/spTransform), [buffer](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/buffer), [crop](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/crop), [mask](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/mask), [pgGetRast](https://www.rdocumentation.org/packages/rpostgis/versions/1.4.0/topics/pgGetRast) and [extract](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/extract). To extract values for spatial points efficiently, the area of interest should first be extracted through a crop and mask function in R. 

The raster layer can be downloaded through the following link (many more raster layers for Europe are available for download): 
* [TCD - Copernicus](https://land.copernicus.eu/pan-european/high-resolution-layers/forests/tree-cover-density/status-maps/view "High Resolution Layer Tree Cover Density")
* This raster is also available in the eurodeer database, for populations with imported GPS and VHF data.  

## CONTENT 

  * [polygon](#polygon)
  * [points](#points)

#### Import points and polygon from database 
```R
### Load packages ###
library(raster)
library(sp)
library(rpostgis)

### Connect to the database ###
con <- dbConnect("PostgreSQL", dbname = "eurodeer_db", host="<host>", user="<myuser>", password="<mypass>")
pgPostGIS(con) # test connection

### Points - Import ###  
locs4326 <- pgGetGeom(con, c("main","gps_data_animals"), geom = "geom", clauses = "WHERE animals_id in (1,2,3,4,5) and gps_validity_code = 1") # import gps locations
# head(locs4326@data) # view first rows

### reproject locations ### 
# crs(locs4326) # check the reference system 
# METHOD A: Extract proj4 string from the database
proj4 <- dbGetQuery(con, "SELECT proj4text FROM spatial_ref_sys JOIN (SELECT st_srid(rast) srid FROM env_data.forest_density limit 1) a USING (srid);")
# METHOD B: Get proj4 string from http://spatialreference.org/ref/epsg/3035/proj4/
proj4 <- c("+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs")
locs3035 <- spTransform(gpsdata,proj4) # transform to the reference system SRID 3035

### Polygon - Import ### Extract a bounding box from the db using the corresponding gps locations 
box4326 <- pgGetBoundary(con, c("main","gps_data_animals"), geom = "geom", clauses = "WHERE animals_id in (1,2,3,4,5) and gps_validity_code = 1") # get bounding box in SRID 4326 (i.e., the reference system of the database)
box3035 <- spTransform(box4326, proj4) # transform to SRID 3035
pol <- buffer(box3035,500) # buffer of 500m around the box3035 - the polygon 
```
#### polygon
```R
### Polygon - Extract raster from R ### 
rast <- raster("forest_density.tif") # import raster - set the correct work directory and name of the raster
rast_c <- crop(rast, pol) # crop the area using boundary (pol)
rast_m <- mask(rast_c, pol) # mask using boundary (pol)

### Polygon - Extract raster from database ###
# If the raster is available within a database also the function pgGetRast can be used instead
rast_m <- pgGetRast(con, c("env_data", "forest_density"), boundary = pol)
```
#### points 
```R
### Points - Extract ### 
gpsdata@data$forest_density <- extract(rast_m, gpsdata3035) #extract raster values for gps locations and add to the data frame 
```

###### [-to read me-](README.md)
