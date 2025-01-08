# automate qmd compilation
raw_data_sites <- list.files("data/raw_data", "harmonized") |>
  gsub(
    pattern = "harmonized_data_|_v1.csv|_temoin|_t[0-9]|[0-9]",
    replacement = ""
  ) |>
  unique()

in_plot_info <- read.csv("data/raw_data/bioforest-plot-information.csv") |>
  subset(!is.na(longitude) & !is.na(Treatment) & Treatment != "") |>
  select(site) |>
  unlist() |>
  tolower() |>
  gsub(pattern = " ", replacement = "_") |>
  gsub(pattern = "_km_|[0-9]", replacement = "") |>
  iconv(to = "ASCII//TRANSLIT") |>
  unique()

automate <- intersect(raw_data, in_plot_info)

# cache: if we don't want to redo the compilation for files that already exist

cache <- FALSE

if (cache) {
  done <- list.files("outputs/data_aggregation_reports/") |>
    gsub(pattern = "aggregated_data_|.csv", replacement = "")

  automate <- setdiff(automate, done)
}

for (s in automate) {
  # render document
  quarto::quarto_render(
    input = "analyses/data_aggregation.qmd",
    output_format = "all",
    output_file = paste0("data_aggregation_", s, ".pdf"),
    execute_params = list(site = s)
  )
  # move to "outputs/data_aggregation_reports" folder
  file.rename(
    from = paste0("data_aggregation_", s, ".pdf"),
    to = paste0("outputs/data_aggregation_reports/data_aggregation_", s, ".pdf")
  )
}
