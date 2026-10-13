# 08_plots.R --------------------------------------------------------------------
# Bar plots of the summary results. Reads the coded articles from 05_code_das.R
# and writes PNGs (300 dpi) to output/figures/.
#
# Figures
#   fig1_most_open_route        most open route claimed, each item counted once
#   fig2_routes_mentioned       every route mentioned (multi-label)
#   fig2b_routes_mentioned_excl_no_data  fig2 without 'no data generated' items
#   fig3_route_by_article_type  fig1 split: Research vs all other item types
#   fig4_statement_features     features of statements (flags), items with a statement
#   fig5_no_data_research_month research articles claiming no data, by month
#
# All counts are the machine (initial) coding; re-run after human checking if
# the checked codes replace the machine codes.
#
# Extra packages: ggplot2, scales

source("R/00_config.R")
library(ggplot2)
library(scales)

articles <- readRDS(file.path(cfg$dir_derived, "articles_coded.rds"))
fig_dir  <- file.path(cfg$dir_out, "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Palette and theme -------------------------------------------------------------
surface  <- "#fcfcfb"
bar_fill <- "#2a78d6"   # single series
ink <- c(primary = "#0b0b0b", secondary = "#52514e", muted = "#898781",
         grid = "#e1e0d9")

route_labels <- c(
  repository             = "Repository or public source",
  in_article             = "In article or supplementary files",
  restricted_third_party = "Restricted or held by a third party",
  on_request             = "On request",
  not_available          = "Not available",
  not_applicable         = "No data generated / not applicable",
  no_statement           = "No statement",
  unclassified           = "Unclassified"
)

theme_das <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background    = element_rect(fill = surface, colour = NA),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.grid.major.x = element_line(colour = ink[["grid"]], linewidth = 0.3),
      axis.text          = element_text(colour = ink[["secondary"]]),
      axis.title         = element_text(colour = ink[["secondary"]], size = rel(0.9)),
      plot.title         = element_text(colour = ink[["primary"]], face = "bold"),
      plot.subtitle      = element_text(colour = ink[["secondary"]], margin = margin(b = 8)),
      plot.caption       = element_text(colour = ink[["muted"]], hjust = 0, size = rel(0.8)),
      strip.text         = element_text(colour = ink[["primary"]], face = "bold", hjust = 0),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.margin        = margin(12, 16, 10, 12)
    )
}

n_items <- nrow(articles)
caption <- sprintf(paste0("Malaria Journal volume 24 (published 2025), n = %d items.\n",
                          "Machine (initial) coding of data availability statements; not yet human-checked."),
                   n_items)
lab_n_pct <- function(n, p) sprintf("%d (%.0f%%)", n, 100 * p)
save_fig  <- function(p, name, height) {
  ggsave(file.path(fig_dir, paste0(name, ".png")), p, width = 8, height = height, dpi = 300, bg = surface)
}
route_factor <- function(code) factor(route_labels[code], levels = rev(route_labels))

# Fig 1: most open route (each item once) ---------------------------------------
d1 <- articles |>
  count(most_open_route) |>
  complete(most_open_route = names(route_labels), fill = list(n = 0L)) |>
  mutate(p = n / sum(n), route = route_factor(most_open_route))

p1 <- ggplot(d1, aes(x = n, y = route)) +
  geom_col(fill = bar_fill, width = 0.62) +
  geom_text(aes(label = lab_n_pct(n, p)), hjust = -0.12, size = 3.2, colour = ink[["secondary"]]) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Most open route to the data claimed in each statement",
       subtitle = "Routes ordered from most to least open; each item counted once",
       x = "Items", y = NULL, caption = caption) +
  theme_das()
save_fig(p1, "fig1_most_open_route", 4.6)

# Fig 2: every route mentioned (multi-label) -------------------------------------
d2 <- tibble(code = names(route_labels),
             n = map_int(names(route_labels), \(cl) sum(articles[[cl]], na.rm = TRUE))) |>
  mutate(p = n / n_items, route = route_factor(code))

p2 <- ggplot(d2, aes(x = n, y = route)) +
  geom_col(fill = bar_fill, width = 0.62) +
  geom_text(aes(label = lab_n_pct(n, p)), hjust = -0.12, size = 3.2, colour = ink[["secondary"]]) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Routes to the data mentioned anywhere in the statement",
       subtitle = sprintf("A statement can mention several routes, so counts sum to more than %d", n_items),
       x = "Items", y = NULL, caption = caption) +
  theme_das()
save_fig(p2, "fig2_routes_mentioned", 4.6)

# Fig 2b: as fig 2, excluding items whose statement only says no data -----------
# Excludes items whose most open route is not_applicable (the statement claims
# nothing else). The one item that says "no data" but also offers data on
# request stays in, counted under its other route(s).
excl    <- filter(articles, most_open_route != "not_applicable")
codes2b <- setdiff(names(route_labels), "not_applicable")
d2b <- tibble(code = codes2b,
              n = map_int(codes2b, \(cl) sum(excl[[cl]], na.rm = TRUE))) |>
  mutate(p = n / nrow(excl),
         route = factor(route_labels[code], levels = rev(route_labels[codes2b])))

p2b <- ggplot(d2b, aes(x = n, y = route)) +
  geom_col(fill = bar_fill, width = 0.62) +
  geom_text(aes(label = lab_n_pct(n, p)), hjust = -0.12, size = 3.2, colour = ink[["secondary"]]) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Routes to the data mentioned, excluding 'no data generated' statements",
       subtitle = sprintf("n = %d items (%d excluded); a statement can mention several routes",
                          nrow(excl), n_items - nrow(excl)),
       x = "Items", y = NULL, caption = caption) +
  theme_das()
save_fig(p2b, "fig2b_routes_mentioned_excl_no_data", 4.4)

# Fig 3: most open route, Research vs other item types ---------------------------
d3 <- articles |>
  mutate(group = if_else(coalesce(article_type, "") == "Research",
                         "Research articles", "All other item types")) |>
  count(group, most_open_route) |>
  complete(group, most_open_route = names(route_labels), fill = list(n = 0L)) |>
  group_by(group) |>
  mutate(N = sum(n), p = n / N) |>
  ungroup() |>
  mutate(route = route_factor(most_open_route),
         group = factor(sprintf("%s (n = %d)", group, N)),
         group = relevel(group, grep("^Research", levels(group), value = TRUE)))

p3 <- ggplot(d3, aes(x = p, y = route)) +
  geom_col(fill = bar_fill, width = 0.62) +
  geom_text(aes(label = sprintf("%.0f%%", 100 * p)), hjust = -0.15, size = 3.0, colour = ink[["secondary"]]) +
  facet_wrap(~group, nrow = 1) +
  scale_x_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.25))) +
  labs(title = "Most open route claimed, by item type",
       subtitle = "Share within each group; other types are reviews, perspectives, corrections, notices etc.",
       x = "Share of items", y = NULL, caption = caption) +
  theme_das() +
  theme(panel.spacing = unit(1.5, "lines"))
save_fig(p3, "fig3_route_by_article_type", 4.8)

# Fig 4: features of statements (flags) -----------------------------------------
flag_labels <- c(
  f_reasonable_request   = "Access qualified as 'reasonable request'",
  f_corresponding_author = "Corresponding author named as contact",
  f_third_party          = "Third-party source or custodian named",
  f_url                  = "Includes a URL",
  f_privacy_ethics       = "Cites privacy, consent or ethics",
  f_identifier           = "Gives an accession number or data DOI",
  f_code                 = "Mentions code or software",
  f_not_public           = "States the data are not public",
  f_future_release       = "Promises a future release",
  f_template_text        = "Contains unfilled template text"
)
with_stmt <- filter(articles, !no_statement)
d4 <- tibble(code = names(flag_labels),
             n = map_int(names(flag_labels), \(cl) sum(with_stmt[[cl]], na.rm = TRUE))) |>
  mutate(p = n / nrow(with_stmt),
         # ascending levels put the most common feature at the top
         feature = factor(flag_labels[code], levels = flag_labels[code][order(n)]))

p4 <- ggplot(d4, aes(x = n, y = feature)) +
  geom_col(fill = bar_fill, width = 0.62) +
  geom_text(aes(label = lab_n_pct(n, p)), hjust = -0.12, size = 3.2, colour = ink[["secondary"]]) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Features of the statements",
       subtitle = sprintf("Items with a statement, n = %d; a statement can have several features", nrow(with_stmt)),
       x = "Items", y = NULL, caption = caption) +
  theme_das()
save_fig(p4, "fig4_statement_features", 4.8)

# Fig 5: research articles claiming no data, by month -----------------------------
d5 <- articles |>
  filter(article_type == "Research") |>
  mutate(month = factor(month.abb[as.integer(substr(published_online, 6, 7))], levels = month.abb),
         no_data = most_open_route == "not_applicable") |>
  group_by(month) |>
  summarise(N = n(), n = sum(no_data), .groups = "drop") |>
  mutate(p = n / N)

p5 <- ggplot(d5, aes(x = month, y = p)) +
  geom_col(fill = bar_fill, width = 0.62) +
  geom_text(aes(label = sprintf("%d/%d", n, N)), vjust = -0.5, size = 3.0, colour = ink[["secondary"]]) +
  scale_y_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Research articles stating that no data were generated or analysed",
       subtitle = sprintf("By month of online publication; labels show n / research articles (total %d / %d)",
                          sum(d5$n), sum(d5$N)),
       x = NULL, y = "Share of research articles", caption = caption) +
  theme_das() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = ink[["grid"]], linewidth = 0.3))
save_fig(p5, "fig5_no_data_research_month", 4.2)

message("Figures written to ", fig_dir)
