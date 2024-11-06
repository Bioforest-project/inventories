#' Taper correction function: estimates a stem's diameter at breast height (dbh)
#' from a measured diameter and the corresponding height of measurement. Adapted
#' from Cushman et al., 2014.
#'
#' @param diam stem's measured diameter in cm.
#' @param hom height of measurement in m.
taper <- function(diam, hom) {
  # default hom (no correction) when there is no reliable information
  hom[is.na(hom) | hom <= 0 | hom > 20] <- 1.3 
  b <- exp(-2.0205 - 0.5053 * log(diam) + 0.3748 * log(hom))
  return(diam * exp(b * (hom - 1.3)))
}
