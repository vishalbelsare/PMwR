\name{PMwR-internal}
\alias{PMwR-internal}
\alias{.timestamp}
\alias{.timestamp<-}
\alias{.may_be_Date}
\title{Internal Functions}
\description{
  Internal functions, not exported from the \pkg{PMwR} namespace.
}
\usage{
.timestamp(x)
.timestamp(x) <- value

.may_be_Date(x, \dots)
}
\details{

  \code{.timestamp} extracts or replaces an object's timestamp.

  \code{.may_be_Date} checks whether a vector could be
  coerced to class \code{\link{Date}}, in which case it
  evaluates to (a single) \code{TRUE}; otherwise it returns
  \code{FALSE}. If \code{TRUE}, the actual \code{Date}s are
  attached as an attribute \code{Date}.

}
\references{

  E. Schumann (2023) \emph{Portfolio Management with \R}.
  \url{https://enricoschumann.net/PMwR/}
}
\author{
  Enrico Schumann
}
\keyword{internal}
