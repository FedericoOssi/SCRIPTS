# Extract environmental data 

Here we describe how to extract environmental information from some european raster layers in R.
The specific example is especially suited if environmental data needs to be extracted from a large raster layer.
This script shows the functionality of several spatial functions such as [spTransform](https://www.rdocumentation.org/packages/sp/versions/1.3-1/topics/spTransform), [buffer](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/buffer), [crop](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/crop), [mask](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/mask) and [extract](https://www.rdocumentation.org/packages/raster/versions/2.6-7/topics/extract). To extract values for spatial points efficiently, the area of interest should first be extracted through a crop and mask function in R. 

The raster layers can be downloaded through the following links: 
* [DEM - Copernicus](https://land.copernicus.eu/pan-european/satellite-derived-products/eu-dem/eu-dem-v1-0-and-derived-products/view "Digital Elevation Model")
* [TCD - Copernicus](https://land.copernicus.eu/pan-european/high-resolution-layers/forests/tree-cover-density/status-maps/view "High Resolution Layer Tree Cover Density")

## CONTENT 

* [r](#r)
  * [rpolygon](#rpolygon)
  * [rpoints](#rpoints)

## r

# Import points, polygon and raster
```R
### Load packages ###
library(raster)
library(sp)
library(rpostgis)

### connect to the database ###
con <- dbConnect("PostgreSQL", dbname = "eurodeer_db", host="eurodeer2.fmach.it", user="<myuser>", password="<mypass>")
pgPostGIS(con) # test connection

### Points - Import ###  
locs4326 <- pgGetGeom(con, c("temp","eurodeer_sample"), geom = "geom") # import gps locations
head(locs@data) # view first rows 
locs3035 <- spTransform(gpsdata,"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs") # transform to SRID 3035

### Polygon - Import ### Extract a bounding box from the db using the corresponding gps locations 
box4326 <- pgGetBoundary(con, c("temp","eurodeer_sample"), geom = "geom") # get bounding box in SRID 4326 (i.e., the reference system of the database) 
box3035 <- spTransform(box4326,"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs") # transform to SRID 3035
pol <- buffer(box3035,500) # buffer of 500m around the box3035 - the polygon 

### Raster - Import ###
rast <- raster("forest_density.tif") # change the name and set the correct work directory where you stored the raster
```

# rpolygon
```R
### Polygon - Extract ### 
rast_c <- crop(rast, boundary) # crop the area using boundary
rast_m <- mask(rast_c, boundary) # mask using boundary 
```

# rpoints 
```R
### Points - Extract ### 
gpsdata@data$forest_density <- extract(rast_m, gpsdata3035) #extract raster values for gps locations and add to the data frame 
```
