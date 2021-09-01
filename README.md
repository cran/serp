
<!-- README.md is generated from README.Rmd. Please edit that file -->

# serp <img src='man/figures/hex_logo.png' align="right" height="105" />

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being
activelydeveloped](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Codecov test
coverage](https://codecov.io/gh/ejikeugba/serp/branch/master/graph/badge.svg)](https://codecov.io/gh/ejikeugba/serp?branch=master)
[![Total
Downloads](http://cranlogs.r-pkg.org/badges/grand-total/serp)](https://CRAN.R-project.org/package=serp)
[![CRAN
status](https://www.r-pkg.org/badges/version/serp)](https://CRAN.R-project.org/package=serp)
[![license](https://img.shields.io/badge/license-GPL--2-blue.svg)](https://www.gnu.org/licenses/gpl-2.0.en.html)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/ejikeugba/serp?branch=master&svg=true)](https://ci.appveyor.com/project/ejikeugba/serp)
[![R build
status](https://github.com/ejikeugba/serp/workflows/R-CMD-check/badge.svg)](https://github.com/ejikeugba/serp/actions)
[![status](https://joss.theoj.org/papers/6ebd3b75ea792be908f0dadebd7cf81c/status.svg)](https://joss.theoj.org/papers/6ebd3b75ea792be908f0dadebd7cf81c)
<!-- badges: end -->

Smooth Effects on Response Penalty for CLM

A regularization method for the cumulative link models (CLM). The ‘serp’
function applies the ‘smooth-effect-on-response penalty’ (SERP) on the
estimates of the general CLM, causing all subject-specific effects
associated with each variable in the model to shrink towards a unique
global effect. Fitting is done using a modified Newton’s method. Several
standard model performance and descriptive methods are also available.
See [Ugba et al., 2021](https://doi.org/10.3390/stats4030037) and [Tutz
and Gertheiss, 2016](https://doi.org/10.1177/1471082X16642560) for more
details.

## Example

Consider the cumulative logit model of the wine dataset, where the
rating of wine bitterness is predicted with the two treatment factors,
temperature and contact.

``` r
## The unpenalized non-proportional odds model returns unbounded estimates, hence,
## not fully identifiable.
f1 <- serp(rating ~ temp + contact, slope = "unparallel",
           reverse = TRUE, link = "logit", data = wine)
coef(f1)
```

``` r
## The penalized non-proportional odds model with a user-supplied lambda gives 
## a fully identified model with bounded estimates. A suitable tuning criterion
## could as well be used to select lambda (e.g., cv) 
f2 <- serp(rating ~ temp + contact, slope = "penalize",
           link = "logit", reverse = TRUE, tuneMethod = "user",
           lambda = 1e1 ,data = wine)
coef(f2)
```

``` r
## A penalized partial proportional odds model with one variable set to 
## global effect is also possible.
f3 <- serp(rating ~ temp + contact, slope = "penalize",
           reverse = TRUE, link = "logit", tuneMethod = "user",
           lambda = 2e1, globalEff = ~ temp, data = wine)
coef(f3)
```

``` r
## The unpenalized proportional odds model with constrained estimates. Using a 
## very strong lambda in f2 will result in estimates equal to estimates in f4.
f4 <-  serp(rating ~ temp + contact, slope = "parallel",
            reverse = FALSE, link = "logit", data = wine)
summary(f4)
```

## Installation:

The released version of serp can be installed from
[CRAN](https://cran.r-project.org/package=serp) with:

``` r
install.packages("serp")
```

or the development version from
[GitHub](https://github.com/ejikeugba/serp) with:

``` r
# install.packages("devtools")
devtools::install_github("ejikeugba/serp")
```

## Loading:

``` r
library(serp)
```

## References:

Ugba, E. R., Mörlein, D. and Gertheiss, J. (2021). Smoothing in Ordinal
Regression: An Application to Sensory Data. *Stats*, 4, 616–633.
<https://doi.org/10.3390/stats4030037>

Tutz, G. and Gertheiss, J. (2016). Regularized Regression for
Categorical Data (With Discussion and Rejoinder). *Statistical
Modelling*, 16, 161-260. <https://doi.org/10.1177/1471082X16642560>
