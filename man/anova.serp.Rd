% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/serp.anova.R
\name{anova.serp}
\alias{anova.serp}
\title{ANOVA method for an object of class 'serp'}
\usage{
\method{anova}{serp}(object, ..., test = c("Chisq", "none"))
}
\arguments{
\item{object}{An object of class 'serp'.}

\item{...}{additional arguments.}

\item{test}{type of test to be conducted.}
}
\value{
An ANOVA table with the following components:
\describe{
  \item{model}{the respective model aliases.}
  \item{no.par}{the no of parameters in the model.}
  \item{AIC}{the akaike information criterion.}
  \item{logLik}{the realized log-likelihood.}
  \item{Test}{the different pair(s) of test(s) conducted.}
  \item{LR.stat}{the computed Likelihood ratio statistic.}
  \item{df}{the degree of freedom.}
  \item{Pr(chi)}{the p-value of test statitic.}
}
}
\description{
Provides an ANOVA table for comparing two or more 'serp' objects.
}
\examples{
# See serp() documentation for examples.

}
\seealso{
\code{\link{serp}}
}