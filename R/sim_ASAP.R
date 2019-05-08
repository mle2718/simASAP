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

    # generate new total catch observations

    # generate new catch at age proportions

    # generate new aggregate index observations

    # generate new index at age proportions

    # write this simulated data
    fname <- file.path(od, paste0(asap.name, "_sim", isim, ".dat"))
    header.text <- "File created with SimASAP"
    WriteASAP3DatFile(fname,sim.dat,header.text)

  }

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
