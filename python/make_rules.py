# Writes rules/das_coding_rules.tsv. Patterns are written once here (raw strings)
# and read by both R (grepl(perl = TRUE, ignore.case = TRUE)) and Python
# (re.search(flags = re.I)). Keep to syntax both engines share.
import csv, sys

TP = (r"ministry\s+of\s+health|\bmoh\b|national\s+malaria|malaria\s+control\s+program|\bnmcp\b|\bpnlp\b|"
      r"programme\s+national|national\s+center|bureau\s+of\s+statistics|public\s+health\s+institut|\bephi\b|\baphi\b|"
      r"\bicmr\b|\bnimr\b|\bkemri\b|\bpamverc\b|malaria\s+consortium|\bmoru\b|mahidol|committee|data\s+governance|"
      r"\bdhs\b|demographic\s+(?:and\s+)?health|dhsprogram|measure\s*dhs|\bwwarn\b|\bdhis2?\b|fellowship\s+program|"
      r"government|institutional\s+(?:approval|guidelines)|health\s+information\s+system|\bcmpe\b|\birss\b|\bkccr\b|swiss\s+tph")

REPO_NAMES = (r"dryad|zenodo|figshare|dataverse|genbank|\bncbi\b|sequence\s+read\s+archive|\bsra\b|\bena\b|european\s+nucleotide|"
              r"nucleotide\s+(?:data\s+)?archive|variation\s+archive|\bddbj\b|gene\s+expression\s+omnibus|arrayexpress|"
              r"proteomexchange|\bpride\b|mendeley\s+data|\bosf\b|open\s+science\s+framework|datashare|clinepidb|"
              r"vectorbase|plasmodb|malariagen|github|gitlab|bioproject|\binsdc\b|vivli|re3data|repository|data\s+lab\b|"
              r"study\s+database|sequence\s+database")
ACCESSION = (r"\bPRJ(?:NA|EB|DB)\d+|\b(?:SRR|ERR|DRR|SRP|ERP)\d+|\bPXD\d+|\bGSE\d+|"
             r"\b(?:OQ|OR|PP|PQ|PV|MN|MT|MW|MZ|ON|OP|OK|OL|KX|KY|MK|MH|MG)\d{6}\b|\bINRP\d+|accession")
OTHER_STUDIES = r"of\s+the\s+(?:included|original|primary)\s+studies"
DATA_DOI = r"10\.5061/|10\.6084/|10\.5281/|10\.7910/|10\.15139/|10\.7488/|10\.17632/|10\.17605/"
NEG_PUBLIC = r"not\s+(?:publicly|openly)|not\s+available\s+in\s+the\s+public|cannot\s+be\s+shared\s+publicly|not\s+be\s+made\s+publicly"
PUBLIC = (r"publicly\s+(?:available|accessible)|openly\s+available|public\s+domain|freely\s+available|available\s+online|"
          r"accessed\s+online|deposited|"
          r"(?:available|accessed|accessible|found|obtained|retrieved|downloaded)\s+(?:at|from|on|through|via|in)\s*:?\s*\[?\s*(?:https?:/|www\.)|"
          r"(?:available|accessible|accessed|found|retrieved|obtained)\s+(?:on|at|from|via|through)\s+[^.]{0,60}(?:https?:/|www\.)|"
          r"(?:provided|available)\s+at\s+https?:/")

rules = [
    # code, kind, scope, pattern, unless, require, description
    ("repository", "category", "sentence", REPO_NAMES, r"will\s+be\s+posted|forthcoming", "",
     "Named public repository, archive or database (not a promised future deposit)"),
    ("repository", "category", "statement", ACCESSION, "", "", "Accession number given"),
    ("repository", "category", "statement", DATA_DOI, "", "", "DOI prefix of a data repository"),
    ("repository", "category", "sentence", PUBLIC, NEG_PUBLIC + r"|publications|published\s+(?:articles|studies|literature)", "",
     "Statement says data are public/open/deposited, or gives a link where data can be accessed (negations excluded)"),
    ("in_article", "category", "sentence",
     r"(?:included|provided|contained|available|found)\s+(?:with\s?in|in)\s+(?:this|the|our)\s+(?:published\s+)?(?:article|manuscript|paper|text|main\s+text|main\s+manuscript)|"
     r"(?:are|is|been|be|were|was)\s+(?:presented\s+|reported\s+|shown\s+|given\s+)?(?:with\s?in|in)\s+(?:this|the|our)\s+(?:published\s+)?(?:article|manuscript|paper|text|main\s+text|main\s+manuscript)|"
     r"(?:supplementary|supplemental)\s+(?:information|files?|materials?|data|tables?)|"
     r"supporting\s+(?:information|files?|materials?)|additional\s+files?|suppl\.?\s+file|"
     r"dans\s+le\s+manuscrit|informations?\s+suppl", r"committee|applicants|proposal", "",
     "Data in the article or its supplementary/additional files"),
    ("on_request", "category", "sentence",
     r"(?:from|by|with|to|through|contact(?:ing)?)\s+(?:the\s+)?(?:corresponding|first|senior|lead|principal|study)?\s*"
     r"(?:authors?|investigators?|co-authors?)\b|"
     r"\bfrom\s+us\b|contact\s+us|available\s+with\s+us|project\s+data\s+manager", OTHER_STUDIES, "",
     "Request routed to the authors or study team"),
    ("on_request", "category", "sentence", r"corresponding\s+authors?|first\s+author|principal\s+investigator", OTHER_STUDIES,
     r"request|available|provid|obtain|contact|access|shar",
     "Corresponding/first author or PI named as source"),
    ("on_request", "category", "sentence", r"\brequests?\b|\brequested\b|on\s+demand",
     TP + r"|granted|was\s+obtained|register|researchers\s+must|" + OTHER_STUDIES, "",
     "Request mentioned, no third-party custodian in the same sentence, not a description of how the authors obtained data"),
    ("restricted_third_party", "category", "statement",
     r"access\s+committee|(?:sharing|governance)\s+committee|controlled\s+access|"
     r"data\s+(?:use|transfer|access|sharing)\s+agreement|\bdta\b|under\s+licen[cs]e|permission|"
     r"approval\s+(?:from|by)|institutional\s+approval|register\s+for\s+an\s+account|registration|custodian|"
     r"\bbelong(?:s)?\s+to\b|owned\s+by|regulated\s+by|secured\s+at|sound\s+proposal|official\s+requests?|"
     r"subject\s+to\s+(?:data[- ]sharing|meta)", "", "",
     "Controlled access, permission, agreement or custodianship"),
    ("restricted_third_party", "category", "sentence", TP, r"publicly|openly|public\s+domain|freely",
     r"request|available|access|obtain|provide|permission|approval|retriev|download",
     "Third-party organisation named as source or gatekeeper"),
    ("not_available", "category", "sentence",
     r"(?:will|can|could)\s*not\s+be\s+(?:made\s+)?(?:available|shared|provided)|cannot\s+be\s+(?:made\s+)?(?:shared|available)|"
     r"(?:are|is)\s+not\s+(?:available|shared)|not\s+be\s+shared|\bunavailable\b",
     r"request|available\s+(?:from|on|upon|in|at|with|via)|\bbut\b|however|public\s+domain|publicly|openly",
     "", "Some or all data explicitly not available, with no route given in the same sentence"),
    ("not_applicable", "category", "statement",
     r"no\s+(?:new\s+)?(?:datasets?|data)\s+(?:were|was|have\s+been)\s+(?:generated|analy[sz]ed|created|collected)|"
     r"not\s+applicable|does\s+not\s+rely\s+on\s+data|no\s+data\s+(?:are|is)\s+associated", "", "",
     "No data generated or analysed / not applicable"),
    # flags
    ("f_reasonable_request", "flag", "statement",
     r"reasonable\s+request|on\s+a\s+reasonable|upon\s+a\s+reasonable|valid\s+request|acceptable\s+request", "", "",
     "'Reasonable request' or similar qualifier"),
    ("f_corresponding_author", "flag", "statement", r"corresponding\s+authors?", "", "", "Corresponding author named as contact"),
    ("f_email_in_statement", "flag", "statement", r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", "", "", "Email address in statement"),
    ("f_url", "flag", "statement", r"https?:/|www\.", "", "", "URL in statement"),
    ("f_identifier", "flag", "statement", ACCESSION + "|" + DATA_DOI, "", "", "Accession number or data-repository DOI"),
    ("f_code", "flag", "statement",
     r"\bcodes?\b|\bscripts?\b|software|pipeline|github|gitlab|r\s+markdown|notebook|\.ipynb", "", "",
     "Code, scripts or software mentioned"),
    ("f_not_public", "flag", "statement",
     r"not\s+(?:publicly|openly)\s+available|not\s+available\s+in\s+the\s+public\s+domain|cannot\s+be\s+shared\s+publicly|"
     r"not\s+be\s+made\s+publicly|can\s+not\s+be\s+made\s+publicly|not\s+openly", "", "", "States data are not public"),
    ("f_privacy_ethics", "flag", "statement",
     r"identifiable|re-?identif|de-?identif|confidential|privacy|sensitiv|ethic|consent|anonym|personal(?:ly)?\s+identif", "", "",
     "Privacy, confidentiality, consent or ethics given as context or reason"),
    ("f_third_party", "flag", "statement",
     TP + r"|world\s+health\s+organi[sz]ation|who\.int|\bihme\b|healthdata\.org|world\s+bank|malaria\s+atlas|openstreetmap|"
     r"\busaid\b|meta\s+data\s+for\s+good|datasus|published\s+(?:articles|studies)|previously\s+reported|included\s+studies",
     "", "", "Data originate with or are held by another organisation or prior publications"),
    ("f_future_release", "flag", "statement",
     r"will\s+be\s+(?:publicly\s+)?(?:released|posted|deposited)|publicly\s+accessible\s+upon\s+publication|"
     r"will\s+be\s+(?:made\s+)?available\s+(?:immediately\s+)?(?:after|upon|following)\s+publication|after\s+(?:the\s+)?completion|"
     r"upon\s+publication|at\s+the\s+publication|following\s+publication|after\s+publication|will\s+be\s+submitted",
     "", "", "Promise of future release"),
    ("f_template_text", "flag", "statement", r"\[\s*(?:generated|analy[sz]ed|and\s+its)", "", "",
     "Unfilled template text in brackets"),
    ("f_non_english", "flag", "statement", r"donn[ée]es|fichiers|\bdatos\b|\bdados\b", "", "", "Statement not in English"),
]

w = csv.writer(open(sys.argv[1], "w", newline=""), delimiter="\t", quoting=csv.QUOTE_NONE, escapechar=None, lineterminator="\n")
w.writerow(["code", "kind", "scope", "pattern", "unless", "require", "description"])
for r in rules:
    for f in r:
        assert "\t" not in f and "\n" not in f
    w.writerow(r)
print(len(rules), "rules written")
