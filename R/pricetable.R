## -*- truncate-lines: t; -*-
## Copyright (C) 2008-24  Enrico Schumann

pricetable <- function(price, ...)
    UseMethod("pricetable")

pricetable.default <- function(price, instrument, timestamp,
                               use.names = NULL, ...) {

    if (isFALSE(use.names))
        unname(price)

    if (!is.matrix(price)) {

        if ((!isFALSE(use.names) && missing(instrument)) ||
            isTRUE(use.names)) {
            instrument <- names(price)
            price <- unname(price)
        }

        if (!missing(instrument) &&
            length(price) == length(instrument) &&
            (missing(timestamp) || length(timestamp) == 1L))
            price <- t(price)
        else
            price <- as.matrix(price)
    }

    if (missing(instrument))
        if (is.null(instrument <- colnames(price)))
            instrument <- paste0("P", seq_len(ncol(price)))

    if (missing(timestamp))
        if (is.null(timestamp <- rownames(price)))
            timestamp <- seq_len(nrow(price))

    if (anyDuplicated(instrument))
        warning("duplicate instruments")

    if (anyDuplicated(timestamp))
        warning("duplicate timestamps")

    ans <- price
    attr(ans, "instrument") <- instrument
    attr(ans, "timestamp") <- timestamp

    class(ans) <- "pricetable"
    ans

}

pricetable.zoo <- function(price, ..., instrument) {
    dots <- list(...)

    if (length(dots)) {
        dots <- c(list(price), dots)
        timestamp <- do.call(c, lapply(dots, index))
        if (inherits(timestamp, "Date")) {
            timestamp <- sort(unique(unclass(timestamp)))
            class(timestamp) <- "Date"
        } else
            timestamp <- sort(unique(timestamp))

        cols <- lapply(dots, dim)
        cols <- lapply(cols,
                       function(x) if (is.null(x)) 1 else x[2L])
        cols <- unlist(cols)
        price <- array(NA, dim = c(length(timestamp), sum(cols)))

        nextC <- 0
        for (j in seq_along(dots)) {
            i <- fmatch(index(dots[[j]]), timestamp, nomatch = 0L)
            ## TODO use unclass instead of coredata?
            nextC <- max(nextC) + seq_len(cols[j])
            price[i, nextC] <-
                if (cols[j] > 1)
                    coredata(dots[[j]])[i > 0, ] else
                    coredata(dots[[j]])[i > 0]
        }
    } else {
        timestamp <- index(price)
        price <- coredata(price)
    }
    pricetable.default(price,
                       instrument = instrument,
                       timestamp = timestamp, ...)
}

`[.pricetable`  <- function(p, i, j, start, end, missing = NA,...,
                            drop = FALSE, as.matrix = TRUE) {

    ## pt[when, instrument]
    ##
    ## i  .. character, logical, numeric, datetime
    ## j  .. character, logical, numeric
    ## answer is guaranteed to have dim(length(i), length(j))


    ## if (is.character(i)) {
    ##     if (is.null(match.against))
    ##         match.against  <- names(x)[unlist(lapply(x, mode)) == "character"]
    ##     ii <- logical(length(x))
    ##     if (length(i) > 1L)
    ##         i <- paste(i, collapse = "|")
    ##     for (m in match.against) {
    ##         if (is.null(x[[m]]))
    ##             next
    ##         ii <- ii | grepl(i, x[[m]], ignore.case = ignore.case, ...)
    ##     }
    ##     if (reverse)
    ##         ii <- !ii
    ## } else
    ##     ii <- i

    timestamp <- attr(p, "timestamp")
    instrument <- attr(p, "instrument")

    if (!is.na(missing) && missing == "locf")
        missing <- "previous"

    if (missing(i)) {
        i <- timestamp
        i.orig <- i
    } else {
        i.orig <- i
        if (is.character(i)) {
            if (inherits(timestamp, "Date")) {
                i <- as.Date(i)
                i.orig <- as.character(i)
            } else if (inherits(timestamp, "POSIXct"))
                i <- as.POSIXct(i)
        }
        if (!is.na(missing) && missing == "previous") {
            i <- matchOrPrevious(i, timestamp)
        } else
            i <- match(i, timestamp, nomatch = 0L)
    }

    if (missing(j))
        j <- instrument
    j.orig <- j
    j <- match(j, instrument, nomatch = 0L)

    ans <- array(NA, dim = c(length(i), length(j)))
    ans[!is.na(i) & i > 0, j > 0] <-
        unclass(p)[i[!is.na(i)], j, drop = drop]

    attr(ans, "timestamp") <- i.orig
    attr(ans, "instrument") <- j.orig

    if (!is.na(missing) && missing != "previous") {
        ans[is.na(ans)] <- missing
    } else if (!is.na(missing) && missing == "previous") {
        ans <- zoo::na.locf(ans, na.rm = FALSE)
    }
    if (!as.matrix)
        class(ans) <- "pricetable"
    else {
        rownames(ans) <- as.character(attr(ans, "timestamp"))
        colnames(ans) <- as.character(attr(ans, "instrument"))
        attr(ans, "timestamp") <- NULL
        attr(ans, "instrument") <- NULL
    }
    ans
}

`[<-.pricetable`  <- function(x, i, j, ..., value)
    stop("extraction only: convert to matrix to replace values")

print.pricetable <- function(x, ...) {
    xx <- x
    rownames(xx) <- as.character(attr(xx, "timestamp"))
    colnames(xx) <- as.character(attr(xx, "instrument"))
    attr(xx, "timestamp") <- NULL
    attr(xx, "instrument") <- NULL
    print.default(unclass(xx))
    invisible(x)
}

as.matrix.pricetable <- function(x, ...) {
    rownames(x) <- as.character(attr(x, "timestamp"))
    colnames(x) <- as.character(attr(x, "instrument"))
    attr(x, "timestamp") <- NULL
    attr(x, "instrument") <- NULL
    unclass(x)
}

names.pricetable <- function(x)
    attr(x, "instrument")

`names<-.pricetable` <- function(x, value) {
    attr(x, "instrument") <- value
    x
}

instrument.pricetable <- function(x, ...)
    attr(x, "instrument")

`instrument<-.pricetable` <- function(x, ..., value) {
    attr(x, "instrument") <- value
    x
}
