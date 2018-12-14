# Home Range Estimation

## CONTENT 
 
* [mcp](#mcp)
* [kernel](#kernel)
* [tlocoh](#tlocoh)
* [brownianbridge](#brownianbridge)

## MCP

**Individual MCP**  
```R
v <- c(1:200) 
```

###### [-to content-](#content)

## kernel

**Individual KDE**  
```R
# # # make a spatial database of df for kernelUD function 
coord_col<- c(1,2) #input column numbers that contain x y coordinates
spatialdf<- SpatialPointsDataFrame(coords=df[,coord_col], data=df) 

# # # GRID ESTIMATION: The kernelUD 'grid' parameter expects a SpatialPixels object that  
# # # #           represents the raster upon which you wish to estimate the animal UD
xmin<- min(df$x_32632)-100 ##found 100 to be absolute minimum that allowed kUD to get homerange area value for 100%
xmax<- max(df$x_32632)+100
ymin<- min(df$y_32632)-100
ymax<- max(df$y_32632)+100
x <- seq(xmin,xmax,by=10)  # where "by = resolution" is the pixel size you desire 
y <- seq(ymin,ymax,by=10) 
xy <- expand.grid(x=x,y=y) 
coordinates(xy) <- ~x+y 
gridded(xy) <- TRUE 

# # # KERNEL UD ANALYSIS 
# # # #       for buffer sensitivity analysis, multiply empirical_mean by respective values (i.e. 0.25, 0.5, 0.75, 1.5 etc)
kud1<- kernelUD(spatialdf[,3], h = empirical_mean, grid = xy) #h is bandwidth, here I chose empirical_mean steplength, grid defined above

```

###### [-to content-](#content)

## tlocoh

**Individual TLOCOH**  
```R
v <- c(1:200) 
```

###### [-to content-](#content)

## BrownianBridge 

**Individual BB**  
```R
v <- c(1:200) 
```

###### [-to content-](#content)

![](images/hr.jpg)


###### [-to read me-](README.md)
