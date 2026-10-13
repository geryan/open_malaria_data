# 01_crossref.R -----------------------------------------------------------------
# Crossref works for the journal across a date window, filtered to the target
# volume. Saves the raw JSON pages and a tidy table.

source("R/00_config.R")

select_fields <- paste(
  "DOI,title,author,volume,article-number,published-online,published-print",
  "issued,type,update-to,relation", sep = ","
)

fetch_crossref <- function() {
  cursor <- "*"
  pages <- list()
  repeat {
    resp <- request(sprintf("https://api.crossref.org/journals/%s/works", cfg$issn)) |>
      req_url_query(
        filter = sprintf("from-pub-date:%s,until-pub-date:%s", cfg$date_from, cfg$date_until),
        rows   = 1000,
        cursor = cursor,
        select = select_fields,
        mailto = cfg$mailto
      ) |>
      req_user_agent(cfg$user_agent) |>
      req_retry(max_tries = 4) |>
      req_perform()
    body <- resp_body_json(resp, simplifyVector = FALSE)
    items <- body$message$items
    pages[[length(pages) + 1]] <- items
    n_so_far <- sum(lengths(pages))
    message("Crossref: ", n_so_far, " of ", body$message$`total-results`)
    if (length(items) == 0 || n_so_far >= body$message$`total-results`) break
    cursor <- body$message$`next-cursor`
  }
  list_flatten(pages)
}

date_str <- function(x) {
  if (is.null(x)) return(NA_character_)
  dp <- unlist(x$`date-parts`[[1]])
  paste(c(dp[1], sprintf("%02d", dp[-1])), collapse = "-")
}

works <- fetch_crossref()
retrieved <- format(Sys.time(), tz = "UTC", usetz = TRUE)
write_json(list(retrieved = retrieved, items = works),
           file.path(cfg$dir_raw, "crossref_works.json"), auto_unbox = TRUE, null = "null")

cr <- tibble(
  doi              = map_chr(works, \(w) tolower(w$DOI)),
  volume           = map_chr(works, \(w) w$volume %||% NA_character_),
  article_number   = map_chr(works, \(w) w$`article-number` %||% NA_character_),
  title_crossref   = map_chr(works, \(w) squish(paste(unlist(w$title), collapse = " "))),
  published_online = map_chr(works, \(w) date_str(w$`published-online`)),
  issued           = map_chr(works, \(w) date_str(w$issued)),
  crossref_type    = map_chr(works, \(w) w$type %||% NA_character_),
  update_to        = map_chr(works, \(w) {
    u <- w$`update-to`
    if (is.null(u)) NA_character_ else paste(map_chr(u, \(z) paste0(z$type, ":", z$DOI)), collapse = "; ")
  }),
  authors_crossref = map(works, \(w) {
    a <- w$author
    if (is.null(a)) return(tibble())
    tibble(
      sequence = map_chr(a, \(z) z$sequence %||% NA_character_),
      given    = map_chr(a, \(z) z$given %||% NA_character_),
      family   = map_chr(a, \(z) z$family %||% z$name %||% NA_character_),
      orcid    = map_chr(a, \(z) z$ORCID %||% NA_character_)
    )
  })
)

message("Volumes in window: ", paste(names(table(cr$volume)), table(cr$volume), sep = "=", collapse = ", "))
cr_vol <- filter(cr, volume == cfg$target_volume)
message("Target volume ", cfg$target_volume, ": ", nrow(cr_vol), " works")

# Completeness check: BMC article numbers within a volume are sequential
an <- sort(as.integer(cr_vol$article_number))
gaps <- setdiff(seq_len(max(an)), an)
if (length(gaps)) warning("Missing article numbers: ", paste(gaps, collapse = ", "))

saveRDS(cr_vol, file.path(cfg$dir_derived, "crossref_target_volume.rds"))
saveRDS(cr, file.path(cfg$dir_derived, "crossref_window.rds"))
