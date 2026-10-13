# How open is malaria data? Pilot: Malaria Journal volume 24 (2025)

Phase 1 pilot. Every item in *Malaria Journal* volume 24 (articles 1–457, published online 5 Jan to 29 Dec 2025): title, authors, DOI, corresponding author emails, the verbatim data availability statement, a first-pass machine coding, and the journal's data availability policy with its history.

## Start here

`output/mj_vol24_data_availability_pilot.xlsx`. The README sheet explains every sheet; the yellow columns in `articles` are for the human check of the machine coding.

## Folder

| Path | What |
|---|---|
| `output/mj_vol24_data_availability_pilot.xlsx` | Pilot workbook |
| `output/articles.csv`, `output/authors.csv` | Same data for R (`readr::read_csv`) |
| `data/raw/mj_vol24_extract_2026-10-12.json` | Raw extract: Crossref records, parsed publisher pages and JATS, policy page texts |
| `data/raw/das_patch_2026-10-12.json` | Three statements under misspelt headings, re-fetched and checksum-verified |
| `rules/das_coding_rules.tsv` | Coding rules shared by R and Python |
| `R/` | Reproducible pipeline (`run_all.R`). **Not yet executed** (see below) |
| `python/` | Code that produced the pilot outputs from the raw extract |
| `browser/extract_vol24.js` | Browser code that produced the raw extract |

## How the pilot was produced

No R runtime and no network access were available to scripts in this session (neither in the cloud workspace nor in the sandboxed shell on this Mac). Retrieval therefore ran in the Claude desktop app's browser pane on this Mac (`browser/extract_vol24.js`), and was saved as JSON into this folder. `python/build_pilot.py` parsed it and applied `rules/das_coding_rules.tsv`; `python/build_workbook.py` wrote the workbook.

The R pipeline implements the same retrieval, parsing and coding (same rules file, same matching semantics). It has been checked by reading only. To confirm it reproduces the pilot, run from this folder in Positron:

```r
install.packages(c("httr2", "xml2", "rvest", "jsonlite", "dplyr", "purrr", "tidyr",
                   "stringr", "readr", "tibble", "writexl"))
source("R/run_all.R")   # ~10-15 min first run; downloads cached in data/raw/
```

`R/07_compare_pilot.R` runs at the end and writes `output/compare_r_vs_pilot_differences.csv`.

## Checks done

- Volume 24 article numbers 1–457 are complete (no gaps) in Crossref.
- All 457 publisher pages and 457 Europe PMC full texts retrieved (HTTP 200).
- The statement on the publisher page agrees with Europe PMC JATS for all 442 items where both exist, after ignoring case, punctuation and doi.org prefixes.
- Corresponding authors agree between the two sources for 456 of 456 items; emails agree for all 210 items where JATS carries them; author counts agree for 453 of 456 (the three differences involve group authorship).
- Summary formulas in the workbook reproduce the Python counts.

## Not done / limits

- The machine coding is the initial coder only; no human check yet.
- "repository" includes public third-party sources (e.g. DHS) when the statement calls them public; DHS access in fact requires registration. Decide the rule before human coding.
- Policy history is from Internet Archive snapshots and has a gap (Feb 2016 to May 2022) for the journal's own research-article instructions.
