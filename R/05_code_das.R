# 05_code_das.R -----------------------------------------------------------------
# Rule-based first-pass coding of each data availability statement (DAS).
# The machine coding is the INITIAL coder; a human checks every row.
#
# Rules live in rules/das_coding_rules.tsv (shared with python/build_pilot.py).
# Engine semantics, identical in both implementations:
#   * scope "statement": the rule fires if `pattern` matches the whole statement
#     and `unless` (if given) does not, and `require` (if given) does.
#   * scope "sentence": the statement is split into sentences; the rule fires if
#     any single sentence satisfies the same three conditions.
#   * a code is TRUE if any of its rules fire. Matching is case-insensitive PCRE.
# Derived fields: no_statement, unclassified, n_categories, categories,
#   most_open_route, f_contradiction, f_na_data_article.

source("R/00_config.R")
articles <- readRDS(file.path(cfg$dir_derived, "articles_extracted.rds"))

rules <- read.delim(cfg$rules_file, quote = "", comment.char = "", colClasses = "character",
                    na.strings = character(0), encoding = "UTF-8")

cats  <- c("repository", "in_article", "on_request", "restricted_third_party",
           "not_available", "not_applicable")
flags <- unique(rules$code[rules$kind == "flag"])
route_order <- c("repository", "in_article", "restricted_third_party", "on_request",
                 "not_available", "not_applicable")
data_types  <- c("Research", "Methodology", "Case Report", "Case Study")

# Sentence splitter; skips common abbreviations ("Suppl. File", "et al. 2016")
split_re <- "(?<![Ss]uppl)(?<!et al)(?<![Ff]ig)(?<![Ff]igs)(?<!e\\.g)(?<!i\\.e)(?<![Dd]r)(?<![Nn]o)[.;!?]\\s+"

has <- function(pattern, x) grepl(pattern, x, perl = TRUE, ignore.case = TRUE)

rule_hit <- function(r, text) {
  units <- if (r$scope == "statement") text else strsplit(text, split_re, perl = TRUE)[[1]]
  any(vapply(units, \(u) has(r$pattern, u) &&
               (r$unless == "" || !has(r$unless, u)) &&
               (r$require == "" || has(r$require, u)), logical(1)))
}

code_one <- function(text, article_type) {
  out <- setNames(as.list(rep(FALSE, length(c(cats, flags)))), c(cats, flags))
  if (is.na(text) || !nzchar(trimws(text))) {
    return(c(out, list(no_statement = TRUE, unclassified = FALSE, n_categories = 0L,
                       f_contradiction = FALSE, f_na_data_article = FALSE,
                       most_open_route = "no_statement", categories = "no_statement")))
  }
  for (i in seq_len(nrow(rules))) {
    r <- rules[i, ]
    if (!out[[r$code]] && rule_hit(r, text)) out[[r$code]] <- TRUE
  }
  hit <- cats[unlist(out[cats])]
  c(out, list(
    no_statement = FALSE,
    unclassified = length(hit) == 0,
    n_categories = length(hit),
    f_contradiction = out$not_applicable && any(unlist(out[setdiff(cats, "not_applicable")])),
    f_na_data_article = out$not_applicable && article_type %in% data_types,
    most_open_route = if (length(hit)) route_order[route_order %in% hit][1] else "unclassified",
    categories = if (length(hit)) paste(hit, collapse = "; ") else "unclassified"
  ))
}

coded <- map2(articles$das_text, articles$article_type, code_one) |>
  map(as_tibble) |>
  list_rbind()

articles_coded <- bind_cols(articles, coded) |>
  arrange(as.integer(article_number))

saveRDS(articles_coded, file.path(cfg$dir_derived, "articles_coded.rds"))
print(count(articles_coded, most_open_route, sort = TRUE))
