# ==============================================================================
# GEOPOLITICAL STABILITY ARTICLE FILTERING - MERGED PIPELINE
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
geopolitical_articles <- readRDS("C:/Users/lsikic/Desktop/geopolitical_articles.rds")

if(!is.data.table(geopolitical_articles)) {
  setDT(geopolitical_articles)
}
message("Total articles loaded: ", format(nrow(geopolitical_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 1: SOURCE TYPE - Keep only web
# ------------------------------------------------------------------------------

message("\n=== FILTER 1: SOURCE TYPE ===")
dt <- geopolitical_articles[SOURCE_TYPE == "web"]
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

# Specialized news (geopolitics relevant)
specialized_news <- c(
  "geopolitika.news", "obris.org", "defender.hr", "vojska.net",
  "morh.hr", "mvep.hr", "gov.hr"
)

# Opinion/Analysis portals
opinion_portals <- c(
  "7dnevno.hr", "dnevno.hr", "hrvatska-danas.com", "otvoreno.hr",
  "narod.hr", "glas.hr", "novine.hr", "priznajem.hr", "kamenjar.com",
  "politikaplus.com", "maxportal.hr", "novo.hr", "logicno.com",
  "totalinfo.hr", "nacionalno.hr", "portalnovosti.com",
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
# FILTER 4: TITLE MUST CONTAIN GEOPOLITICAL-RELATED TERM
# ------------------------------------------------------------------------------

message("\n=== FILTER 4: TITLE RELEVANCE ===")

title_pattern <- paste0(
  "(",
  # Alliances/Organizations
  "\\bNATO\\b|Sjevernoatlantsk|euroatlantsk|",
  "\\bEU\\b.*sigurnost|sigurnost.*\\bEU\\b|",
  "\\bUN\\b|Ujedinjeni narodi|Vije[cć]e sigurnosti|",
  
  # Major powers
  "Rusij|rusk[aeiou]|Moskv|Kremlj|Putin|",
  "Kin[aeu]|kinesk|Peking|",
  "\\bSAD\\b|ameri[cč]k|Washington|Pentagon|Biden|Trump|",
  
  # Conflicts
  "Ukrajin|Kijev|Donbas|Krim|",
  "Gaz[aeu]|Izrael|Hamas|Hezbollah|Palestin|",
  "Bliski istok|",
  
  # Balkans
  "Srbij|Beograd|Vu[cč]i[cć]|",
  "Kosov|Pri[sš]tin|",
  "\\bBiH\\b|Bosn|Republika Srpska|Dodik|",
  "zapadni Balkan|",
  
  # Security concepts
  "rat[aeu]?\\b|invazij|agresij|sukob|",
  "sankcij|embargo|",
  "nuklearn|raket|",
  "hibridn|cyber.?napad|",
  "teroriz|terorist|",
  
  # Military
  "vojn[aeiou]|oru[zž]an|",
  "obran[aeu]|sigurnost|",
  
  # Diplomacy
  "diplomatsk|veleposlan|ambasad|",
  "sporazum|pregovor|summit|",
  "pro[sš]irenj.*(NATO|EU)|",
  "[cč]lanstvo.*(NATO|EU)|",
  
  # Geopolitical terms
  "geopoliti[cč]k|me[dđ]unarodn.*odnos",
  ")"
)

dt[, title_relevant := stri_detect_regex(TITLE, title_pattern, case_insensitive = TRUE)]
dt <- dt[title_relevant == TRUE]
message("After title filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 5: CORE GEOPOLITICAL TERM IN TEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 5: CORE TERM VERIFICATION ===")

core_pattern <- paste0(
  "(",
  # === NATO/COLLECTIVE DEFENSE ===
  "nato.+(vojn|obran|[cč]lanic|pro[sš]irenj|misij|snag|kontingent)|",
  "(vojn|obran|[cč]lanic|pro[sš]irenj|kontingent).+nato|",
  "[cč]lanak 5|",
  "kolektivn[aeiou]+ obran|",
  "sjevernoatlantsk[aeiou]+ savez|",
  "euroatlantsk[aeiou]+ (integracij|savezni[sš]tv|suradnj)|",
  
  # === EU SECURITY/FOREIGN POLICY ===
  "(eu|europsk[aeiou]+ unij).+(sigurnost|obran|sankcij|vanjsk[aeiou]+ politik)|",
  "zajedni[cč]k[aeiou]+ vanjsk[aeiou]+ i sigurnosn[aeiou]+ politik|",
  
  # === UN SECURITY ===
  "vije[cć][aeu]+ sigurnosti|",
  "(un|ujedinjeni narodi).+(rezolucij|misij|sankcij|mirovn)|",
  "mirovn[aeiou]+ (snag|misij|operacij)|",
  
  # === RUSSIA GEOPOLITICAL ===
  "(rusij|rusk|moskv|kremlj).+(invazij|agresij|prijetn|sankcij|napetost|sukob|vojn|napad)|",
  "(invazij|agresij|prijetn|sankcij).+(rusij|rusk)|",
  "kremlj.+(najav|prijet|optu[zž]|zahtjev|odluk)|",
  "putin.+(najav|prijet|optu[zž]|zahtjev|rat|invazij)|",
  
  # === CHINA GEOPOLITICAL ===
  "(kin|peking).+(vojn|prijetn|sankcij|napetost|sukob|tajvan|utjecaj)|",
  "kinesk[aeiou]+ (vojn|prijetn|ekspanzij|utjecaj)|",
  
  # === USA GEOPOLITICAL ===
  "(sad|ameri[cč]k|washington|pentagon).+(vojn|sankcij|prijetn|napad|operacij|strateg)|",
  "ameri[cč]k[aeiou]+ (vojsk|sankcij|intervencij|strateg)|",
  
  # === UKRAINE CONFLICT ===
  "(ukrajin|kijev|donbas|krim).+(rat|invazij|sukob|ofenziv|obran|vojn|napad)|",
  "(rat|invazij|sukob|ofenziv) (u|na|protiv) ukrajin|",
  "rusk[aeiou]+ (invazij|agresij) (na|u) ukrajin|",
  "ukrajinsk[aeiou]+ (rat|sukob|front|obran)|",
  
  # === MIDDLE EAST CONFLICTS ===
  "(gaza|izrael|hamas|hezbollah|palestin).+(rat|sukob|napad|bombardiranj|ofenziv)|",
  "(rat|sukob|napad) (u|na) (gaz|izrael)|",
  "bliskoisto[cč]n[aeiou]+ (sukob|rat|kriza|napetost)|",
  "(iran|teheran).+(nuklearn|prijetn|sankcij|raket)|",
  
  # === BALKANS GEOPOLITICAL ===
  "(srbij|beograd).+(napetost|sukob|provokacij|prijetn|vojn[aeiou]+ vje[zž]b)|",
  "(kosov|pri[sš]tin).+(napetost|sukob|kriza|priznanj|dijalog)|",
  "srbij[aeiou]?.+(kosov|pri[sš]tin).+(napetost|sukob|pregovor|dijalog)|",
  "(bih|bosn[aeiou]|republika srpska|dodik).+(kriza|napetost|secesij|destabiliz)|",
  "balkansk[aeiou]+ (nestabilnost|napetost|kriza)|",
  "zapadn[aeiou]+ balkan.+(stabilnost|sigurnost|integracij|pro[sš]irenj)|",
  
  # === HYBRID THREATS ===
  "hibridn[aeiou]+ (rat|prijetn|napad|djelovanj)|",
  "hibridno ratovanj|",
  "cyber (rat|napad|prijetn).+(dr[zž]av|vojn|rusij|kin)|",
  "dezinformacij[aeiou]+.+(rusij|kin|kampanj|ratovanj)|",
  "informacijski rat|",
  
  # === NUCLEAR/WMD ===
  "nuklearn[aeiou]+ (prijetn|oru[zž]j|program)|",
  "balisti[cč]k[aeiou]+ raket|",
  "(kemijsk|biolo[sš]k)[aeiou]+ oru[zž]j|",
  "razouru[zž]anj|",
  
  # === SANCTIONS ===
  "sankcij[aeiou]+.+(rusij|kin|iran|bjelorusij)|",
  "(rusij|kin|iran).+sankcij|",
  "(ekonomsk|financijsk)[aeiou]+ sankcij|",
  "embargo.+(oru[zž]j|nafta?|plin)|",
  
  # === MILITARY OPERATIONS ===
  "vojn[aeiou]+ (operacij|intervencij|akcij|ofenziv)|",
  "(vojn|oru[zž]an)[aeiou]+ sukob|",
  "vojn[aeiou]+ vje[zž]b[aeiou]+.+(nato|rusij|kin|granica)|",
  "vojn[aeiou]+ pomo[cć]|",
  "isporuk[aeiou]+ oru[zž]ja|",
  
  # === TERRITORIAL DISPUTES ===
  "teritorijaln[aeiou]+ (integritet|sukob|spor)|",
  "oku?pacij[aeiou]+.+(teritorij|podru[cč]j)|",
  "(aneksij|pripojenje).+(krim|teritorij)|",
  "separatiz[ao]m|secesij|",
  
  # === DIPLOMATIC INCIDENTS ===
  "diplomatsk[aeiou]+ (kriza|incident|sukob)|",
  "protjerivanje diplomat|",
  "persona non grata|",
  "prekid diplomatskih odnosa|",
  
  # === ALLIANCES/TREATIES ===
  "vojn[aeiou]+ (savez|savezni[sš]tv)|",
  "strate[sš]k[aeiou]+ partnerstvo|",
  "sigurnosn[aeiou]+ (sporazum|ugovor|garancij)|",
  
  # === INTEGRATION/ENLARGEMENT ===
  "pro[sš]irenj[aeu]+ (nato|eu)|",
  "(pristupanj|[cč]lanstvo).+(nato|eu)|",
  "[cč]lanstv[aou]+ u (nato|eu)|",
  
  # === GEOPOLITICAL ANALYSIS ===
  "geopoliti[cč]k[aeiou]+|",
  "me[dđ]unarodn[aeiou]+ (sigurnost|odnos[aei]?|poredak)|",
  "globaln[aeiou]+ (sigurnost|poredak|nestabilnost)|",
  "ravnote[zž][aeu]? (snaga|mo[cć]i)|",
  "sfer[aeu]? utjecaja",
  ")"
)

dt[, has_core := stri_detect_regex(FULL_TEXT, core_pattern, case_insensitive = TRUE)]
dt <- dt[has_core == TRUE]
message("After core term filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 6: EXCLUSION CHECK
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
  
  # Travel/Tourism (not geopolitics)
  "pla[zž]a|kupanje|odmor|",
  "turisti[cč]ki aran[zž]man|putovanje u|",
  
  # Historical (without current relevance)
  "Drugi svjetski rat(?!.+(paralel|uspored|ponavlja|sli[cč]n))|",
  "srednji vijek|",
  
  # Other noise
  "horoskop|astrolog|",
  "vremenska prognoza|",
  "tv program|recept|kuhanje",
  ")"
)

override_pattern <- paste0(
  "(",
  "\\bNATO\\b|euroatlantsk|[cč]lanak 5|",
  "vije[cć]e sigurnosti|",
  "invazij.+ukrajin|ukrajin.+invazij|",
  "rusk[aeiou]+ agresij|",
  "nuklearn[aeiou]+ prijetn|",
  "hibridn[aeiou]+ (rat|prijetn)|",
  "sankcij.+(rusij|kin|iran)|",
  "geopoliti[cč]k|",
  "vojn[aeiou]+ sukob|oru[zž]ani sukob|",
  "teritorijalni integritet|",
  "zapadni balkan.+(stabilnost|integracij)|",
  "(gaza|izrael).+(rat|sukob|napad)|",
  "pro[sš]irenje (nato|eu)",
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
# FILTER 7: CROATIAN RELEVANCE (broader for geopolitics)
# ------------------------------------------------------------------------------

message("\n=== FILTER 7: CROATIAN RELEVANCE ===")

# For geopolitics, we want articles relevant to Croatia OR affecting Croatia
# This is broader than other indexes because geopolitical events elsewhere matter
croatian_pattern <- paste0(
  "(",
  # Direct country references
  "\\bHrvatsk[aeiou]?[mj]?|\\bRH\\b|\\bHR\\b|",
  
  # Croatian institutions
  "MORH|Ministarstvo obrane|",
  "MVEP|Ministarstvo vanjskih|",
  "Vlad[aeiou] RH|",
  "\\bHV\\b|Hrvatska vojska|",
  "SOA|sigurnosno.?obavje[sš]tajn|",
  
  # Croatian leaders in context
  "predsjednik.*RH|predsjedni[ck].*Hrvatske|",
  "Plenkovi[cć]|Milanovi[cć]|Grlić Radman|",
  
  # Croatian military/diplomatic
  "hrvatsk[aeiou]+ (vojsk|kontingent|diplomat|veleposlan)|",
  "NATO.+Hrvatsk|Hrvatsk.+NATO|",
  "EU.+Hrvatsk|Hrvatsk.+EU|",
  
  # Regional relevance (neighbors)
  "Srbij|Bosn|\\bBiH\\b|Crna Gora|Slovenij|Kosov|",
  "susjed|regij[aeiou]|balkansk|jadran|",
  
  # Security implications for Croatia
  "sigurnost.+Hrvatsk|Hrvatsk.+sigurnost|",
  "obran.+Hrvatsk|Hrvatsk.+obran|",
  "prijetn.+regij|regij.+prijetn|",
  
  # EU/NATO membership context
  "[cč]lanic[aeu]? (EU|NATO)|",
  "savezni[ck]|saveznički|",
  
  # General European security (affects Croatia)
  "europsk[aeiou]+ sigurnost|sigurnost Europe|",
  "isto[cč]n[aeiou]+ (bok|krilo) NATO|",
  
  # Energy security (affects Croatia)
  "energetsk[aeiou]+ sigurnost|",
  "LNG.+(terminal|Krk)|Krk.+LNG|",
  "plinovod|naftovod",
  ")"
)

dt[, croatian_context := stri_detect_regex(FULL_TEXT, croatian_pattern, case_insensitive = TRUE)]

message("Articles WITH Croatian relevance: ", format(sum(dt$croatian_context), big.mark = ","))
message("Articles WITHOUT Croatian relevance: ", format(sum(!dt$croatian_context), big.mark = ","))

dt <- dt[croatian_context == TRUE]
message("After Croatian relevance filter: ", format(nrow(dt), big.mark = ","))

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
write_path_rds <- "C:/Users/lsikic/Desktop/geopolitical_filtered.rds"
saveRDS(dt_final, write_path_rds)
message("Saved RDS: ", write_path_rds)

# Save Excel for QC
library(openxlsx)
write_path_xlsx <- "C:/Users/lsikic/Desktop/geopolitical_filtered.xlsx"

dt_excel <- copy(dt_final)
message("Saving all ", format(nrow(dt_excel), big.mark = ","), " rows to Excel...")

# Truncate FULL_TEXT for Excel (too large)
dt_excel[, FULL_TEXT := substr(FULL_TEXT, 1, 500)]
write.xlsx(dt_excel, write_path_xlsx, overwrite = TRUE)
message("Saved Excel: ", write_path_xlsx)

message("\n=== DONE ===")