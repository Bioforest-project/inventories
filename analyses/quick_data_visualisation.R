# quick data visualisation of all aggregated datasets
library(data.table)


control_string <- "unlogged|to be logged|old-growth|control|natural"
silv_string <- "treatment|devital|thinning"

plot_information <- read.csv("data/raw_data/bioforest-plot-information.csv") |>
  mutate(
    Treatment = ifelse(Treatment != "", Treatment, NA),
    logging = !grepl(control_string, tolower(Treatment)),
    silv_treat = grepl(silv_string, tolower(Treatment))
  ) |>
  ## remove plots that don't have coordinates and treatment information
  subset(!is.na(longitude) & !is.na(Treatment)) |>
  select(site, plot, logging, silv_treat)

data <- list.files("data/derived_data/", "aggregated", full.names = TRUE) |>
  lapply(read.csv) |>
  rbindlist(fill = TRUE, use.names = TRUE) |>
  merge(
    plot_information,
    by.x = c("Site", "Plot"),
    by.y = c("site", "plot"),
    all.x = TRUE
  )

data <- data |>
  mutate(treatment = paste0(
    ifelse(logging, "logging", "control"),
    ifelse(silv_treat, "\n+ silv. treat.", "")
  ))

for (var in unique(data$variable)) {
  subset(data, variable == var & value != 0) |>
    ggplot(aes(x = Year, y = value, group = Plot, col = treatment)) +
    geom_point() +
    geom_line() +
    ggrepel::geom_text_repel(
      data = filter(data, variable == var & Year == max(Year, na.rm = TRUE),
        .by = c("Site", "Plot")
      ),
      aes(label = Plot), col = 1
    ) +
    scale_color_manual(values = c("forestgreen", "coral", "darkmagenta")) +
    facet_wrap(~Site, scales = "free") +
    theme_minimal()
  ggsave(paste0("figures/summary_", var, ".pdf"), height = 15, width = 16)
}
