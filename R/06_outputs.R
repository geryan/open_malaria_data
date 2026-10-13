# 06_outputs.R ------------------------------------------------------------------
# Write CSV outputs (for R) and a simple xlsx (two sheets). The richer pilot
# workbook (README, summary formulas, coding scheme, policy, sources checked)
# was built by python/build_workbook.py for the browser-run pilot.

source("R/00_config.R")
library(writexl)

articles <- readRDS(file.path(cfg$dir_derived, "articles_coded.rds"))
authors  <- readRDS(file.path(cfg$dir_derived, "authors_long.rds"))

stamp <- format(Sys.Date(), "%Y-%m-%d")
write_csv(articles, file.path(cfg$dir_out, sprintf("articles_vol%s_%s.csv", cfg$target_volume, stamp)), na = "")
write_csv(authors,  file.path(cfg$dir_out, sprintf("authors_vol%s_%s.csv",  cfg$target_volume, stamp)), na = "")
write_xlsx(list(articles = articles, authors = authors),
           file.path(cfg$dir_out, sprintf("mj_vol%s_data_availability_%s.xlsx", cfg$target_volume, stamp)))
message("Outputs written to ", cfg$dir_out)
