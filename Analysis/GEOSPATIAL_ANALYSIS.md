# Geospatial analysis

In this document we present some common analysis to download, handle and visualize spatial data in R. 

## CONTENT 

* [Load raster files](#Loading)
* [Compute Terrain Characteristics](#Computing)


#### Loading

```r
library(raster)
 
setwd("~/folder_with_file")

# Load the Digital Elevation Model in your laptop 
DEM <- raster("DEM.tif")

# In alternative, you can get geographic data for anywhere in the world.
## Countries are specified by their 3 letter ISO codes.
## Data set name, currently supported are 'GADM', 'countries', 'SRTM', 'alt', and 'worldclim'

Italy <- raster::getData("alt", country = "ITA", mask = TRUE) # DEM at 90 resolution
raster::plot(Italy)

```

#### Computing
