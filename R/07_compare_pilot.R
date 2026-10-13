# 07_compare_pilot.R -------------------------------------------------------------
# Compare an R run with the browser-run pilot (output/articles.csv). Use this to
# confirm the R pipeline reproduces the pilot before extending it to other volumes.

source("R/00_config.R")

r_run <- readRDS(file.path(cfg$dir_derived, "articles_coded.rds"))
pilot <- read_csv("output/articles.csv", col_types = cols(.default = "c"))

cols <- c("article_type", "das_text", "categories", "most_open_route",
          "corresponding_emails", "n_authors")
cmp <- inner_join(
  mutate(r_run, across(all_of(cols), as.character)) |> select(doi, all_of(cols)),
  select(pilot, doi, all_of(cols)),
  by = "doi", suffix = c("_r", "_pilot")
)

message("DOIs: R run ", nrow(r_run), ", pilot ", nrow(pilot), ", matched ", nrow(cmp))
for (cl in cols) {
  a <- cmp[[paste0(cl, "_r")]]; b <- cmp[[paste0(cl, "_pilot")]]
  same <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & squish(a) == squish(b))
  message(sprintf("%-22s identical: %d / %d", cl, sum(same), length(same)))
}
diffs <- cmp |> filter(categories_r != categories_pilot | squish(das_text_r) != squish(das_text_pilot))
write_csv(diffs, file.path(cfg$dir_out, "compare_r_vs_pilot_differences.csv"))
