# ==============================================================================
# INFLATION ARTICLE FILTERING - MERGED PIPELINE
# ==============================================================================

library(data.table)
library(stringi)

# Set max threads
setDTthreads(0)
message("Using ", getDTthreads(), " threads")

# ------------------------------------------------------------------------------
# LOAD DATA
# ------------------------------------------------------------------------------

message("\n=== LOADING DATA ===")
#infla_articles <- readRDS("C:/Users/lsikic/Desktop/inflacija_articles.rds")

if(!is.data.table(infla_articles)) {
  setDT(infla_articles)
}
message("Total articles loaded: ", format(nrow(infla_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 1: SOURCE TYPE - Keep only web
# ------------------------------------------------------------------------------

message("\n=== FILTER 1: SOURCE TYPE ===")
dt <- infla_articles[SOURCE_TYPE == "web"]
message("After web filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 2: RELEVANT NEWS PORTALS
# ------------------------------------------------------------------------------

message("\n=== FILTER 2: RELEVANT NEWS PORTALS ===")

# Major national news portals
national_news <- c(
  "index.hr", "jutarnji.hr", "vecernji.hr", "24sata.hr", 
  "tportal.hr", "dnevnik.hr", "net.hr", "rtl.hr", "hrt.hr",
  "telegram.hr", "nacional.hr", "direktno.hr", "n1info.com", "n1info.hr",
  "hina.hr", "novosti.hr"
)

# Business/Economic news
business_news <- c(
  "poslovni.hr", "seebiz.eu", "lidermedia.hr", "lider.media",
  "bloombergadria.com", "hrportfolio.hr", "energypress.net",
  "energetika-net.com", "jatrgovac.com", "gospodarski.hr",
  "privredni.hr", "ictbusiness.info"
)

# Regional news portals
regional_news <- c(
  "slobodnadalmacija.hr", "dalmatinskiportal.hr", "dalmacijadanas.hr",
  "dalmacijanews.hr", "antenazadar.hr", "zadarskilist.hr", "057info.hr",
  "sibenik.in", "sibenskiportal.hr", "dulist.hr", "dubrovnikinsider.hr",
  "dubrovnikportal.com", "dubrovnikpress.hr", "makarska-danas.com",
  "kastela.org", "plavakamenica.hr",
  "glasistre.hr", "novilist.hr", "istra24.hr", "istrain.hr",
  "rijekadanas.com", "istarski.hr", "porestina.info",
  "glas-slavonije.hr", "icv.hr", "034portal.hr", "035portal.hr",
  "slavonijainfo.com", "brodportal.hr", "ebrod.net", "epodravina.hr",
  "podravski.hr", "glaspodravine.hr", "pozeska-kronika.hr", "pozega.eu",
  "pozeski.hr",
  "zagreb.info", "01portal.hr", "prigorski.hr",
  "varazdinske-vijesti.hr", "sjever.hr", "medjimurjepress.net",
  "medjimurski.hr", "zagorje.com", "zagorje-international.hr",
  "vzaktualno.hr", "evarazdin.hr", "muralist.hr", "drava.info",
  "sjeverni.info",
  "karlovacki.hr", "radio-banovina.hr", "likaclub.eu", "044portal.hr",
  "radiokrizevci.hr", "bjelovar.live", "mnovine.hr"
)

# Specialized news
specialized_news <- c(
  "agroklub.com", "mirovina.hr", "legalis.hr", "srednja.hr",
  "studentski.hr", "gov.hr", "fino.hr"
)

# Opinion/Analysis portals
opinion_portals <- c(
  "7dnevno.hr", "dnevno.hr", "hrvatska-danas.com", "otvoreno.hr",
  "narod.hr", "glas.hr", "novine.hr", "priznajem.hr", "kamenjar.com",
  "politikaplus.com", "maxportal.hr", "novo.hr", "logicno.com",
  "totalinfo.hr", "geopolitika.news", "nacionalno.hr", "portalnovosti.com",
  "liberoportal.hr", "hrvatski-fokus.hr", "objektivno.hr", "stvarnost.hr",
  "tockanai.hr", "suvremena.hr", "cronika.hr", "hrv.hr"
)

relevant_sources <- unique(c(national_news, business_news, regional_news, 
                             specialized_news, opinion_portals))

dt <- dt[FROM %in% relevant_sources]
message("After source filter: ", format(nrow(dt), big.mark = ","))

# Add source category
dt[, source_category := fcase(
  FROM %in% national_news, "national",
  FROM %in% business_news, "business",
  FROM %in% regional_news, "regional",
  FROM %in% specialized_news, "specialized",
  FROM %in% opinion_portals, "opinion",
  default = "other"
)]

cat("\nBy category:\n")
print(dt[, .N, by = source_category][order(-N)])

# ------------------------------------------------------------------------------
# FILTER 3: MINIMUM TEXT LENGTH
# ------------------------------------------------------------------------------

message("\n=== FILTER 3: TEXT LENGTH ===")
dt[, text_length := nchar(FULL_TEXT)]
dt <- dt[text_length >= 500]
message("After length filter (>=500 chars): ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 4: TITLE MUST CONTAIN INFLATION-RELATED TERM
# ------------------------------------------------------------------------------

message("\n=== FILTER 4: TITLE RELEVANCE ===")

title_pattern <- paste0(
  "(",
  "inflacij|",
  "cijena|cijene|cijenu|",
  "poskup|pojeftin|",
  "tro[sš]kov.*[zž]ivota|",
  "kupovn.*mo[cć]|",
  "[zž]ivotn.*standard|",
  "goriva|benzin|dizel|struj[aeu]|plin[au]?|",
  "hran[aeu]|namirnic|",
  "kamatn|monetarn|",
  "HNB|ECB|DZS|Eurostat|",
  "ko[sš]aric|",
  "re[zž]ij|",
  "energen|",
  "HICP|CPI",
  ")"
)

dt[, title_relevant := stri_detect_regex(TITLE, title_pattern, case_insensitive = TRUE)]
dt <- dt[title_relevant == TRUE]
message("After title filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 5: CORE INFLATION TERM IN TEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 5: CORE TERM VERIFICATION ===")

core_pattern <- paste0(
  "(",
  # Inflation word (all inflections)
  "inflacij[aeiou]?[mj]?[ao]?|",
  "dezinflacij|hiperinflacij|stagflacij|",
  
  # Price index
  "indeks potro[sš]a[cč]kih cijena|HICP|",
  
  # Price movements
  "poskupljenj|pojeftinjenj|",
  "rast cijena|porast cijena|pad cijena|skok cijena|",
  "cijene (rastu|porasle|padaju|pale|skočile)|",
  
  # Cost of living
  "tro[sš]kov[aei]? [zž]ivota|",
  "[zž]ivotn[aeiou]? standard|",
  "kupovn[aeu] mo[cć]|",
  "realn[aeiou]? pla[cć][aeu]?|",
  "realn[aeiou]? primanj|",
  
  # Specific prices
  "cijena?e? goriva|",
  "cijena?e? hrane|",
  "cijena?e? struje|",
  "cijena?e? plina|",
  "cijena?e? benzina|",
  "cijena?e? energenata|",
  "cijena?e? namirnica|",
  
  # Policy
  "zamrzavanj[aeiou]? cijena|",
  "regulacij[aeiou]? cijena|",
  
  # Consumer basket
  "potro[sš]a[cč]k[aeiou]+ ko[sš]aric|",
  
  # Monetary
  "kamatn[aeiou]? stop[aeu]?|",
  "monetarn[aeiou]? politik",
  ")"
)

dt[, has_core := stri_detect_regex(FULL_TEXT, core_pattern, case_insensitive = TRUE)]
dt <- dt[has_core == TRUE]
message("After core term filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# OPTIONAL: EXCLUSION FILTER (can skip if dataset is clean enough)
# ------------------------------------------------------------------------------

message("\n=== FILTER 6: EXCLUSION CHECK ===")

excl_pattern <- paste0(
  "(",
  # Sports
  "nogomet|ko[sš]ark|rukomet|tenis|vaterpolo|",
  "liga prvak|premijer lig|bundeslig|",
  "utakmic|golova|igra[cč]|trener|mom[cč]ad|",
  "Dinamo|Hajduk|UEFA|FIFA|NBA|olimpijsk|",
  "sportski|reprezentacij|prvenstv|",
  
  # Entertainment
  "glumac|glumic|redatelj|",
  "koncert|festival|",
  "pjeva[cč]|album|pjesm|",
  "reality|showbiz|celebrity|",
  
  # Other noise
  "horoskop|astrolog|",
  "vremenska prognoza|",
  "tv program",
  ")"
)

override_pattern <- paste0(
  "(",
  "inflacij|",
  "\\bDZS\\b|\\bHNB\\b|\\bECB\\b|\\bEurostat\\b|",
  "indeks potro[sš]a[cč]kih cijena|",
  "\\bCPI\\b|\\bHICP\\b|",
  "kupovn[aeu] mo[cć]|",
  "monetarn|kamatn|",
  "tro[sš]kov.*[zž]ivota|",
  "poskupljenj|pojeftinjenj",
  ")"
)

dt[, excl := stri_detect_regex(FULL_TEXT, excl_pattern, case_insensitive = TRUE)]
dt[, override := stri_detect_regex(FULL_TEXT, override_pattern, case_insensitive = TRUE)]
dt[, passes_exclusion := (!excl | override)]

excluded_count <- sum(!dt$passes_exclusion)
message("Excluded by sports/entertainment (without override): ", excluded_count)

dt <- dt[passes_exclusion == TRUE]
message("After exclusion filter: ", format(nrow(dt), big.mark = ","))


# ------------------------------------------------------------------------------
# FILTER 6: CROATIAN CONTEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 6: CROATIAN CONTEXT ===")

croatian_pattern <- paste0(
  "(",
  # Country references
  "\\bHrvatsk[aeiou]?[mj]?|\\bRH\\b|\\bHR\\b|",
  
  # Institutions
  "\\bHNB\\b|\\bDZS\\b|Vlad[aeiou] RH|Vlad[aeiou] Republike Hrvatske|",
  "Hrvatska narodna banka|Dr[zž]avn[io] zavod za statistiku|",
  "Hrvatsk[aeiou] agencij|Ministarstvo|",
  
  # Cities (major ones)
  "Zagreb|Split|Rijeka|Osijek|Zadar|Pula|Slavonski Brod|",
  "Karlovac|Vara[zž]din|[SŠ]ibenik|Dubrovnik|",
  
  # Currency/Economic terms
  "\\beuro?[aeimu]?\\b.*\\bHrvatsk|Hrvatska.*\\beuro?[aeimu]?\\b|",
  "\\bkun[aeiou]?[mj]?\\b|kunama|",
  
  # Regional
  "\\bu nas\\b|kod nas|na[sš][aeiou]? tr[zž]i[sš]|hrvatsk[aeiou]? tr[zž]i[sš]|",
  "doma[cć][aeiou]? tr[zž]i[sš]|doma[cć]i potro[sš]a[cč]i|",
  
  # Comparative
  "\\bEU prosjek|europski prosjek.*Hrvatska|Hrvatska.*europski prosjek",
  ")"
)

dt[, croatian_context := stri_detect_regex(FULL_TEXT, croatian_pattern, case_insensitive = TRUE)]

# Show how many would be filtered
message("Articles WITH Croatian context: ", format(sum(dt$croatian_context), big.mark = ","))
message("Articles WITHOUT Croatian context: ", format(sum(!dt$croatian_context), big.mark = ","))

dt <- dt[croatian_context == TRUE]
message("After Croatian context filter: ", format(nrow(dt), big.mark = ","))




# ------------------------------------------------------------------------------
# FINAL DATASET
# ------------------------------------------------------------------------------

message("\n", strrep("=", 80))
message("FINAL RESULTS")
message(strrep("=", 80))

message("\nFinal article count: ", format(nrow(dt), big.mark = ","))

message("\nBy source category:")
print(dt[, .N, by = source_category][order(-N)])

message("\nTop 15 sources:")
print(head(sort(table(dt$FROM), decreasing = TRUE), 15))

message("\nBy year:")
dt[, year := format(as.Date(DATE), "%Y")]
print(dt[, .N, by = year][order(year)])

# ------------------------------------------------------------------------------
# QUALITY CONTROL - SAMPLE TITLES
# ------------------------------------------------------------------------------

message("\n", strrep("=", 80))
message("QUALITY CONTROL - 20 RANDOM TITLES")
message(strrep("=", 80))

set.seed(123)
sample_idx <- sample(nrow(dt), min(20, nrow(dt)))

for(i in seq_along(sample_idx)) {
  idx <- sample_idx[i]
  message(sprintf("%2d. [%s] %s", i, dt$FROM[idx], substr(dt$TITLE[idx], 1, 80)))
}

# ------------------------------------------------------------------------------
# EXTRACT MATCHED WORDS FOR QC
# ------------------------------------------------------------------------------

message("\n=== EXTRACTING MATCHED TERMS ===")

extract_words <- function(text, pattern) {
  matches <- stri_extract_all_regex(text, pattern, case_insensitive = TRUE)
  sapply(matches, function(x) paste(unique(na.omit(x)), collapse = "; "))
}

dt[, matched_terms := extract_words(FULL_TEXT, core_pattern)]

# Word frequency
message("\nTop 20 matched terms:")
all_words <- unlist(stri_split_fixed(dt$matched_terms, "; "))
all_words <- all_words[all_words != ""]
all_words <- tolower(all_words)
freq <- sort(table(all_words), decreasing = TRUE)
print(head(freq, 20))

# ------------------------------------------------------------------------------
# SAVE
# ------------------------------------------------------------------------------

message("\n=== SAVING ===")

# Select final columns
dt_final <- dt[, .(
  DATE, 
  FROM,
  URL,
  TITLE, 
  FULL_TEXT,
  MENTION_SNIPPET,
  SOURCE_TYPE,
  AUTHOR,
  source_category,
  text_length,
  matched_terms,
  REACH,
  INTERACTIONS
)]

# Save RDS
write_path_rds <- "C:/Users/lsikic/Desktop/inflacija_filtered.rds"
saveRDS(dt_final, write_path_rds)
message("Saved RDS: ", write_path_rds)

# Save Excel for QC (sample or full)
library(openxlsx)
write_path_xlsx <- "C:/Users/lsikic/Desktop/inflacija_filtered.xlsx"

# For large datasets, save only sample to Excel
# if(nrow(dt_final) > 10000) {
#   dt_excel <- dt_final[sample(.N, 10000)]
#   message("Saving 10K sample to Excel...")
# } else {
#   dt_excel <- dt_final
# }

# Save all data to Excel
dt_excel <- dt_final
message("Saving all ", format(nrow(dt_excel), big.mark = ","), " rows to Excel...")

# Remove FULL_TEXT for Excel (too large)
#dt_excel[, FULL_TEXT := substr(FULL_TEXT, 1, 500)]
write.xlsx(dt_excel, write_path_xlsx, overwrite = TRUE)
message("Saved Excel: ", write_path_xlsx)


