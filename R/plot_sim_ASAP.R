#' PlotSimASAP
#'
#' Comparison plots of SSB, Freport, and Recruitment from SimASAP runs with true values.
#'
#' @param wd directory where original ASAP run is located
#' @param asap.name base name of original dat file (without the .dat extension)
#' @param whichsim vector of numbers for which simulated data sets to plot
#' @param od location where new data sets are saved (defaults to sim subdirectory of wd)
#' @param asapretro logical flag for whether to add "_000" before ".rdat" when selecting files (default=FALSE)
#' @param save.plots will save png files if TRUE (default = FALSE)
#' @param returnwhat valid options are "results", "plot", "both", "nothing" (default="nothing")
#' @export

PlotSimASAP <- function(wd, asap.name, whichsim, od=file.path(wd, "sim"), asapretro=FALSE, save.plots=FALSE, returnwhat="nothing"){

  # check for valid returnwhat value
  validoptions <- c("results", "plot", "both", "nothing")
  if (!(returnwhat %in% validoptions)) {
    return(paste("Error: returnwhat must be one of:", paste(validoptions, collapse = ", ")))
  }

  # check for files
  rdat_ext <- ifelse(asapretro == FALSE, ".rdat", "_000.rdat")
  
  if (!file.exists(file.path(wd, paste0(asap.name, rdat_ext)))) {
    return(paste0("Error: ", asap.name, rdat_ext, " not located in ", wd))
  }

  simrdats <- FALSE
  for (isim in 1:length(whichsim)) {
    if(file.exists(file.path(od, paste0(asap.name, "_sim", isim, rdat_ext)))) {
      simrdats <- TRUE
    }
  }
  if (simrdats == FALSE) {
    return(paste0("Error: no files ", asap.name, "_sim(whichsim)", rdat_ext," located in ", od))
  }

  # get true values
  asap <- dget(file.path(wd, paste0(asap.name, rdat_ext)))
  years <- seq(asap$parms$styr, asap$parms$endyr)
  nyears <- length(years)
  res <- data.frame(Source = "True",
                    metric = rep(c("SSB", "Freport", "Recruits"), each=nyears),
                    Year = rep(years, 3),
                    value = c(asap$SSB, asap$F.report, asap$N.age[,1]))

  # get simulated values
  for (isim in 1:length(whichsim)) {
    mysim <- whichsim[isim]
    fname <- file.path(od, paste0(asap.name, "_sim", mysim, rdat_ext))
    if (file.exists(fname)) {
      asap <- dget(fname)
      simres <- data.frame(Source = paste0("Sim", mysim),
                           metric = rep(c("SSB", "Freport", "Recruits"), each=nyears),
                           Year = rep(years, 3),
                           value = c(asap$SSB, asap$F.report, asap$N.age[,1]))
      res <- rbind(res, simres)
    }
  }

  # make plot and optionally save
  p <- ggplot2::ggplot(res, aes(x=Year, y=value, color=Source)) +
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
    ggplot2::ggsave(filename = file.path(od, "comparisonplots.png"), p)
  }

  myreturn <- NULL
  if (returnwhat == "results"){
    myreturn <- res
  } else if (returnwhat == "plot"){
    myreturn <- p
  } else if (returnwhat == "both"){
    myreturn <- list(res = res, p = p)
  }
  return(myreturn)
}
