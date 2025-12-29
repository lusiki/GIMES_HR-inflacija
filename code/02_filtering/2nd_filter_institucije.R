# ==============================================================================
# INSTITUTIONAL PERCEPTION ARTICLE FILTERING - MERGED PIPELINE
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
institutional_articles <- readRDS("C:/Users/lsikic/Desktop/institutional_articles.rds")

if(!is.data.table(institutional_articles)) {
  setDT(institutional_articles)
}
message("Total articles loaded: ", format(nrow(institutional_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 1: SOURCE TYPE - Keep only web
# ------------------------------------------------------------------------------

message("\n=== FILTER 1: SOURCE TYPE ===")
dt <- institutional_articles[SOURCE_TYPE == "web"]
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

# Specialized news (institutional/legal relevant)
specialized_news <- c(
  "legalis.hr", "gov.hr", "pravosudje.hr", "sudovi.hr",
  "ombudsman.hr", "dorh.hr"
)

# Opinion/Analysis portals (relevant for institutional analysis)
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
# FILTER 4: TITLE MUST CONTAIN INSTITUTIONAL-RELATED TERM
# ------------------------------------------------------------------------------

message("\n=== FILTER 4: TITLE RELEVANCE ===")

title_pattern <- paste0(
  "(",
  # Institutions
  "vlad[aeiou]|sabor|ministar|predsjedni[ck]|",
  "\\bsud\\b|sudstv|pravosu[dđ]|sudac|sutkinja|",
  "\\bDORH\\b|\\bUSKOK\\b|\\bPNUSKOK\\b|dr[zž]avn.*odvjetni[sš]|",
  "[zž]upan|gradona[cč]elnik|na[cč]elnik|",
  "zastupni[ck]|saborsk|",
  
  # Performance/Trust
  "povjerenje.*institucij|institucij.*povjerenje|",
  "(ne)?u[cč]inkovit|funkcioniranj|",
  "reform[aeiou]|modernizacij|digitalizacij|",
  
  # Corruption/Scandals
  "korupcij|afer[aeu]|skandal|",
  "zlouporab|zloupotreb|",
  "uhićen|priveden|optužen|osumnji[cč]en|",
  "nepotiz|kroniz|klijenteliz|podobnost|uhljeb|",
  "sukob interesa|",
  
  # Rule of law
  "vladavina prava|pravna dr[zž]av|",
  "politi[zck]acij|",
  "kr[sš]enje (zakona|ustava)|",
  
  # Oversight
  "revizij[aeiou]|ombudsman|pu[cč]ki pravobranitelj|",
  "(ne)?transparentnost|",
  
  # Bureaucracy
  "birokratsk|administrativn.*prepreke|",
  "javna uprava|dr[zž]avna uprava|",
  
  # Crisis
  "kriza institucij|uru[sš]avanje|erozij",
  ")"
)

dt[, title_relevant := stri_detect_regex(TITLE, title_pattern, case_insensitive = TRUE)]
dt <- dt[title_relevant == TRUE]
message("After title filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 5: CORE INSTITUTIONAL TERM IN TEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 5: CORE TERM VERIFICATION ===")

core_pattern <- paste0(
  "(",
  # === INSTITUTIONAL TRUST/DISTRUST ===
  "(ne)?povjerenje u institucij|",
  "(ne)?povjerenje (gra[dđ]ana|javnosti) u (vlad|sabor|sud|policij|pravosu[dđ])|",
  "(kriza|gubitak|pad|rast) povjerenja|",
  "povjerenje u (vladu|sabor|sudstvo|pravosu[dđ]e|policiju|dr[zž]avu)|",
  
  # === INSTITUTIONAL FUNCTIONING ===
  "(ne)?funkcioniranje (institucij|dr[zž]ave|sustav|vlad|sabor|sudstv)|",
  "(ne)?u[cč]inkovitost (institucij|dr[zž]ave|sustav|vlad|pravosu[dđ])|",
  "(ne)?efikasnost (institucij|javne uprave|dr[zž]avne uprave)|",
  "disfunkcionaln[aeiou]+ (institucij|sustav|dr[zž]av)|",
  
  # === CORRUPTION (with institutional frame) ===
  "korupcij[aeiou]?.+(institucij|vlad|sabor|ministar|sud|policij|dr[zž]avn)|",
  "(institucij|vlad|sabor|ministar|dr[zž]avn).+korupcij|",
  "korupcij[aeiou]+ u (vladi|saboru|ministarstvu|policiji|sudstvu|pravosu[dđ]u)|",
  "zlouporab[aeiou]+ (polo[zž]aja|ovlasti|vlasti)|",
  "zlouporab[aeiou]+.+(ministar|du[zž]nosni|ravnatelj|direktor|[zž]upan|gradona[cč]elnik)|",
  
  # === POLITICAL AFFAIRS/SCANDALS ===
  "afer[aeiou]?.+(vlad|ministar|sabor|hdz|sdp|predsjedni|[zž]upan|gradona[cč]elnik)|",
  "(vlad|ministar|sabor|hdz|sdp|predsjedni|[zž]upan|gradona[cč]elnik).+afer|",
  "politi[cč]k[aeiou]+ (afera|skandal)|",
  "korupcijsk[aeiou]+ (afera|skandal)|",
  
  # === PROSECUTION OF OFFICIALS ===
  "(uskok|pnuskok|dorh).+(ministar|du[zž]nosni|[zž]upan|gradona[cč]elnik|zastupni|direktor)|",
  "(ministar|du[zž]nosni|[zž]upan|gradona[cč]elnik|zastupni).+(uhićen|priveden|istra[zž]|optužen|osumnji[cč]en)|",
  "uhićen[aei]? (ministar|du[zž]nosni|[zž]upan|gradona[cč]elnik|zastupni)|",
  "optužnic[aeiou]+.+(ministar|du[zž]nosni|[zž]upan|gradona[cč]elnik|zastupni)|",
  
  # === RULE OF LAW ===
  "vladavin[aeiou]+ prava|",
  "pravn[aeiou]+ dr[zž]av|",
  "rule of law|",
  "kr[sš]enje (zakona|ustava|prava)|",
  "(ne)?neovisnost (sudstv|pravosu[dđ]|sudov)|",
  "politi[zck]acij[aeiou]+ (sudstv|pravosu[dđ]|institucij|dr[zž]avnih tijela)|",
  
  # === NEPOTISM/CLIENTELISM ===
  "nepotiz[ao]m|",
  "kroniz[ao]m|",
  "klijenteliz[ao]m|",
  "podobnost|",
  "strana[cč]ko zapo[sš]ljavanj|",
  "zapo[sš]ljavanje (podobnih|po strana[cč]koj liniji)|",
  "uhljeb|",
  
  # === CONFLICT OF INTEREST ===
  "sukob interesa|",
  "conflict of interest|",
  "povjerenstvo za sukob interesa|",
  "imovinska kartica|",
  "nespojiv[aeiou]+ du[zž]nost|",
  
  # === INSTITUTIONAL REFORM ===
  "reform[aeiou]+ (institucij|javne uprave|dr[zž]avne uprave|pravosu[dđ]|sudstv)|",
  "(institucij|javne uprave|dr[zž]avne uprave|pravosu[dđ]).+reform|",
  "modernizacij[aeiou]+ (javne uprave|dr[zž]avne uprave|institucij)|",
  "digitalizacij[aeiou]+ (javne uprave|dr[zž]avne uprave|institucij)|",
  "debirokratizacij|",
  
  # === GOVERNMENT/PARLIAMENT PERFORMANCE ===
  "(ne)?u[cč]inkovit[aeiou]+ (vlad|sabor|ministarstv)|",
  "rad (vlade|sabora|ministarstva|institucij).+(ocjen|kritik|pohval)|",
  "ocjena rada (vlade|sabora|ministarstva)|",
  
  # === JUDICIARY ASSESSMENT ===
  "(ne)?u[cč]inkovitost (sudstv|pravosu[dđ]|sudov)|",
  "trajanje (sudskih postupaka|postupaka|procesa)|",
  "sudski zaostatci|",
  "zaostatci u sudstv|",
  "(ne)?pristran[aeiou]+ sud|",
  
  # === OVERSIGHT BODIES ===
  "dr[zž]avn[aeiou]+ (ured za )?revizij|",
  "pu[cč]ki pravobranitelj|",
  "ombudsman|",
  "povjereni[ck][aeiou]+ za informiranje|",
  
  # === TRANSPARENCY ===
  "(ne)?transparent?nost (vlad|institucij|javne uprave|rada)|",
  "pristup informacijam|",
  "pravo na informacij|",
  "javnost rada|",
  "tajna?ost (vlad|institucij|podataka)|",
  
  # === BUREAUCRACY ISSUES ===
  "birokratsk[aeiou]+ (prepreke|zapreke|sporost|tromost|barijere)|",
  "pretjeran[aeiou]+ birokratiz|",
  "administrativn[aeiou]+ (prepreke|zapreke|optere[cć]enj)|",
  "(sporost|tromost|inertnost) (javne uprave|dr[zž]avne uprave|administracij)|",
  
  # === POLITICAL APPOINTMENTS ===
  "(politi[cč]k|strana[cč]k)[aeiou]+ (imenovanje|postavljanje|kadroviranje)|",
  "imenovanje (ravnatelja|direktora|[cč]elnika) (po strana[cč]koj|zbog politi[cč]k)|",
  
  # === INSTITUTIONAL CRISIS ===
  "kriza (institucij|vladavine prava|pravosu[dđ]|sudstv)|",
  "uru[sš]avanje (institucij|sustava|vladavine prava)|",
  "erozij[aeiou]+ (institucij|vladavine prava|povjerenja)|",
  "slabljenje (institucij|vladavine prava)",
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
  
  # Routine government announcements (without analysis)
  "vlada usvojila|sabor usvojio|donesena odluka|",
  
  # Other noise
  "horoskop|astrolog|",
  "vremenska prognoza|",
  "tv program|recept|kuhanje",
  ")"
)

override_pattern <- paste0(
  "(",
  "(ne)?povjerenje u institucij|kriza povjerenja|",
  "(ne)?u[cč]inkovitost (institucij|vlad|sudstv|pravosu[dđ])|",
  "korupcij.+(institucij|vlad|ministar|dr[zž]avn)|",
  "afer[aeiou]?.+(vlad|ministar|[zž]upan|gradona[cč]elnik)|",
  "(uskok|pnuskok|dorh).+(ministar|du[zž]nosni|[zž]upan)|",
  "(ministar|du[zž]nosni|[zž]upan|gradona[cč]elnik).+(uhićen|optužen)|",
  "vladavina prava|pravna dr[zž]av|",
  "politi[zck]acij|",
  "nepotiz[ao]m|kroniz[ao]m|klijenteliz[ao]m|uhljeb|",
  "sukob interesa|",
  "reform[aeiou]+ (institucij|javne uprave|pravosu[dđ])|",
  "ombudsman|pu[cč]ki pravobranitelj|",
  "(ne)?transparentnost|",
  "birokratsk[aeiou]+ prepreke|",
  "kriza institucij|uru[sš]avanje institucij",
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
# FILTER 7: CROATIAN CONTEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 7: CROATIAN CONTEXT ===")

croatian_pattern <- paste0(
  "(",
  # Country references
  "\\bHrvatsk[aeiou]?[mj]?|\\bRH\\b|\\bHR\\b|",
  
  # Government/Parliament
  "Vlad[aeiou] RH|Vlad[aeiou] Republike Hrvatske|",
  "Hrvatski sabor|saborsk|",
  "predsjednik.*RH|predsjedni[ck].*Hrvatske|",
  "Banski dvori|Pantov[cč]ak|",
  
  # Specific institutions
  "\\bDORH\\b|dr[zž]avno odvjetni[sš]tvo|",
  "\\bUSKOK\\b|\\bPNUSKOK\\b|",
  "Vrhovni sud RH|Ustavni sud RH|",
  "\\bMUP\\b|Ministarstvo unutarnjih|",
  "\\bHNB\\b|Hrvatska narodna banka|",
  "\\bHZMO\\b|\\bHZZO\\b|",
  "\\bHANFA\\b|\\bHAKOM\\b|\\bAZTN\\b|",
  "Dr[zž]avna revizija|Dr[zž]avni ured za reviziju|",
  
  # Political parties
  "\\bHDZ\\b|\\bSDP\\b|\\bMo[zž]emo\\b|\\bMost\\b|\\bDP\\b|",
  
  # Croatian politicians (current and recent)
  "Plenkovi[cć]|Milanovi[cć]|Jandrokovi[cć]|",
  "Grbin|Bernardić|Petrov|Grmoja|",
  
  # Local government
  "[zž]upan[aeiou]?|gradona[cč]elni[ck]|",
  "Grad Zagreb|",
  
  # Cities
  "Zagreb|Split|Rijeka|Osijek|Zadar|Pula|Dubrovnik|",
  
  # Regional
  "\\bu nas\\b|kod nas|hrvatsk[aeiou]+ institucij|",
  
  # Comparative EU
  "u odnosu na EU|u usporedbi s EU|europski standardi",
  ")"
)

dt[, croatian_context := stri_detect_regex(FULL_TEXT, croatian_pattern, case_insensitive = TRUE)]

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
write_path_rds <- "C:/Users/lsikic/Desktop/institutional_filtered.rds"
saveRDS(dt_final, write_path_rds)
message("Saved RDS: ", write_path_rds)

# Save Excel for QC
library(openxlsx)
write_path_xlsx <- "C:/Users/lsikic/Desktop/institutional_filtered.xlsx"

dt_excel <- copy(dt_final)
message("Saving all ", format(nrow(dt_excel), big.mark = ","), " rows to Excel...")

# Truncate FULL_TEXT for Excel (too large)
dt_excel[, FULL_TEXT := substr(FULL_TEXT, 1, 500)]
write.xlsx(dt_excel, write_path_xlsx, overwrite = TRUE)
message("Saved Excel: ", write_path_xlsx)

message("\n=== DONE ===")