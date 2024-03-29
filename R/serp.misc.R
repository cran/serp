# SERP internal functions

formxL <- function(x, nL, slope, globalEff, m, vnull, ...)
{
  Xdt <- function(x, nL)
  {
    nv  <- length(x)
    zs <- rep(0, nv)
    bc <- do.call(rbind, lapply(1:(nL-1), function(i)
      c(rep(zs, i-1), x, rep(zs, nL-1-i))
    ))
    bc
  }
  h1 <- diag(nL-1)
  nv <- dim(x)[2L]
  lq <- as.vector(t(matrix(1:(nv * (nL-1)), nv, nL-1)))
  xL <- lapply(seq_len(nrow(x)), function(u)
  {
    if (slope == 'partial'){
      gb <- unlist(globalEff)
      subg <- subset(m, select = c(gb))
      subm <- model.matrix(~., data = subg)
      subn <- colnames(subm)[-1L]
      xnames <- colnames(x)
      if (any(grepl(":", xnames))){
        subn2 <- xnames[which(grepl(":", xnames))]
        subn <- c(subn, subn2)
      }
      col.num <- seq_len(ncol(x))
      col.glo <- c(1, which(xnames %in% subn))
      specifc <- setdiff(col.num, col.glo[-1L])
      if(!dim(x)[1] == 1)
        xs <- x[,specifc]
      else xs <- subset(x, select = specifc)
      nv <- dim(xs)[2]
      lq <- as.vector(t(matrix(1:(nv * (nL-1)), nv, nL-1)))
      xx <- xs[u, ]
      xL1 <- Xdt(xx, nL)[ ,lq]
      xL1 <- xL1[,-c(1:nL-1)]
      cname <- unique(colnames(xL1)[colnames(xL1) != ""])
      colnames(xL1) <- rep(cname, each = nL-1)
      if (!dim(x)[1] == 1L)
        xg <- x[,col.glo]
      else xg <- subset(x, select = col.glo)
      nv <- dim(xg)[2]
      xx <- xg[u, ]
      h2 <- rbind(xx)[rep(1, nL-1), ,drop = FALSE]
      if (!vnull)
        xL2 <- h2[,-1L, drop = FALSE]
      else xL2 <- h2
      XL3 <- cbind(xL1, xL2)
      xListi <- cbind(h1, XL3[ , order(colnames(XL3))])
    }else{
      xx <- x[u, ]
      if (slope == 'parallel'){
        h2 <- rbind(xx)[rep(1, nL-1), ,drop = FALSE]
        if (!vnull)  xListi <- cbind(h1, h2[,-1L])
        else xListi <- cbind(h1, h2)
      }
      if (slope == 'unparallel'|| slope == 'penalize'){
        xListi <- Xdt(xx, nL)[ ,lq]
      }
      rownames(xListi) <- NULL
      xListi
    }
  })
  xL
}

PenMx <- function(lamv, delta, nL, slope, m, globalEff, mslope, Terms)
{
  if (mslope == 'penalize' && !is.null(globalEff)){
    xnam <- c(colnames(m)[1], attributes(Terms)$term.labels)
    interac <- grep(':', xnam, fixed = TRUE)
    gb <- unlist(globalEff)
    var.num <- seq_len(length(xnam))
    var.glo <- which(xnam %in% gb)
    if (length(interac) != 0L ) {
      var.glo <- c(var.glo, interac)
    }
    nvar <- (nL-1) * (length(xnam) - 1)
  }   else nvar <- length(delta)-(nL-1)
  diagx <- rep(-1, nvar-1)
  mt <- diag(-1, nrow = nvar-1, ncol = nvar)
  mt <- 1*((row(mt) == col(mt) - (1)) + 0)
  diag(mt) <- diagx
  r <- 0
  while(r < nvar-1)
  {
    r <- r + nL-1
    if (r > nvar-1) break
    mt[r, ] <- 0L
  }
  Dx <- t(mt) %*% mt
  pM <- rbind(matrix(0, nL-1, nvar+nL-1),
              cbind(matrix(0, nvar, nL-1), Dx))
  if (mslope == 'penalize' && !is.null(globalEff)){
    smx <- matrix(seq_len(ncol(pM)), ncol = nL-1, byrow=TRUE)
    hmx <- smx[,-ncol(smx), drop = FALSE]
    pM[c(smx[var.glo, ]), c(smx[var.glo, ])] <- 0L
    pM <- pM[-c(hmx[var.glo, ]), -c(hmx[var.glo, ])]
    slope <- 'penalize'
  }
  if (slope=="parallel" || slope=="partial") lamv <- 0L
  py1 <- lamv * pM
  py2 <- lamv * pM %*% delta
  py3 <- lamv * t(delta) %*%  pM  %*% delta
  list(infopen = py1, scorepen = py2, logpen = py3)
}

prlg <- function(delta, xMat, obs, yMtx, penx, linkf, control, wt)
{
  hh <- xMat %*% delta
  invlink <- 1 - apply(hh, 1, linkf$pfun)
  eta <- cbind(1,matrix(invlink, nrow = obs, byrow = TRUE))
  pr <- exact.pr <- if (dim(eta)[1L] == 1)
    c(eta[, -ncol(eta)] - eta[, -1], eta[,dim(eta)[2L]])
  else
    cbind(eta[, -ncol(eta)] - eta[, -1L], eta[,dim(eta)[2L]] )
  np <- any(pr < 0)
  pr[pr <= control$minP] <- control$minP
  pr[pr > 1-control$minP] <- 1- control$minP

  logpr <- suppressWarnings(log(pr))
  logL <- sum(wt * yMtx * logpr) + penx$logpen
  exact.logpr <- suppressWarnings(log(exact.pr))
  exact.logL <- sum(wt * yMtx * exact.logpr) + penx$logpen
  res <- list(negprob = np,
              logL = logL,
              pr = pr,
              exact.logL = exact.logL,
              exact.pr = exact.pr)
  res
}

ScoreInfo <- function(x, y, pr, wt, nL, yMtx, xlst, penx, linkf)
{
  um <- uMatFun(pr, yMtx, linkf, nL)
  uMat <- um$uMat
  if (is.null(attr(yMtx, "wts")))
    wts <- rowSums(yMtx) else wts <- attr(yMtx, "wts")
  pw <- wts/um$pr
  ff <- wts/um$lp
  eta <- um$etaMat
  split.eta <- split(eta, seq_len(nrow(eta)))
  q <- lapply(split.eta, etfun, nL, linkf)
  invmat <- lapply(split(pw, seq_len(nrow(pw))), diag)
  Infx <- mapply(
    function(invt, ff, x, q, wt){
      inv <- invt + ff
      w <- crossprod(q,inv) %*% q
      fm <- wt * crossprod(x, w %*% x)
    }, invmat, ff, xlst, q, wt, SIMPLIFY = FALSE)
  info <- Reduce("+", Infx) + penx$infopen
  sc <- mapply(function(q, uMat, x, wt) wt*crossprod(x, crossprod(q, uMat)),
               q, uMat, xlst, wt, SIMPLIFY = FALSE)
  score <- Reduce("+", sc) - penx$scorepen
  list(score = score, info = info)
}

checkArg <- function (mcall, scall, argnames)
{
  nm <- names(as.list(mcall))
  if (!"formula" %in% nm)
    stop("Model needs a formula", call. = FALSE)
  nd <- list(m1 = names(mcall), m2 = names(scall))
  nd <- setdiff(nd$m1, nd$m2)
  if (length(nd) > 1)
    stop("unassigned value in serp function.", call. = FALSE)
  check <- argnames %in% names(formals(cat))
  if (any(!check)) anyerr <- TRUE else anyerr <- FALSE
  if (length(check) > 1)
    err <- sprintf("unused arguments: \"%s\"",
                   paste(argnames[!check], collapse = ", "))
  else err <- sprintf("unused argument: \"%s\"",
                      paste(argnames[!check], collapse = ", "))
  if (anyerr) stop(err, call. = FALSE)
}

startv <- function(link, linkf, globalEff, x, yFreq, xMat, nL, nvar, slope)
{
  if (link == "logit")
    ut <- linkf$qfun(cumsum(yFreq[-nL]))
  if (link == "cauchit")
    ut <- tan(pi*(cumsum(yFreq[-nL]) - 0.5))
  if (link == "cloglog")
    ut <- log(-log(1 - cumsum(yFreq[-nL])))
  if (link == "loglog")
    ut <- -log(-log(cumsum(yFreq[-nL])))
  if (link == "probit")
    ut <- qnorm(cumsum(yFreq[-nL]))

  if (slope == "parallel")
    ibeta <- c(ut, rep(0, nvar))
  if (slope == "partial")
    ibeta <- c(ut, rep(0, ncol(xMat)-(nL-1)))
  if (slope == "unparallel" || slope == "penalize")
    ibeta <- c(ut, rep(0, nvar * (nL - 1)))
  ibeta
}

levformat <- function (pr, digits)
  paste(format(pr * 1e2, scientific = FALSE,
               trim = FALSE, digits = digits),"%")

etfun <- function(eta, nL, linkf)
{
  mt <- diag(-1, nrow = nL-1)
  mt <- -1*((row(mt) == col(mt) + (1)) + 0)
  diag(mt) <- rep(1, nL-1)
  et <- rep(linkf$dfun(eta), each=length(eta)) * mt
  et
}

pGumbel <- function (q, loc = 0, scale = 1, lower.tail = TRUE)
{
  q <- (q - loc)/scale
  p <- exp(-exp(q))
  if (lower.tail)
    1 - p
  else p
}

dGumbel <- function (x, loc = 0, scale = 1, log = FALSE)
{
  x <- -(x - loc)/scale
  d <- log(1/scale) - x - exp(-x)
  if (!log)
    exp(d)
  else d
}

qGumbel <- function (p, location = 0, scale = 1,
                     lower.tail = TRUE, max = FALSE)
{
  if (!lower.tail)
    p <- 1 - p
  if (max)
    location - scale * log(-log(p))
  else location + scale * log(-log(1 - p))
}

yMx <- function(y, obs, nL)
{
  ym <- matrix(0, nrow = obs, ncol = nL,
               dimnames = list(NULL, levels(y)))
  yi <- as.integer(y)
  ym[cbind(1:obs, yi)] <- 1
  ym
}

uMatFun <- function(pr, yMtx, linkf, nL)
{
  pf <- cbind(pr, 1-rowSums(pr))
  pf <- pf/rowSums(pf)
  lp <- pf[, nL]
  pr <- pf[, -nL, drop = FALSE]
  g  <- yMtx[, nL]/lp
  g[yMtx[, nL] == 0] <- 0
  yp <- yMtx[, -nL, drop = FALSE]/pr
  yp[yMtx[, -nL] == 0] <- 0
  etaMat <- suppressWarnings(
    t(apply(t(apply(pr,1,cumsum)), 1, linkf$qfun)))
  uMat <- yp - g
  uMat <- split(uMat, seq_len(nrow(etaMat)))
  list(uMat = uMat, etaMat = etaMat, pr = pr, lp = lp)
}

df.serp <- function(fvalues, xMat, penx, nL){
  P  <- fvalues$pr[,-nL]
  pi <- matrix(apply(P,1,c), ncol = 1L)
  V  <- sqrt(pi*(1-pi))
  VX <- c(V) * xMat
  plty <- penx$infopen
  INV <-  try({solve( (crossprod(VX,VX) + plty), t(VX) )}, silent=TRUE)
  if (!inherits(INV, "try-error")) {
    H <- VX %*% INV
    M <- as.matrix(diag(nrow(H)) - H)
    edf <- sum(diag(H))
    rdf <- sum(diag(M))
    list(edf=edf, rdf=rdf)
  } else list(edf=NA, rdf=NA)
}

lnkfun <- function(link)
{
  structure(list(
    pfun = switch(link, logit = plogis, probit = pnorm,
                  loglog = pgumbel, cloglog = pGumbel, cauchit = pcauchy),
    dfun = switch(link, logit = dlogis, probit = dnorm,
                  loglog = dgumbel, cloglog = dGumbel, cauchit = dcauchy),
    qfun = switch(link, logit = qlogis, probit = qnorm,
                  loglog = qgumbel, cloglog = qGumbel, cauchit = qcauchy)
  ), name = "linkfun")
}

cvfun <- function(lambda, x, y, nrFold, linkf, link, m, slope, globalEff,
                  nvar, reverse, vnull, control, wt, cverror, mslope,
                  Terms, xlst, yMtx, obs)
{
  obs <- nrow(m)
  set.seed(control$cv.seed)
  Indx <- sample(seq_len(obs))
  xlst <- xlst[Indx]
  x <- x[Indx, ]
  y <- y[Indx]
  yMtx <- yMtx[Indx, ]
  folds  <- cut(seq_len(obs), breaks = nrFold,
                labels = FALSE)
  err  <- matrix(NA, nrow = nrFold, ncol = 1)
  for (r in seq_len(nrFold))
  {
    Indexes <- which(folds == r)
    tn.yMtx <- yMtx[-Indexes, ]
    tn.y <- y[-Indexes]
    tn.x <- x[-Indexes, ]
    tn.xlst <- xlst[-Indexes]
    nL <- nlevels(tn.y)
    tn.xMat <- do.call(rbind, tn.xlst)
    obs  <- nrow(tn.yMtx)
    yFreq <- colSums(tn.yMtx)/obs
    startval <- startv(link, linkf, globalEff, tn.x, yFreq, tn.xMat, nL, nvar,
                       slope)
    npar <- length(startval)
    wt <- rep(1, obs)
    estx <- try(serp.fit(lambda, tn.x, tn.y, wt, startval, tn.xlst,
                         tn.xMat, tn.yMtx, nL, obs, npar, linkf, link,
                         vnull, control, slope, globalEff, m, mslope,
                         Terms, xtrace = FALSE), silent = TRUE)
    if (!inherits(estx, "try-error")){
      est <-  c(estx$coef)
      ts.yMtx <- yMtx[Indexes, ]
      ts.y <- y[Indexes]
      ts.x <- x[Indexes, ]
      ts.xlst <- xlst[Indexes]
      obs <- length(ts.y)
      ts.xMat <- do.call(rbind, ts.xlst)
      pr <- prlg(est, ts.xMat, obs, yMtx = NULL, penx = NULL, linkf,
                 control = NULL, wt = NULL)$exact.pr
      lv <- levels(ts.y)
      dplv <- levels(droplevels(ts.y))
      if (length(dplv) != length(lv)){
        sdf <- setdiff(lv, dplv)
        if (length(sdf) == 0L) sdf <- setdiff(dplv, lv)
        ts.y <- droplevels(ts.y)
        pr <- pr[, which(dplv %in% lv), drop = FALSE]
      }
      pm <- errorMetrics(ts.y, pr, control, type = cverror)
    } else pm <- NA
    err[r, ] <- pm
  }
  res <- na.omit(err)
  sum(res)/length(res)
}

errorMetrics <- function(y, prob, control,
                                 type = c("brier", "logloss", "misclass"))
{

  type <- match.arg(type)
  eps <- control$minP
  prob[prob < eps] <- eps
  prob[prob > 1-eps] <- 1-eps
  prob <- prob/rowSums(prob)
  y <- droplevels(y)
  nL <- nlevels(y)
  obs <- length(y)
  if (nrow(prob) != obs || max(unclass(y)) != ncol(prob)
      || min(unclass(y)) < 0)
    stop("levels of actual observations not equal to the number of ",
         "columns of fitted values, or unequal ",
         "lengths of observations", call. = FALSE)
  ym <- matrix(0, nrow=obs, ncol=nL,
               dimnames=list(NULL, levels(y)))
  yi <- as.integer(y)
  ym[cbind(1:obs, yi)] <- 1
  if (type=="brier"){
    rs <- rowSums(ym)
    res <- sum(ym * (1 - prob)^2 + (rs - ym) *
                 prob^2) / sum(rs)}
  if (type=="logloss"){
    res <- -sum(ym * log(prob))/nrow(prob)}
  if (type=="misclass"){
    rr <- apply(prob, 1, which.max)
    rr <- rr - min(rr) + 1L
    hh <- vapply(seq_len(nrow(ym)), function(i) sum(ym[i, -rr[i]]),
                 numeric(1))
    res <- sum(hh) / sum(ym)}
  res
}

dvfun <- function(lambda, globalEff, x, y, startval, xlst, xMat, yMtx,
                  nL, obs, npar, linkf, link, vnull,control, slope, wt,
                  tuneMethod, m, mslope, Terms)
{
  rr <- NA
  tryCatch({
    rr <- serp.fit(lambda, x, y, wt, startval, xlst,
                   xMat, yMtx, nL, obs, npar, linkf, link,
                   vnull,control, slope, globalEff, m,
                   mslope, Terms, xtrace=FALSE);},
    error=function(e) {rr <- NA})
  if(is.list(rr)){
    if(tuneMethod == "aic"){
      tryCatch({rd <- -2*as.numeric(rr$logL) + 2*rr$edf;}, error=function(e) {rd <- NA})
    }
    if(tuneMethod == "finite"){
      tryCatch({rd <- -2*as.numeric(rr$exact.logL);}, error=function(e) {rd <- NA})
    }
  } else {rd <- Inf}

  return(rd)
}

Trace <- function (iter, maxGrad, obj, delta, step,
                   score, eigen, info, trc, inflector, first = FALSE,
                   half.iter = NULL, step.type = c("modify", "adjust", "full"))
{
  step.type <- match.arg(step.type)
  t1 <- sprintf("\n %3d:   %1.3e    %.5f  ",
                iter, maxGrad, -obj)
  if(step.type == "modify")
    cat(if (half.iter == 1) "\nTaking modified step." else ".")
  if(step.type == "adjust")
    cat(paste("\nSingular Hessian at iteration", iter,
              "inflating diagonal with",
              formatC(inflector, digits=5, format="f")))
  if(step.type == "full"){
    if (first)
      cat("iter:   max|grad|    logLik")
    cat(t1)
    if (trc > 1) {
      cat("\n\tdelta: ")
      cat(paste(formatC(delta, digits=3, format = "e")))
      cat("\n\tstep: ")
      cat(paste(formatC(-step, digits=3, format = "e")))
    }
    if (trc > 2) {
      cat("\n\tgrad: ")
      cat(paste(formatC(score, digits=3, format = "e")))
      cat("\n\teigen: ")
      cat(paste(formatC(eigen(info, symmetric = TRUE,
                              only.values = TRUE)$values, digits = 3L,
                        format = "e")))
    }
  }
}

varnames <- function(cofnames, coefs, nL)
{
  thresh <- sprintf("(Intercept):%d", 1:(nL-1))
  cfn <- make.unique(as.character(cofnames), sep = ":" )
  ind <- !duplicated(cofnames)
  for (i in seq_along(cfn[ind])){
    cfn[ind][i]<-ifelse(
      cofnames[ind][i] %in% cofnames[duplicated(cofnames)],
      gsub("(.*)","\\1:0", cfn[ind][i]), cfn[ind][i])}
  mx <- sub(".*:([0-9]+)","\\1",grep(":([0-9]*)$",cfn,value=TRUE) )
  mn <- sub("(.*:)[0-9]+","\\1",grep(":([0-9]*)$",cfn,value=TRUE) )
  mxm <- as.numeric(mx)+1
  cfn[grep(":([0-9]*)$",cfn)] <- paste0(mn,mxm)
  names(coefs) <- c(thresh, cfn)
  coefs
}

penalty.print <- function(object, max.tun)
{
  tun <- object$tuneMethod
  if (tun =='user'){
    h1 <- " "
    h2 <- round(object$lambda, 5L)
  }
  if (!tun == 'user'){
    if(tun == "cv")
      h1 <- round(as.numeric(object$testError), 6L)
    else
      h1 <- round(as.numeric(object$value), 6L)
    h2 <- round(as.numeric(object$lambda), 5L)
  }
  cat(crayon::green("\nRegularization Info:"))
  cat("\npenalty:", "  "," SERP")
  cat("\ntuneMethod:","" , tun)
  if (tun == "cv"){
    cat("\ncvMetric:",  "  ", object$cvMetric)
    cat("\ntestError:"," " , h1)
  }
  if (tun == "finite"){
    if (is.na(h1)) cat("\nvalue:","     " , h1)
    else cat("\nvalue:","    " , h1)
  }
  if (tun == "aic" || tun == "user")
    cat("\nvalue:","     " , h1)
  if (tun == "cv" || tun == "aic"){
    if (is.null(object$gridType)){
      len.lamG <- length(object$lambdaGrid)
      max.lam <- round(max(object$lambdaGrid))
    } else {
      len.lamG <- 2L
      max.lam <- round(object$control$maxpen)
    }
    if (!is.na(h2) && len.lamG > 1L &&
        round(h2) >= max.lam){
      cat("\nlambda:","    " , h2,'*')
      max.tun <- TRUE
    } else cat("\nlambda:","    " , h2)
  } else cat("\nlambda:","    " , h2)
  cat("\n")
  return(max.tun)
}

est.names <- function(coefs, slope, globalEff, colnames.x, x, m, npar,
                      xMat, nL, vnull, useout)
{
  if (slope == "parallel"){
    rr <- c(sprintf("(Intercept):%d", 1:(nL-1)), colnames.x[-1L])
    if(vnull == TRUE) rr <- rr[1:(nL-1)]
    names(coefs) <- rr
  }
  if (slope == "unparallel" || slope == "penalize"){
    xname <- rep(colnames.x[-1L], each = nL-1)
    rr <- c(sprintf("(Intercept):%d", 1:(nL-1)),
            paste(xname, 1:(nL-1), sep = ":"))
    if (vnull == TRUE) rr <- rr[1:(nL-1)]
    names(coefs) <- rr
  }
  if (slope == "partial"){
    xnam <- colnames(xMat)[-c(1:nL-1)]
    gb <- unlist(globalEff)
    subg <- subset(m, select = c(gb))
    subm <- model.matrix(~., data = subg)
    subn <- colnames(subm)[-1L]
    if (any(grepl(":", xnam))){
      subn2 <- xnam[which(grepl(":", xnam))]
      subn <- c(subn, subn2)
    }
    col.num <- seq_len(length(xnam))
    col.glo <- which(xnam %in% subn)
    specifc <- setdiff(col.num, col.glo)
    ss <- xnam[specifc]
    if (vnull == TRUE) ss <- ss[1:(nL-1)]
    ww <- rep(colnames.x[-1L], each = nL-1)
    ww <- ww[!duplicated(ww, incomparables = ss)]
    origvec <- varnames(xnam, coefs, nL)
    posvec <- varnames(ww, coefs, nL)
    coefs <- origvec[names(posvec)]
    if(useout) coefs <- posvec[names(origvec)]
  }
  coefs
}
