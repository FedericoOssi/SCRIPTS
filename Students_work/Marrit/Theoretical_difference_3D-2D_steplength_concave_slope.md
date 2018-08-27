In this script the difference between 3D and 2D step length onconcave slopes, ranging from 0 - 60 degrees (default, but this can be changed according to other needs) is calculated as the 3D step length minus the 2D step length. Dividing the difference by the 2D step length returns the relative difference, which is the output of this script.

```{r}
library(pracma)
library(tidyr)
library(ggplot2)
```
In the following block of code the ranges of steplength 2D and slope or set. These can be modified if other ranges are needed.
```{r}
# range of steplengths in 2D
min_steplength2D <-  0
max_steplength2D <- 1000
increment_steplength2D <- 100

# range of slopes
min_slope <- 0
max_slope <- 60
increment_slope <- 0.1
```

```{r}
# sequences of steplength and slope to calculate
steplength_2D <-  seq(min_steplength2D, max_steplength2D, increment_steplength2D)
slope <- seq(min_slope, max_slope, increment_slope)

# make sure lists are empty
steplength_3D <- NULL
steplength_3D_concave <- NULL
diff_3D_2D <- NULL
diff_3D_concave <- NULL
diff_2D_concave <- NULL
x <- NULL
y <-  NULL

# define parametrized function
f <- function(t) c(t, a*t^2)
```

In the follwing block of code the actual calculations are conducted. 

```{r}
# calculate steplength in 3D and the difference between 3D-2D for every combination
for (step in steplength_2D) {
  for (angle in slope) {
    
    # concave slope = ax^2: calculate 'a' for step (x) and the angle (to determine the height (y) at x by constant slope)
    a <- (tan(angle*pi/180)*step)/(step^2)  
    
    # calculate steplength on the straight slope
    D3 <- step/cos(angle*pi/180)
    
    # calculate steplength on the concave slope
    concave <- arclength(f,0,step)$length 
    
    # append to lists
    steplength_3D <- append(steplength_3D, D3)
    steplength_3D_concave <- append(steplength_3D_concave, concave)
    
    # calculate difference
    diff_3D_2D <- append(diff_3D_2D, D3 - step)
    diff_3D_concave <- append(diff_3D_concave, concave - D3)
    diff_2D_concave <- append(diff_2D_concave, concave - step)
    
    # append step and angle to lists for plotting
    x <- append(x, step)
    y <- append(y, angle)
  }
}
```
Visualisatin difference 3D-2D step length on constant and concave slopes

```{r}
# create dataframe
th_cncv <- data.frame("slope"=y, "di2D"=x, "di3D"=steplength_3D, "di3D_cncv"=steplength_3D_concave, "didiff"=diff_3D_2D, "diff3D_cncv"=diff_3D_concave, "diff2D_cncv"=diff_2D_concave)
th_cncv$constant=th_cncv$didiff/th_cncv$di2D
th_cncv$reldiff3D_cncv=th_cncv$diff3D_cncv/th_cncv$di2D
th_cncv$concave=th_cncv$diff2D_cncv/th_cncv$di2D


th_cncv2 <- th_cncv %>% tidyr::gather(key=Type, value=rell_diff, constant, concave)

# plot
pl <- ggplot(data = th_cncv2, aes(x = slope, y = rell_diff, color = Type)) + geom_point() + labs(x= 'Slope (degrees)', y="Relative difference 3D and 2D step length") + scale_x_continuous(breaks = scales::pretty_breaks(n = 13)) + scale_y_continuous(breaks = scales::pretty_breaks(n=10))
pl
```


Visualisation with countour plots

```{r}
# matrix needed to make a contour plot (difference between steplength 3D on straight and on concave slope)
diff_3D_concave_matrix <- matrix(unlist(diff_3D_concave), ncol = (max_slope/increment_slope)+1, byrow = TRUE)
contour(steplength_2D,slope,diff_3D_concave_matrix, xlab = "steplength (m)", ylab = "constant slope (degrees)")

# difference between 2D and 3D on a concave slope
diff_2D_concave_matrix <- matrix(unlist(diff_2D_concave), ncol = (max_slope/increment_slope)+1, byrow = TRUE)
contour(steplength_2D,slope,diff_2D_concave_matrix, levels = c(10,100,1000,10000), xlab = "steplength (m)", ylab = "constant slope (degrees)")

# difference between 2D and 3D on a straight slope
diff_3D_2D_matrix <- matrix(unlist(diff_3D_2D), ncol = (max_slope/increment_slope)+1, byrow = TRUE)
contour(steplength_2D,slope,diff_2D_concave_matrix, levels = c(10,100,1000,10000), xlab = "steplength (m)", ylab = "constant slope (degrees)")
```

Now do the same but with steplengths calculated on one long concave slope (so short step lengths on a long concave slope).

```{r}
# calculate steplength in 3D and the difference between 3D-2D for every combination
for (step in steplength_2D) {
  for (angle in slope) {
    
    # concave slope = ax^2: calculate 'a' for step (x) and the angle (to determine the height (y) at x by stable slope)
    a <- (tan(angle*pi/180)*max_steplength2D)/(max_steplength2D^2)  
    
    # calculate steplength on the straight slope
    D3 <- step/cos(angle*pi/180)
    
    # calculate steplength on the concave slope
    concave <- arclength(f,0,step)$length 
    
    # append to lists
    steplength_3D <- append(steplength_3D, D3)
    steplength_3D_concave <- append(steplength_3D_concave, concave)
    
    # calculate difference
    diff_3D_2D <- append(diff_3D_2D, D3 - step)
    diff_3D_concave <- append(diff_3D_concave, concave - D3)
    diff_2D_concave <- append(diff_2D_concave, concave - step)
    
    # append step and angle to lists for plotting
    x <- append(x, step)
    y <- append(y, angle)
  }
}
```

Visualisation with contour plot

```{r}
# matrix needed to make a contour plot (difference between steplength 3D on straight and on concave slope)
diff_3D_concave_matrix <- matrix(unlist(diff_3D_concave), ncol = (max_slope/increment_slope)+1, byrow = TRUE)
contour(steplength_2D,slope,diff_3D_concave_matrix, levels = c(-10,-100,-1000,-10000,10,100,1000,10000), xlab = "steplength (m)", ylab = "constant slope (degrees)")

# difference between 2D and 3D on a concave slope
diff_2D_concave_matrix <- matrix(unlist(diff_2D_concave), ncol = (max_slope/increment_slope)+1, byrow = TRUE)
contour(steplength_2D,slope,diff_2D_concave_matrix, levels = c(10,100,1000,10000), xlab = "steplength (m)", ylab = "stable slope (degrees)")

# difference between 2D and 3D on a constant slope
diff_3D_2D_matrix <- matrix(unlist(diff_3D_2D), ncol = (max_slope/increment_slope)+1, byrow = TRUE)
contour(steplength_2D,slope,diff_2D_concave_matrix, levels = c(10,100,1000,10000), xlab = "steplength (m)", ylab = "stable slope (degrees)")
```
