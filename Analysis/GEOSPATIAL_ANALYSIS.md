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

**Terrain Characteristics**

With the function terrain() in the package _raster_ is it possible to compute: 
* slope 
* aspect
* TPI (Topographic Position Index) as in [Wilson et al, 2007](https://www.tandfonline.com/doi/abs/10.1080/01490410701295962)
* TRI (Terrain Ruggedness Index) as in [Wilson et al, 2007](https://www.tandfonline.com/doi/abs/10.1080/01490410701295962)
* roughness (as the difference between the max and the min value of a cell and its surrounding cells)
* flowdir ('flow direction' (of water), namely the direction of the greatest drop in elevation)

```r
library(raster)

DEM <- raster("DEM.tif")
slope <- terrain(DEM, opt = 'slope', unit='radians', neighbors=8, filename= "slope.tif")
raster::plot(slope)
```

TPI and TRI can be also computed using the package [spatialEco](https://rdrr.io/cran/spatialEco/): Spatial Analysis and Modelling Utilities.

* The TPI - Topographic Position Index is computed following the procedure of [De reu et al, 2013](https://www.sciencedirect.com/science/article/pii/S0169555X12005739).
* TRI - Terrain Ruggedness Index is computed following the procedure of [Riley et al, 1999](https://download.osgeo.org/qgis/doc/reference-docs/Terrain_Ruggedness_Index.pdf)


```r
library(raster)
library(spatialEco)

DEM <- raster("DEM.tif")
TRI <- tri(DEM)
TPI <- tpi(DEM)

par(mfrow=c(1:3))
raster::plot(DEM)
raster::plot(TRI)
raster::plot(TPI)
```

**Heat Load Index**

Equations for potential annual direct incident radiation and heat load, as presented by [Bruce and Dylan, 2002](https://onlinelibrary.wiley.com/doi/epdf/10.1111/j.1654-1103.2002.tb02087.x).

```r
library(raster)
library(spatialEco)

DEM <- raster("DEM.tif")
heat_load <- hli(DEM)

# Visual comparison of the outputs (Digital Elevation Model vs. Heat Load map)
par(mfrow=c(1:2))
raster::plot(DEM)
raster::plot(heat_load)
```
