# ==============================================================================
# SECURITY & STABILITY ARTICLE FILTERING - MERGED PIPELINE
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
security_articles <- readRDS("C:/Users/lsikic/Desktop/security_articles.rds")

if(!is.data.table(security_articles)) {
  setDT(security_articles)
}
message("Total articles loaded: ", format(nrow(security_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 1: SOURCE TYPE - Keep only web
# ------------------------------------------------------------------------------

message("\n=== FILTER 1: SOURCE TYPE ===")
dt <- security_articles[SOURCE_TYPE == "web"]
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

# Specialized news (security relevant)
specialized_news <- c(
  "policija.hr", "vatrogasci.hr", "hvz.hr", "duzs.hr",
  "morh.hr", "defender.hr", "obris.org", "gov.hr"
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
# FILTER 4: TITLE MUST CONTAIN SECURITY-RELATED TERM
# ------------------------------------------------------------------------------

message("\n=== FILTER 4: TITLE RELEVANCE ===")

title_pattern <- paste0(
  "(",
  # Crime - violent
  "ubojstv|ubij|umorst|",
  "napad[aeu]?\\b|napada[cč]|nasilje|nasiln|",
  "pljačk|razbojni[sš]tv|",
  "silovanj|seksualn.*napad|seksualn.*nasilj|",
  "otmic|kidnapiranj|",
  
  # Crime - property
  "krađ[aeu]|ukrao|provale?|provalnik|",
  "vandaliz|pale[zž]|",
  
  # Crime - organized
  "organiziran.*kriminal|mafij|krijum[cč]ar|",
  "drog[aeu]|narkotik|narko|",
  "trgovin.*ljudima|",
  
  # Prosecution/Police
  "policij|\\bMUP\\b|",
  "uhićen|priveden|pritvor|",
  "\\bDORH\\b|dr[zž]avn.*odvjetni[sš]tv|tu[zž]iteljstv|",
  "optu[zž]nic|presud|kaznen.*prijav|istra[zž]n.*zatvor|",
  "\\bUSKOK\\b|\\bPNUSKOK\\b|",
  
  # Traffic
  "prometn.*nesre[cć]|sudar|poginuo|smrtno stradao|",
  
  # Fire
  "po[zž]ar|vatrogasc|ga[sš]enj|izgorjel|",
  
  # Natural disasters
  "potres|poplav|oluj|bujic|klizi[sš]t|odron|nevrijem|",
  
  # Emergency services
  "\\bHGSS\\b|spa[sš]avanj|evakuacij|",
  "civiln.*za[sš]tit|sto[zž]er|",
  
  # Terrorism
  "teroriz|terorist|eksplozij|bomb|detonacij|",
  
  # Victims/Damage
  "[zž]rtv|ozlije[dđ]en|ranjen|poginul|",
  "[sš]tet[aeu]|uni[sš]ten|devastira|",
  
  # Cyber
  "cyber.*napad|haker|ransomware|",
  
  # General security
  "sigurnosn.*incident|ugroza|opasnost",
  ")"
)

dt[, title_relevant := stri_detect_regex(TITLE, title_pattern, case_insensitive = TRUE)]
dt <- dt[title_relevant == TRUE]
message("After title filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 5: CORE SECURITY TERM IN TEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 5: CORE TERM VERIFICATION ===")

core_pattern <- paste0(
  "(",
  # === VIOLENT CRIME WITH INSTITUTIONAL FRAMING ===
  
  # --- Murder/homicide ---
  "ubojstv[aou]?.+(policij|istra[zž]|uhićen|osumnji[cč]en|optužen|pritvoren)|",
  "(policij|dorh|dr[zž]avno odvjetni[sš]tvo).+ubojstv|",
  "osumnji[cč]en[aei]? za ubojstvo|",
  "ubijena?.+prona[dđ]en|",
  
  # --- Physical attacks ---
  "(fizi[cč]ki|no[zž]em|oru[zž]jem|pal[ci]om) napad|",
  "napad[aeu]?.+(policij|hitna|ozlije[dđ]en|uhićen|prijavljen)|",
  "napada[cč].+(uhićen|priveden|identificiran)|",
  "brutalan napad|",
  
  # --- Sexual violence ---
  "silovanj[aeu]?|",
  "seksualn[aeiou]+ (napad|nasilj|zlostavljanj)|",
  "spolno zlostavljanj|",
  
  # --- Robbery ---
  "(oružana|bankovna) pljačk|",
  "pljačk[aeu]?.+(policij|uhićen|prijavljen|istraga)|",
  "razbojni[sš]tv|",
  
  # --- Domestic violence ---
  "obiteljsk[aeiou]+ nasilj|",
  "nasilj[aeu]? u obitelji|",
  "zlostavljanj[aeu]? (djece|suprug|partner)|",
  
  # === ORGANIZED CRIME ===
  "organiziran[aeiou]+ kriminal|",
  "kriminaln[aeiou]+ (skupin|organ|mre[zž])|",
  "krijum[cč]arenj[aeu]?|",
  "trgovin[aeu]? ljudima|",
  "narko.?(kartel|bos|mafij|diler)|",
  "mafija[sš]k|",
  "reketarenj|",
  
  # === PROSECUTION/ARRESTS ===
  "\\bdorh\\b|",
  "dr[zž]avn[aeiou]+ odvjetni[sš]tv|",
  "tu[zž]iteljstv|",
  "kaznen[aeu]+ prijav[aeu]?|",
  "podignut[aeu]? optu[zž]nic|",
  "uhićen[aei]?.+(osob|osumnji[cč]|zbog)|",
  "priveden[aei]?.+(osob|osumnji[cč]|zbog)|",
  "pritvor(en|eni)?|",
  "istra[zž]ni zatvor|",
  "pravomo[cć]n[aeu]+ presud|",
  
  # === POLICE OPERATIONS ===
  "policijsk[aeiou]+ (akcij|racija|potjera|potrag)|",
  "velika policijska|",
  "uskok.+(istra[zž]|akcij|uhićen)|",
  "\\bpnuskok\\b|",
  "\\beppo\\b|",
  
  # === TRAFFIC ACCIDENTS ===
  "prometn[aeiou]+ nesre[cć][aeiou]?|",
  "(poginuo|poginula|smrtno stradao) u prometu|",
  "(sudar|slijetanje).+(ozlije[dđ]en|poginuo|policij)|",
  "te[sš]k[aeu]+ prometn[aeu]+ nesre[cć]|",
  "alkohol za volanom|",
  "pijan za volanom|",
  
  # === FIRES ===
  "[sš]umski po[zž]ar|",
  "stambeni po[zž]ar|",
  "po[zž]ar[aeu]?.+(vatrogasc|jvp|dvd|intervencij|evakuacij|izgorjel)|",
  "(vatrogasc|jvp).+po[zž]ar|",
  "ga[sš]enje po[zž]ara|",
  "izbio po[zž]ar|",
  "po[zž]ar (u |na ).+(zgrad|ku[cć]|tvorn|skladi[sš]t|[sš]um)|",
  
  # === NATURAL DISASTERS ===
  "potres[aeu]?.+(magnituda|richter|seizmolo[sš]k|[sš]teta|evakuacij)|",
  "seizmolo[sš]k[aeiou]+ (aktivnost|slu[zž]ba)|",
  "poplav[aeu]?.+(evakuacij|[sš]teta|civilna za[sš]tita|interventn)|",
  "izlijevanje rijeke|",
  "bujic[aeu]?|",
  "oluj[aeu]?.+([sš]teta|bez struje|interventn|vatrogasc)|",
  "klizi[sš]t[aeu]?|",
  "odron[aeu]?|",
  
  # === EMERGENCY SERVICES ===
  "\\bhgss\\b|",
  "hrvatska gorska slu[zž]ba spa[sš]avanj|",
  "sto[zž]er civilne za[sš]tite|",
  "civiln[aeu]+ za[sš]tit[aeu]?.+(aktivira|progla[sš]|koordin)|",
  "evakuacij[aeiou]+ (stanovni|zgrada|naselja)|",
  "spa[sš]avanje (unesre[cć]enih|[zž]rtava|preživjelih)|",
  
  # === VICTIMS & CASUALTIES ===
  "(smrtn|smrtno) stradal|",
  "[zž]rtv[aeu]?.+(po[zž]ar|potres|poplav|prometn|nesre[cć]|napad)|",
  "ozlije[dđ]en[aeiou]+.+(osob|osoba|preba[cč]en|bolnic)|",
  "preba[cč]en[aei]? u bolnicu|",
  "[zž]ivotno ugro[zž]en|",
  "te[sš]ke (tjelesne )?ozljede|",
  
  # === TERRORISM ===
  "terorist[aeikou]+[mh]? (napad|prijetn|akt)|",
  "teroriz[ao]m|",
  "radikalizacij|",
  "eksplozij[aeu]?.+(bomba|eksploziv|policij|istraga|[zž]rtv)|",
  "detonacij[aeu]?|",
  "podmetnuta bomba|",
  
  # === CYBER CRIME ===
  "cyber (napad|kriminal|sigurnost).+(policij|istraga|cert|prijav)|",
  "hakersk[aeiou]+ napad.+(policij|cert|istraga|prijav)|",
  "kra[dđ][aeu]+ podataka|",
  "ransomware|",
  "phishing.+(policij|upozorenj|[zž]rtv)|",
  
  # === DAMAGE & MATERIAL IMPACT ===
  "materijalna [sš]teta|",
  "procjena [sš]tete|",
  "[sš]tet[aeu]? (od|nakon|zbog).+(po[zž]ar|potres|poplav|oluj)|",
  "milijun[aei]? (kuna|eura) [sš]tete|",
  "sanacija [sš]tet|",
  
  # === SAFETY WARNINGS ===
  "(upozorenje|uzbuna).+(sigurnost|opasnost|evakuacij)|",
  "crveni meteoalarm|",
  "naran[cč]asti meteoalarm",
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
  "napad.*obran|obran.*napad|kontranapad|",
  
  # Entertainment
  "glumac|glumic|redatelj|",
  "koncert|festival|",
  "pjeva[cč]|album|pjesm|",
  "reality|showbiz|celebrity|",
  
  # Fiction/TV crime
  "kriminalisti[cč]k[aeiou]+ serij|",
  "kriminalisti[cč]ki film|",
  "triler|horor|akcijski film|",
  "netflix|hbo|amazon prime|",
  "nova sezona|premijera serije|",
  
  # Historical crime (without current relevance)
  "dokumentarac o|dokumentarni film|",
  
  # Other noise
  "horoskop|astrolog|",
  "vremenska prognoza(?!.+(upozorenj|alarm|opasnost))|",
  "tv program|recept|kuhanje",
  ")"
)

override_pattern <- paste0(
  "(",
  "\\bDORH\\b|dr[zž]avno odvjetni[sš]tvo|",
  "\\bUSKOK\\b|\\bPNUSKOK\\b|",
  "uhićen[aei]?|priveden[aei]?|pritvoren|",
  "kaznen[aeu]+ prijav|optu[zž]nic|",
  "policijsk[aeiou]+ (akcij|istraga)|",
  "prometn[aeiou]+ nesre[cć]|",
  "(poginuo|poginula|smrtno stradao)|",
  "[sš]umski po[zž]ar|stambeni po[zž]ar|",
  "vatrogasc.+intervencij|",
  "potres.+(magnituda|richter|[sš]teta)|",
  "poplav.+(evakuacij|[sš]teta)|",
  "\\bHGSS\\b|sto[zž]er civilne za[sš]tite|",
  "evakuacij[aeiou]+|",
  "[zž]rtv[aeu]?.+(napad|nesre[cć]|po[zž]ar|potres)|",
  "organiziran[aeiou]+ kriminal|",
  "terorist|eksplozij|detonacij",
  ")"
)

dt[, excl := stri_detect_regex(FULL_TEXT, excl_pattern, case_insensitive = TRUE)]
dt[, override := stri_detect_regex(FULL_TEXT, override_pattern, case_insensitive = TRUE)]
dt[, passes_exclusion := (!excl | override)]

excluded_count <- sum(!dt$passes_exclusion)
message("Excluded by sports/entertainment/fiction (without override): ", excluded_count)

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
  
  # Security institutions
  "\\bMUP\\b|Ministarstvo unutarnjih|",
  "\\bDORH\\b|dr[zž]avno odvjetni[sš]tvo|",
  "\\bUSKOK\\b|\\bPNUSKOK\\b|",
  "hrvatska policij|policijska uprava|",
  
  # Emergency services
  "\\bHGSS\\b|Hrvatska gorska slu[zž]ba|",
  "\\bJVP\\b|javna vatrogasna postrojba|",
  "\\bDVD\\b|dobrovoljno vatrogasno|",
  "civilna za[sš]tita|",
  
  # Courts
  "[zž]upanijski sud|op[cć]inski sud|vrhovni sud|",
  "ustavni sud|",
  
  # Government
  "Vlad[aeiou] RH|Vlad[aeiou] Republike Hrvatske|",
  
  # Cities (all major and regional)
  "Zagreb|Split|Rijeka|Osijek|Zadar|Pula|Slavonski Brod|",
  "Karlovac|Vara[zž]din|[SŠ]ibenik|Dubrovnik|",
  "Sisak|Petrinja|Glina|Bjelovar|Koprivnica|",
  "[CČ]akovec|Vukovar|Vinkovci|Po[zž]ega|Virovitica|",
  "Samobor|Velika Gorica|Zapre[sš]i[cć]|",
  
  # Counties
  "[zž]upanij[aeiou]|",
  
  # Regional
  "\\bu nas\\b|kod nas|",
  
  # Roads/Locations
  "\\bA[0-9]+\\b|autocest|dr[zž]avn[aeiou]+ cest|",
  "[zž]upanijsk[aeiou]+ cest",
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
write_path_rds <- "C:/Users/lsikic/Desktop/security_filtered.rds"
saveRDS(dt_final, write_path_rds)
message("Saved RDS: ", write_path_rds)

# Save Excel for QC
library(openxlsx)
write_path_xlsx <- "C:/Users/lsikic/Desktop/security_filtered.xlsx"

dt_excel <- copy(dt_final)
message("Saving all ", format(nrow(dt_excel), big.mark = ","), " rows to Excel...")

# Truncate FULL_TEXT for Excel (too large)
dt_excel[, FULL_TEXT := substr(FULL_TEXT, 1, 500)]
write.xlsx(dt_excel, write_path_xlsx, overwrite = TRUE)
message("Saved Excel: ", write_path_xlsx)

message("\n=== DONE ===")