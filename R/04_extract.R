# 04_extract.R ------------------------------------------------------------------
# Parse publisher pages (primary source: version of record) and Europe PMC JATS
# (secondary source, used to cross-check the data availability statement).
# Produces one row per article and one row per author.

source("R/00_config.R")
cr_vol <- readRDS(file.path(cfg$dir_derived, "crossref_target_volume.rds"))
ids    <- readRDS(file.path(cfg$dir_derived, "epmc_ids.rds"))

# Publisher page ---------------------------------------------------------------
parse_springer <- function(f) {
  doc  <- read_html(f)
  meta <- function(n) html_attr(html_element(doc, sprintf('meta[name="%s"]', n)), "content")

  # Authors: citation_author meta tags in document order; institution and email
  # tags that follow an author belong to that author
  m  <- html_elements(doc, 'meta[name^="citation_author"]')
  nm <- html_attr(m, "name")
  ct <- html_attr(m, "content")
  idx <- cumsum(nm == "citation_author")
  authors <- tibble(idx = idx, name = nm, content = ct) |>
    filter(idx > 0) |>
    group_by(idx) |>
    summarise(
      author       = content[name == "citation_author"][1],
      institutions = paste(content[name == "citation_author_institution"], collapse = " | "),
      email        = paste(content[name == "citation_author_email"], collapse = "; "),
      .groups = "drop"
    ) |>
    mutate(across(c(institutions, email), \(x) na_if(x, "")))

  corr <- html_elements(doc, '#corresponding-author-list a[href^="mailto:"]')
  corresp <- tibble(name = squish(html_text(corr)),
                    email = sub("^mailto:", "", html_attr(corr, "href")))

  h2    <- html_elements(doc, "h2")
  h2txt <- squish(html_text(h2))
  sec_of <- function(re) {
    hits <- which(grepl(re, h2txt, ignore.case = TRUE, perl = TRUE))
    map(hits, \(i) {
      sec <- xml_find_first(h2[[i]], paste0(
        "ancestor::*[self::section or contains(concat(' ', normalize-space(@class), ' '),",
        " ' c-article-section ')][1]"))
      if (inherits(sec, "xml_missing")) sec <- xml_parent(h2[[i]])
      content <- html_element(sec, ".c-article-section__content")
      if (inherits(content, "xml_missing")) content <- sec
      list(heading = h2txt[i], text = squish(html_text(content)),
           links = html_attr(html_elements(content, "a[href]"), "href"))
    })
  }
  # Fallback: statement under an h3 (e.g. inside a Declarations section)
  h3    <- html_elements(doc, "h3")
  h3txt <- squish(html_text(h3))
  h3_das <- map(which(grepl(das_heading_re, h3txt, ignore.case = TRUE, perl = TRUE)), \(i) {
    sibs <- xml_find_all(h3[[i]], "following-sibling::*")
    stop_at <- which(xml_name(sibs) %in% c("h2", "h3"))
    if (length(stop_at)) sibs <- sibs[seq_len(stop_at[1] - 1)]
    list(heading = h3txt[i], text = squish(paste(html_text(sibs), collapse = " ")),
         links = unlist(map(sibs, \(s) html_attr(html_elements(s, "a[href]"), "href"))))
  })

  list(title = meta("citation_title"), article_type = meta("citation_article_type"),
       online_date = meta("citation_online_date"), volume = meta("citation_volume"),
       firstpage = meta("citation_firstpage"), authors = authors, corresp = corresp,
       das = sec_of(das_heading_re), das_h3 = h3_das, code = sec_of(code_heading_re))
}

# Europe PMC JATS -------------------------------------------------------------
parse_jats <- function(f) {
  doc  <- xml_ns_strip(read_xml(f))
  secs <- xml_find_all(doc, "//sec[title] | //notes[title]")
  ttl  <- squish(xml_text(xml_find_first(secs, "./title")))
  styp <- xml_attr(secs, "sec-type")
  body_text <- function(s) squish(paste(xml_text(xml_find_all(s, "./node()[not(self::title)]")), collapse = " "))
  pick <- function(re) {
    hit <- which(grepl(re, ttl, ignore.case = TRUE, perl = TRUE) &
                   (is.na(styp) | styp != "data-availability-statement"))
    map(hit, \(i) list(heading = ttl[i], text = body_text(secs[[i]]),
                       links = xml_text(xml_find_all(secs[[i]], ".//ext-link/@*[local-name()='href']"))))
  }
  assoc <- map_chr(which(styp %in% "data-availability-statement"), \(i) body_text(secs[[i]]))

  fn <- xml_find_all(doc, "//author-notes/fn | //author-notes/corresp")
  fn_ids <- xml_attr(fn[grepl("correspond", xml_text(fn), ignore.case = TRUE)], "id")
  contribs <- xml_find_all(doc, "//contrib-group//contrib[@contrib-type='author'] | //contrib-group[@content-type='author']//contrib")
  is_corr <- map_lgl(contribs, \(c) {
    identical(xml_attr(c, "corresp"), "yes") ||
      any(xml_attr(xml_find_all(c, ".//xref[@ref-type='author-notes' or @ref-type='corresp']"), "rid") %in% fn_ids)
  })
  cname <- map_chr(contribs, \(c) squish(paste(
    xml_text(xml_find_first(c, ".//given-names")) %|% "",
    xml_text(xml_find_first(c, ".//surname")) %|% xml_text(xml_find_first(c, ".//collab")) %|% "")))

  list(article_type = xml_attr(xml_find_first(doc, "//article"), "article-type"),
       das = pick(das_heading_re), code = pick(code_heading_re), assoc_das = assoc,
       corresp_names = cname[is_corr], n_contrib = length(contribs))
}
`%|%` <- function(a, b) ifelse(is.na(a), b, a)
nz <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a[1])) b else a[1]

# Run --------------------------------------------------------------------------
first_or_na <- function(lst, field) if (length(lst)) lst[[1]][[field]] else NA_character_
collapse_or_na <- function(x) if (length(x) && any(nzchar(x))) paste(unique(x[nzchar(x)]), collapse = "; ") else NA_character_
# Compare texts ignoring case, punctuation and doi.org prefixes (the publisher
# page writes DOIs as https://doi.org/... links; JATS often writes bare DOIs)
norm_cmp <- function(x) gsub("[^a-z0-9]", "", gsub("https?://(dx\\.)?doi\\.org/", "", tolower(x)))

base <- left_join(cr_vol, ids, by = "doi")

parsed <- map(seq_len(nrow(base)), \(i) {
  d  <- base$doi[i]
  fh <- file.path(cfg$dir_html, paste0(doi_file(d), ".html"))
  fj <- if (!is.na(base$pmcid[i])) file.path(cfg$dir_jats, paste0(base$pmcid[i], ".xml")) else NA
  list(spr = if (file.exists(fh)) parse_springer(fh) else NULL,
       jats = if (!is.na(fj) && file.exists(fj)) parse_jats(fj) else NULL)
}, .progress = TRUE)

articles <- map(seq_len(nrow(base)), \(i) {
  s <- parsed[[i]]$spr; j <- parsed[[i]]$jats
  das_list <- if (!is.null(s) && length(s$das)) s$das else if (!is.null(s)) s$das_h3 else list()
  das_src  <- if (!is.null(s) && length(s$das)) "publisher_h2" else if (length(das_list)) "publisher_h3" else NA_character_
  jdas <- if (!is.null(j)) map_chr(j$das, "text") else character()
  if (is.na(das_src) && length(jdas)) { das_list <- j$das; das_src <- "jats" }
  das_text <- if (length(das_list)) paste(map_chr(das_list, "text"), collapse = " || ") else NA_character_
  tibble(
    doi = base$doi[i],
    volume = base$volume[i],
    article_number = base$article_number[i],
    published_online = base$published_online[i],
    title = nz(s$title, base$title_crossref[i]),
    article_type = nz(s$article_type, NA_character_),
    jats_article_type = nz(j$article_type, NA_character_),
    pmcid = base$pmcid[i], pmid = base$pmid[i],
    url = paste0("https://doi.org/", base$doi[i]),
    n_authors = if (!is.null(s)) nrow(s$authors) else NA_integer_,
    authors = if (!is.null(s)) paste(s$authors$author, collapse = "; ") else NA_character_,
    corresponding_authors = if (!is.null(s)) collapse_or_na(s$corresp$name) else NA_character_,
    corresponding_emails  = if (!is.null(s)) collapse_or_na(s$corresp$email) else NA_character_,
    all_author_emails     = if (!is.null(s)) collapse_or_na(na.omit(s$authors$email)) else NA_character_,
    jats_corresponding    = if (!is.null(j)) collapse_or_na(j$corresp_names) else NA_character_,
    das_heading = if (length(das_list)) paste(map_chr(das_list, "heading"), collapse = " || ") else NA_character_,
    das_text = das_text,
    das_links = if (length(das_list)) collapse_or_na(unlist(map(das_list, "links"))) else NA_character_,
    das_n_sections = length(das_list),
    das_source = das_src,
    jats_das_text = if (length(jdas)) paste(jdas, collapse = " || ") else NA_character_,
    das_sources_agree = if (length(jdas) && !is.na(das_text)) norm_cmp(das_text) == norm_cmp(paste(jdas, collapse = " || ")) else NA,
    epmc_assoc_das_text = if (!is.null(j)) collapse_or_na(j$assoc_das) else NA_character_,
    code_heading = if (!is.null(s) && length(s$code)) paste(map_chr(s$code, "heading"), collapse = " || ") else NA_character_,
    code_text = if (!is.null(s) && length(s$code)) paste(map_chr(s$code, "text"), collapse = " || ") else NA_character_,
    update_to = base$update_to[i]
  )
}) |> list_rbind()

authors_long <- map(seq_len(nrow(base)), \(i) {
  s <- parsed[[i]]$spr
  if (is.null(s) || !nrow(s$authors)) return(NULL)
  a <- s$authors
  orc <- base$authors_crossref[[i]]
  # Corresponding flag: match names first. Meta tags give "Surname, Given";
  # the correspondence list gives "Given Surname". Fall back to email only if
  # no name matches (one page gives two authors the same email address).
  flip <- function(n) ifelse(grepl(", ", n, fixed = TRUE),
                             paste(sub("^[^,]*, ", "", n), sub(", .*$", "", n)), n)
  key  <- function(n) gsub("[^a-z]", "", tolower(stringi::stri_trans_general(n, "Latin-ASCII")))
  by_name  <- key(flip(a$author)) %in% key(s$corresp$name)
  by_email <- !is.na(a$email) & a$email %in% s$corresp$email
  tibble(
    doi = base$doi[i], position = a$idx, author = a$author,
    institutions = a$institutions, email = a$email,
    corresponding = if (any(by_name)) by_name else by_email,
    # ORCID from Crossref, matched by position when author counts agree
    orcid = if (nrow(orc) == nrow(a)) orc$orcid else NA_character_
  )
}) |> list_rbind()

saveRDS(articles, file.path(cfg$dir_derived, "articles_extracted.rds"))
saveRDS(authors_long, file.path(cfg$dir_derived, "authors_long.rds"))
message("Articles: ", nrow(articles), "; no statement found: ", sum(is.na(articles$das_text)),
        "; publisher/JATS statements differ: ", sum(articles$das_sources_agree %in% FALSE))
