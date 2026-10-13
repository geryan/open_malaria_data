#!/bin/sh
# Rebuild the pilot outputs from the raw extract (run from the project root).
set -e
python3 -I python/make_rules.py rules/das_coding_rules.tsv
python3 -I python/build_pilot.py data/raw/mj_vol24_extract_2026-10-12.json data/raw/das_patch_2026-10-12.json rules/das_coding_rules.tsv output
python3 -I python/policy_history_data.py data/raw/mj_vol24_extract_2026-10-12.json output/policy_history.json
python3 -I python/build_workbook.py output data/raw/mj_vol24_extract_2026-10-12.json rules/das_coding_rules.tsv output/policy_history.json output/mj_vol24_data_availability_pilot.xlsx
# Formulas have no cached values until the workbook is opened in Excel (or recalculated in LibreOffice).
