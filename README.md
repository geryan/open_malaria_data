# How open is malaria data? Pilot: Malaria Journal volume 24 (2025)

Phase 1 pilot. It covers every item in *Malaria Journal* volume 24: articles 1–457, published online 5 Jan to 29 Dec 2025. For each item it records:

- title, authors, DOI and corresponding author emails;
- the verbatim data availability statement;
- a first-pass machine coding of that statement.

It also records the journal's data availability policy and its history.

Notes for Claude Code are in `CLAUDE.md`.

## Start here

`output/mj_vol24_data_availability_pilot.xlsx`. Its README sheet explains every sheet. The yellow columns in `articles` are for the human check of the machine coding. Figures are in `output/figures/`.

## Folder

| Path | What |
|---|---|
| `R/` | Pipeline: `source("R/run_all.R")` runs 01–08 |
| `rules/das_coding_rules.tsv` | Coding rules (shared by R and Python) |
| `python/` | Code that produced the pilot outputs from the browser extract |
| `browser/extract_vol24.js` | Browser code that produced the original extract |
| `data/raw/` | Crossref JSON, cached publisher pages and JATS, the browser extract, the heading patch |
| `data/derived/` | Intermediate `.rds` files |
| `output/` | Pilot workbook, CSVs, R outputs, `figures/` |

## How it was produced

**12 Oct 2026.** No R runtime or network was available to scripts at the time. Retrieval therefore ran in the Claude desktop app's browser pane, using Crossref, Europe PMC and link.springer.com. Python then applied the coding rules and built the workbook.

**13 Oct 2026.** The R pipeline was run on this Mac and reproduced the pilot exactly: 0 differences in statement text or coding across 457 items (`output/compare_r_vs_pilot_differences.csv`). Plots were added in `R/08_plots.R`.

## Checks done

- Volume 24 article numbers 1–457 are complete in Crossref.
- All 457 publisher pages and 457 Europe PMC full texts were retrieved.
- The publisher-page statement agrees with Europe PMC for all 442 items where both exist, ignoring case, punctuation and doi.org prefixes.
- Corresponding authors agree between the two sources for 456 of 456 items.
- Emails agree for all 210 items where Europe PMC includes them.
- Author counts agree for 453 of 456 items; the 3 differences involve group authorship.

## Limits

- The machine coding is the initial coder only. No human check has been done yet.
- "Repository" includes public third-party sources (e.g. DHS) when the statement calls them public, although DHS access requires registration.
- The policy history comes from Internet Archive snapshots. There is a gap from Feb 2016 to May 2022 for the journal's own research-article instructions.
