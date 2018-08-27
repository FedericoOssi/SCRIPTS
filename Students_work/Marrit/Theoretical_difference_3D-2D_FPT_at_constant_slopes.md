
In this script the difference between 3D and 2D FPT on a constant slope is calculated. This is done for radius of FPT circles ranging from 50 to 700m and slopes ranging from 0 to 60 degrees. However, this can be changed according to other needs. The difference is calculated by subtracting the 2D FPT from the 3D FPT. 
In this script the FPT3D is the circle and FPT2D is the ellipse. However, it might be better to do it the other way around and make the FPT3D the ellipse and the FPT2D the circle. In that case, calculate the second radius in line 201 with ```radi*cos(angle*pi/180)``` in stead of dividing the radius with the cosinus. 

```{r}
library(adehabitatLT)
library(spatstat)
library(maptools)
library(rgeos)
```

These variables can be changed according to the ranges you want to investigate

```{r}
# variables
starttime <- ISOdatetime(2018,1,1,0,0,0)
steps <- 100
timelag <- 30    # in minutes
n_simulations <- 250

# range of radius
min_radius <-  50
max_radius <- 700
increment_radius <- 10

# range of slopes
min_slope <- 0
max_slope <- 60
increment_slope <- 5
```

Load the functions that are needed in this script

```{r}
# load functions
passingFun <- function(trajectory, enclosure){
  # function to find step where a trajectory crosses an enclosed area 
  #
  # args:
  #   trajectory: trajectory of class ltraj
  #   enclosure: spatial lines data frame enclosing an area
  #
  # returns:
  #   passing: object with the points before and after passing and the step in which enclosure is passed
  
  points_out <- which(!point.in.polygon(trajectory[[1]]$x, trajectory[[1]]$y, enclosure$x, enclosure$y))
  
  # if there are no points outside the enclosure, return NULL
  if(length(points_out) == 0){
    return(NULL)
  }
  
  # find the minimum of all points outside the polygon
  minimum <- min(points_out)
  
  # find both coordinates from first point outside enclosure and last point before and the assosiated time
  index <- minimum
  x <- trajectory[[1]]$x[index]
  y <- trajectory[[1]]$y[index]
  time <- trajectory[[1]]$date[index]
  first_out <- list(index, x, y, time)
  names(first_out) <- c("index","x", "y", "time")
  
  index <- minimum-1
  x <- trajectory[[1]]$x[index]
  y <- trajectory[[1]]$y[index]
  time <- trajectory[[1]]$date[index]
  last_in <- list(index, x, y, time)
  names(last_in) <- c("index","x","y", "time")

  # make a spatial Line of passing step
  L <- Line(cbind(c(last_in$x, first_out$x), c(last_in$y, first_out$y)))
  L_l = Lines(list(L), ID="L")
  step = SpatialLines(list(L_l))
  
  # save everything in one object
  passing <- list(first_out, last_in, step)
  names(passing) <- c("first_out", "last_in", "step")
  
  # return
  return(passing)
}

findIntersectFun <- function(trajectory, passingStep, enclosure_sl, timelag){
  # function to find the specific intersection point
  #
  # args:
  #   trajectory: trajectory of class ltraj
  #   passingStep: object with passingstep (obtained from passingFun)
  #   enclosure_sl: spatial lines data frame enclosing an area
  #   timelag: interval between the trajectory steps
  #
  # return: 
  #   first intersecting point between enclosed area and the trajectory
  
  # make spatial lines df of trajectory
  trajectory_sldf <- ltraj2sldf(trajectory)
  
  # find the intersecting points
  intersects <- gIntersection(enclosure_sl, trajectory_sldf)
  
  # find the first intersection
  intersects_buff <- gBuffer(intersects, width=0.001)
  intersect_line <- gIntersection(passingStep$step, intersects_buff)
  intersect_point <- getSpatialLinesMidPoints(intersect_line)
  index_first_intersect <- match(round(intersect_point$x, digits = 2), round(intersects$x, digits = 2))[1]
  if(is.na(index_first_intersect)){
    index_first_intersect <- match(round(intersect_point$y, digits = 2), round(intersects$y, digits = 2))[1]
  }
  
  # save the coordinates of the first intersection
  x_first_intersect <- intersects$x[index_first_intersect]
  y_first_intersect <- intersects$y[index_first_intersect]
  
  # calculate length of lines
  length_in <- lineLengthFun(passingStep$last_in$x, x_first_intersect, passingStep$last_in$y, y_first_intersect)
  length_tot <- lineLengthFun(passingStep$last_in$x,passingStep$first_out$x , passingStep$last_in$y, passingStep$first_out$y)
  
  # calculate the proportion of the line to the intersect to the total step and time associated to that proportion
  proportion <- length_in/length_tot
  minutes <- (proportion * timelag)
  time_crossing <- as.POSIXct(minutes*60, origin = passingStep$last_in$time)
  
  # make object to return
  first_intersect <- list(index_first_intersect, x_first_intersect, y_first_intersect, time_crossing)
  names(first_intersect) <- c("index", "x", "y", "time")
  
  return(first_intersect)
  
}

lineLengthFun <- function(x_coordinate1, x_coordinate2, y_coordinate1, y_coordinate2){
  # function to calculate the length of a straigt line based on the coordinates
  #
  # args:
  #   x_coordinate1: x coordinate of first point
  #   x_coordinate2: x coordinate of last point of straight line
  #   y_coordinate1: y coordinate of first point
  #   y_coordinate2: y coordiante of last point of straight line
  #
  # return:
  #   length of line

  # calculate the length of the x displacement    
  x_length <- abs(max(x_coordinate1,x_coordinate2) - min(x_coordinate1,x_coordinate2))
  
  # calculate the length of the y displacement  
  y_length <- abs(max(y_coordinate1,y_coordinate2) - min(y_coordinate1,y_coordinate2))
  
  # calculate the Euclidean distance between the two endpoints of the line
  Eucledian_length <- sqrt(x_length^2 + y_length^2)
  
  return(Eucledian_length)
}

```

In this block the other variables and parameters that should not be changed are created.

```{r}
# setting up datetime vector
date_seq <- seq(from = starttime, by = paste(timelag, "min"), length.out = steps)

# sequences of steplength and slope to calculate
radius <-  seq(min_radius, max_radius, increment_radius)
slope <- seq(min_slope, max_slope, increment_slope)

# empty lists
FPT_list3D <- NULL
FPT_list2D <- NULL
FPT_list_diff <- NULL
FPT_mean_diff <- NULL
FPT_min_diff <- NULL
FPT_max_diff <- NULL
x <- NULL
y <- NULL
count3D_list <- NULL
count2D_list <- NULL
count3D <- 0
count2D <- 0

# create seeds
seeds <- sample(1:100000000, n_simulations, replace=FALSE)
```

Here the actual calculations find place.

```{r}
# running simulations and calculations
for (radi in radius) {
  for (angle in slope) { 
    for (n in 1:n_simulations){
      set.seed(seeds[n])
      
      # create circle with specific radius
      circle <- ellipse(radi,radi, centre = c(0,0))
      circle_sp <- as(circle, "SpatialPolygons")
      circle_sl <- as(circle_sp, "SpatialLines")
    
      # create ellipse with specific radius and slope
      ellipse <- ellipse(radi,radi/cos(angle*pi/180), centre = c(0,0))
      ellipse_sp <- as(ellipse, "SpatialPolygons")
      ellipse_sl <- as(ellipse_sp, "SpatialLines")
      
      # simulate random walk
      random_walk <- simm.crw(date_seq, r = 0, burst = "RW r = 0")
      
      # cast to spatial lines data frame for later use
      random_walk_sldf <- ltraj2sldf(random_walk)
      
      # find out where the trajectory passes the circle or ellipse
      passing3D <- passingFun(random_walk, circle$bdry[[1]])
      passing2D <- passingFun(random_walk, ellipse$bdry[[1]])
      
      if (!is.null(passing3D)){
        count3D <- count3D + 1
        
        # find the first intersection
        intersection3D <- findIntersectFun(random_walk, passing3D, circle_sl, timelag)
        
        # calculate first passage time
        FPT3D <- as.numeric(difftime(intersection3D$time, starttime, units = "hours"))
        FPT_list3D <- append(FPT_list3D, FPT3D)
      }
      
      if (!is.null(passing2D)){
        count2D <- count2D + 1
        
        # find the first intersection
        intersection2D <- findIntersectFun(random_walk, passing2D, ellipse_sl, timelag)
        
        # calculate first passage time
        FPT2D <- as.numeric(difftime(intersection2D$time, starttime, units = "hours"))
        FPT_list2D <- append(FPT_list2D, FPT2D)
      }
      
      if (!is.null(passing2D) && !is.null(passing3D)){
        
        # calculate difference between 2D and 3D FPT
        diff_FPT <- FPT3D - FPT2D
        FPT_list_diff <- append(FPT_list_diff, diff_FPT)
        
        # save if this is the largest difference
        if(max(FPT_list_diff) == diff_FPT){
          largest_diff <- diff_FPT
          largest_traj <- random_walk
          largest_intersect3D <- intersection3D
          largest_intersect2D <- intersection2D
          largest_passing3D <- passing3D
          largest_passing2D <- passing2D
        }
        
        # save if this is the smallest difference
        if(min(FPT_list_diff) == diff_FPT){
          smallest_diff <- diff_FPT
          smallest_traj <- random_walk
          smallest_intersect3D <- intersection3D
          smallest_intersect2D <- intersection2D
          smallest_passing3D <- passing3D
          smallest_passing2D <- passing2D
        }
      }
    }
     # add values to a lists for plotting
    if(!is.null(FPT_list_diff)){
      FPT_mean_diff <- append(FPT_mean_diff, mean(FPT_list_diff))
      FPT_min_diff <- append(FPT_min_diff, min(FPT_list_diff))
      FPT_max_diff <- append(FPT_max_diff, max(FPT_list_diff))
      x <- append(x, radi)
      y <- append(y, angle)
    }
    # keep track of how many times the trajectory does not cross the FPT circle
    count2D_list <- append(count2D_list, count2D)
    count3D_list <- append(count3D_list, count3D)
  
    # set list to NULL again
    FPT_list_diff <- NULL
    
    # set counts to 0
    count3D <- 0
    count2D <- 0
  }
}
```

Plot!

```{r}
# create dataframe
th_FPT <- data.frame("slope"=y, "radius"=x, "FPTdiff"=FPT_mean_diff)
th_FPT$rel_diff=th_FPT$FPTdiff/th_FPT$radius

# plot
pl <- ggplot(data = th_FPT, aes(x = slope, y = FPTdiff, color = radius)) + geom_point() + labs(x= 'Slope (degrees)', y="Difference 3D and 2D FPT (h)") + scale_x_continuous(breaks = scales::pretty_breaks(n=12), limit=c(0,60)) + scale_y_continuous(breaks = scales::pretty_breaks(n=7), limit=c(0,14)) + scale_colour_gradientn(colors=terrain.colors(10), limit=c(0,700))
pl

```


Visualise with 3D plot, quick and dirty.

```{r}
# set up plot
axx <- list(title = "radius (m)")

axy <- list(title = "slope (degrees)")

axz <- list(title = "difference 3D and 2D FPT (hours)")

# plot
p <- plot_ly(x = x, y = y, z = FPT_mean_diff, type = 'mesh3d')%>%
  layout(scene = list(xaxis = axx, yaxis = axy, zaxis = axz))
p
```
Visualise with contour plot

```{r}
FPT_diff_matrix <- matrix(unlist(FPT_mean_diff), ncol = (max_slope/increment_slope)+1, byrow = TRUE)
contour(radius,slope,FPT_diff_matrix, main = "Difference between 3D and 2D FPT", xlab = "radius (m)", ylab = "slope (degrees)")

```

Print the mean, minimum, maximum 

```{r}
# statistics FPT
paste("mean 3D FPT:", round(mean(FPT_list3D), digits = 2), "hours")
paste("minimum 3D FPT:", round(min(FPT_list3D), digits = 2), "hours")
paste("maximum 3D FPT:", round(max(FPT_list3D), digits = 2), "hours")

paste("mean 2D FPT:", round(mean(FPT_list2D), digits = 2), "hours")
paste("minimum 2D FPT:", round(min(FPT_list2D), digits = 2), "hours")
paste("maximum 2D FPT", round(max(FPT_list2D), digits = 2), "hours")

paste("mean 2D and 3D difference in FPT", round(mean(FPT_mean_diff), digits = 2), "hours")
paste("minimum 2D and 3D difference in FPT", round(min(FPT_min_diff)*3600, digits = 2), "seconds")
paste("maximum 2D and 3D difference in FPT", round(max(FPT_max_diff), digits = 2), "hours")
```

Show smallest and largest difference between 2D and 3D FPT in graphs

```{r}
# plot trajectory with smallest difference 2D and 3D FPT
plot(smallest_traj, addpoints = FALSE, xlim = c(-1000,1000), main = paste("Smallest difference 2D and 3D FPT: ", round(smallest_diff*3600, digits = 2), " seconds"))
points(smallest_intersect2D$x , smallest_intersect2D$y, col='green')
points(smallest_intersect3D$x, smallest_intersect3D$y, col = 'orange')
lines(circle_sl)
lines(ellipse_sl)
legend('topright',legend = c(smallest_intersect2D$time, smallest_intersect3D$time), lty=1, col = c('green', 'orange'))

# plot trajectory with largest difference 2D and 3D FPT
plot(largest_traj, addpoints = FALSE, xlim = c(-1000,1000), main = paste("Largest difference 2D and 3D FPT: ", round(largest_diff, digits = 2), " hours"))
points(largest_intersect2D$x, largest_intersect2D$y, col='green')
points(largest_intersect3D$x, largest_intersect3D$y, col = 'orange')
lines(circle_sl)
lines(ellipse_sl)
legend('topright',legend = c(largest_intersect2D$time, largest_intersect3D$time), lty=1, col = c('green', 'orange'))
```
