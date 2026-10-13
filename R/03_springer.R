# 03_springer.R -----------------------------------------------------------------
# Download the publisher's article page for each DOI. Malaria Journal article
# URLs on malariajournal.biomedcentral.com redirect to link.springer.com.
# Pages carry: article type, all authors with affiliations, corresponding
# author email(s), and the data availability statement (version of record).

source("R/00_config.R")
cr_vol <- readRDS(file.path(cfg$dir_derived, "crossref_target_volume.rds"))

log <- map(cr_vol$doi, \(d) {
  f <- file.path(cfg$dir_html, paste0(doi_file(d), ".html"))
  if (file.exists(f)) return(tibble(doi = d, status = 200L, final_url = NA_character_, cached = TRUE))
  resp <- get_with_retry(paste0("https://link.springer.com/article/", d))
  st <- resp_status(resp)
  if (st == 200) writeLines(resp_body_string(resp), f, useBytes = TRUE)
  Sys.sleep(cfg$delay_s)
  tibble(doi = d, status = st, final_url = resp$url, cached = FALSE)
}, .progress = TRUE) |> list_rbind()

log$retrieved <- format(Sys.time(), tz = "UTC", usetz = TRUE)
write_csv(log, file.path(cfg$dir_raw, "springer_fetch_log.csv"))
message("Pages not retrieved: ", sum(log$status != 200))
