# example_SimASAP.R
# walks the user through a set of examples

library("simASAP")
library("ggplot2") # shouldn't need to do this but doesn't seem to work otherwise

# first define where your original ASAP run is located
base.dir <- "C:\\Users\\chris.legault\\Desktop\\testSimASAP"
my.asap.name <- "simplelogistic"

# run simASAP with defaults to create 10 data sets
SimASAP(wd=base.dir, asap.name=my.asap.name, nsim=10)
# the C:\\Users\\chris.legault\\Desktop\\testSimASAP\\sim directory should have been created
# in this new directory open up two or more of the simplelogistic_simX.dat files
# and compare the Fleet-1 Catch Data (lines 164-184) and Index-1 and Index-2 Data (lines 281-322)
# with each other and the original run to see that they have changed
# can do this by hand or using the ReadASAP3DatFile function
datorig <- ReadASAP3DatFile(file.path(base.dir, paste0(my.asap.name, ".dat")))
od <- file.path(base.dir, "sim")
datsim1 <- ReadASAP3DatFile(file.path(od, paste0(my.asap.name, "_sim1.dat")))
datsim2 <- ReadASAP3DatFile(file.path(od, paste0(my.asap.name, "_sim2.dat")))
rbind(datorig$dat$CAA_mats[[1]][1, ],
      datsim1$dat$CAA_mats[[1]][1, ],
      datsim2$dat$CAA_mats[[1]][1, ])
# note the original file has the catch at age in proportions (the first 10 columns),
# while the simulated files have the catch at age in numbers (which will be converted to proportions by ASAP automatically when the program is run)

# now actually run ASAP for a new set of random errors
SimASAP(wd=base.dir, asap.name=my.asap.name, nsim=10, runflag=FALSE)
