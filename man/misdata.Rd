% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/preprocess.R
\name{misdata}
\alias{misdata}
\title{Replace Missing Data by Interpolation}
\usage{
misdata(data)
}
\arguments{
\item{data}{an object of class \code{idframe}}
}
\value{
data (an idframe object) with missing data replaced.
}
\description{
Function for replacing missing values with interpolated ones. This is an
extension of the \code{na.approx} function from the \code{zoo} package.
The missing data is indicated using the value \emph{NA}.
}
\examples{
data(cstr_mis)
summary(cstr_mis) # finding out the number of NAs
cstr <- misdata(cstr_mis)

}
\seealso{
\code{\link[zoo]{na.approx}}
}

