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
Terrain Characteristics

With the function terrain() in the package _raster_ is it possible to compute: 
* slope 
* aspect
* TPI (Topographic Position Index) 
* TRI (Terrain Ruggedness Index)
* roughness (as the difference between the max and the min value of a cell and its surrounding cells)
* flowdir ('flow direction' (of water), namely the direction of the greatest drop in elevation)

```r
library(raster)

DEM <- raster("DEM.tif")
slope <- terrain(DEM, opt = 'slope', unit='radians', neighbors=8, filename= "slope.tif")
raster::plot(slope)
```

