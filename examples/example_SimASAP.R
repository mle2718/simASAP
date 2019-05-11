# example_SimASAP.R
# walks the user through a set of examples

library("simASAP")
library("ggplot2") # shouldn't need to do this but doesn't seem to work otherwise
library("dplyr")   # shouldn't need to do this but doesn't seem to work otherwise

# first define where your original ASAP run will be located
base.dir <- "C:\\Users\\chris.legault\\Desktop\\testSimASAP"
my.asap.name <- "simplelogistic"
# assumes you have already run simASAP.dir <- find.package("simASAP")
file.copy(from = file.path(simASAP.dir, "examples", paste0(my.asap.name, ".dat")), to = base.dir)
# get ASAP from the NOAA Fisheries Toolbox and run through the GUI

# now ready to start using simASAP package
# run SimASAP with defaults to create 10 data sets
SimASAP(wd=base.dir, asap.name=my.asap.name, nsim=10)
# the C:\\Users\\chris.legault\\Desktop\\testSimASAP\\sim directory should have been created
# in this new directory open up two or more of the simplelogistic_simX.dat files
# and compare the Fleet-1 Catch Data (lines 164-184) and Index-1 and Index-2 Data (lines 281-322)
# with each other and the original run to see that they have changed
# can do this by hand or using the ReadASAP3DatFile function
datorig <- ReadASAP3DatFile(file.path(base.dir, paste0(my.asap.name, ".dat")))
datsim1 <- ReadASAP3DatFile(file.path(base.dir, "sim", paste0(my.asap.name, "_sim1.dat")))
datsim2 <- ReadASAP3DatFile(file.path(base.dir, "sim", paste0(my.asap.name, "_sim2.dat")))
rbind(datorig$dat$CAA_mats[[1]][1, ],
      datsim1$dat$CAA_mats[[1]][1, ],
      datsim2$dat$CAA_mats[[1]][1, ])
# note the original file has the catch at age in proportions (the first 10 columns),
# while the simulated files have the catch at age in numbers (which will be converted to proportions by ASAP automatically when the program is run)

# now actually run ASAP for a new set of random errors by setting runflag to TRUE
SimASAP(wd=base.dir, asap.name=my.asap.name, nsim=10, runflag=TRUE)
# the console should show the simulation number and objective function value
# it will also show when a particular simulation did not converge

# to see how the results from the simulated data compared to the true values use PlotSimASAP
PlotSimASAP(wd=base.dir, asap.name=my.asap.name, whichsim=1)
# this should produce a plot showing Freport, Recruits, and SSB over time
# comparing the True values and the estimates from the first simulated data set

# to see the results from multiple simulations change whichsim
PlotSimASAP(wd=base.dir, asap.name=my.asap.name, whichsim=c(1, 3, 5, 7))

# to see the results from all 10 simulations use whichcim=1:10
PlotSimASAP(wd=base.dir, asap.name=my.asap.name, whichsim=1:10)
# note the legend is not shown when there are more than five lines plotted
# the True values are still shown with dots

# to save the plot set save.plots to TRUE
PlotSimASAP(wd=base.dir, asap.name=my.asap.name, whichsim=1:10, save.plots=TRUE)

# can go wild examining the results, for example,
# to show just the simulations with the highest and lowest SSB in the terminal year
res <- PlotSimASAP(wd=base.dir, asap.name=my.asap.name, whichsim=1:10, returnwhat="results")
mysims <- res %>%
  filter(Year == max(Year), metric == "SSB", Source != "True") %>%
  filter(value == min(value) | value == max(value)) %>%
  mutate(simnum = substr(Source, 4, 99)) %>%
  select(simnum) %>%
  unlist(.) %>%
  as.numeric(.)
PlotSimASAP(wd=base.dir, asap.name=my.asap.name, whichsim=mysims)

# what if take away a bunch of data and crank up the CVs?
base.dir <- "C:\\Users\\chris.legault\\Desktop\\testSimASAP"
my.asap.name <- "badmodel"
file.copy(from = file.path(simASAP.dir, "examples", paste0(my.asap.name, ".dat")), to = base.dir)
# need to run badmodel.dat through ASAP GUI before continuing
SimASAP(wd=base.dir, asap.name=my.asap.name, nsim=10, runflag=TRUE)
PlotSimASAP(wd=base.dir, asap.name=my.asap.name, whichsim=1:10)

#------------------------------------------------------
# what if use the wrong M in the simulated input files?
# this is an advanced use of the package requiring more user coding
file.copy(from = file.path(base.dir, paste0(my.asap.name, ".dat")),
          to = file.path(base.dir, "wrongM.dat"))
file.copy(from = file.path(base.dir, paste0(my.asap.name, ".rdat")),
          to = file.path(base.dir, "wrongM.rdat"))

wrongM.dir <- file.path(base.dir, "sim", "wrongM")
if (!dir.exists(wrongM.dir)) dir.create(wrongM.dir)
file.copy(from = file.path(base.dir, "ASAP3.EXE"),
          to = file.path(wrongM.dir, "ASAP3.EXE"))
orig.dir <- getwd()
setwd(wrongM.dir) # unfortunately need to do this to run ASAP3

for (isim in 1:10){
  asap.dat <- ReadASAP3DatFile(file.path(base.dir, "sim", paste0(my.asap.name, "_sim", isim, ".dat")))
  asap.dat$dat$M <- asap.dat$dat$M / 2 # use M=0.15 instead of true M of 0.3
  wname <- paste0("wrongM_sim", isim)
  my.bad.name <- file.path(base.dir, "sim", "wrongM", paste0(wname, ".dat"))
  WriteASAP3DatFile(my.bad.name, asap.dat, "double true M")
  dname <- paste0(wname, ".dat")
  file.remove("asap3.rdat")
  file.remove("asap3.std")
  shell(paste("ASAP3.exe -ind", dname), intern=TRUE)
  # use presence of .std file to indicate converged run
  if (file.exists("asap3.std")){
    file.copy(from = "asap3.rdat", to =paste0(wname, ".rdat"))
    asap <- dget("asap3.rdat")
    objfxn <- asap$like$lk.total
    print(paste("simulation", isim, "complete, objective function =", objfxn))
  }else{
    print(paste("simulation", isim, "did not converge"))
  }
}
setwd(orig.dir)
wrongM.plot <- PlotSimASAP(base.dir, "wrongM", 1:10, wrongM.dir, FALSE, "plot")
wrongM.plot <- wrongM.plot + ggtitle("Wrong M (0.15 instead of 0.30) used in assessment")
ggsave(file = file.path(wrongM.dir, "wrongM.png"), wrongM.plot)

#------------------------------------------------------

# the following lines are just to copy the file into my examples directory and rename
# file.copy(from = file.path(od, "comparisonplots.png"),
#           to = paste0("./examples/comparisonplots_", my.asap.name, ".png"))
# file.copy(from = file.path(base.dir, "simplelogistic.dat"), to = "./examples")
# file.copy(from = file.path(base.dir, "badmodel.dat"), to = "./examples")
# file.copy(from = file.path(wrongM.dir, "wrongM.png"), to = "./examples")

# ###################################################################
# # took a look at a number of actual assessments to see what happens
# # all this is commented out so users don't try to do it themselves
# # included here to demonstrate how it can be done
#
# # groundfish
# # ASAP assessment input files from https://www.nefsc.noaa.gov/saw/sasi/sasi_report_options.php
# base.dir <- "C:\\Users\\chris.legault\\Desktop\\jitter_asap\\"
# gstocks <- c("gomcod", "gomhaddock", "pollock", "redfish", "snemawinter", "snemayt", "whitehake")
# nstocks <- length(gstocks)
# gname <- "base" # did not have to do this, just an easier way of running through many cases in a loop
#
# # run each model 10 times
# for (istock in 1:nstocks){
#   wd <- file.path(base.dir, gstocks[istock])
#   SimASAP(wd=wd, asap.name=gname, nsim=10, runflag=TRUE)
# }
#
# # make the plots and modify them to include stock name as title (nice feature of ggplot)
# gres <- list()
# for (istock in 1:nstocks){
#   wd <- file.path(base.dir, gstocks[istock])
#   myplot <- PlotSimASAP(wd, gname, 1:10, returnwhat="plot")
#   gres[[istock]] <- myplot + ggtitle(gstocks[istock])
# }
# # no indications of problems with any of these
#
# pdf(file=file.path(base.dir, "groundfish_comparison_plots.pdf"))
# for (istock in 1:nstocks){
#   print(gres[[istock]])
# }
# dev.off()
# file.copy(from=file.path(base.dir, "groundfish_comparison_plots.pdf"), to="./examples")
#

