% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/serp.method.R
\name{summary.serp}
\alias{summary.serp}
\title{Summary method for a serp object.}
\usage{
\method{summary}{serp}(object, ...)
}
\arguments{
\item{object}{An object of class serp.}

\item{...}{Not used. Additional summary arguments.}
}
\value{
an object of class "summary.serp", a list (depending on the type of
\code{slope} used) with the components itemized below. Note that the
'components from object' are already defined in the main function.
\describe{
  \item{call}{the component from object.}
  \item{link}{the component from object.}
  \item{edf}{the component from object.}
  \item{ylev}{the component from object.}
  \item{nobs}{the component from object.}
  \item{gradient}{the component from object.}
  \item{Hessian}{the component from object.}
  \item{fitted.values}{the component from object.}
  \item{slope}{the component from object.}
  \item{Terms}{the component from object.}
  \item{control}{the component from object.}
  \item{reverse}{the component from object.}
  \item{converged}{the component from object.}
  \item{iter}{the component from object.}
  \item{message}{the component from object.}
  \item{misc}{the component from object.}
  \item{model}{the component from object.}
  \item{coefficients}{the matrix of coefficients, standard errors,
        z-values and p-values.}
  \item{logLik}{the component from object.}
  \item{deviance}{the component from object.}
  \item{aic}{the component from object.}
  \item{bic}{the component from object.}
  \item{contrasts}{the component from object.}
  \item{penalty}{list of penalization information when \code{slope} set
        to "penalize".}
  \item{expcoefs}{the exponentiated coefficients.}
  \item{cvMetric}{the component from object.}
  \item{globalEff}{the component from object.}
  \item{lambda}{the component from object.}
  \item{lambdaGrid}{v}
  \item{na.action}{the component from object.}
  \item{nrFold}{the component from object.}
  \item{testError}{the component from object.}
  \item{trainError}{the component from object.}
  \item{tuneMethod}{the component from object.}
  \item{value}{the component from object.}
}
}
\description{
Summarizes the results of the fitted model in a dataframe.
}
\examples{
# See serp() documentation for examples.
}
\seealso{
\code{\link{serp}}
}
