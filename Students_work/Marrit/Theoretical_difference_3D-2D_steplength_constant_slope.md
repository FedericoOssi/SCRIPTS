
In this script the difference between 3D and 2D step length on a constant slope is calculated. This is done for 2D step lengths ranging from 0 to 1000m and slopes ranging from 0 to 60 degrees. However, this can be changed according to other needs. The difference is calculated by subtracting the 2D step length from the 3D step length. Dividing by the 2D step length results in the relative difference (proportional change in step lenght).

```
library(ggplot2)
```

Change these variables if other ranges are needed. 

```
# range of step lengths in 2D
min_steplength2D <-  0
max_steplength2D <- 1000
increment_steplength2D <- 100

# range of slopes
min_slope <- 0
max_slope <- 60
increment_slope <- 0.1

# sequences of step length and slope to calculate
steplength_2D <-  seq(min_steplength2D, max_steplength2D, increment_steplength2D)
slope <- seq(min_slope, max_slope, increment_slope)

# make sure lists are empty
steplength_3D <- NULL
diff_3D_2D <- NULL
x <- NULL
y <-  NULL
```

In the following block of code the actual calculations are conducted. 

```R
# calculate steplength in 3D and the difference between 3D-2D for every combination
for (step in steplength_2D) {
  for (angle in slope) {
    D3 <- step/cos(angle*pi/180)
    steplength_3D <- append(steplength_3D, D3)
    diff <- D3 - step
    diff_3D_2D <- append(diff_3D_2D, diff)
    
    # append step and angle to lists for plotting
    x <- append(x, step)
    y <- append(y, angle)
  }
}
```

Plot the relative difference.

```
# create dataframe
th_slope <- data.frame("slope"=y, "di2D"=x, "di3D"=steplength_3D, "didiff"=diff_3D_2D)
th_slope$reldiff=th_slope$didiff/th_slope$di2D

# plot
pl <- ggplot() + geom_point(data = th_slope, aes(x=slope, y = reldiff*100)) + labs(x= 'Slope (degrees)', y="Relative difference 3D and 2D step length (%)") + scale_x_continuous(breaks = scales::pretty_breaks(n = 13)) + scale_y_continuous(breaks = scales::pretty_breaks(n=10))
pl
```
