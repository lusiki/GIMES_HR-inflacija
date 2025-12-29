# ==============================================================================
# POLITICAL POLARIZATION ARTICLE FILTERING - MERGED PIPELINE
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
polarization_articles <- readRDS("C:/Users/lsikic/Desktop/polarization_articles.rds")

if(!is.data.table(polarization_articles)) {
  setDT(polarization_articles)
}
message("Total articles loaded: ", format(nrow(polarization_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 1: SOURCE TYPE - Keep only web
# ------------------------------------------------------------------------------

message("\n=== FILTER 1: SOURCE TYPE ===")
dt <- polarization_articles[SOURCE_TYPE == "web"]
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
  "legalis.hr", "gov.hr"
)

# Opinion/Analysis portals (very relevant for polarization)
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
# FILTER 4: TITLE MUST CONTAIN POLARIZATION-RELATED TERM
# ------------------------------------------------------------------------------

message("\n=== FILTER 4: TITLE RELEVANCE ===")

title_pattern <- paste0(
  "(",
  # Division/Conflict
  "polarizacij|podijeljen|podjel[aeu]|rascjep|razdor|",
  "sukob.+(ljev|desn|hdz|sdp|vladaju|oporb)|",
  
  # Left/Right
  "ljevic|desnic|lijevi|desni|",
  "konzervativ|liberal|progresiv|",
  "nacionalist|populist|suverenist|",
  
  # Parties in conflict
  "(hdz|sdp|mo[zž]emo|most|dp).+(sukob|napad|optu[zž]|protiv)|",
  "vladaju[cć].*oporb|oporb.*vladaju[cć]|",
  
  # Hate speech/Intolerance
  "govor mr[zž]nje|mr[zž]nj[aeu]|netrpeljivost|",
  "ksenofobij|homofobij|rasiz|antisemitiz|",
  "diskriminacij|stigmatizacij|",
  
  # Historical memory conflicts
  "usta[sš]|partizan|ndh|za dom spremni|",
  "jasenovac|bleiburg|kri[zž]ni put|",
  
  # Hot button issues
  "rodn[aeiou]+ ideologij|istanbulsk[aeiou]+ konvencij|",
  "istospoln[aeiou]+ (brak|zajednic)|lgbti?|pride|",
  "poba[cč]aj|hod za [zž]ivot|pro.?life|",
  "vjeronauk|crkv.*dr[zž]av|sekulariz|klerikaliz|",
  "migrant.*sukob|izbjegli.*sukob|",
  
  # Disinformation
  "dezinformacij|la[zž]n[aeiou]+ vijesti|fake news|propaganda|",
  
  # Identity politics
  "identitetsk[aeiou]+ politik|politi[cč]ki rat|kulturni rat|",
  "sukob vrijednosti|svjetonazorsk",
  ")"
)

dt[, title_relevant := stri_detect_regex(TITLE, title_pattern, case_insensitive = TRUE)]
dt <- dt[title_relevant == TRUE]
message("After title filter: ", format(nrow(dt), big.mark = ","))

# ------------------------------------------------------------------------------
# FILTER 5: CORE POLARIZATION TERM IN TEXT
# ------------------------------------------------------------------------------

message("\n=== FILTER 5: CORE TERM VERIFICATION ===")

core_pattern <- paste0(
  "(",
  # === POLARIZATION AS CONCEPT ===
  "polarizacij[aeiou]+ (dru[sš]tv|politi[cč]k|javnost|biračkog)|",
  "(dru[sš]tven|politi[cč]k)[aeiou]+ polarizacij|",
  "polarizirano dru[sš]tvo|",
  
  # === SOCIAL/POLITICAL DIVISIONS ===
  "podjel[aeu]+ (u dru[sš]tvu|u hrvatskoj|dru[sš]tv|politi[cč]k|izme[dđ]u)|",
  "(dru[sš]tven|politi[cč]k|ideolo[sš]k|svjetonazorsk)[aeiou]+ podjel|",
  "rascjep.+(dru[sš]tv|politi[cč]k|izme[dđ]u)|",
  "razdor (u dru[sš]tvu|u hrvatskoj|izme[dđ]u)|",
  
  # === LEFT VS RIGHT CONFLICT ===
  "(ljevic|desnic)[aeiou]+.+(sukob|napad|optu[zž]|konfrontacij|podjel)|",
  "sukob.+(ljevic|desnic)|",
  "(ljevic|desnic)[aeiou]+ (i|protiv|versus|vs) (ljevic|desnic)|",
  
  # === PARTY VS PARTY CONFLICT ===
  "(hdz|sdp|mo[zž]emo|most|dp|domovinski pokret).+(sukob|napad|optu[zž]|konfrontacij|obra[cč]un).+(hdz|sdp|mo[zž]emo|most|dp)|",
  "sukob.+(hdz i sdp|sdp i hdz|vladaju[cć]ih i oporb)|",
  "(vladaju[cć]|oporb)[aeiou]+.+(sukob|napad|konfrontacij|obra[cč]un).+(vladaju[cć]|oporb)|",
  
  # === HATE SPEECH ===
  "govor mr[zž]nje|",
  "(politi[cč]k|nacionaln|etni[cč]k|vjers)[aeiou]+ mr[zž]nj|",
  "mr[zž]nj[aeu]+ (prema|na|protiv).+(grup|manjin|narod|stranka)|",
  "poticanje mr[zž]nje|",
  "[sš]irenje mr[zž]nje|",
  
  # === EXTREMISM IN POLITICAL CONTEXT ===
  "(politi[cč]k|desni[cč]arsk|ljevi[cč]arsk)[aeiou]+ ekstremiz|",
  "ekstremn[aeiou]+ (ljevic|desnic|stranka|pokret)|",
  "radikalizacij[aeiou]+ (politi[cč]k|dru[sš]tv|javnog diskursa)|",
  "(politi[cč]k|ideolo[sš]k)[aeiou]+ radikalizacij|",
  
  # === HISTORICAL MEMORY CONFLICTS ===
  "(usta[sš]|partizan).+(sukob|rasprav|polemik|podjel|provokacij)|",
  "(jasenovac|bleiburg|kri[zž]ni put).+(podjel|sukob|rasprav|politi[zk]|instrumentaliz)|",
  "(ndh|za dom spremni).+(rasprav|polemik|sukob|provokacij|zabran)|",
  "revizij[aeu]+ povijesti|",
  "politi[ck]a instrumentalizacija (pro[sš]losti|povijesti|[zž]rtava)|",
  
  # === INTOLERANCE TERMS ===
  "(ksenofobij|homofobij|rasiz|antisemitiz|mizoginij)[aeiou]?[mj]?|",
  "(ksenofobi[cč]n|homofobi[cč]n|rasisti[cč]k|antisemitsk)[aeiou]+|",
  "netrpeljivost prema|",
  "nesno[sš]ljivost prema|",
  
  # === DISINFORMATION/PROPAGANDA WAR ===
  "dezinformacij[aeiou]?.+(politi[cč]k|stranka|kampanj|izbor)|",
  "(politi[cč]k|stranka[cč]k|izborna)[aeiou]+ (propaganda|manipulacij)|",
  "la[zž]n[aeiou]+ vijesti.+(politi[cč]k|stranka|izbor)|",
  "informacijski rat|",
  "medijski rat|",
  "botov[aei]?.+(politi[cč]k|stranka|kampanj)|",
  
  # === US VS THEM FRAMING ===
  "mi protiv njih|",
  "nas i njih|",
  "demonizacij[aeiou]+ (protivnik|oporb|politi[cč]k)|",
  "dehumanizacij[aeiou]+ (protivnik|oporb|politi[cč]k)|",
  
  # === HOT BUTTON ISSUES ===
  # --- Gender/LGBT ---
  "rodn[aeiou]+ ideologij|",
  "istanbulsk[aeiou]+ konvencij[aeiou]?.+(sukob|rasprav|podjel|prosvjed|protiv)|",
  "istospoln[aeiou]+ (brak|zajednic|partnerstvo).+(sukob|rasprav|podjel|prosvjed|protiv|referend)|",
  "lgbti?.+(sukob|rasprav|podjel|prosvjed|napad|diskriminacij|mr[zž]nj)|",
  "pride.+(napad|prosvjed|protiv|incident|sukob)|",
  
  # --- Abortion ---
  "(poba[cč]aj|pravo na poba[cč]aj|pro.?life).+(sukob|rasprav|podjel|prosvjed)|",
  "hod za [zž]ivot|",
  
  # --- Church/State ---
  "(crkv|klerikaliz).+(politi[ck]|dr[zž]av|sukob|utjecaj na politi)|",
  "(vjeronauk|kri[zž] u [sš]kolama).+(sukob|rasprav|podjel)|",
  "sekulariz[ao]m.+(sukob|rasprav|crkv)|",
  
  # --- Migration ---
  "(migrant|izbjegli[ck]).+(sukob|podjel|mr[zž]nj|netrpelj|kseno|napad na)|",
  "anti.?migraci|",
  
  # === IDENTITY POLITICS ===
  "identitetsk[aeiou]+ politik|",
  "politi[ck][aeiou]+ identitet[aeu]?|",
  "(politi[cč]ki|kulturni) rat|",
  "kulturolo[sš]ki sukob|",
  "sukob vrijednosti|",
  
  # === POLARIZING PROTESTS ===
  "(prosvjed|demonstracij|mar[sš]).+(protiv|za).+(vlad|hdz|sdp|poba[cč]aj|lgbti?|migran|crkv)|",
  "kontra.?prosvjed|",
  "sukob (prosvjednika|demonstranata)|",
  
  # === DISCOURSE ANALYSIS META ===
  "(politi[cč]k|javni) diskurs.+(polariz|radikaliz|mr[zž]nj|netrpelj)|",
  "(toxi[cč]n|otrovan)[aeiou]+ (atmosfer|diskurs|javnost)|",
  "nepomirljiv[aeiou]+ (stajali[sš]t|stav|pozicij)",
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
  "derbi|navija[cč]|",
  
  # Entertainment
  "glumac|glumic|redatelj|",
  "koncert|festival|",
  "pjeva[cč]|album|pjesm|",
  "reality|showbiz|celebrity|",
  
  # Sports rivalries (not political)
  "vje[cč]ni derbi|navija[cč]ki sukob|",
  "sukob navija[cč]|torcida|bad blue boys|",
  
  # Other noise
  "horoskop|astrolog|",
  "vremenska prognoza|",
  "tv program|recept|kuhanje",
  ")"
)

override_pattern <- paste0(
  "(",
  "polarizacij[aeiou]+ dru[sš]tv|politi[cč]k[aeiou]+ polarizacij|",
  "govor mr[zž]nje|",
  "(dru[sš]tven|politi[cč]k)[aeiou]+ podjel|",
  "(ljevic|desnic).+(sukob|podjel|konfrontacij)|",
  "(hdz|sdp).+(sukob|napad|optu[zž]).+(hdz|sdp)|",
  "(usta[sš]|partizan).+(sukob|podjel|rasprav)|",
  "(jasenovac|bleiburg).+(podjel|sukob|instrumentaliz)|",
  "rodn[aeiou]+ ideologij|istanbulsk[aeiou]+ konvencij|",
  "istospoln[aeiou]+ (brak|zajednic)|lgbti?|",
  "(ksenofobij|homofobij|rasiz|antisemitiz)|",
  "dezinformacij|la[zž]n[aeiou]+ vijesti|",
  "identitetsk[aeiou]+ politik|politi[cč]ki rat|kulturni rat|",
  "hod za [zž]ivot|pro.?life",
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
  
  # Political institutions
  "Sabor|Hrvatski sabor|saborsk|",
  "Vlad[aeiou] RH|Vlad[aeiou] Republike Hrvatske|",
  "predsjednik.*RH|predsjedni[ck].*Hrvatske|",
  
  # Political parties (Croatian)
  "\\bHDZ\\b|Hrvatska demokratska zajednica|",
  "\\bSDP\\b|Socijaldemokratska partija|",
  "\\bMo[zž]emo\\b|",
  "\\bMost\\b|Most nezavisnih lista|",
  "\\bDP\\b|Domovinski pokret|",
  "\\bHNS\\b|\\bHSS\\b|\\bHSLS\\b|\\bIDS\\b|",
  
  # Croatian political figures
  "Plenkovi[cć]|Milanovi[cć]|Grmoja|Petrov|Penava|[SŠ]koro|",
  "Bero[sš]|Borg|Puljak|Toma[sš]evi[cć]|",
  
  # Croatian society references
  "hrvatsko dru[sš]tvo|hrvatska javnost|",
  "hrvatski (gra[dđ]ani|bira[cč]i|narod)|",
  
  # Croatian historical references
  "Domovinski rat|Oluja|Vukovar|",
  
  # Cities
  "Zagreb|Split|Rijeka|Osijek|Zadar|Pula|Dubrovnik|",
  
  # Regional
  "\\bu nas\\b|kod nas|na[sš][aeiou]? (dru[sš]tv|politi[cč]k)|",
  
  # Media
  "HRT|Nova TV|RTL|N1|",
  
  # Referendum/Elections
  "referendu?m.*Hrvatsk|Hrvatsk.*referendu?m|",
  "izbor[aei]?.*Hrvatsk|Hrvatsk.*izbor|",
  "parlamentarn[aeiou]+ izbor|predsjedni[cč]k[aeiou]+ izbor|lokaln[aeiou]+ izbor",
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
write_path_rds <- "C:/Users/lsikic/Desktop/polarization_filtered.rds"
saveRDS(dt_final, write_path_rds)
message("Saved RDS: ", write_path_rds)

# Save Excel for QC
library(openxlsx)
write_path_xlsx <- "C:/Users/lsikic/Desktop/polarization_filtered.xlsx"

dt_excel <- copy(dt_final)
message("Saving all ", format(nrow(dt_excel), big.mark = ","), " rows to Excel...")

# Truncate FULL_TEXT for Excel (too large)
dt_excel[, FULL_TEXT := substr(FULL_TEXT, 1, 500)]
write.xlsx(dt_excel, write_path_xlsx, overwrite = TRUE)
message("Saved Excel: ", write_path_xlsx)

message("\n=== DONE ===")