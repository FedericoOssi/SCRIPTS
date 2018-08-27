
In this script the difference between 2D and 3D step length of real roe deer movement data is calculated, I used data from Germany (studyarea 15 in the eurodeer database) and Switzerland (studyarea 25 in the database). 


```{r}
# libraries
library("RPostgreSQL")
library("lubridate")
library("sp")
library("rpostgis")
library("rgdal")
library("raster")
library("adehabitatLT")
library("amoter")
library("ggplot2")
```

Functions used in this script

```{r}
distanceCalc_df <- function(x_vector, y_vector, z_vector=rep(0,10000000)){
  # function to calculate the distance between every point on a line
  #
  # args:
  #   x_vector: numerical array with the x_coordinates
  #   y_vector: numerical array with the y_coordinates
  #   z_vector: numerical array with the z_coordinates, default = zeros
  #
  # returns:
  #   dist: numerical array with the distance between every point on the line
  
  dist <- NULL
  dist[[1]] <- 0
  for (k in 2:length(x_vector)){
    dist[[k]] <- sqrt((x_vector[k]-x_vector[k-1])^2+(y_vector[k]-y_vector[k-1])^2+(z_vector[k]-z_vector[k-1])^2)
  }

  return(dist)
}


cumsumCalc <- function(segment, distance){
  # function to calculate the cumulative distance between every point on a line, starts on zero with new segment.
  #
  # args:
  #   segment: a list with the index of the point on the segments
  #   distance: a list with the distance between every point on the line (as calculated with distanceCalc_df)
  #
  # returns:
  #   cumsum: vector with the cumulative distance between every point on the line, starting on zero at every new segment.
  
  cumdist <- NULL
  cumdist[[1]] <- cumsum(distance[segment[[1]]])
  for (i in 2:length(segment)){cumdist[[i]] <- c(0,(cumsum(distance[segment[[i]]])))}
  return(cumdist)

}


terrainCalc <- function(cum_distance, elevation, segment){
  # function to calculate the rugosity and elevation for a tracking step profile. 
  #
  # args:
  #   cum_distance: cumulative distance between point on the trajectory, starting on zero for every segment.
  #   elevation: elevation for every point on the trajectory. 
  #   segment: a list with the index of the point on the segments
  #
  # returns:
  #   terrain: matrix with the the segment number, rugosity and slope for every segment.
  
  # prepare matrix for output
  terrain <- matrix(nrow=0,ncol=3)
  colnames(terrain) <- c('seg','roughness','slope')
  
  for (i in 1:length(segment)){
    
    reg_lin <- lm(elevation[segment[[i]]]~cum_distance[[i]])
    residuals <- resid(reg_lin)
    stddev <- sd(residuals)
    slope <- abs(atan(reg_lin$coefficients[2])/pi*180)

    # add result to output
    terrain <- rbind(terrain, cbind(i ,stddev,slope))
    }
  return(terrain)
  
}


#' @examples
#' require(raster)
#' elev <- raster(ncol=30, nrow=30,ext=extent(0,30,0,30),crs=NA)
#' values(elev) <- runif(ncell(elev))*10
#' p1 <- cbind( x=c(1,8,14,18,23), y=c(3,5,11,4,17))
#' p2 <- cbind( x=c(1,3,4,15,21), y=c(3,12,21,24,16))
#
#  # elevation added, no resampling between observation points
#' p1e <- eal(p1,elev)
#' p2e <- eal(p2,elev)
#'
#' # elevation added with resampling between observation points
#' p1er <- eal(p1,elev,step=1)
#' p2er <- eal(p2,elev,step=1)
#' @export

eal_marrit <- function(co,elev,step=NULL,endpt=TRUE) {
#' elevation along a 2D line, adapted from package 'amoter' (van Loon, 2018)
#'
#' @param co a numeric 2-column matrix with the x-coordinate in the first
#' column and the y-coordinate in the second
#' @param elev a raster object which contains the elevation values for a domain
#' which covers the x- and y-coordinates
#' @param step the length between the steps on the line
#' @param endpt a binary value to indicate whether the endpoints of each line
#' segment should be kept in the resampled data (if set to TRUE, the endpoints
#' are kept in the output)
#' @return a 4-column matrix with the first two columns
#' identical to co, and the z in the third column, the fourth column contains
#' integers which refer to the line segments in co. The end-point of each line
#' segment is also the starting point of the subsequent line segment, and
#' and a choice has been made to number these points by the id of the
#' new segment.
#' @examples
#' require(raster)
#' elev <- raster(ncol=30, nrow=30,ext=extent(0,30,0,30),crs=NA)
#' values(elev) <- runif(ncell(elev))*10
#' p1 <- cbind( x=c(1,8,14,18,23), y=c(3,5,11,4,17))
#' p2 <- cbind( x=c(1,3,4,15,21), y=c(3,12,21,24,16))
#
#  # elevation added, no resampling between observation points
#' p1e <- eal(p1,elev)
#' p2e <- eal(p2,elev)
#'
#' # elevation added with resampling between observation points
#' p1er <- eal(p1,elev,step=1)
#' p2er <- eal(p2,elev,step=1)
#' @export

  if(is.data.frame(co)){
    co<-as.matrix(co)
  }
  
  if(is.null(step)){
    seg <- c(1:nrow(co))
    return( cbind(co, z=raster::extract(elev,co), seg=seg) )
  }else{
    coi <- ed_resamp_marrit(co, step=step,endpt=endpt)
    zi <- raster::extract(elev,coi[,c(1,2)])
    coi <- cbind(x=coi[,1], y=coi[,2], z=zi, seg=coi[,3])
    return(coi)
  }

}


ed_resamp_marrit <- function(co, step=1, endpt=TRUE) {
#' find x,y coordinates at equal distances along a piecewise linear line, adapted from package 'amoter' (van Loon, 2018)
#'
#' @param co a numeric 2-column matrix with the x-coordinates in the first
#' column and the y-coordinates in the second
#' @param step the length between the steps on the line
#' @param endpt a boolean value which indicates whether the nodes of the
#' piecewise linear line have to be included
#'
#' @return A 3-column matrix with in the first two columns x and y coordinates
#' of the equidistant points and in the third columns an integer which specifies
#' in which line-segment of co each point falls. The end-point of each line
#' segment is also the starting point of the subsequent line segment, and
#' and a choice has been made to number these points by the id of the
#' new segment. To keep this pattern consistent, the very last point of the
#' trajectory has a new id
#' @import stats
#' @examples
#' co <- cbind(x=c(1,3,7,8,5),y=c(12,7,6,10,14))
#'
#' coi1 <- ed_resamp(co, step=1, endpt=FALSE)
#' coi2 <- ed_resamp(co, step=2, endpt=FALSE)
#' plot(co[,1],co[,2],type='l',col='red')
#' points(coi1[,1],coi1[,2],pch=3)
#' points(coi2[,1],coi2[,2],pch=1,col='blue')
#'
#' coi1 <- ed_resamp(co, step=1, endpt=TRUE)
#' coi2 <- ed_resamp(co, step=2, endpt=TRUE)
#' plot(co[,1],co[,2],type='l',col='red')
#' points(coi1[,1],coi1[,2],pch=3)
#' points(coi2[,1],coi2[,2],pch=1,col='blue')
#' @export
 
  
  # for storing outputs
  coit <- matrix(nrow=0,ncol=3)
  colnames(coit) <- c('xi','yi','seg')
  xpart <- FALSE

  for(i in 1:(nrow(co)-1)){
  
    xpart <- FALSE
    # determine x-coordinate of last point
    if(i==1){
      pt_start <- co[1,]
      xi_start <- co[1,1]
    }else{
      if( coi$x[length(xi)] == co[i,1] | endpt){
        # last point falls on next node OR
        # explicit setting that each node should be part of interpolation
        pt_start <- co[i,]
        xi_start <- co[i,1]
      }else{
        xpart <- TRUE
        pt_start <- c(coi$x[length(xi)], coi$y[length(xi)])
        xi_start <- pt_start[1]
      }
    }

    # check if furthest point in next segment is more than 1 step
    # away from lastpoint, if not: move on to next segment
    # this part is only relevant if endpt == FALSE
    nextsegment <- co[c(i,i+1),]
    rngmax <- max( distrange_pl(co=nextsegment, pt=pt_start) )
    if((step>rngmax) & !endpt){next()}

    # if the remaining distance on the last line segment is smaller than
    # step, new starting x-value on the new segment is determined
    if(xpart){
      xi_start <- intpoint_pl(co=nextsegment, pt=pt_start, dist=step)[1]
      xpart <- FALSE
    }

    # the step length along the x-asis is calculated,
    # when the step length on the path is set to 'step'
    totstep <- diff( dal(nextsegment) )
    xstep <- diff(nextsegment[,1])
    pr_xstep <- step*xstep/totstep

    # the points on next segment are determined by linear interpolation, if-statement MARRIT
    xi_end <- nextsegment[2,1]
    if (xi_start == xi_end){ 
      xi = 1
      coi <- data.frame(x=co[i,1], y=co[i,2])
      
    }else{
      xi <- seq(from=xi_start, to=xi_end, by=pr_xstep)
      coi <- approx(nextsegment, xout=xi)}
    
    # add result to output
    coit <- rbind(coit, cbind(coi$x,coi$y,rep(i,length(xi))))
  }
  
  # adding the very last coordinate of track at the end
  coit <- rbind(coit, c(nextsegment[2,],i+1))

  return(coit)
}




```

Connect to the database

```{r}
# connect to database
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "eurodeer_db", host = "eurodeer2.fmach.it", user = "mleenstra", password = "maestra")

# check if postGIS is enabled on the database
pgPostGIS(con)
```

Retrieve the data from the database

```{r}
# get the right projection of the DEM copernicus
proj4 <- dbGetQuery(con, "SELECT proj4text FROM spatial_ref_sys JOIN 
(SELECT st_srid(rast) srid FROM env_data.dem_copernicus limit 1) a USING (srid);")

# get boundary of studyareas
boundDE <- spTransform(pgGetBoundary(con, c("main", "study_areas"), clauses = "WHERE study_areas_id = 15"), CRS(as.character(proj4)))
boundCH <- spTransform(pgGetBoundary(con, c("main", "study_areas"), clauses = "WHERE study_areas_id = 25"), CRS(as.character(proj4)))

# get dem of studyareas
demDE <- pgGetRast(con, c("env_data", "dem_copernicus"), boundary = boundDE)
demCH <- pgGetRast(con, c("env_data", "dem_copernicus"), boundary = boundCH)
```

Get some metrics for the whole study area

```{r}
# calculate the mean elevation for the studyareas
demDEMean <- cellStats(demDE, mean)
demCHMean <- cellStats(demCH, mean)

# calculate slope
slopeDE <- terrain(demDE, opt = 'slope', units = 'degrees')
slopeCH <- terrain(demCH, opt = 'slope', units = 'degrees')
mean_relslopeDE <- cellStats(slopeDE, mean)
mean_relslopeCH <- cellStats(slopeCH, mean)
mean_slopeDE <- mean_relslopeDE*100
mean_slopeCH <- mean_relslopeCH*100
```

Now extract the slected trajectories from the database

```{r}
query15 <- "SELECT study_areas_id, animals_id, yyear, acquisition_time, temp.marrit_de15.geom as geom, fixes_o, fixes_e, prop 
FROM temp.marrit_de15 
LEFT JOIN main.gps_data_animals USING (animals_id, acquisition_time)
WHERE gps_validity_code = 1
ORDER BY animals_id, acquisition_time;"

query25 <- "SELECT study_areas_id, animals_id, yyear, acquisition_time, temp.marrit_ch25.geom as geom, fixes_o, fixes_e, prop 
FROM temp.marrit_ch25 
LEFT JOIN main.gps_data_animals USING (animals_id, acquisition_time)
WHERE gps_validity_code = 1
ORDER BY animals_id, acquisition_time;"

animals_de15 <- spTransform(pgGetGeom(con, query = query15), CRS(as.character(proj4)))
animals_ch25 <- spTransform(pgGetGeom(con, query = query25), CRS(as.character(proj4)))

# make ltraj class
tracksDE <- as.ltraj(coordinates(animals_de15), date = animals_de15$acquisition_time, id = animals_de15$animals_id)
tracksCH <- as.ltraj(coordinates(animals_ch25), date = animals_ch25$acquisition_time, id = animals_ch25$animals_id)
```

Plot the trajectories (if you want)

```{r}
# check the trajectories Switzerland
plot(demCH, main = "Selected roe deer trajectories in the Swiss alps")
lines(tracksCH[[1]], col = 1)
lines(tracksCH[[2]], col = 2)
lines(tracksCH[[3]], col = 3)
lines(tracksCH[[4]], col = 4)
lines(tracksCH[[5]], col = 5)
lines(tracksCH[[6]], col = 6)
lines(tracksCH[[7]], col = 7)
lines(tracksCH[[8]], col = 'purple')
lines(tracksCH[[9]], col = 9)
lines(tracksCH[[10]], col = 10)

# check the trajectories Germany
plot(demDE, main = "Selected roe deer trajectories in South Germany")
lines(tracksDE[[1]], col = 1)
lines(tracksDE[[2]], col = 2)
lines(tracksDE[[3]], col = 'pink')
lines(tracksDE[[5]], col = 5)
lines(tracksDE[[6]], col = 6)
lines(tracksDE[[7]], col = 'red')
lines(tracksDE[[8]], col = 1)
lines(tracksDE[[9]], col = 'blue')
lines(tracksDE[[10]], col = 'purple')
lines(tracksDE[[4]], col = 'yellow')
```


Calculate for the Swiss dataset at every step the steplength in 3D and 2D, slope and roughness. 

```{r}
stepsCH <- NULL
for (i in 1:10){
  
  # determine elevation and distance along profile by linear interpolation.  
  tr1 <- cbind(x=tracksCH[[i]]$x, y= tracksCH[[i]]$y)
  tr1e <- eal_marrit(tr1, demCH)
  tr1er <- eal_marrit(tr1, demCH, step = 25)
  tr1er_dist3D <- dalw(tr1er, 3)
  tr1er_dist2D <- dalw(tr1er, 2)
  
  # calculate the right indexes of the segments
  seg <- ptseg(tr1er)
  
  # take the double index of the segments (thus not endpoint == startpoint)
  segm <- seg
  for (j in 2:length(segm)){segm[[j]] <- segm[[j]][2:length(segm[[j]])]} 
  
  # recalculate distance and cumulative distance to use in the terrainCalc (incl. a linear regression)
  distance <-  distanceCalc_df(tr1er[,1], tr1er[,2])
  cumdist_2D <- cumsumCalc(segm, distance)
  terrain <- terrainCalc(cumdist_2D, tr1er[,3], seg)
  
  # create a data frame
  joined <-plyr::join(tracksCH[[i]][,c(1:3,6)],data.frame(tr1er), type="left",by=c("x", "y"))
  
  # add NA to end to get same length
  tr1er_dist2D <- c(tr1er_dist2D, NA)
  tr1er_dist3D <- c(tr1er_dist3D, NA)
  terrain2 <- rbind(terrain, NA)

  # save results in data.frame 
  tr1er_df <- (cbind(rep(id(tracksCH)[i],length(tr1er_dist2D)),joined, tr1er_dist2D, tr1er_dist3D, (tr1er_dist3D-tr1er_dist2D), terrain2[,'slope'], terrain2[,'roughness'], rep(25,length(tr1er_dist2D))))
  names(tr1er_df) <- c("id","x", "y", "date","dist", "z" , "seg", "di2D", "di3D", "didiff", "slope", "roughness", "studyarea")

  # and save result in list
  stepsCH[[i]] <- tr1er_df
}
```

Clean data

```{r}
sub_stepsCH <- NULL
for (i in 1:10){
  # remove steps more than 40' apart
  sub_stepsCH[[i]] <- stepsCH[[i]][-which(diff(stepsCH[[i]][,'date']) > 40),]
  
  # remove steps < 10m: can be GPS errors
  sub_stepsCH[[i]] <- sub_stepsCH[[i]][-which(sub_stepsCH[[i]][,"di2D"] < 15),]
}

# combine alle animals in one dataframe
sub_stepsCH_all <- rbind(sub_stepsCH[[1]], sub_stepsCH[[2]], sub_stepsCH[[3]], sub_stepsCH[[4]], sub_stepsCH[[5]], sub_stepsCH[[6]], sub_stepsCH[[7]], sub_stepsCH[[8]], sub_stepsCH[[9]], sub_stepsCH[[10]])

# plot
plot(sub_stepsCH_all$di2D,sub_stepsCH_all$didiff, ylab= "Difference (3D-2D  (m))", xlab = 'Step length 2D (m)')
plot(sub_stepsCH_all$slope,sub_stepsCH_all$didiff, ylab= "Difference (3D-2D (m))", xlab = 'Slope (degrees)')
plot(sub_stepsCH_all$roughness,sub_stepsCH_all$didiff, ylab= "Difference (3D-2D (m))", xlab = 'Roughness')
```

Calculate for every step the steplength in 3D and 2D, slope and roughness. For the German dataset. 

```{r}
stepsDE <- NULL

for (i in 1:10){

  # determine elevation and distance along profiles by linear interpolation. 
  tr1 <- cbind(x=tracksDE[[i]]$x, y= tracksDE[[i]]$y)
  tr1e <- eal_marrit(tr1, demDE)
  tr1er <- eal_marrit(tr1, demDE, step = 25)
  tr1er_dist3D <- dalw(tr1er, 3)
  tr1er_dist2D <- dalw(tr1er, 2)
  
  # calculate the right indexes of the segments
  seg <- ptseg(tr1er)
  
  # take the double index of the segments (thus not endpoint == startpoint)
  segm <- seg
  for (j in 2:length(segm)){segm[[j]] <- segm[[j]][2:length(segm[[j]])]} 
  
  # recalculate distance and cumulative distance to use in the terrainCalc (incl. a linear regression)
  distance <-  distanceCalc_df(tr1er[,1], tr1er[,2])
  cumdist_2D <- cumsumCalc(segm, distance)
  terrain <- terrainCalc(cumdist_2D, tr1er[,3], seg)
  
  # create a data frame
  joined <-cbind(tracksDE[[i]][,c(1:3,6)],tr1e[,3:4])
  
  # add NA to end to get same length
  tr1er_dist2D <- c(tr1er_dist2D, NA)
    tr1er_dist3D <- c(tr1er_dist3D, NA)
    terrain2 <- rbind(terrain, NA)
  
  # save results in data.frame 
  tr1er_df <- (cbind(rep(id(tracksDE)[i],length(tr1er_dist2D)),joined, tr1er_dist2D, tr1er_dist3D, (tr1er_dist3D-tr1er_dist2D), terrain2[,'slope'], terrain2[,'roughness'], rep(15,length(tr1er_dist2D))))
  names(tr1er_df) <- c("id","x", "y", "date","dist", "z" , "seg", "di2D", "di3D", "didiff", "slope", "roughness", "studyarea")
  
  # save result in list
  stepsDE[[i]] <- tr1er_df
}
```

Clean data

```{r}
sub_stepsDE <- NULL
for (i in 1:10){
  # remove steps more than 40' apart
  sub_stepsDE[[i]] <- stepsDE[[i]][-which(diff(stepsDE[[i]][,'date']) > 40),]
  
  # remove steps < 10m: can be GPS errors
  sub_stepsDE[[i]] <- sub_stepsDE[[i]][-which(sub_stepsDE[[i]][,"di2D"] < 15),]
}

# combine alle animals in one dataframe
sub_stepsDE_all <- rbind(sub_stepsDE[[1]], sub_stepsDE[[2]], sub_stepsDE[[3]], sub_stepsDE[[4]], sub_stepsDE[[5]], sub_stepsDE[[6]], sub_stepsDE[[7]], sub_stepsDE[[8]], sub_stepsDE[[9]], sub_stepsDE[[10]])

# plot
plot(sub_stepsDE_all$di2D,sub_stepsDE_all$didiff, ylab= "Difference (3D-2D  (m))", xlab = 'Step length 2D (m)')
plot(sub_stepsDE_all$slope,sub_stepsDE_all$didiff, ylab= "Difference (3D-2D (m))", xlab = 'Slope (degrees)')
plot(sub_stepsDE_all$roughness,sub_stepsDE_all$didiff, ylab= "Difference (3D-2D (m))", xlab = 'Roughness')
```

Combine Switzerland and Germany data

```{r}
# create one dataframe for all data, add some variables 
all <- rbind(sub_stepsCH_all, sub_stepsDE_all)
all$studyarea <- as.factor(all$studyarea)
levels(all$studyarea) <- c("Germany", "Switzerland")          # needed as for legend
all$reldiff <- all$didiff/all$di2D                            # relative difference (s3D-s2D)/s2D
all$groupRq <- floor(all$roughness)                           # idea to plot the different groups of rugosity
all$theoretical <- rep("constant slope", length(all$reldiff)) # needed as for legend
all$rugosity <- all$roughness                                 # renamed
all$Rq <- all$roughness                                       # needed as for legend
```

Finally, make the different plots!

```{r}
# different plots with ggplot
all_plot_step <- ggplot(data = all, aes(x = di2D, y = didiff, color = studyarea)) + geom_point(alpha = 0.1) + labs(x= 'Step length 2D (m)', y="Difference 2D and surface step length (m)") + guides(colour = guide_legend(override.aes = list(alpha=1)))

all_plot_slope <- ggplot(data = all, aes(x = slope, y = didiff, color = studyarea)) + geom_point(alpha = 0.1) + labs(x= 'Slope (degrees)', y="Difference 2D and surface step length (m)") + guides(colour = guide_legend(override.aes = list(alpha=1)))

all_plot_roughness <- ggplot(data = all, aes(x = roughness, y = didiff, color = studyarea)) + geom_point(alpha = 0.1) + labs(x= 'Roughness', y="Difference (surface-2D  (m))") + guides(colour = guide_legend(override.aes = list(alpha=1)))

all_rel_slope_rq <- ggplot(data = all, aes(x = slope, y = reldiff*100, color = Rq, size = theoretical)) + geom_point(alpha = 0.2) + labs(x= 'Slope (degrees)', y="Relative difference 2D and surface step length ()%") + geom_line(data = all, aes(x=slope, y = (((di2D/cos(slope*pi/180))-di2D)/di2D)*100, color = theoretical), color='black') + scale_colour_gradientn(colors=terrain.colors(10), limit = c(0,15)) + scale_x_continuous(breaks = scales::pretty_breaks(n = 13)) + scale_y_continuous(breaks = scales::pretty_breaks(n=10))

all_rel_slope_area <- ggplot(data = all, aes(x = slope, y = reldiff*100, color = studyarea, size = theoretical)) + geom_point(alpha = 0.2) + labs(x= 'Slope (degrees)', y="Relative difference 2D and surface step length (%)") + geom_line(data = all, aes(x=slope, y = (((di2D/cos(slope*pi/180))-di2D)/di2D)*100, color = theoretical), color='black') + guides(colour = guide_legend(override.aes = list(alpha=1))) + scale_x_continuous(breaks = scales::pretty_breaks(n = 13)) + scale_y_continuous(breaks = scales::pretty_breaks(n=10))

all_rel_roughness  <- ggplot(data = all, aes(x = roughness, y = reldiff*100, color = studyarea)) + geom_point(alpha = 0.1) + labs(x= 'Roughness', y="Relative difference 2D and surface step length (%)")


all_plot_step
all_plot_slope
all_plot_roughness
all_rel_slope_rq
all_rel_slope_area
all_rel_roughness
```
