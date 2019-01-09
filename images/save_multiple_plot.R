## Save multiple plots in R as image

jpeg("multiple_plots.jpg",  # It works also with the functions png(), bmp(), tiff()
      width = 1920,
      height = 1080,
      pointsize = 25, # size of the plotted text
      quality = 100 # percentage, only for jpeg()
    ) 

  par(mfrow=c(2,1))
  hist("plot_1")
  hist("plot_2")
  
dev.off()
