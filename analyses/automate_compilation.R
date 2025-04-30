library(tidyverse)

# automate qmd compilation
raw_data_sites <- gsub(
  "^[^_]*_[^_]*_([^_]*)_.*$", "\\1",
  list.files("data/raw_data", "harmonized")
) |>
  strsplit("-") |>
  lapply(first) |>
  unlist() |>
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

# add sites which had "-" in the file name
add <- c("antimary-apu2", "antimary-apu3", "embrapa-acre")

# removing sites that are not working
remove <- c(
  "pad-limo-2-barracos", "pad-limo-chico-bocao", "pad-limo-cumaru",
  "pad-limo-jatoba", "pad-limo-pocao", "pad-limo-stcp", "pad-limo-tabocal"
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

version <- 7
# delete previous files
paste0("data/derived_data/aggregated_data_v", seq_len(version), ".csv") |>
  file.remove()
# make one file with all sites
list.files("data/derived_data", "aggregated_data_", full.names = TRUE) |>
  lapply(read.csv) |>
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
