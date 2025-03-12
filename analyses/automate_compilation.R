library(tidyverse)

# automate qmd compilation
raw_data_sites <- gsub("^[^_]*_[^_]*_([^_]*)_.*$", "\\1", list.files("data/raw_data", "harmonized") ) |>
  unique()
  #list.files("data/raw_data", "harmonized") |>
  #gsub(
  #  pattern = "harmonized_data_|_v1.csv|_v2.csv|_temoin|_t[0-9]|_control_|_logged_|_loggedonce_[0-9][0-9][0-9][0-9]_|_loggedtwice_[0-9][0-9][0-9][0-9]_|_prelogging_|_postlogging_",
  #  replacement = ""
  #unique()

in_plot_info <- read.csv("data/raw_data/bioforest-plot-information.csv", fileEncoding='latin1') |>
  subset(!is.na(longitude)) |>
  select(site) |>
  unlist() |>
  tolower() |>
  gsub(pattern = " ", replacement = "") |>
  gsub(pattern = "_", replacement = "") |>
  #gsub(pattern = "_km_|[0-9]", replacement = "") |>
  #gsub(pattern = "sg_", replacement = "sungai") |>
  iconv(to = "ASCII//TRANSLIT") |>
  unique()

#compile_sites <- intersect(raw_data_sites, c("nelliyampathy","tene2018", in_plot_info))
compile_sites <- intersect(raw_data_sites, c("tene2018", in_plot_info))

#removing sites that are not working 
remove <- c( "mil")
compile_sites <- compile_sites[!compile_sites %in% remove] 

# cache: if we don't want to redo the compilation for files that already exist

cache <- TRUE

if (cache) {
  #done <- list.files("reports/") |>
  #  gsub(pattern = "data_aggregation_|.pdf", replacement = "")
  done <- list.files("data/derived_data/") |>
    gsub(pattern = "aggregated_data_|.csv", replacement = "")
  compile_sites <- setdiff(compile_sites, done)
}


failed_sites <- c()
if (length(compile_sites) > 0) {
  for (s in compile_sites) {
    # render document
    error <- try({
      quarto::quarto_render(
        input = "analyses/data_aggregation.qmd",
        output_format = "all",
        output_file = paste0("data_aggregation_", s, ".pdf"),
        execute_params = list(site = s, taper = FALSE)
      )
      # move to "outputs/data_aggregation_reports" folder
      file.rename(
        from = paste0("data_aggregation_", s, ".pdf"),
        to = paste0("reports/data_aggregation_", s, ".pdf")
      )
    })
    if(inherits(error, "try-error"))
      failed_sites <- c(failed_sites, s)
  }
}

print(paste("The following sites failed:",
            paste(failed_sites, collapse = ", ")))

# make one file with all sites
list.files("data/derived_data", "aggregated_data_", full.names = TRUE) |>
  lapply(read.csv) |>
  data.table::rbindlist() |>
  write.csv(file = "data/derived_data/aggregated_data.csv", row.names = FALSE)
list.files("data/derived_data", "aggregated_data_", full.names = TRUE) 
  #file.remove()

# make one file with all sites - plot area
list.files("data/derived_data", "plot_area", full.names = TRUE) |>
  lapply(read.csv) |>
  data.table::rbindlist() |>
  write.csv(file = "data/derived_data/plot_area.csv", row.names = FALSE)
list.files("data/derived_data", "plot_area_", full.names = TRUE) |>
  file.remove()
