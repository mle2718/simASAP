#' SimASAP
#'
#' Generate a number of ASAP data sets with observation error from one already run and optionally run them.
#' @param wd directory where original ASAP run is located
#' @param asap.name base name of original dat file (without the .dat extension)
#' @param nsim number of simulated data sets to create
#' @param od location where new data sets are saved (defaults to sim subdirectory of wd)
#' @param runflag flag to run ASAP on new data sets (TRUE) or not (FALSE) (default = FALSE)
#' @export

SimASAP <- function(wd, asap.name, nsim, od=file.path(wd, "sim"), runflag=FALSE){

  # error checks for missing files
  if (!file.exists(file.path(wd, paste0(asap.name, ".dat")))){
    return(paste0("Error: ", asap.name, ".dat not located in ", wd))
  }

  if (!file.exists(file.path(wd, paste0(asap.name, ".rdat")))){
    return(paste0("Error: ", asap.name, ".rdat not located in ", wd))
  }

  if (runflag == TRUE & !file.exists(file.path(wd, "ASAP3.exe"))){
    return(paste0("Error: ASAP3.exe not located in ", wd))
  }

  if (!dir.exists(od)){
    dir.create(od)
  }

  # get the dat and rdat files
  asap.dat <- ReadASAP3DatFile(file.path(wd, paste0(asap.name, ".dat")))
  asap <- dget(file.path(wd, paste0(asap.name, ".rdat")))

  # begin simulation loop to create data sets
  for (isim in 1:nsim){

    sim.dat <- asap.dat

    # handle each fleet one at a time
    for (ifleet in 1:asap$parms$nfleets){

      # generate new total catch observations
      ctotfleet <- asap$catch.pred[ifleet, ]
      sigma <- sqrt(log(1 + asap$control.parms$catch.tot.cv[, ifleet] ^ 2))
      randomval <- stats::rnorm(length(ctotfleet))
      ctotnew <- ctotfleet * exp(randomval * sigma)

      # generate new catch at age proportions
      myval <- (ifleet - 1) * 4 + 2 # obs and pred for catch and discards for each fleet, catch pred 2nd
      caafleet <- asap$catch.comp.mats[[myval]]
      caanew <- caafleet
      ess <- asap$fleet.catch.Neff.init[ifleet, ]
      for (icount in 1:length(ess)){
        if (ess[icount] > 0){
          sumcaa <- sum(caafleet[icount, ])
          if (sumcaa > 0){
            myprob <- caafleet[icount, ] / sumcaa
            caanew[icount, ] <- rmultinom(1, ess[icount], prob=myprob)
          } else {
            caanew[icount, ] <- rep(0, length(caafleet[icount, ]))
          }
        }
      }

      # put new values into sim.dat object
      sim.dat$dat$CAA_mats[[ifleet]] <- cbind(caanew, ctotnew)
    }

    #--------------------------------
    # handle each index one at a time
    for (ind in 1:asap$parms$nindices){

      iaa_mat <- asap.dat$dat$IAA_mats[[ind]]
      sim_mat <- iaa_mat

      # generate new index observations, only replace positive values
      indval <- iaa_mat[,2]
      sigma <- sqrt(log(1 + iaa_mat[,3] ^ 2))
      for (icount in 1:length(indval)){
        if (indval[icount] > 0){
          randomval <- stats::rnorm(1)
          sim_mat[icount, 2] <- indval[icount] * exp(randomval * sigma[icount])
        }
      }

      # generate new index at age proportions for years with ess > 0
      ess <- iaa_mat[, (asap$parms$nages + 4)]
      mycols <- seq(4, (length(iaa_mat[1,]) - 1))
      for (icount in 1:length(ess)){
        if (ess[icount] > 0){
          iaavals <- iaa_mat[icount, mycols]
          sumiaavals <- sum(iaavals)
          if (sumiaavals > 0){
            myprob <- iaavals / sumiaavals
            sim_mat[icount, mycols] <- rmultinom(1, ess[icount], prob=myprob)
          }
        }
      }

      # put into sim.dat object
      sim.dat$dat$IAA_mats[[ind]] <- sim_mat
    }

    #--------------------------
    # write this simulated data
    fname <- file.path(od, paste0(asap.name, "_sim", isim, ".dat"))
    header.text <- "File created with SimASAP"
    WriteASAP3DatFile(fname,sim.dat,header.text)

  } # end of isim data file creation loop

  #-----------------------------------
  # optionally run all the simulations
  if (runflag == TRUE){
    file.copy(from = file.path(wd, "ASAP3.EXE"), to = od, overwrite = FALSE)
    orig.dir <- getwd()
    setwd(od)

    for (isim in 1:nsim){
      sname <- paste0(asap.name, "_sim", isim)
      dname <- paste0(sname, ".dat")
      shell("del asap3.rdat", intern = TRUE)
      shell("del asap3.std", intern = TRUE)
      shell(paste("ASAP3.exe -ind", dname), intern=TRUE)
      # use presence of .std file to indicate converged run
      if (file.exists("asap3.std")){
        shell(paste("copy asap3.rdat", paste0(sname, ".rdat")), intern=TRUE)
        asap <- dget("asap3.rdat")
        objfxn <- asap$like$lk.total
        print(paste("simulation", isim, "complete, objective function =", objfxn))
      }else{
        print(paste("simulation", isim, "did not converge"))
      }
    }
    setwd(orig.dir)
  }

  return("OK")
}
