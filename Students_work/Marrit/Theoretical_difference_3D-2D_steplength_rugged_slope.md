In this script the difference between 2D and 3D steplength on a rugged slope is calculated. This is done by generating a number of simulated profiles  (default 1000, but this can be changed according to other needs) and calculate the step length by following these slopes (3D) and a flat surface (2D). the difference is calculated by subtracting the 2D step length from the 3D step length and dividing this difference by the 2D step length results in the relative difference (*100 makes thus %).  

```{r}
library(zoo)
library(sp)
```

Change the ranges to your needs. 

```{r}
# range of step lengths in 2D
min_steplength2D <-  0
max_steplength2D <- 1000
increment_steplength2D <- 100

# other variables
Sd <- 20
mean <- 0
n_simulations <- 1000
moving_avg <- 300
resolution <- 1
```

Create sequences and empty lists that you need in the rest of the script. 

```{r}
# sequence of step lengths
steplength_2D <-  seq(min_steplength2D, max_steplength2D, increment_steplength2D)
max_range_steplength <- max_steplength2D + moving_avg

# empty lists
dist <- NULL
slope <- NULL
di2D <- NULL
di3D_rgh <- NULL
Rq <- NULL 
Rqgroup <- NULL
```

Function used in this script

```{r}
distanceCalc <- function(profile_vector){
  # function to calculate the distance between every point on a line
  #
  # args:
  #   profile_vector: a vector with elevation at every point along the line
  #   Uses also max_range_steplength, moving_avg and resolution from the main script
  #
  # returns:
  #   dist: vector with the distance between every point on the line
  
  dist[[1]] <- 0
  for (k in 2:(max_range_steplength-moving_avg+1)){
    dist[[k]] <- sqrt((profile_vector[k]-profile_vector[k-1])^2 + resolution^2)
  }
  return(dist)
}

```

In this block the profiles are created and the slope, rugosity, 2D and 3D step lengths are calculated. 

```{r}
# create elevation profiles
for (j in 1:n_simulations){
  Rq1 <- Sd
  x <- numeric(max_range_steplength)
  x[1] <- mean
  x[2] <- rnorm(1, x[1], Rq1)
  x[3] <- rnorm(1, (x[2]+x[1])/2, Rq1)
  for( i in 4:max_range_steplength ) {
    x[i] <- rnorm(1, (x[i-1]+x[i-2]+x[i-3])/3, Sd)
  }
  
  # take the moving average
  profile <- rollmean(x, moving_avg)
  
  # do a linear regression for different step lengths
  for (step in steplength_2D){
    di2D <- append(di2D, step)
    
    time = (1:(step))
    reg_lin = lm(profile[1:step+1]~time)
    
    # find slope
    slope <- append(slope, abs(atan(reg_lin$coefficients[2])/pi*180))
  
    # find Rq through the residuals as the profile 
    residuals <-  resid(reg_lin)
    Rq <- append(Rq, sd(residuals))
    Rqgroup <- append(Rqgroup, floor(sd(residuals)))
    
    # calcualte distance for the profile and save in matrix
    dist <- distanceCalc(profile[1:step+1])
    cum_dist <- cumsum(dist)
    if (step == 0){di3D_rgh <- append(di3D_rgh, 0)}
    else{di3D_rgh <- append(di3D_rgh, cum_dist[step])}
  }
}
```

Finally, the results are plotted.

```{r}
# create a data frame with all variables
th_rgh <- data.frame("slope"=slope, "di2D"=di2D, "di3D_rgh"=di3D_rgh, "Rq"=Rq, "Rqgroup"=Rqgroup)
th_rgh$di3D <- th_rgh$di2D/cos(slope*pi/180)
th_rgh$didiff <- th_rgh$di3D-th_rgh$di2D
th_rgh$constant=th_rgh$didiff/th_rgh$di2D
th_rgh$diff2D_rgh <- th_rgh$di3D_rgh - th_rgh$di2D
th_rgh$diff3D_rgh <- th_rgh$di3D_rgh - th_rgh$di3D
th_rgh$reldiff3D_rgh <- th_rgh$diff3D_rgh/th_rgh$di2D
th_rgh$rugosity <- th_rgh$diff2D_rgh/th_rgh$di2D
th_rgh$constant_slope <- rep("constant slope", length(th_rgh$rugosity))

# remove slopes steeper than 60 degrees
th_rgh <- th_rgh[-which(th_rgh$slope>60),]

# sequenses needed for plotting
x = seq(0, 60, 0.1)
y = (((1000/cos(seq(0, 60, 0.1)*pi/180))-1000)/1000)
df = data.frame(slope = x, rugosity=y, constant_slope=rep("constant slope", length(x)))

# plot
pl <- ggplot(data = th_rgh, aes(x = slope, y = rugosity*100, color = Rq, size = constant_slope)) + geom_point(alpha = 0.2) + labs(x= 'Slope (degrees)', y="Relative difference 2D and surface step length (%)") + scale_x_continuous(breaks = scales::pretty_breaks(n = 13)) + scale_y_continuous(breaks = scales::pretty_breaks(n=10)) + geom_line(data = df, aes(x=slope, y=rugosity*100, color = constant_slope), color='black') + scale_colour_gradientn(colors=terrain.colors(10), limit = c(0,60))
pl
``` 
