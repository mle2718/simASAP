# simASAP
Simulate ASAP data sets and optionally run them.

This package allows the user to create, and optionally run, ASAP data sets in a manner similar to the simulate approach used in TMB. An original ASAP run provides the True values as the predicted catch and indices. The CV in the original input file is used to generate a random realization from a lognormal distribution and applied to the predicted values of total catch in weight and the index observations. The input effective sample size is used to create a random realization from the multinomial distribution using the catch at age and indices at age. All other inputs remain at the values in the original ASAP file. This allows the user to easily conduct self-tests of the model, meaning, can the model accurately estimate the true values given the input level of uncertainty in the catch and indices and the model formulation selected. The outputs used for comparison are Freport, recruitment, and spawning stock biomass time series. The examples directory contains an R script that walks the user through using the functions. This script can also be accessed by

```
library(simASAP)
simASAP.dir <- find.package("simASAP")
# replace my directory with one on your computer that you want to use
my.dir <- "C:\\Users\\chris.legault\\Desktop\\testSimASAP" 
file.copy(from = file.path(simASAP.dir, "example_SimASAP.R"), to = my.dir)
```

