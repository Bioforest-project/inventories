#' Function to linearly interpolate missing diameter values for one stem. Returns a
#' data.frame with all diameters and years, including interpolated values (if
#' any).
#'
#' @param diam stem's measured diameters in cm.
#' @param years census years corresponding to diameter measurements.
#' @param all_years complete list of census years in the plot to which the stem
#'   belongs.
interpolate <- function(diam, years, all_years) {
  # add all measurement years
  df <- data.frame(diam, year = years) |>
    merge(data.frame(year = all_years), all = TRUE) |>
    # remove NA values before the first of after the last measured diameter
    subset(!(is.na(diam) & (year < min(years) | year > max(years))))
  # interpolate NA values
  df$diam <- approx(df$year, df$diam, df$year)$y
  return(df)
}
