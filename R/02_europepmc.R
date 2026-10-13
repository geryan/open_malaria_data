# 02_europepmc.R ----------------------------------------------------------------
# Map DOIs to PMCIDs through the Europe PMC search API, then download the
# JATS full text for each article. Europe PMC's JATS omits author email
# addresses; those come from the publisher pages (03_springer.R).

source("R/00_config.R")
cr_vol <- readRDS(file.path(cfg$dir_derived, "crossref_target_volume.rds"))

search_epmc <- function(query) {
  cursor <- "*"
  out <- list()
  repeat {
    resp <- request("https://www.ebi.ac.uk/europepmc/webservices/rest/search") |>
      req_url_query(query = query, format = "json", pageSize = 1000,
                    resultType = "lite", cursorMark = cursor) |>
      req_user_agent(cfg$user_agent) |>
      req_retry(max_tries = 4) |>
      req_perform()
    body <- resp_body_json(resp, simplifyVector = FALSE)
    res <- body$resultList$result
    out <- c(out, res)
    message("Europe PMC: ", length(out), " of ", body$hitCount)
    if (length(res) == 0 || is.null(body$nextCursorMark) || body$nextCursorMark == cursor) break
    cursor <- body$nextCursorMark
  }
  out
}

q <- sprintf("ISSN:%s AND FIRST_PDATE:[%s TO %s]", cfg$issn, "2024-12-01", cfg$date_until)
ep <- search_epmc(q)
ep_tbl <- tibble(
  doi            = map_chr(ep, \(e) tolower(e$doi %||% NA_character_)),
  pmcid          = map_chr(ep, \(e) e$pmcid %||% NA_character_),
  pmid           = map_chr(ep, \(e) e$pmid %||% NA_character_),
  epmc_pub_type  = map_chr(ep, \(e) e$pubType %||% NA_character_),
  epmc_first_pub = map_chr(ep, \(e) e$firstPublicationDate %||% NA_character_),
  epmc_oa        = map_chr(ep, \(e) e$isOpenAccess %||% NA_character_)
) |>
  filter(!is.na(doi)) |>
  distinct(doi, .keep_all = TRUE)

ids <- left_join(select(cr_vol, doi), ep_tbl, by = "doi")
message("Matched to Europe PMC: ", sum(!is.na(ids$pmcid)), " of ", nrow(ids))
saveRDS(ids, file.path(cfg$dir_derived, "epmc_ids.rds"))

# Download JATS (skips files already present)
walk(na.omit(ids$pmcid), \(p) {
  f <- file.path(cfg$dir_jats, paste0(p, ".xml"))
  if (file.exists(f)) return(invisible())
  resp <- get_with_retry(sprintf("https://www.ebi.ac.uk/europepmc/webservices/rest/%s/fullTextXML", p))
  if (resp_status(resp) == 200) writeLines(resp_body_string(resp), f, useBytes = TRUE)
  else message(p, ": HTTP ", resp_status(resp))
  Sys.sleep(0.2)
}, .progress = TRUE)
