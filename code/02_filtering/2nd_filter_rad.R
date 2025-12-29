# ==============================================================================
# LABOR MARKET ARTICLE FILTERING - MERGED PIPELINE
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
labor_articles <- readRDS("C:/Users/lsikic/Desktop/labor_articles.rds")

if(!is.data.table(labor_articles)) {
  setDT(labor_articles)
}
message("Total articles loaded: ", format(nrow(labor_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 1: SOURCE TYPE - Keep only web
# ------------------------------------------------------------------------------

message("\n=== FILTER 1: SOURCE TYPE ===")
dt <- labor_articles[SOURCE_TYPE == "web"]
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

# Business/Economic news (relevant for labor)
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

# Specialized news (labor relevant)
specialized_news <- c(
  "moj-posao.net", "posao.hr", "mirovina.hr", "legalis.hr", 
  "srednja.hr", "studentski.hr", "gov.hr", "hzz.hr"
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
# FILTER 4: TITLE MUST CONTAIN LABOR-RELATED TERM
# ------------------------------------------------------------------------------

message("\n=== FILTER 4: TITLE RELEVANCE ===")

title_pattern <- paste0(
  "(",
  # Employment/Unemployment
  "zaposlen|nezaposlen|zapo[sš]ljavanj|",
  "tr[zž]i[sš]te rada|radn[aeiou]+ snag|",
  "\\bHZZ\\b|zavod za zapo[sš]ljavanj|burza rada|",
  
  # Wages
  "pla[cć][aeu]|primanj|minimaln[aeiou]+ pla[cć]|minimalac|",
  "prosje[cč]n[aeiou]+ pla[cć]|rast pla[cć]|povi[sš]ic|",
  
  # Labor relations
  "sindikat|kolektivni ugovor|[sš]trajk|",
  "radni[cč]k|Zakon o radu|",
  
  # Job creation/destruction
  "otpu[sš]tanj|otkaz[aei]?\\b|vi[sš]ak radnika|",
  "nov[aeiou]+ radn[aeiou]+ mjest|otvaranje radnih mjesta|",
  
  # Brain drain/Migration
  "odljev (mozgova|radne snage|radnika)|",
  "iseljavanje|doseljavanje|povratak iseljenih|",
  "stran[aeiou]+ radni[ck]|radn[aeiou]+ dozvol|",
  "nedostatak radnika|manjak radnika|",
  
  # Pension
  "mirovinski|\\bHZMO\\b|umirovljenj|",
  
  # Work conditions
  "prekarn[aeiou]+ rad|rad na crno|agencijski rad|",
  "sezonsk[aeiou]+ (rad|zapo[sš]ljavanj)|",
  
  # Statistics
  "stopa (ne)?zaposlenosti|",
  "\\bDZS\\b|Eurostat",
  ")"
)

dt[, title_relevant := stri_detect_regex(TITLE, title_pattern, case_insensitive = TRUE)]
dt <- dt[title_relevant == TRUE]
message("After title filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 5: CORE LABOR TERM IN TEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 5: CORE TERM VERIFICATION ===")

core_pattern <- paste0(
  "(",
  # --- UNEMPLOYMENT RATES/STATISTICS ---
  "stop[aeu]? nezaposlenosti|",
  "stop[aeu]? zaposlenosti|",
  "registriran[aeiou]+ nezaposlen|",
  "anketn[aeiou]+ nezaposlen|",
  "ilo metodolog|",
  "anketa o radnoj snazi|",
  
  # --- LABOR MARKET AS CONCEPT ---
  "tr[zž]i[sš]t[aeu]+ rada|",
  "radn[aeiou]+ snag[aeiou]?|",
  "radna populacija|",
  "radno sposobn|",
  "aktivn[aeiou]+ stanovni[sš]tv|",
  
  # --- EMPLOYMENT INSTITUTIONS ---
  "\\bhzz\\b|",
  "hrvatsk[aeiou]+ zavod za zapo[sš]ljavanj|",
  "zavod za zapo[sš]ljavanj|",
  "bura?z[aeiou]? rada|",
  
  # --- WAGE STATISTICS ---
  "prosje[cč]n[aeiou]+ pla[cć][aeiou]?|",
  "medijanln[aeiou]+ pla[cć]|",
  "minimaln[aeiou]+ pla[cć][aeiou]?|",
  "minimalac|",
  "zajam[cč]en[aeiou]+ pla[cć]|",
  "(rast|pad|pove[cć]anje|smanjenje) pla[cć]|",
  "povi[sš]ic[aeiou]+ pla[cć]|",
  
  # --- WAGE POLICY ---
  "platn[aeiou]+ razred|",
  "platn[aeiou]+ ljestvic|",
  "indeksacij[aeiou]+ pla[cć]|",
  "zamrzavanj[aeiou]+ pla[cć]|",
  "uskla[dđ]ivanj[aeiou]+ pla[cć]|",
  
  # --- COLLECTIVE BARGAINING ---
  "kolektivn[aeiou]+ ugovor|",
  "kolektivn[aeiou]+ pregovar|",
  "pregovor[aei]+ o pla[cć]|",
  "socijalni dijalog|",
  "tripartitn[aeiou]+ dijalog|",
  "gospodarsko.?socijalno vije[cć]|",
  
  # --- UNIONS (with labor context) ---
  "sindikaln[aeiou]+ (pregovor|zahtjev|akcij|pritisa|najav|[sš]trajk)|",
  "sindikat[aei]? (tra[zž]|zahtijeva|najavljuj|prijeti|organizira)|",
  "\\bsssh\\b|",
  "matica hrvatskih sindikat|",
  
  # --- LABOR LAW ---
  "zakon o radu|",
  "radn[aeiou]+ prav[aou]?|",
  "radn[io]+ odnos[aei]?|",
  "inspekcij[aeiou]+ rada|",
  "inspektorat rada|",
  
  # --- JOB CREATION/DESTRUCTION ---
  "(otvaranje|zatvaranje|ukidanje|kreiranje) radnih mjesta|",
  "nov[aeiou]+ radn[aeiou]+ mjest|",
  "kolektivn[aeiou]+ otkaz|",
  "vi[sš]ak radnika|",
  "tehnolo[sš]ki vi[sš]ak|",
  "masovn[aeiou]+ otpu[sš]tanj|",
  
  # --- BRAIN DRAIN/MIGRATION ---
  "odljev (mozgova|radne snage|radnika)|",
  "odlazak radnika|",
  "iseljavanje radnika|",
  "uvoz radne snage|",
  "stran[aeiou]+ radni[ck]|",
  "radn[aeiou]+ dozvol[aeiou]?|",
  "povratak iseljenih|",
  "nedostatak radne snage|",
  "manjak radnika|",
  
  # --- EMPLOYMENT TYPES ---
  "prekarn[aeiou]+ rad|",
  "nesigurn[aeiou]+ poslov|",
  "rad na crno|",
  "agencijsk[aeiou]+ rad|",
  "sezonsk[aeiou]+ zapo[sš]ljavanj|",
  
  # --- PENSION SYSTEM ---
  "\\bhzmo\\b|",
  "hrvatsk[aeiou]+ zavod za mirovinsko|",
  "mirovinski (sustav|fond|stup)|",
  
  # --- STRUCTURAL UNEMPLOYMENT ---
  "strukturn[aeiou]+ nezaposlenost|",
  "dugotrajn[aeiou]+ nezaposlen|",
  "nezaposlenost mladih|",
  
  # --- EMPLOYMENT STATISTICS CONTEXT ---
  "(prema |po )?(podacima )?(hzz|dzs|eurostat)|",
  "zaposlenost[i]? (rast|pad|u)|",
  "nezaposlenost[i]? (rast|pad|u)|",
  "broj zaposlenih|",
  "broj nezaposlenih",
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
  # Sports (players, contracts, transfers)
  "nogomet|ko[sš]ark|rukomet|tenis|vaterpolo|",
  "liga prvak|premijer lig|bundeslig|",
  "utakmic|golova|igra[cč]|trener|mom[cč]ad|",
  "Dinamo|Hajduk|UEFA|FIFA|NBA|olimpijsk|",
  "sportski|reprezentacij|prvenstv|",
  "transfer|potpisao ugovor.*klub|ugovor.*igra[cč]|",
  "pla[cć][aeu]+ igra[cč]|",
  
  
  # Entertainment (celebrity salaries)
  "glumac|glumic|redatelj|",
  "koncert|festival|",
  "pjeva[cč]|album|pjesm|",
  "reality|showbiz|celebrity|influencer|",
  "honorar.*glumac|honorar.*pjeva[cč]|",
  
  # Job ads (not labor market analysis)
  "tra[zž]imo radnike|tra[zž]i se radnik|",
  "natje[cč]aj za posao|natje[cč]aj za radno mjesto|",
  "oglas za posao|potrebni radnici|",
  "\\bCV\\b|[zž]ivotopis.*poslati|",
  
  # Other noise
  "horoskop|astrolog|",
  "vremenska prognoza|",
  "tv program|recept|kuhanje",
  ")"
)

override_pattern <- paste0(
  "(",
  "\\bHZZ\\b|zavod za zapo[sš]ljavanj|",
  "stopa (ne)?zaposlenosti|",
  "tr[zž]i[sš]te rada|",
  "prosje[cč]n[aeiou]+ pla[cć]|minimaln[aeiou]+ pla[cć]|",
  "(rast|pad) (zaposlenosti|nezaposlenosti|pla[cć])|",
  "kolektivni ugovor|socijalni dijalog|",
  "sindikat.+(pregovor|zahtjev|[sš]trajk)|",
  "odljev (mozgova|radne snage)|",
  "nedostatak radne snage|manjak radnika|",
  "\\bDZS\\b|\\bEurostat\\b|",
  "masovn[aeiou]+ otpu[sš]tanj|kolektivni otkaz|",
  "Zakon o radu|radn[aeiou]+ prav|",
  "mirovinski (sustav|fond|stup)",
  ")"
)

dt[, excl := stri_detect_regex(FULL_TEXT, excl_pattern, case_insensitive = TRUE)]
dt[, override := stri_detect_regex(FULL_TEXT, override_pattern, case_insensitive = TRUE)]
dt[, passes_exclusion := (!excl | override)]

excluded_count <- sum(!dt$passes_exclusion)
message("Excluded by sports/entertainment/job ads (without override): ", excluded_count)

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
  
  # Labor institutions
  "\\bHZZ\\b|Hrvatski zavod za zapo[sš]ljavanj|",
  "\\bHZMO\\b|Hrvatski zavod za mirovinsko|",
  "\\bHZZO\\b|Hrvatski zavod za zdravstveno|",
  "Ministarstvo rada|",
  
  # Unions
  "\\bSSS?H\\b|Savez samostalnih sindikata|",
  "Matica hrvatskih sindikata|",
  "\\bHUS\\b|Hrvatski udruga sindikata|",
  
  # Government
  "Vlad[aeiou] RH|Vlad[aeiou] Republike Hrvatske|",
  
  # Cities (major ones)
  "Zagreb|Split|Rijeka|Osijek|Zadar|Pula|Slavonski Brod|",
  "Karlovac|Vara[zž]din|[SŠ]ibenik|Dubrovnik|",
  
  # Currency
  "\\beuro?[aeimu]?\\b.*\\bHrvatsk|Hrvatska.*\\beuro?[aeimu]?\\b|",
  "\\bkun[aeiou]?[mj]?\\b|kunama|",
  
  # Regional
  "\\bu nas\\b|kod nas|na[sš][aeiou]? tr[zž]i[sš]|hrvatsk[aeiou]? tr[zž]i[sš]|",
  "doma[cć][aeiou]? tr[zž]i[sš]te rada|hrvatsk[aeiou]? tr[zž]i[sš]te rada|",
  "hrvatski radnici|radnici iz Hrvatske|",
  
  # Comparative
  "\\bEU prosjek|europski prosjek.*Hrvatska|Hrvatska.*europski prosjek|",
  "u (odnosu na|usporedbi s) (EU|Europu)|",
  
  # Brain drain context
  "odlazak iz Hrvatske|iseljavanje iz Hrvatske|",
  "prema (Njema[cč]k|Irsk|Austrij)|",
  "povratak u Hrvatsku",
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
write_path_rds <- "C:/Users/lsikic/Desktop/labor_filtered.rds"
saveRDS(dt_final, write_path_rds)
message("Saved RDS: ", write_path_rds)

# Save Excel for QC
library(openxlsx)
write_path_xlsx <- "C:/Users/lsikic/Desktop/labor_filtered.xlsx"

dt_excel <- copy(dt_final)
message("Saving all ", format(nrow(dt_excel), big.mark = ","), " rows to Excel...")

# Truncate FULL_TEXT for Excel (too large)
dt_excel[, FULL_TEXT := substr(FULL_TEXT, 1, 500)]
write.xlsx(dt_excel, write_path_xlsx, overwrite = TRUE)
message("Saved Excel: ", write_path_xlsx)

message("\n=== DONE ===")