# 00_config.R -----------------------------------------------------------------
# Parameters for the Malaria Journal data availability pilot.
# Source this file first; every other script reads these objects.
#
# Pipeline (run in order, or source R/run_all.R):
#   01_crossref.R   Crossref metadata for the journal; keep target volume
#   02_europepmc.R  Map DOI -> PMCID; download JATS full text from Europe PMC
#   03_springer.R   Download publisher article pages (Springer Nature Link)
#   04_extract.R    Parse pages and JATS: article type, authors, emails,
#                   data availability statement (DAS), code availability
#   05_code_das.R   Rule-based first-pass coding of each DAS
#   06_outputs.R    Write CSV and xlsx outputs
#   07_compare_pilot.R  Compare this run against the browser-run pilot CSV
#
# Required packages: httr2, xml2, rvest, jsonlite, dplyr, purrr, tidyr,
#                    stringr, readr, tibble, writexl

suppressPackageStartupMessages({
  library(httr2)
  library(xml2)
  library(rvest)
  library(jsonlite)
  library(dplyr)
  library(purrr)
  library(tidyr)
  library(stringr)
  library(readr)
  library(tibble)
})

cfg <- list(
  issn          = "1475-2875",          # Malaria Journal
  target_volume = "24",                 # volume 24 = articles published 2025
  # Crossref has no volume filter, so query a wide date window and keep
  # target_volume. Volume 24 articles were published online 2025-01-05 to
  # 2025-12-29; 68 articles published online Nov-Dec 2025 carry volume 25.
  date_from     = "2024-10-01",
  date_until    = "2026-03-31",
  mailto        = "gezryan@gmail.com",  # Crossref polite pool
  user_agent    = "malaria-journal-open-data/0.1 (mailto:gezryan@gmail.com)",
  delay_s       = 1.0,                  # pause between page requests
  dir_raw       = "data/raw",
  dir_jats      = "data/raw/jats",
  dir_html      = "data/raw/html",
  dir_derived   = "data/derived",
  dir_out       = "output",
  rules_file    = "rules/das_coding_rules.csv"
)

for (d in c(cfg$dir_raw, cfg$dir_jats, cfg$dir_html, cfg$dir_derived, cfg$dir_out)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# Helpers ----------------------------------------------------------------------

# Squish whitespace (incl. non-breaking spaces) to single spaces
squish <- function(x) {
  x <- gsub("[   ]", " ", x)
  trimws(gsub("\\s+", " ", x))
}

# File-safe version of a DOI
doi_file <- function(doi) gsub("[^A-Za-z0-9._-]", "_", tolower(doi))

# Section headings treated as a data availability statement / code availability
# Tolerates misspelt headings seen in volume 24 ("Availiability of data
# materials", "Available of data and materials", "Data Availibility").
das_heading_re  <- "(avail\\w*\\s+of\\s+(the\\s+)?(data|supporting\\s+data)|data\\s+avail\\w*|data\\s+(and|&)\\s+(materials?|code)\\s+avail\\w*|^\\s*data\\s+sharing(\\s+statement)?\\s*$|^\\s*data\\s+access(\\s+statement)?\\s*$)"
code_heading_re <- "(code availability|availability of (code|software)|software availability)"

# GET with retries on 429 / 5xx
get_with_retry <- function(url, max_tries = 4) {
  request(url) |>
    req_user_agent(cfg$user_agent) |>
    req_retry(max_tries = max_tries,
              is_transient = \(resp) resp_status(resp) %in% c(429, 500, 502, 503, 504),
              backoff = \(i) 2 * i) |>
    req_error(is_error = \(resp) FALSE) |>
    req_perform()
}
