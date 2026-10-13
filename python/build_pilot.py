"""Build the volume 24 pilot tables from the browser extract.

Reads the browser extract (JSON) and the heading patch, applies the shared coding
rules (rules/das_coding_rules.tsv), writes CSVs. Mirrors R/04_extract.R and
R/05_code_das.R. Usage:
    python3 -I python/build_pilot.py <extract.json> <patch.json> <rules.tsv> <outdir>
"""
import csv, json, re, sys, os, collections, hashlib, unicodedata

extract_f, patch_f, rules_f, outdir = sys.argv[1:5]
os.makedirs(outdir, exist_ok=True)
D = json.load(open(extract_f, encoding="utf-8"))
P = json.load(open(patch_f, encoding="utf-8"))["records"]

# ---- rules engine (identical semantics in R/05_code_das.R) -------------------
rules = list(csv.DictReader(open(rules_f, encoding="utf-8"), delimiter="\t", quoting=csv.QUOTE_NONE))
CATS = ["repository", "in_article", "on_request", "restricted_third_party", "not_available", "not_applicable"]
FLAGS = sorted({r["code"] for r in rules if r["kind"] == "flag"}, key=lambda c: [r["code"] for r in rules].index(c))
SPLIT = re.compile(r"(?<![Ss]uppl)(?<!et al)(?<![Ff]ig)(?<![Ff]igs)(?<!e\.g)(?<!i\.e)(?<![Dd]r)(?<![Nn]o)[.;!?]\s+")  # same pattern in R/05_code_das.R

def s(p, x):
    return re.search(p, x, flags=re.I) is not None

def rule_hit(r, text):
    units = [text] if r["scope"] == "statement" else SPLIT.split(text)
    for u in units:
        if s(r["pattern"], u) and (r["unless"] == "" or not s(r["unless"], u)) and (r["require"] == "" or s(r["require"], u)):
            return True
    return False

DATA_TYPES = {"Research", "Methodology", "Case Report", "Case Study"}
ROUTE_ORDER = ["repository", "in_article", "restricted_third_party", "on_request", "not_available", "not_applicable"]

def code_statement(text, article_type):
    out = {c: False for c in CATS + FLAGS}
    if text is None or text.strip() == "":
        out.update(no_statement=True, unclassified=False, n_categories=0, f_contradiction=False,
                   f_na_data_article=False, most_open_route="no_statement", categories="no_statement")
        return out
    for r in rules:
        if not out[r["code"]] and rule_hit(r, text):
            out[r["code"]] = True
    cats = [c for c in CATS if out[c]]
    out["no_statement"] = False
    out["unclassified"] = len(cats) == 0
    out["n_categories"] = len(cats)
    out["f_contradiction"] = out["not_applicable"] and any(out[c] for c in CATS if c != "not_applicable")
    out["f_na_data_article"] = out["not_applicable"] and article_type in DATA_TYPES
    out["most_open_route"] = next((c for c in ROUTE_ORDER if out[c]), "unclassified")
    out["categories"] = "; ".join(cats) if cats else "unclassified"
    return out

# ---- build tables -------------------------------------------------------------
norm_cmp = lambda t: re.sub(r"[^a-z0-9]", "", re.sub(r"https?://(dx\.)?doi\.org/", "", (t or "").lower()))
def uniq_join(xs):
    seen = []
    for x in xs:
        if x and x not in seen:
            seen.append(x)
    return "; ".join(seen) if seen else ""
def date_str(dp):
    if not dp: return ""
    p = dp["date-parts"][0]
    return "-".join([str(p[0])] + [f"{v:02d}" for v in p[1:]])

articles, authors = [], []
for x in D["records"]:
    c, sp, j = x["crossref"], x["spr"], x["jats"]
    das_list = sp["das"] or sp["das_h3"]
    src = "publisher_h2" if sp["das"] else ("publisher_h3" if sp["das_h3"] else "")
    patched = False
    if not das_list and x["doi"] in P:
        das_list = [P[x["doi"]]]; src = "publisher_h2_patch"; patched = True
    if not das_list and j["das"]:
        das_list = j["das"]; src = "jats"
    das_text = " || ".join(d["text"] for d in das_list)
    jdas = " || ".join(d["text"] for d in j["das"])
    agree = "" if not (das_text and jdas) else (norm_cmp(das_text) == norm_cmp(jdas))
    corr_names = [a["name"] for a in sp["corresp"]]
    corr_emails = [a["email"] for a in sp["corresp"]]
    cr_auth = c.get("author") or []
    row = {
        "doi": x["doi"],
        "volume": c.get("volume", ""),
        "article_number": c.get("article-number", ""),
        "published_online": date_str(c.get("published-online") or c.get("issued")),
        "title": sp.get("title") or " ".join(c.get("title") or []),
        "article_type": sp.get("article_type") or "",
        "jats_article_type": j.get("article_type") or "",
        "pmcid": x.get("pmcid") or "", "pmid": x.get("pmid") or "",
        "url": "https://doi.org/" + x["doi"],
        "n_authors": len(sp["authors"]),
        "authors": "; ".join(a["name"] for a in sp["authors"]),
        "corresponding_authors": uniq_join(corr_names),
        "corresponding_emails": uniq_join(corr_emails),
        "all_author_emails": uniq_join([a["email"] for a in sp["authors"] if a.get("email")]),
        "jats_corresponding": uniq_join(j.get("corresp_names") or []),
        "das_heading": " || ".join(d["heading"] for d in das_list),
        "das_text": das_text,
        "das_links": uniq_join([l for d in das_list for l in (d.get("links") or [])]),
        "das_n_sections": len(das_list),
        "das_source": src,
        "das_patched": patched,
        "jats_das_text": jdas,
        "das_sources_agree": agree,
        "epmc_assoc_das_text": uniq_join(j.get("assoc_das") or []),
        "code_heading": " || ".join(d["heading"] for d in sp["code"]),
        "code_text": " || ".join(d["text"] for d in sp["code"]),
        "update_to": "; ".join(f'{u.get("type")}:{u.get("DOI")}' for u in (c.get("update-to") or [])),
        "retrieved_utc": x.get("retrieved", ""),
    }
    row.update(code_statement(das_text, row["article_type"]))
    articles.append(row)
    orcids = [a.get("ORCID", "") for a in cr_auth] if len(cr_auth) == len(sp["authors"]) else [""] * len(sp["authors"])
    # corresponding flag: match names first ("Surname, Given" -> "Given Surname");
    # fall back to email only if no name matches (one page gives two authors the same email)
    flip = lambda n: (n.split(", ", 1)[1] + " " + n.split(", ", 1)[0]) if ", " in n else n
    key = lambda n: re.sub(r"[^a-z]", "", unicodedata.normalize("NFKD", n).encode("ascii", "ignore").decode().lower())
    ck = {key(c) for c in corr_names}
    by_name = [key(flip(a["name"])) in ck for a in sp["authors"]]
    by_email = [bool(a.get("email")) and a.get("email") in corr_emails for a in sp["authors"]]
    is_corr = by_name if any(by_name) else by_email
    for i, a in enumerate(sp["authors"], start=1):
        authors.append({
            "doi": x["doi"], "position": i, "author": a["name"],
            "institutions": " | ".join(a["institutions"]), "email": a.get("email") or "",
            "corresponding": is_corr[i - 1],
            "orcid": orcids[i - 1] or "",
        })

def write_csv(rows, f):
    with open(f, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)

articles.sort(key=lambda r: int(r["article_number"]))
write_csv(articles, os.path.join(outdir, "articles.csv"))
write_csv(authors, os.path.join(outdir, "authors.csv"))
print("articles", len(articles), "authors", len(authors))
print(collections.Counter(r["most_open_route"] for r in articles))
print({c: sum(r[c] for r in articles) for c in CATS + ["no_statement", "unclassified"] + FLAGS + ["f_contradiction", "f_na_data_article"]})
