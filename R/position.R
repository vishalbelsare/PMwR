## -*- truncate-lines: t; -*-
## Copyright (C) 2008-25  Enrico Schumann

position <- function(amount, ...)
    UseMethod("position")

position.default <- function(amount, timestamp, instrument,
                             when, drop.zero = FALSE,
                             account = NULL,
                             use.names = NULL, ...) {

    dim.amount <- dim(amount)
    is.amount.matrix  <- !is.null(dim.amount) &&
                         sum(dim.amount > 1L) == 2L
    is.amount.matrix1 <- !is.null(dim.amount) &&
                         sum(dim.amount > 1L) == 1L

    no.instruments <- FALSE ## are all instruments missing/NA?
    if ((!isFALSE(use.names) && missing(instrument)) ||
        isTRUE(use.names)) {

        if (is.amount.matrix1) {
            nm <- colnames(amount)
            amount <- c(amount)
        } else if (is.amount.matrix) {
            ## instrument is required
            nm <- rep(colnames(amount), each = dim.amount[1L])
            amount <- c(amount)
        } else
            nm <- names(amount)
        if (!is.null(nm))
            instrument <- nm
    }


    if (missing(instrument) ||
        !length(instrument) ||
        all(is.na(instrument))) {
        if (is.amount.matrix)
            stop(sQuote("amount"), " is a matrix but ",
                 sQuote("instrument"), " is missing")
        instrument <- rep.int("", length(amount))
        no.instruments <- TRUE
    } else if (is.amount.matrix && length(instrument) == dim.amount[2L])
        instrument <- rep(instrument, each = dim.amount[1L])

    no.timestamp <- FALSE
    if (missing(timestamp) ||
        !length(timestamp) ||
        all(is.na(timestamp))) {
        timestamp <- if (is.amount.matrix)
                         seq_len(dim.amount[1L])
                     else
                         rep(1, length(amount))
        no.timestamp <- TRUE
    } else {
        if (is.amount.matrix &&
            length(timestamp) != dim.amount[1L])
            stop("timestamp length does not match amount")
    }

    len <- max(length(amount),
               length(timestamp),
               length(instrument),
               length(account))
    amount <- rep(amount, len/length(amount))
    timestamp <- rep(timestamp, len/length(timestamp))
    instrument <- rep(instrument, len/length(instrument))

    timestamp.xtfrm <- TRUE
    if (inherits(timestamp, "numeric") ||
        inherits(timestamp, "Date") ||
        inherits(timestamp, "POSIXt")) {
        timestamp.xtfrm <- FALSE
    }


    if (!is.null(account)) {
        ## if 'account' is specified, paste
        ##   account%SEP%instrument.
        ## 'account' is then no longer needed
        account <- rep(account, len/length(account))
        sep <- "%%"
        while (any(grepl(sep, c(account, instrument), fixed = TRUE))) {
            sep <- paste0("%", runif(1)*1e14, unclass(Sys.time()), "%")
        }
        instrument <- paste(account, sep, instrument, sep = "")
    }

    if (missing(when)) {
        ## if 'when' is missing, we can sum the
        ## amounts. Missing timestamps do no harm.

        if (length(timestamp)) {
            when <- max(timestamp, na.rm = TRUE)
        } else {
            when <- Inf
        }

        uniq.instrument <- sort(unique(instrument))
        pos <- array(0, dim = c(1, length(uniq.instrument)))
        colnames(pos) <- if (!is.null(account))
                             gsub(sep, ".", uniq.instrument, fixed = TRUE)
                         else
                             uniq.instrument
        rownames(pos) <- ""
        for (i in seq_along(uniq.instrument)) {
            ri  <-  uniq.instrument[i] == instrument
            iv  <- amount[ri]
            pos[1, i] <- sum(iv)
        }

    } else {
        if (no.timestamp)
            warning(sQuote("when"),
                    " specified, but no valid timestamp supplied")
        if (is.character(when)) {
            if (when[[1L]] == "last" ||
                when[[1L]] == "newest" ||
                when[[1L]] == "latest")
                when <- max(timestamp)
            else if (when[[1L]] == "all")
                when <- unique(timestamp)
            else if (when[[1L]] == "endofyear" ||
                     when[[1L]] == "lastofyear") {
                ## TODO preferable?
                ## when <- last(timestamp,
                ##              format(as.Date(timestamp), "%Y"))
                timestamp <- as.Date(as.POSIXlt(timestamp))
                when <- end_of_year(seq(min(timestamp),
                                        max(timestamp),
                                        by = "1 year"))
            } else if (when[[1L]] == "endofmonth" ||
                       when[[1L]] == "lastofmonth") {
                ## TODO preferable?
                ## when <- last(timestamp,
                ##              format(as.Date(timestamp), "%Y-%m"))
                timestamp <- as.Date(as.POSIXlt(timestamp))
                when <- end_of_month(seq(first_of_month(min(timestamp)),
                                         first_of_month(max(timestamp)),
                                         by = "1 month"))
            } else if (when[[1L]] == "endofday") {
                timestamp <- as.Date(as.POSIXlt(timestamp))
                when <- last(timestamp,
                             format(timestamp, "%Y-%m-%d"))
            } else if (when[[1L]] == "first" ||
                       when[1L] == "oldest")
                when <- min(timestamp)
        }


        if (!anyNA(timestamp) && is.unsorted(timestamp)) {
            io <- order(timestamp)
            timestamp <- timestamp[io]
            amount  <- amount[io]
            instrument <- instrument[io]
            if (!is.null(account))
                account <- account[io]
        }

        if (anyNA(timestamp) && is.unsorted(timestamp, na.rm = TRUE))
            stop("cannot compute position: journal is not sorted ",
                 "and timestamp has NA values")

        if (anyNA(timestamp) && !is.unsorted(timestamp, na.rm = TRUE))
            warning("timestamp has NA values")

        if (any(not.needed <- timestamp > max(when))) {
            amount    <-      amount[!not.needed]
            timestamp <-   timestamp[!not.needed]
        }

        ## remove unnecessary timestamps
        if (drop.zero) {
            instrument <- instrument[!not.needed]
            uniq.instrument <- sort(unique(instrument))
            ni <- length(uniq.instrument)
        } else {
            uniq.instrument <- sort(unique(instrument))
            ni <- length(uniq.instrument)
            instrument <- instrument[!not.needed]
        }

        uniq.when <- unique(when)
        nw <- length(uniq.when)
        pos <- array(0, dim = c(nw, length(uniq.instrument)))
        colnames(pos) <- if (!is.null(account))
                             gsub(sep, ".", uniq.instrument, fixed = TRUE)
                         else
                             uniq.instrument
        rownames(pos) <- if (no.timestamp)
                             rep("", nw)
                         else
                             as.character(uniq.when)


        for (i in seq_along(uniq.instrument)) {
            m <- uniq.instrument[i] == instrument
            if (!sum(m))
                next

            cum.amount <- cumsum(amount[m])
            if (timestamp.xtfrm) {

                tmp <- xtfrm(c(uniq.when, timestamp[m]))
                tmp1 <- length(uniq.when)
                tmp2 <- length(tmp) - tmp1

                j <- findInterval(
                    tmp[seq_len(tmp1)],
                    tmp[seq(tmp1 + 1, to = length(tmp))])

            } else {
                j <- findInterval(uniq.when, timestamp[m])
            }
            good <- j > 0
            pos[good, i] <- cum.amount[j[good]]

        }

        ## TODO if 'when' entries are not unique, make copies
        if (length(uniq.when) != length(when)) {
            pos <- pos[match(when, unique(when)), , drop = FALSE]
            colnames(pos) <- uniq.instrument
        }
    }

    if (!is.logical(drop.zero)) {
        ## drop.zero is a tolerance
        drop <- apply(pos, 2, function(x) all(abs(x) < drop.zero))
        pos <- pos[, is.na(drop) | !drop, drop = FALSE]
        uniq.instrument <- uniq.instrument[is.na(drop) | !drop]

    } else if (drop.zero) {
        drop <- apply(pos, 2, function(x) all(x == 0))
        pos <- pos[, is.na(drop) | !drop, drop = FALSE]
        uniq.instrument <- uniq.instrument[is.na(drop) | !drop]
    }

    if (no.instruments)
        uniq.instrument[] <- NA
    if (!is.null(account)) {
        tmp <- strsplit(uniq.instrument, sep, fixed = TRUE)
        attr(pos, "instrument") <- unlist(lapply(tmp, `[[`, 2))
        attr(pos, "account") <- unlist(lapply(tmp, `[[`, 1))
    } else
        attr(pos, "instrument") <- uniq.instrument
    attr(pos, "timestamp") <- if (no.timestamp) NA else when
    attr(pos, "unit") <- "amount"
    class(pos) <- "position"
    pos
}

position.journal <- function(amount, when,
                             drop.zero = FALSE,
                             use.account = FALSE, ...) {

    instrument <- amount$instrument
    timestamp  <- amount$timestamp
    account <- if (use.account)
                   amount$account
    amount     <- amount$amount

    position.default(amount = amount,
                     timestamp = timestamp,
                     instrument = instrument,
                     when = when,
                     drop.zero = drop.zero,
                     account = account,
                     use.names = FALSE,
                     ...)
}


position.data.frame <- position.journal


position.btest <- function(amount, when, ...,
                           include.cash = FALSE) {
    ans <- amount$position
    class(ans) <- "position"

    attr(ans, "timestamp") <- if (!is.null(amount$timestamp))
                                  amount$timestamp
                              else
                                  NA

    instrument <- if (!is.null(amount$instrument))
                      amount$instrument
                  else
                      rep(NA, ncol(ans))

    if (include.cash) {
        ans <- cbind(ans, amount$cash)
        instrument <- c(instrument, "cash")
    }

    attr(ans, "instrument") <- instrument
    attr(ans, "unit") <- "amount"
    ans
}

print.position <- function(x, ..., sep = ":") {
    if (dim(x)[[2L]] == 0L)  ## empty position
        return(invisible(x))
    original.x <- x
    ## if (!is.na(sep))
    ##     .NotYetUsed("sep")
    account <- attr(x, "account")
    instrument <- attr(x, "instrument")
    timestamp <- attr(x, "timestamp")
    if (!is.null(account)) {
        instrument <- paste(account, instrument, sep = sep)
        if (nrow(x) == 1L) {
            all_i <- .expand(instrument, sep = sep)
            instrument <- paste0(.tree(all_i$level, style = "ascii"),
                                 .leaf(paste(all_i$description), sep))
            pos <- numeric(nrow(all_i)) + NA
            dim(pos) <- c(1L, nrow(all_i))
            pos[all_i$position > 0] <- unclass(x)[all_i$position]
            x <- pos
        }
    }
    if (!all(is.na(instrument)))
        colnames(x) <- instrument

    if (all(is.na(timestamp)) ||
        (is.character(timestamp) && all(timestamp == "")))
        rownames(x) <- NULL
    if (all(is.na(instrument)) ||
        (is.character(instrument) && all(instrument == "")))
        colnames(x) <- NULL

    attr(x, "account") <- NULL
    attr(x, "instrument") <- NULL
    attr(x, "timestamp") <- NULL
    attr(x, "unit") <- NULL
    if (all(dim(x) == c(1L, 1L)) &&
        is.null(rownames(x)) &&
        is.null(colnames(x))) {
        cat(x, "\n")
    } else if (dim(x)[1L] > 1L) {
        print(unclass(x), na.print = "")
    } else {
        if (is.na(timestamp))
            write.table(t(unclass(x)), col.names = FALSE, quote = FALSE)
        else
            print(t(unclass(x)), na.print = "")
    }
    invisible(original.x)
}

as.matrix.position <- function(x, ...) {
    ans <- c(x)
    dim(ans) <- dim(x)

    if (!all(is.na(attr(x, "timestamp"))))
        rownames(ans) <- as.character(attr(x, "timestamp"))
    colnames(ans) <- attr(x, "instrument")
    ans
}

as.data.frame.position <- function(x, ...) {
    ans <- c(x)
    dim(ans) <- dim(x)
    ans <- as.data.frame(ans, ...)

    if (!all(is.na(attr(x, "timestamp")))) {
        timestamp <- make.unique(as.character(attr(x, "timestamp")))
        row.names(ans) <- timestamp
    }
    names(ans) <- colnames(x)
    ans
}

Ops.position <- function(e1, e2) {
    if (nargs() == 1L) {
        switch(.Generic,
               `+` = {},
               `-` = {
                      e1[] <- -unclass(e1)
                     },
               `!` = {
                      tmp <- !as.logical(c(e1))
                      dim(tmp) <- dim(e1)
                      colnames(tmp) <- attr(e1, "instrument")
                      if (!is.na(attr(e1, "timestamp")))
                          rownames(tmp) <- as.character(attr(e1, "timestamp"))
                      colnames(tmp) <- attr(e1, "instrument")
                      e1 <- tmp
                     },
               NextMethod(.Generic)
        )
        return(e1)
    }

    if (inherits(e1, "position") && inherits(e2, "position") &&
        all(!is.na(i1 <- instrument(e1))) &&
        all(!is.na(i2 <- instrument(e2))) ) {
        allI <- sort(unique(c(i1, i2)))
        ans <- numeric(length(allI))
        ans[match(instrument(e1), allI)] <- as.numeric(e1)
        ii <- match(instrument(e2), allI)
        if (.Generic == "+") {
            ans[ii] <- ans[ii] + as.numeric(e2)
        } else if (.Generic == "-") {
            ans[ii] <- ans[ii] - as.numeric(e2)
        } else if (.Generic == "/") {
            ans[ii] <- ans[ii] / as.numeric(e2)
        }
        position.default(ans, instrument = allI,
                         timestamp = rep(attr(e1, "timestamp"),
                                         length(allI)))
    } else
        NextMethod(.Generic)
}

as.zoo.position <- function(x, ...) {
    zoo(x, attr(x, "timestamp"))
}

.expand <- function(s, sep, perl = FALSE, warn.dup = TRUE) {
    if (warn.dup && any(d <- duplicated(s))) {
        warning("duplicated values:\n",
                paste(sort(unique(s[d])), collapse = "\n"))
    }
    s[is.na(s)] <- ""
    gs <- sort(unique(s))

    list.gs <- strsplit(gs, sep, perl = perl)

    all.acc <- NULL
    for (i in seq_along(list.gs)) {
        if ((lg <- length(list.gs[[i]])) == 1L)
            next

        tmp <- NULL
        for (j in seq_len(lg-1))
            tmp <- c(tmp, paste(list.gs[[i]][1:j],
                                collapse = sep))
        all.acc <- c(all.acc, tmp)
    }
    all.acc <- sort(unique(c(all.acc, s)))

    ## LEVEL
    level <- as.numeric(
        unlist(lapply(gregexpr(sep, all.acc),
                      function(x) length(x) == 1 && x == -1)))
    level[level == 0L] <- lengths(gregexpr(sep, all.acc))[level == 0L] + 1

    data.frame(description = all.acc,
               level,
               position = match(all.acc, s, nomatch = 0L),
               stringsAsFactors = FALSE)

}

acc.split <- function(account, sep, perl = FALSE, tree = FALSE) {
    .Deprecated(".expand")
    account[is.na(account)] <- ""
    gs <- sort(unique(account))

    list.gs <- strsplit(gs, sep, perl = perl)

    all.acc <- NULL
    for (i in seq_along(list.gs)) {
        if ((lg <- length(list.gs[[i]])) == 1L)
            next

        tmp <- NULL
        for (j in seq_len(lg-1))
            tmp <- c(tmp, paste(list.gs[[i]][1:j],
                                collapse = sep))
        all.acc <- c(all.acc, tmp)
    }
    all.acc <- sort(unique(c(all.acc, account)))
    positions <- match(account, all.acc)

    ## LEVEL
    level <- as.numeric(
        unlist(lapply(gregexpr(sep, all.acc),
                      function(x) length(x) == 1 && x == -1)))
    level[level == 0L] <- lengths(gregexpr(sep, all.acc))[level == 0L] + 1


    ## TREE
    if (tree) {
        leaf <- function(x, sep = sep) {
            ## return last subaccount
            ## account::subaccount::...::deepest_subaccount
            gsub(paste0(".*", sep, "([^", substr(sep,1,1), "]+)$"),
                 "\\1", x, perl = TRUE)
        }

        sp <- spaces(4*(level - 1))
        tree1 <- paste0(sp, leaf(all.acc))

        tree2 <- paste0(.tree(level), leaf(all.acc))
        tree3 <- paste0(.tree(level, TRUE), leaf(all.acc))
        tree3 <- enc2utf8(tree3)

        res <- data.frame(account = all.acc,
                          level,
                          tree_indent  = tree1,
                          tree_ascii   = tree2,
                          tree_unicode = tree3,
                          stringsAsFactors = FALSE)
    } else {
        res <- data.frame(account = all.acc, level, stringsAsFactors = FALSE)
    }
    attr(res, "positions") <- positions
    res
}

.leaf <- function(x, sep, perl = TRUE) {
    ## return last level
    ## level::sublevel::...::subbest_sublevel
    ## => the regexp used greedy matching
    gsub(paste0(".*", sep, "(.*)"), "\\1", x, perl = TRUE)
}

.tree <- function(lv, style = "indent", width = 4,
                  styles) {

    if (style != "indent" && width != 4)
        warning(sQuote("width"), " is ignored")
    if (style == "indent") {
        spaces(width*(lv - 1))
    } else  {
        child <- "|--"
        final_child <- "`--"
        cont <- "|  "
        indent <- spaces((lv-1)*width)
        n <- length(lv)
        for (i in 1L:(max(lv)-1L)) {
            group.start <- c(which(lv == i), n + 1)
            group.end <- group.start
            for (g in 1:length(group.start)) {
                if (any(next_l <- 1:n < group.start[g+1] &
                            1:n >= group.start[g] &
                            lv == i+1))
                    group.end[g] <- max(which(next_l))
            }

            group.start <- group.start[-length(group.start)]
            group.end <- group.end[-length(group.end)]

            for (g in 1:length(group.start)) {
                if (group.start[g] == group.end[g])
                    next
                else if (group.end[g] - group.start[g] == 1L)
                    substring(indent[group.end[g]], (i-1)*4+1,(i-1)*4+3) <- final_child
                else  {
                    substring(indent[1:n > group.start[g] & 1:n < group.end[g] & lv==1+i],
                    (i-1)*4+1,(i-1)*4+3) <- child
                    substring(indent[1:n > group.start[g] & 1:n < group.end[g] & lv != 1+i],
                    (i-1)*4+1,(i-1)*4+3) <- cont
                    substring(indent[group.end[g]],
                    (i-1)*4+1,(i-1)*4+3) <- final_child
                }
            }
        }
        if (style == "unicode") {
            indent <- gsub("|--", "\u251c\u2500\u2500", indent, fixed = TRUE)
            indent <- gsub("`--", "\u2514\u2500\u2500", indent, fixed = TRUE)
            indent <- gsub("|  ", "\u2502  ", indent, fixed = TRUE)
        }
        indent
    }
}

toHTML.position <- function(x, ..., template = NULL) {

    x <- unclass(x)
    x <- unname(x)

    if (nrow(x) <= 1L) {
        .template <- c("<tr><td>%instrument%</td><td>%amount</td></tr>")
        textutils::toHTML(
                       data.frame(Instrument = attr(x, "instrument"),
                                  Quantity = c(x),
                                  stringsAsFactors = FALSE))
    } else
        stop("not supported")
}

.compare_position <- function(x, y,
                              use.names = FALSE,
                              ignore.case = FALSE,
                              exclude.zero = use.names) {

    if (exclude.zero) {
        tol <- sqrt(.Machine$double.eps)
        x <- x[ abs(x) > tol ]
        y <- y[ abs(y) > tol ]
    }

    if (!use.names) {
        stopifnot(length(x) == length(y))
    } else {
        if (is.null(names(x)) || is.null(names(y)))
            stop(sQuote("use.names"), " is TRUE but no names")
        if (ignore.case) {
            names(x) <- tolower(x)
            names(y) <- tolower(y)
        }
        all.names <- sort(unique(c(names(x), names(y))))
        new.y <- new.x <- numeric(length(all.names))
        names(new.y) <- names(new.x) <- all.names
        new.x[names(x)] <- x
        new.y[names(y)] <- y
        x <- new.x
        y <- new.y
    }

    same.sign <- sign(x) == sign(y)

    list(same.assets = sum(same.sign),
         weight.overlap = sum(pmin(abs(x[same.sign]),
                                   abs(y[same.sign]))),
         max.abs.difference = max(abs(x-y)),
         mean.abs.difference = sum(abs(x-y))/length(x))
}
