#' PlotSimASAP
#'
#' Comparison plots of SSB, Freport, and Recruitment from SimASAP runs with true values.
#'
#' @param wd directory where original ASAP run is located
#' @param asap.name base name of original dat file (without the .dat extension)
#' @param whichsim vector of numbers for which simulated data sets to plot
#' @param od location where new data sets are saved (defaults to sim subdirectory of wd)
#' @param save.plots will save png files if TRUE (default = FALSE)
#' @export

PlotSimASAP <- function(wd, asap.name, whichsim, od=file.path(wd, "sim"), save.plots=FALSE){

  # check for files first
  if (!file.exists(file.path(wd, paste0(asap.name, ".rdat")))){
    return(paste0("Error: ", asap.name, ".rdat not located in ", wd))
  }

  simrdats <- FALSE
  for (isim in 1:length(whichsim)){
    if(file.exists(file.path(od, paste0(asap.name, "_sim", isim, ".rdat")))){
      simrdats <- TRUE
    }
  }
  if (simrdats == FALSE){
    return(paste0("Error: no files ", asap.dat, "_sim(whichsim).rdat located in ", od))
  }

  # get true values
  asap <- dget(file.path(wd, paste0(asap.name, ".rdat")))
  years <- seq(asap$parms$styr, asap$parms$endyr)
  nyears <- length(years)
  res <- data.frame(Source = "True",
                    metric = rep(c("SSB", "Freport", "Recruits"), each=nyears),
                    Year = rep(years, 3),
                    value = c(asap$SSB, asap$F.report, asap$N.age[,1]))

  # get simulated values
  for (isim in 1:length(whichsim)){
    mysim <- whichsim[isim]
    fname <- file.path(od, paste0(asap.name, "_sim", mysim, ".rdat"))
    if (file.exists(fname)){
      asap <- dget(fname)
      simres <- data.frame(Source = paste0("Sim", mysim),
                           metric = rep(c("SSB", "Freport", "Recruits"), each=nyears),
                           Year = rep(years, 3),
                           value = c(asap$SSB, asap$F.report, asap$N.age[,1]))
      res <- rbind(res, simres)
    }
  }

  # make plot and optionally save
  p <- ggplot(res, aes(x=Year, y=value, color=Source)) +
    geom_line() +
    geom_point(data=dplyr::filter(res, Source == "True")) +
    facet_wrap(~metric, ncol = 1, scales = "free_y") +
    expand_limits(y=0) +
    theme_bw()

  if (length(unique(res$Source)) > 5){
    p <- p + theme(legend.position = "none")
  }

  print(p)
  if (save.plots == TRUE){
    ggsave(filename = file.path(od, "comparisonplots.png"), p)
  }
  return(res)
}
