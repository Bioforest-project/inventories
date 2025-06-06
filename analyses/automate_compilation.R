library(tidyverse)

# if updated script - remove old version of aggregated data
new <- FALSE
if (new) { # remove files that were not create today
  files <- "data/derived_data/" |>
    list.files("aggregated_data", full.names = TRUE)
  files[as.Date(file.info(files)$ctime) < Sys.Date()] |> file.remove()
}
# automate qmd compilation
raw_data_sites <- gsub(
  "^[^_]*_[^_]*_([^_]*)_.*$", "\\1",
  list.files("data/raw_data", "harmonized")
)

raw_data_sites <- raw_data_sites |>
  strsplit("-logged|-control|-postlogging|-t1|-t2|-t3|-temoin") |>
  lapply(first) |>
  unlist() |>
  c(raw_data_sites) |>
  # c(gsub("limoeiro", "limo", raw_data_sites)) |>
  unique()

agg_data_sites <- gsub(
  "^[^_]*_[^_]*_([^_]*)_.*$", "\\1",
  list.files("data/derived_data", "aggregated")
) |>
  unique()

in_plot_info <- read.csv("data/raw_data/bioforest-plot-information.csv",
  fileEncoding = "latin1"
) |>
  subset(!is.na(longitude)) |>
  mutate(Site = site) |>
  select(site) |>
  unlist() |>
  tolower() |>
  gsub(pattern = " ", replacement = "-") |>
  gsub(pattern = "_", replacement = "") |>
  iconv(to = "ASCII//TRANSLIT") |>
  unique()

compile_sites <- intersect(
  raw_data_sites,
  c("tene2018", in_plot_info, gsub("-", "", in_plot_info))
)

# removing sites that are not working
remove <- c(
  "gola" # gola: plots are very small, with a nested design of min DBH
  # group plots by clusters? + group trees by DBH
  # note: we only compile one pad-limo as all files are the same and contain the
  # entire set of pad-limo sites
)
compile_sites <- compile_sites[!compile_sites %in% remove]

# cache: if we don't want to redo the compilation for files that already exist
cache <- TRUE
if (cache) {
  done <- list.files("data/derived_data/", pattern = "aggregated_data_") |>
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
        execute_params = list(site = s, taper = FALSE, print = TRUE)
      )
      # move to "outputs/data_aggregation_reports" folder
      file.rename(
        from = paste0("data_aggregation_", s, ".pdf"),
        to = paste0("reports/data_aggregation_", s, ".pdf")
      )
    })
    if (inherits(error, "try-error")) {
      failed_sites <- c(failed_sites, s)
    }
  }
}

print(paste(
  "The following sites failed:",
  paste(failed_sites, collapse = ", ")
))

version <- 8
# delete previous files
paste0("data/derived_data/aggregated_data_v", seq_len(version), ".csv") |>
  file.remove()
# make one file with all sites
list.files("data/derived_data", "aggregated_data_", full.names = TRUE) |>
  lapply(function(x) read_csv(x, col_types = "ccicd")) |>
  data.table::rbindlist() |>
  write.csv(
    file = paste0("data/derived_data/aggregated_data_v", version, ".csv"),
    row.names = FALSE
  )

# copy to modelling folder
modelling_folder <- "D:/github/Bioforest-project/modelling/data/raw_data/"
if (dir.exists(modelling_folder)) {
  file.copy(paste0("data/derived_data/aggregated_data_v", version, ".csv"),
    modelling_folder,
    overwrite = TRUE
  )
}

# copy to demography folder
demography_folder <- "D:/github/Bioforest-project/demography/data/derived_data/"
if (dir.exists(demography_folder)) {
  file.copy(paste0("data/derived_data/aggregated_data_v", version, ".csv"),
    demography_folder,
    overwrite = TRUE
  )
}
