# run_all.R -----------------------------------------------------------------------
# Run from the project root (the folder containing R/, rules/, data/, output/).
# Full run downloads ~457 article pages at 1 per second plus ~457 JATS files:
# roughly 10-15 minutes. Downloads are cached in data/raw/, so re-runs are fast.

source("R/01_crossref.R")
source("R/02_europepmc.R")
source("R/03_springer.R")
source("R/04_extract.R")
source("R/05_code_das.R")
source("R/06_outputs.R")
if (file.exists("output/articles.csv")) source("R/07_compare_pilot.R")
source("R/08_plots.R")
