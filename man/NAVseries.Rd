\name{NAVseries}
\alias{NAVseries}
\alias{as.NAVseries}
\alias{plot.NAVseries}
\alias{print.NAVseries}
\alias{summary.NAVseries}
\alias{as.data.frame.summary.NAVseries}
\alias{window.NAVseries}
\title{
  Net-Asset-Value (NAV) Series
}
\description{
  Create a net-asset-value (NAV) series.
}
\usage{
NAVseries(NAV, timestamp,
          instrument = NULL, title = NULL,
          description = NULL,
          drop.NA = NULL)

as.NAVseries(x, ...)

\method{print}{NAVseries}(x, \dots , na.rm = FALSE)

\method{summary}{NAVseries}(object, \dots, monthly.vol = TRUE,
        bm = NULL, monthly.te = TRUE,
        na.rm = FALSE, assume.daily = FALSE)

\method{plot}{NAVseries}(x, y, \dots, xlab = "", ylab = "", type = "l")

\method{window}{NAVseries}(x, start = NULL, end = NULL, \dots)

\method{as.data.frame}{summary.NAVseries}(x, \dots)
}
\arguments{
  \item{NAV}{%
    numeric
  }
  \item{timestamp}{%
    time stamp, typically \code{\link{Date}} or \code{\link{POSIXct}}
  }
  \item{instrument}{%
    character
  }
  \item{title}{%
    character
  }
  \item{description}{%
    character
  }
  \item{x}{%
    an \code{NAVseries} or an object to be coerced to NAVseries
  }
  \item{object}{%
    an \code{NAVseries}
  }
  \item{\dots}{%

    further arguments. For \code{summary}, these can be
    \code{NAVseries}.

  }
  \item{drop.NA}{%

    logical. If \code{NAV} is the result of calling
    \code{btest}, then this controls whether unused initial
    observations (\sQuote{burnin}) are dropped.

  }
  \item{bm}{%

    an optional NAVseries. If \code{bm} does not inherit
    from \code{NAVseries}, \code{\link{as.NAVseries}} is
    tried.

  }
  \item{monthly.vol}{%

    if \code{TRUE} (default), volatility computations
    are done on monthly returns

  }
  \item{monthly.te}{%

    if \code{TRUE} (default), tracking-error computations
    are done on monthly returns

  }
  \item{assume.daily}{%
    logical
  }
  \item{na.rm}{%
    logical
  }
  \item{y}{%
    a second NAVseries to be plotted. Not supported yet.
  }
  \item{xlab}{%
    character. See \code{\link{plot}}.
  }
  \item{ylab}{%
    character. See \code{\link{plot}}.
  }
  \item{type}{%
    character. See \code{\link{plot}}.
  }
  \item{start}{%
    same class as timestamp; \code{NULL} means the first timestamp
  }
  \item{end}{%
    same class as timestamp; \code{NULL} means the last timestamp
  }
}
\details{

  \subsection{NAV series}{%

    An \acronym{NAV} series is a numeric vector (the actual
    series) and additional information, attached as
    attributes: timestamp, instrument, title, description. Of
    these attributes, timestamp is the most useful, as it is
    used for several computations (e.g. when calling
    \code{\link{summary}}) and for plotting.

    The \sQuote{instrument} is typically an internal label
    used to identify the series, such as a ticker;
    \sQuote{title} is a label, too, but is intended to be
    human-readable; \sQuote{description} finally should be
    human-readable as well, but may be longer than \sQuote{title}.
  }

  \subsection{Summaries}{

    The \code{summary} method returns a list of the original
    NAVseries plus various statistics, such as return per year
    and volatility.  The method may receive several NAV series
    as input.

  }

}
\section{Note}{

  The semantics of handling NAVseries are not stable
  yet. Currently, objects of class \code{NAVseries} are
  univariate: you create a single NAVseries, summarise
  it, plot it, and so one. In the future, at least some
  of the methods will support the multi-variate case,
  i.e. be able to handle several series at once.

}
\value{

  an \code{NAVseries}: see Details.

  an \code{NAVseries} summary: a list of lists. If a
  benchmark series is present, the summary has an
  attribute \code{bm}: an integer, specifying the
  position of the benchmark.

}
\references{

  Schumann, E. (2025) \emph{Portfolio Management with R}.
  \url{https://enricoschumann.net/PMwR/};\cr
  in particular, see
  \url{https://enricoschumann.net/R/packages/PMwR/manual/PMwR.html#NAVseries}

}
\author{
  Enrico Schumann <es@enricoschumann.net>
}
\seealso{

  \code{\link{btest}}, \code{\link{journal}}

  For handling external cashflows, see \code{\link{unit_prices}},
  \code{\link{split_adjust}} and \code{\link{div_adjust}}.

}
\examples{
summary(NAVseries(DAX[[1]],
        timestamp = as.Date(row.names(DAX)),
        title = "DAX"))
}
