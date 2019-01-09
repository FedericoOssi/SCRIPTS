jpeg("multiple_plots.jpg")

  par(mfrow=c(2,1))
  hist(plot_1)
  hist(plot_2)
  
dev.off()
