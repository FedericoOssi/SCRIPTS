## Save multiple plots in R as image

getwd()
setwd("~/your_working_directory")

# First open the Graphics device
jpeg("multiple_plots.jpg",  # It works also with the functions png(), bmp() & tiff()
      width = 1920, height = 1080, # fullHD size
      pointsize = 25, # size of the plotted text
      quality = 100 # as a percentage, only for jpeg()
    ) 

# Then call the function for generating the plots 
  par(mfrow=c(2,1))
  hist("plot_1")
  hist("plot_2")
 
# Finally, close the Graphics device
dev.off()

# The image with the plots is now saved in your working directory #
