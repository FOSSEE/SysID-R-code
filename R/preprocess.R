#' Remove offsets and linear trends
#' 
#' Removes offsets or trends from data
#' @param x an object of class \code{idframe}
#' @param type argument indicating the type of trend to be removed (Default=\code{0})
#'  \itemize{
#'    \item type=\code{0}: Subtracts mean value from each signal
#'    \item type=\code{1}: Subtracts a linear trend (least-squres fit)
#'    \item type=\code{trInfo} object: Subtracts a trend specified by the object
#'  }
#' 
#' @return 
#' A list containing two objects: the detrended data and the trend information
#' 
#' @details 
#' 
#' \code{R} by default doesn't allow return of multiple objects. The \code{\%=\%}
#' operator and \code{g} function in this package facillitate this behaviour. See 
#' the examples section for more information.
#' 
#' @aliases trInfo
#' 
#' @examples
#' data(cstr)
#' datatrain <- dataSlice(cstr,end=4500)
#' datatest <- dataSlice(cstr,4501)
#' g(Ztrain,tr) %=% detrend(datatrain) # Remove means
#' g(Ztest) %=% detrend(datatest,tr)
#' 
#' @seealso \code{\link[stats]{lm}}
#' @export
detrend <- function(x,type=0){ 
  z <- x 
  reg <- time(x)
  if(class(type)=="trInfo"){ # remove custom trend
    if(nOutputSeries(x)!=0){
      fit <- sweep(sweep(matrix(rep(reg,nOutputSeries(x)),ncol=nOutputSeries(x)),
                         2,type$OutputSlope,"*"),2,type$OutputOffset,"+")
      z$output <- x$output-fit
    }
    if(nInputSeries(x)!=0){
      fit <- sweep(sweep(matrix(rep(reg,nInputSeries(x)),ncol=nInputSeries(x)),
                         2,type$InputSlope,"*"),2,type$InputOffset,"+")
      z$input <- x$input-fit
    }
    tinfo <- type
  } else if(type == 0){ # remove means
    tinfo <- trInfo()
    if(nOutputSeries(x)!=0){
      outputData(z) <- apply(outputData(x),2,scale,T,F)
      tinfo$OutputOffset <- colMeans(x$output)
      tinfo$OutputSlope <- rep(0,nOutputSeries(x))
    }
    
    if(nInputSeries(x)!=0){
      inputData(z) <- apply(inputData(x),2,scale,T,F)
      tinfo$InputOffset <- colMeans(x$input)
      tinfo$InputSlope <- rep(0,nInputSeries(x))
    }
  } else if(type==1){
    formula <- X ~ reg
    
    # Function which performs linear regression across every column
    multilm <- function(x,formula,time){
      l <- lapply(as.list(x),function(x) data.frame(X=x,reg=time))
      trend <- lapply(l,function(x) lm(formula,data=x))
      trend
    }
    
    tinfo <- trInfo()
    if(nOutputSeries(x)!=0){
      output_trend <- multilm(outputData(x),formula,reg)
      outputData(z) <- ts(sapply(output_trend,resid),start=reg[1],
                          end=tail(reg,n=1),deltat=deltat(x))
      out_coefs <- sapply(output_trend,coef)
      tinfo$OutputOffset <- out_coefs[1,]
      tinfo$OutputSlope <- out_coefs[2,]
    }
    
    if(nInputSeries(x)!=0){
      input_trend <- multilm(inputData(x),formula,reg)
      inputData(z) <- ts(sapply(input_trend,resid),start=reg[1],
                         end=tail(reg,n=1),deltat=deltat(x))
      in_coefs <- sapply(input_trend,coef)
      tinfo$InputOffset <- in_coefs[1,]
      tinfo$InputSlope <- in_coefs[2,]
    }
  } else{
    stop("Error: Invalid trend type")
  }
  list(z,tinfo)
}

#' @export
trInfo <- function(InputOffset=numeric(0),OutputOffset=numeric(0),
                      InputSlope=numeric(0),OutputSlope=numeric(0)){
  l <- list(InputOffset=InputOffset,OutputOffset=OutputOffset,
            InputSlope=InputSlope,OutputSlope=OutputSlope)
  class(l) <- "trInfo"
  l
}

#' Replace Missing Data by Interpolation
#' 
#' Function for replacing missing values with interpolated ones. This is an
#' extension of the \code{na.approx} function from the \code{zoo} package.
#' The missing data is indicated using the value \emph{NA}.
#' 
#' @param data an object of class \code{idframe}
#' @return 
#' data (an idframe object) with missing data replaced.
#' 
#' @seealso \code{\link[zoo]{na.approx}}
#' 
#' @examples
#' data(cstr_mis)
#' summary(cstr_mis) # finding out the number of NAs
#' cstr <- misdata(cstr_mis)
#' 
#' @importFrom zoo na.approx
#' @export
misdata <- function(data){
  if (!requireNamespace("zoo", quietly = TRUE)) {
    stop("Package zoo needed for this function to work. Please install it.",
         call. = FALSE)
  }
  
  f <- function(var,start,end,Ts){
    time_range <- range(time(var))
    start <- time_range[1];end <- time_range[2]
    Ts <- stats::deltat(var)
    var <- ts(data=var,start=start,end=end,deltat=Ts)
    out <- zoo::na.approx(var,na.rm=F)
    return(as.numeric(out))
  }
  
  Z <- data
  outputData(Z) <- apply(outputData(data),2,f)
  inputData(Z) <- apply(inputData(data),2,f)
  Z
}


#' Subset or Resample idframe data
#' 
#' \code{dataSlice} is a subsetting method for objects of class \code{idframe}. It 
#' extracts the subset of the object \code{data} observed between indices \code{start}
#' and \code{end}.  If a frequency is specified, the series is then re-sampled at the 
#' new frequency.
#' 
#' @param data an object of class \code{idframe}
#' @param start the start index
#' @param end the end index
#' @param freq fraction of the original frequency at which the series
#' to be sampled.
#' 
#' @details
#' The dataSlice function extends the \code{\link[stats]{window}} 
#' function for idframe objects
#' 
#' @return an idframe object
#' 
#' @examples
#' data(cstr)
#' cstrsub <- dataSlice(cstr,start=200,end=400) # extract between indices 200 and 400
#' cstrTrain <- dataSlice(cstr,end=4500) # extract upto index 4500
#' cstrTest <- dataSlice(cstr,start=6501) # extract from index 6501 till the end
#' cstr_new <- dataSlice(cstr,freq=0.5) # resample data at half the original frequency  
#' 
#' @seealso \code{\link[stats]{window}}
#' @export
dataSlice <- function(data,start=NULL,end=NULL,freq=NULL){
  # check if the class is correct
  if(class(data)!='idframe')
    stop("Not an idframe data")
  
  indexWindow <- function(y,start,end,freq){
    Y <- matrix(y,ncol=ncol(y)); z <- as.vector(time(y))
    Y <- window(Y,start=start,end=end,frequency=freq)
    zw <- window(z,start=start,end=end,frequency=freq)
    temp <- ts(Y,start=zw[1],end=tail(zw,n=1),deltat=diff(zw)[1])
    colnames(temp) <- colnames(y)
    temp
  }
  if(nOutputSeries(data)!=0)
    outputData(data) <- indexWindow(outputData(data),start,end,freq)
  
  if(nInputSeries(data)!=0)
    inputData(data) <- indexWindow(inputData(data),start,end,freq)
  
  return(data)
}