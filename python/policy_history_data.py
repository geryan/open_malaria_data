"""Policy summary, archive snapshot results, sources checked and data dictionary
for the pilot workbook. Snapshot flags were computed in the browser (term
presence in each archived page) on 2026-10-12 and transcribed here.
Usage: python3 -I python/policy_history_data.py <extract.json> <out.json>
"""
import json, sys
D = json.load(open(sys.argv[1], encoding="utf-8"))
P = D["policy"]
t = lambda u: P[u]["retrieved"] if u in P else ""
SG = "https://link.springer.com/journal/12936/submission-guidelines"
SGR = SG + "/research"
EP = "https://link.springer.com/brands/bmc/editorial-policies"

policy_rows = [
    {"topic": "Statement required (current)", "summary": "Every Malaria Journal manuscript must carry an 'Availability of data and materials' section under Declarations. If a section does not apply, authors keep the heading and write 'Not applicable'.",
     "short_quote": "All manuscripts must include an ‘Availability of data and materials’ statement.", "source": SGR, "section": "Declarations > Availability of data and materials", "retrieved_utc": t(SGR)},
    {"topic": "What 'data' means (current)", "summary": "The statement should say where the data supporting the reported results can be found, with links to archived datasets where applicable. 'Data' is defined as the minimal dataset needed to interpret, replicate and build on the findings. Where data cannot be public (e.g. privacy), availability and access conditions must still be stated.",
     "short_quote": "the minimal dataset that would be necessary to interpret, replicate and build upon", "source": SGR, "section": "Declarations > Availability of data and materials", "retrieved_utc": t(SGR)},
    {"topic": "Accepted statement forms (current)", "summary": "Templates offered (alone or combined): (1) in a named repository with persistent link; (2) from the corresponding author on reasonable request; (3) included in the article and supplementary files; (4) not public for a stated reason but available from the corresponding author on reasonable request; (5) data sharing not applicable because no datasets were generated or analysed; (6) held by a third party under licence, available from the authors on reasonable request with the third party's permission; (7) 'Not applicable' where the manuscript contains no data.",
     "short_quote": "", "source": SGR, "section": "Declarations > Availability of data and materials", "retrieved_utc": t(SGR)},
    {"topic": "Journal-level guidance (current)", "summary": "General submission guidelines: BMC journals strongly encourage or require authors to provide all datasets on which conclusions rely, by repository deposit or in the paper/supplementary files, in machine-readable form. Community-endorsed repository deposit is mandatory where that is the norm. Gives formatting templates for repository and additional-file statements; data on personal or departmental websites are not acceptable.",
     "short_quote": "", "source": SG, "section": "Prepare supporting information > Data and materials", "retrieved_utc": t(SG)},
    {"topic": "BMC data policy (current)", "summary": "Submission implies relevant raw data will be freely available to any scientist for non-commercial use without breaching confidentiality. BMC strongly encourages availability of all data underlying conclusions and mandates deposition where a community norm exists (e.g. nucleotide and protein sequences; novel sequences must go to INSDC repositories).",
     "short_quote": "BMC mandates data deposition in a public access repository upon submission", "source": EP, "section": "Availability of data and materials", "retrieved_utc": t(EP)},
    {"topic": "Data that cannot be shared openly (current)", "summary": "Authors must include the statement even if data cannot be shared openly, and give the reason. Editors of some journals may decline a manuscript if restrictions are unduly prohibitive. Restrictions on sensitive human data need an explanation and the conditions of access.",
     "short_quote": "", "source": EP, "section": "Availability of data and materials statements", "retrieved_utc": t(EP)},
    {"topic": "Post-publication obligation (current)", "summary": "After publication authors must comply with their statement and make data available as stated. If data cannot be produced the editor may investigate and contact the institution or funder. Relevant to Phase 2 (requests to authors).",
     "short_quote": "inability to gain access to the requested data may lead to a retraction.", "source": EP, "section": "Post-publication access of data", "retrieved_utc": t(EP)},
    {"topic": "Code and software (current)", "summary": "Previously unreported software or custom code should be available to editors and reviewers; the statement should describe access and link to an archived version with a DOI (Zenodo recommended for GitHub code).",
     "short_quote": "", "source": EP, "section": "Software and code", "retrieved_utc": t(EP)},
    {"topic": "Data citation and clinical trials (current)", "summary": "Publicly available datasets should be cited in the reference list with a persistent identifier (Force 11 principles). Clinical trial statements are encouraged to follow ICMJE data-sharing recommendations.",
     "short_quote": "", "source": EP, "section": "Data citation; Availability of data and materials statements", "retrieved_utc": t(EP)},
    {"topic": "Springer Nature policy type (current)", "summary": "Springer Nature's standardised research data policy requires data availability statements for primary research articles; the policy-types page states this is already in place for BMC journals. Legacy Types 1-4 apply to Springer and Palgrave titles only.",
     "short_quote": "", "source": "https://www.springernature.com/gp/authors/research-data-policy/data-policy-types/12327096", "section": "Legacy data policy types", "retrieved_utc": "2026-10-12 (WebFetch summary; page undated)"},
    {"topic": "History: before 2016", "summary": "Malaria Journal's research-article instructions (archived Nov 2011 to Jan 2015) contain no data availability section. BMC's editorial policies (archived 2013-2015) refer to an 'Availability of supporting data' policy page.",
     "short_quote": "", "source": "https://web.archive.org/web/20150117091253/http://www.malariajournal.com:80/authors/instructions/research", "section": "Instructions for authors: research", "retrieved_utc": "2026-10-12 (archive)"},
    {"topic": "History: January 2016", "summary": "Malaria Journal's instructions (archived 16 Jan 2016) include an 'Availability of supporting data' section and state that the journal requires deposition of supporting datasets in a public repository; the section is to be included only when supporting data are available, naming repository and identifier.",
     "short_quote": "Malaria Journal requires authors to deposit the data set(s) supporting the results", "source": "https://web.archive.org/web/20160116102104/http://www.malariajournal.com:80/authors/instructions/research", "section": "Availability of supporting data", "retrieved_utc": "2026-10-12 (archive)"},
    {"topic": "History: June 2016", "summary": "BMC editorial policies (archived 12 Jun 2016) rename the section 'Availability of data and materials' and require every manuscript to include it, with formatting templates.",
     "short_quote": "All authors must include an “Availability of Data and Materials” section", "source": "https://web.archive.org/web/20160612084632/http://www.biomedcentral.com:80/getpublished/editorial-policies", "section": "Availability of data and materials section", "retrieved_utc": "2026-10-12 (archive)"},
    {"topic": "History: January 2017 onward", "summary": "BMC editorial policies (archived 4 Jan 2017 to Jan 2021) add the template forms, including 'available from the corresponding author on reasonable request' and 'not applicable as no datasets were generated or analysed', and allow authors to decline sharing if they state why. From the Jan 2022 snapshot the templates are no longer on the BMC policy page; they appear on Malaria Journal's research-article page (archived Jun 2022 to Jul 2025) with the 'All manuscripts must include' wording.",
     "short_quote": "must state that data will not be shared, and give the reason", "source": "https://web.archive.org/web/20170104235045/http://www.biomedcentral.com/getpublished/editorial-policies", "section": "Availability of data and materials section", "retrieved_utc": "2026-10-12 (archive)"},
    {"topic": "History: not established", "summary": "No archived copy of a Malaria Journal research-article instructions page was found for Feb 2016 to May 2022 at the URLs checked, so the exact date the journal-level deposition requirement was dropped is not established. The 2011 and 2012 BMC blog posts on the 'Availability of supporting data' section could not be read (HTTPS-to-HTTP redirect). Manual search could check these and the journal's own editorials.",
     "short_quote": "", "source": "https://blogs.biomedcentral.com/bmcblog/2011/07/07/availability-of-supporting-data-crediting-transparency-and-enhancing-the-literature/", "section": "", "retrieved_utc": "not retrieved"},
]

T, F_ = True, False
def snap(target, ts, orig, aodm, aosd, must, reasonable, na_tmpl, no_ds, status=200):
    return {"target": target, "ts": ts, "orig": orig, "status": status,
            "flags": {"aodm": aodm, "aosd": aosd, "all_manuscripts": must, "reasonable": reasonable,
                      "not_applicable_tmpl": na_tmpl, "no_datasets": no_ds}}
B1 = "www.biomedcentral.com/about/editorialpolicies"
B2 = "www.biomedcentral.com/getpublished/editorial-policies"
M1 = "www.malariajournal.com/authors/instructions/research"
M2 = "malariajournal.biomedcentral.com/submission-guidelines/preparing-your-manuscript"
M3 = "malariajournal.biomedcentral.com/submission-guidelines/preparing-your-manuscript/research"
snapshots = (
    [snap(B1, ts, "http://www.biomedcentral.com:80/about/editorialpolicies", F_, T, F_, F_, F_, F_) for ts in ["20130419030403", "20140115091930", "20150209100611"]] +
    [snap(B2, "20160612084632", "http://www.biomedcentral.com:80/getpublished/editorial-policies", T, F_, T, F_, F_, F_)] +
    [snap(B2, ts, "https://www.biomedcentral.com/getpublished/editorial-policies", T, F_, T, T, T, T) for ts in ["20170104235045", "20181106143356", "20190320224532", "20200114221941", "20210118082338"]] +
    [snap(B2, ts, "https://www.biomedcentral.com/getpublished/editorial-policies", T, F_, T, F_, F_, F_) for ts in ["20220120091045", "20230110110720", "20240112145039", "20250116164125"]] +
    [snap(M1, ts, "http://www.malariajournal.com/authors/instructions/research", F_, F_, F_, F_, F_, F_) for ts in ["20111116083003", "20120115202034", "20130129013641", "20141023070436", "20150117091253"]] +
    [snap(M1, "20160116102104", "http://www.malariajournal.com:80/authors/instructions/research", F_, T, F_, F_, F_, F_)] +
    [snap(M2, "20160415013329", "http://malariajournal.biomedcentral.com/submission-guidelines/preparing-your-manuscript", F_, F_, F_, F_, F_, F_)] +
    [snap(M2, ts, "https://malariajournal.biomedcentral.com/submission-guidelines/preparing-your-manuscript", T, F_, F_, F_, F_, F_) for ts in ["20170214213221", "20190821163226", "20200807110058", "20210119160959", "20220210094352", "20230207122014", "20240513175118", "20250602102513"]] +
    [snap(M3, ts, "https://malariajournal.biomedcentral.com/submission-guidelines/preparing-your-manuscript/research", T, F_, T, T, T, T) for ts in ["20220627175210", "20230621020949", "20240301082104", "20250701201844"]]
)
# the 2013-15 BMC flag 'all_manuscripts' is the broader must-include test; 2016-04 M2 snapshot was a 1.5 kB stub page

run = D["run"]
sources = [
    {"source": "Crossref REST API", "url_or_query": "api.crossref.org/journals/1475-2875/works?filter=from-pub-date:2024-10-01,until-pub-date:2026-03-31 (cursor paging, select fields)", "what_was_checked": "All works in the window; volume, article number, title, authors, ORCID, dates, update-to", "when_utc": run["crossref_retrieved"], "method": "Browser pane fetch (user's Mac)", "outcome": "764 works: volume 23 = 110, 24 = 457, 25 = 197. Volume 24 article numbers 1-457, none missing. 68 volume-25 items were published online Nov-Dec 2025."},
    {"source": "Europe PMC search API", "url_or_query": "ISSN:1475-2875 AND FIRST_PDATE:[2024-12-01 TO 2026-03-31], resultType=lite", "what_was_checked": "DOI to PMCID/PMID mapping; open-access status", "when_utc": run["epmc_retrieved"], "method": "Browser pane fetch", "outcome": "694 records; all 457 volume-24 DOIs matched, all with PMCID, all open access."},
    {"source": "Europe PMC full text (JATS)", "url_or_query": "ebi.ac.uk/europepmc/webservices/rest/{PMCID}/fullTextXML x 457", "what_was_checked": "Article type, data availability section, corresponding author, code availability", "when_utc": f"{run['started']} to {run['finished']}", "method": "Browser pane fetch + DOMParser", "outcome": "457/457 HTTP 200. Corresponding authors are marked but email addresses are mostly absent, so emails were taken from publisher pages. Statement text agrees with the publisher page for all 442 items where both exist (after ignoring case, punctuation and doi.org prefixes)."},
    {"source": "Publisher article pages", "url_or_query": "link.springer.com/article/{DOI} x 457 (malariajournal.biomedcentral.com redirects here)", "what_was_checked": "Article type, title, authors, affiliations, corresponding author names and emails, data availability and code availability sections", "when_utc": f"{run['started']} to {run['finished']}", "method": "Browser pane fetch + DOMParser", "outcome": "457/457 HTTP 200. 15 items had no section matching the first heading pattern."},
    {"source": "Publisher article pages (re-fetch)", "url_or_query": "15 items without a statement, revised heading pattern", "what_was_checked": "Misspelt headings; statements elsewhere on page", "when_utc": "2026-10-12 ~00:52", "method": "Browser pane fetch; SHA-256 check of transcribed text", "outcome": "3 statements recovered under misspelt headings. 12 confirmed with no statement (11 corrections/notices/editorial/abstract; 1 systematic review)."},
] + [
    {"source": "Journal/BMC policy page", "url_or_query": u, "what_was_checked": "Current data availability requirements", "when_utc": v["retrieved"], "method": "Browser pane fetch; full text stored in the extract JSON", "outcome": f"HTTP {v['status']}"}
    for u, v in P.items()
] + [
    {"source": "Springer Nature research data policy types", "url_or_query": "https://www.springernature.com/gp/authors/research-data-policy/data-policy-types/12327096", "what_was_checked": "Which policy applies to BMC journals", "when_utc": "2026-10-12 ~01:05", "method": "WebFetch (summary only)", "outcome": "Standardised policy requiring data availability statements stated to be in place for BMC journals. Page undated."},
    {"source": "Internet Archive Wayback Machine", "url_or_query": "CDX + yearly snapshots: " + "; ".join([B1, B2, M1, M2, M3, "www.biomedcentral.com/about/policies/datasharing", "www.biomedcentral.com/about/editorial-policies"]), "what_was_checked": "Presence of data availability terms per year; key sentences in 2015, Jan 2016, Jun 2016, Jan 2017, Feb 2017 and Jun 2022 snapshots", "when_utc": "2026-10-12 00:58 to ~01:08", "method": "Browser pane (each action approved by user)", "outcome": "First attempt at 00:5x: 'Temporarily Offline'. Retry succeeded: 32 snapshots read. The last two URLs returned no captures. See 'policy' sheet."},
    {"source": "BMC blog posts", "url_or_query": "blogs.biomedcentral.com/bmcblog/2011/07/07/availability-of-supporting-data-... ; blogs.biomedcentral.com/bmcseriesblog/2012/10/10/bmc-series-launches-new-section-...", "what_was_checked": "When the 'Availability of supporting data' section was introduced", "when_utc": "2026-10-12 ~01:05", "method": "WebFetch", "outcome": "Not read: HTTPS redirects to HTTP and the fetch tool cannot follow. Titles (from search results only) indicate the section dates from 2011-2012. Manual check needed."},
    {"source": "Crossref and Europe PMC from cloud tools", "url_or_query": "api.crossref.org; ebi.ac.uk/europepmc (WebFetch and shell)", "what_was_checked": "Direct API access", "when_utc": "2026-10-12 ~00:15", "method": "Cloud shell and WebFetch", "outcome": "Shell: blocked (HTTP 403 at proxy). WebFetch: HTTP 429 rate limit. Not used."},
    {"source": "Remote shell on user's Mac", "url_or_query": "Rscript; curl to Crossref, Europe PMC, CRAN, PyPI", "what_was_checked": "Whether the R pipeline could run on the Mac from this session", "when_utc": "2026-10-12 ~00:34", "method": "device shell (sandboxed Linux VM)", "outcome": "No R installed; no network (all hosts refused). R pipeline not executed."},
]

dd = [
    ("articles", "article_number", "Article number within volume 24 (BMC continuous numbering).", "Crossref"),
    ("articles", "doi", "DOI, lower case.", "Crossref"),
    ("articles", "published_online", "Online publication date (YYYY-MM-DD).", "Crossref published-online"),
    ("articles", "article_type", "Publisher article type (citation_article_type).", "Publisher page"),
    ("articles", "title", "Article title.", "Publisher page"),
    ("articles", "n_authors / authors", "Author count and names in order, '; '-separated.", "Publisher page citation_author"),
    ("articles", "corresponding_authors / corresponding_emails", "Names and emails listed under 'Correspondence to'.", "Publisher page"),
    ("articles", "all_author_emails", "Every email in citation_author_email meta tags (usually the corresponding author only).", "Publisher page"),
    ("articles", "das_heading / das_text", "Heading and verbatim text of the data availability section (whitespace normalised). Multiple sections joined with ' || '.", "Publisher page (version of record)"),
    ("articles", "machine_categories", "Machine (initial) coding: categories present, '; '-separated. See coding_scheme.", "rules/das_coding_rules.tsv"),
    ("articles", "machine_most_open_route", "Most open route claimed (see coding_scheme).", "Derived"),
    ("articles", "repository ... not_applicable", "TRUE/FALSE per category.", "Derived"),
    ("articles", "no_statement / unclassified / n_categories", "Derived fields (see coding_scheme).", "Derived"),
    ("articles", "f_*", "Flags (see coding_scheme).", "Derived"),
    ("articles", "das_links", "Hyperlinks inside the statement section.", "Publisher page"),
    ("articles", "das_source", "Where the statement came from: publisher_h2, publisher_h2_patch (misspelt heading, re-fetched), jats.", "Pipeline"),
    ("articles", "das_patched", "TRUE when recovered by the heading re-fetch.", "Pipeline"),
    ("articles", "das_sources_agree", "Publisher and JATS statements identical after removing case, punctuation and doi.org prefixes.", "Derived"),
    ("articles", "jats_das_text", "Statement text from Europe PMC JATS.", "Europe PMC"),
    ("articles", "epmc_assoc_das_text", "Europe PMC 'Associated Data > Data Availability Statement', where present.", "Europe PMC"),
    ("articles", "code_heading / code_text", "Separate code availability section, if any.", "Publisher page"),
    ("articles", "jats_article_type / jats_corresponding", "Article type and corresponding author names from JATS (cross-check).", "Europe PMC"),
    ("articles", "pmcid / pmid", "PubMed Central and PubMed IDs.", "Europe PMC"),
    ("articles", "url", "https://doi.org/ link.", "Derived"),
    ("articles", "update_to", "Crossref update-to relation (corrections/retractions: which article is updated).", "Crossref"),
    ("articles", "retrieved_utc", "When this item was retrieved.", "Pipeline"),
    ("articles", "human_*", "Columns for the human checker (yellow). human_agrees_machine is a formula.", "Human"),
    ("authors", "doi / position / author", "Article DOI, author order, author name.", "Publisher page"),
    ("authors", "corresponding", "TRUE if listed under 'Correspondence to'.", "Publisher page"),
    ("authors", "email", "Email where published for that author.", "Publisher page"),
    ("authors", "institutions", "Affiliations, ' | '-separated.", "Publisher page citation_author_institution"),
    ("authors", "orcid", "ORCID from Crossref, matched by author position only when author counts agree; blank otherwise.", "Crossref"),
]
data_dictionary = [dict(zip(["sheet", "column", "description", "source"], r)) for r in dd]

json.dump({"policy_rows": policy_rows, "snapshots": snapshots, "sources_checked": sources, "data_dictionary": data_dictionary},
          open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("policy rows", len(policy_rows), "snapshots", len(snapshots), "sources", len(sources))
