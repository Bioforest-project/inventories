#' Function to linearly interpolate missing diameter values for one stem.
#' Returns a vector with all interpolated diameters (if any).
#'
#' @param diam stem's measured diameters in cm.
#' @param years census years corresponding to diameter measurements.
#'   belongs.
interpolate <- function(diam, years) {
  if (sum(!is.na(diam)) > 1) {
    return(approx(years, diam, years)$y)
  } else {
    return(diam)
  }
}
