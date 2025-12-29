# ==============================================================================
# CHECK CONDITIONS - WITH PROGRESS AND SENTENCE EXTRACTION
# ==============================================================================


readRDS("C:/Users/lsikic/Desktop/inflacija_articles.rds") -> infla_articles


infla_articles <- head(infla_articles_, 100000)
#list me top 100 infla_articles_ by FROM



#filter only where SOURCE_TYPE is "web"
infla_articles <- infla_articles[infla_articles$SOURCE_TYPE == "web", ]


# Major national news portals
national_news <- c(
  "index.hr", "jutarnji.hr", "vecernji.hr", "24sata.hr", 
  "tportal.hr", "dnevnik.hr", "net.hr", "rtl.hr", "hrt.hr",
  "telegram.hr", "nacional.hr", "direktno.hr", "n1info.com", "n1info.hr",
  "hina.hr", "novosti.hr"
)

# Business/Economic news (highly relevant for inflation topic)
business_news <- c(
  "poslovni.hr", "seebiz.eu", "lidermedia.hr", "lider.media",
  "bloombergadria.com", "hrportfolio.hr", "energypress.net",
  "energetika-net.com", "jatrgovac.com", "gospodarski.hr",
  "privredni.hr", "ictbusiness.info"
)

# Regional news portals
regional_news <- c(
  # Dalmatia
  "slobodnadalmacija.hr", "dalmatinskiportal.hr", "dalmacijadanas.hr",
  "dalmacijanews.hr", "antenazadar.hr", "zadarskilist.hr", "057info.hr",
  "sibenik.in", "sibenskiportal.hr", "dulist.hr", "dubrovnikinsider.hr",
  "dubrovnikportal.com", "dubrovnikpress.hr", "makarska-danas.com",
  "kastela.org", "plavakamenica.hr",
  
  # Istria & Kvarner
  "glasistre.hr", "novilist.hr", "istra24.hr", "istrain.hr",
  "rijekadanas.com", "istarski.hr", "porestina.info",
  
  # Slavonia
  "glas-slavonije.hr", "icv.hr", "034portal.hr", "035portal.hr",
  "slavonijainfo.com", "brodportal.hr", "ebrod.net", "epodravina.hr",
  "podravski.hr", "glaspodravine.hr", "pozeska-kronika.hr", "pozega.eu",
  "pozeski.hr",
  
  # Zagreb & Central Croatia
  "zagreb.info", "01portal.hr", "prigorski.hr",
  
  # Northern Croatia
  "varazdinske-vijesti.hr", "sjever.hr", "medjimurjepress.net",
  "medjimurski.hr", "zagorje.com", "zagorje-international.hr",
  "vzaktualno.hr", "evarazdin.hr", "muralist.hr", "drava.info",
  "sjeverni.info",
  
  # Karlovac & Lika
  "karlovacki.hr", "radio-banovina.hr", "likaclub.eu", "044portal.hr",
  
  # Other regional
  "radiokrizevci.hr", "bjelovar.live", "mnovine.hr"
)

# Specialized but relevant news
specialized_news <- c(
  "agroklub.com",      # Agriculture (food prices relevant)
  "mirovina.hr",       # Pensions (cost of living relevant)
  "legalis.hr",        # Legal news
  "srednja.hr",        # Education
  "studentski.hr",     # Student news
  "gov.hr",            # Government
  "fino.hr"            # Financial agency
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

# Combine all relevant sources
relevant_sources <- c(
  national_news,
  business_news, 
  regional_news,
  specialized_news,
  opinion_portals
)

# Remove duplicates
relevant_sources <- unique(relevant_sources)

message("Total relevant news sources defined: ", length(relevant_sources))



library(data.table)
library(stringi)

# Set max threads
setDTthreads(0)
message("Using ", getDTthreads(), " threads")

# Convert to data.table
if(!is.data.table(infla_articles)) {
  setDT(infla_articles)
}

dt <- copy(infla_articles)
message("Processing ", format(nrow(dt), big.mark = ","), " articles...")

# ------------------------------------------------------------------------------
# PATTERNS
# ------------------------------------------------------------------------------

g1_pattern <- "cijen|cjenik|naknad|tro[sš]a|tro[sš]kov|izdatak|izdaci|ra[cč]un|re[zž]ij|poskupljenj|poskupjel|poskupil|rast cijena|skok cijena|porast cijena|dizanje cijena|korekcija cijena|skuplje|skupo[cć]|preskupo|hiperinflacij|visoka inflacij|mar[zž]|doplat|pove[cć]anj|pojeftinjenj|pojeftinil|pad cijena|sni[zž]en|popust|rasprodaj|jeftinij|ni[zž]e cijen|smanjenje|dezinflacij|goriv|benzin|dizel|naft|plin|struj|elektri[cč]na energij|energent|hran|namirnic|prehrambeni proizvod|potro[sš]a[cč]k|ko[sš]aric"

g2_pattern <- "DZS|Dr[zž]avni zavod za statistik|HNB|Hrvatska narodna bank|HANFA|HGK|HOK|Ministarstvo financij|Ministarstvo gospodar|Porezna uprav|Carinska uprav|ECB|Europska sredi[sš]nja bank|Eurostat|Europska komisij|MMF|Me[dđ]unarodni monetarni fond|Svjetska bank|OECD|EBRD|inflacij|deflacij|dezinflacij|monetarn|kamatn|kupovn|[zž]ivotni standard|tro[sš]kovi [zž]ivot|realn primanj|realn pla[cć]|socijalna pomo[cć]|ku[cć]anst|ku[cć]ni bud[zž]et|potro[sš]a[cč]|potro[sš]nj|gra[dđ]an|umirovljenik|regulacija cijena|kontrola cijena|zamrzavanje cijena|ograni[cč]enje cijena|antiinflacijs"

g3_pattern <- "posto|postotak|postotnih bodov|mjese[cč]n|godi[sš]nj|kvartaln|tromjese[cč]n|polugodi[sš]nj|tjedn|dnevn|na godi[sš]njoj razin|na mjese[cč]noj razin|u odnosu na|u usporedbi|usporedba|vi[sš]e nego|manje nego|rekordno|najvi[sš]|najni[zž]|prosje[cč]n|prosjek|indeks|stopa|stope|razin|prag|granic|indeks potro[sš]a[cč]kih cijena|IPC|CPI|PPI|mjerenj|izra[cč]un|projekcij|prognoz|procjen|revizij|bazni efekt|sezonski utjecaj|kalendarski efekt"

excl_pattern <- "nogomet|ko[sš]ark|rukomet|tenis|liga prvak|premijer lig|bundeslig|utakmic|golova|igra[cč]|trener|mom[cč]ad|Dinamo|Hajduk|Rijeka|Osijek|UEFA|FIFA|NBA|olimpijsk|sportski|reprezentacij|film|serij|glumac|glumic|koncert|festival|glazb|pjeva[cč]|album|pjesm|reality|showbiz|celebrity"

override_pattern <- "inflacij|DZS|HNB|ECB|Eurostat|indeks potro[sš]a[cč]kih cijena|kupovna mo[cć]|monetarna politik|kamatne stop|poskupljenj|tro[sš]kovi [zž]ivota"

# ------------------------------------------------------------------------------
# PROGRESS BAR FUNCTION
# ------------------------------------------------------------------------------

progress_bar <- function(current, total, width = 50, prefix = "") {
  pct <- current / total
  filled <- round(pct * width)
  bar <- paste0(
    prefix,
    " [", 
    paste(rep("=", filled), collapse = ""),
    paste(rep(" ", width - filled), collapse = ""),
    "] ",
    sprintf("%5.1f%%", pct * 100),
    " (", format(current, big.mark = ","), "/", format(total, big.mark = ","), ")"
  )
  cat("\r", bar, sep = "")
  if(current == total) cat("\n")
}

# ------------------------------------------------------------------------------
# FAST DETECTION WITH PROGRESS
# ------------------------------------------------------------------------------

message("\n=== CHECKING CONDITIONS ===\n")
start_time <- Sys.time()
total_steps <- 5

# Step 1: g1
cat("Step 1/5: Group 1 (Price terms)...\n")
dt[, g1 := stri_detect_regex(FULL_TEXT, g1_pattern, case_insensitive = TRUE)]
progress_bar(1, total_steps, prefix = "Overall")
message("  -> Matches: ", format(sum(dt$g1, na.rm = TRUE), big.mark = ","), 
        " (", round(mean(dt$g1, na.rm = TRUE) * 100, 1), "%)")

# Step 2: g2
cat("\nStep 2/5: Group 2 (Economic/institutional terms)...\n")
dt[, g2 := stri_detect_regex(FULL_TEXT, g2_pattern, case_insensitive = TRUE)]
progress_bar(2, total_steps, prefix = "Overall")
message("  -> Matches: ", format(sum(dt$g2, na.rm = TRUE), big.mark = ","),
        " (", round(mean(dt$g2, na.rm = TRUE) * 100, 1), "%)")

# Step 3: g3
cat("\nStep 3/5: Group 3 (Measurement terms)...\n")
dt[, g3 := stri_detect_regex(FULL_TEXT, g3_pattern, case_insensitive = TRUE)]
progress_bar(3, total_steps, prefix = "Overall")
message("  -> Matches: ", format(sum(dt$g3, na.rm = TRUE), big.mark = ","),
        " (", round(mean(dt$g3, na.rm = TRUE) * 100, 1), "%)")

# Step 4: exclusion
cat("\nStep 4/5: Exclusion terms (sports/entertainment)...\n")
dt[, excl := stri_detect_regex(FULL_TEXT, excl_pattern, case_insensitive = TRUE)]
progress_bar(4, total_steps, prefix = "Overall")
message("  -> Excluded: ", format(sum(dt$excl, na.rm = TRUE), big.mark = ","),
        " (", round(mean(dt$excl, na.rm = TRUE) * 100, 1), "%)")

# Step 5: override
cat("\nStep 5/5: Override anchors...\n")
dt[, override := stri_detect_regex(FULL_TEXT, override_pattern, case_insensitive = TRUE)]
progress_bar(5, total_steps, prefix = "Overall")
message("  -> Override: ", format(sum(dt$override, na.rm = TRUE), big.mark = ","),
        " (", round(mean(dt$override, na.rm = TRUE) * 100, 1), "%)")

# Calculate final pass
dt[, `:=`(
  groups_matched = g1 + g2 + g3,
  passes = (g1 + g2 + g3 >= 2) & (!excl | override)
)]

elapsed <- round(difftime(Sys.time(), start_time, units = "secs"), 1)
message("\n=== CONDITIONS CHECKED IN ", elapsed, " SECONDS ===")

# ------------------------------------------------------------------------------
# RESULTS SUMMARY
# ------------------------------------------------------------------------------

message("\n=== FILTERING RESULTS ===")
message("Total articles: ", format(nrow(dt), big.mark = ","))
message("Pass filter:    ", format(sum(dt$passes), big.mark = ","), 
        " (", round(mean(dt$passes) * 100, 1), "%)")

message("\nGroups matched distribution:")
print(dt[, .(count = .N, pct = round(.N/nrow(dt)*100, 2)), by = groups_matched][order(groups_matched)])

message("\nExclusion impact:")
message("  Excluded by sports/entertainment: ", 
        format(sum(dt$excl & !dt$override), big.mark = ","))
message("  Saved by override: ", 
        format(sum(dt$excl & dt$override), big.mark = ","))

# ------------------------------------------------------------------------------
# EXTRACT WORDS AND SENTENCES (only for passing articles)
# ------------------------------------------------------------------------------

dt_pass <- dt[passes == TRUE]
n_pass <- nrow(dt_pass)
message("\n=== EXTRACTING WORDS & SENTENCES FOR ", format(n_pass, big.mark = ","), " ARTICLES ===\n")

# Function to extract matched words
extract_words <- function(text, pattern) {
  matches <- stri_extract_all_regex(text, pattern, case_insensitive = TRUE)
  sapply(matches, function(x) paste(unique(na.omit(x)), collapse = "; "))
}

# Function to extract sentences containing matches
extract_sentences <- function(text, pattern, max_sentences = 3) {
  # Split into sentences
  sentences <- stri_split_regex(text, "(?<=[.!?])\\s+", simplify = FALSE)[[1]]
  # Find sentences with matches
  matches <- stri_detect_regex(sentences, pattern, case_insensitive = TRUE)
  matched_sentences <- sentences[matches]
  # Limit and join
  if(length(matched_sentences) > max_sentences) {
    matched_sentences <- matched_sentences[1:max_sentences]
  }
  # Truncate long sentences
  matched_sentences <- stri_sub(matched_sentences, 1, 200)
  paste(matched_sentences, collapse = " [...] ")
}

# Process in chunks with progress
chunk_size <- 100
n_chunks <- ceiling(n_pass / chunk_size)

start_time <- Sys.time()

# Initialize columns
dt_pass[, `:=`(
  g1_words = character(.N),
  g2_words = character(.N),
  g3_words = character(.N),
  g1_sentences = character(.N),
  g2_sentences = character(.N),
  g3_sentences = character(.N)
)]

message("Processing in ", n_chunks, " chunks of ~", format(chunk_size, big.mark = ","), " articles each...\n")

for(i in seq_len(n_chunks)) {
  start_idx <- (i - 1) * chunk_size + 1
  end_idx <- min(i * chunk_size, n_pass)
  
  # Extract words
  dt_pass[start_idx:end_idx, g1_words := extract_words(FULL_TEXT, g1_pattern)]
  dt_pass[start_idx:end_idx, g2_words := extract_words(FULL_TEXT, g2_pattern)]
  dt_pass[start_idx:end_idx, g3_words := extract_words(FULL_TEXT, g3_pattern)]
  
  # Extract sentences
  dt_pass[start_idx:end_idx, g1_sentences := sapply(FULL_TEXT, extract_sentences, pattern = g1_pattern)]
  dt_pass[start_idx:end_idx, g2_sentences := sapply(FULL_TEXT, extract_sentences, pattern = g2_pattern)]
  dt_pass[start_idx:end_idx, g3_sentences := sapply(FULL_TEXT, extract_sentences, pattern = g3_pattern)]
  
  progress_bar(i, n_chunks, prefix = "Extracting")
}

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("\nExtraction completed in ", elapsed, " minutes")

# ------------------------------------------------------------------------------
# QUALITY CONTROL SAMPLE
# ------------------------------------------------------------------------------

message("\n" , strrep("=", 80))
message("QUALITY CONTROL SAMPLES")
message(strrep("=", 80))

# Sample 10 random articles
set.seed(123)
sample_idx <- sample(nrow(dt_pass), min(10, nrow(dt_pass)))

for(i in seq_along(sample_idx)) {
  idx <- sample_idx[i]
  row <- dt_pass[idx]
  
  message("\n", strrep("-", 80))
  message("ARTICLE ", i, " / ", length(sample_idx))
  message(strrep("-", 80))
  message("DATE:  ", row$DATE)
  message("TITLE: ", stri_sub(row$TITLE, 1, 100))
  if("SOURCE_TYPE" %in% names(row)) message("SOURCE: ", row$SOURCE_TYPE)
  message("\nMATCHED GROUPS: ", row$groups_matched, " (g1=", row$g1, ", g2=", row$g2, ", g3=", row$g3, ")")
  message("EXCLUDED: ", row$excl, " | OVERRIDE: ", row$override)
  
  message("\n>> G1 WORDS (Price): ")
  message("   ", stri_sub(row$g1_words, 1, 200))
  message(">> G1 SENTENCE: ")
  message("   ", stri_sub(row$g1_sentences, 1, 300))
  
  message("\n>> G2 WORDS (Economic): ")
  message("   ", stri_sub(row$g2_words, 1, 200))
  message(">> G2 SENTENCE: ")
  message("   ", stri_sub(row$g2_sentences, 1, 300))
  
  message("\n>> G3 WORDS (Measurement): ")
  message("   ", stri_sub(row$g3_words, 1, 200))
  message(">> G3 SENTENCE: ")
  message("   ", stri_sub(row$g3_sentences, 1, 300))
}

# ------------------------------------------------------------------------------
# WORD FREQUENCY ANALYSIS
# ------------------------------------------------------------------------------

message("\n", strrep("=", 80))
message("MOST FREQUENT MATCHED TERMS")
message(strrep("=", 80))

# Function to count word frequencies
count_word_freq <- function(words_col, top_n = 15) {
  all_words <- unlist(stri_split_fixed(words_col, "; "))
  all_words <- all_words[all_words != ""]
  all_words <- tolower(all_words)
  freq <- sort(table(all_words), decreasing = TRUE)
  head(freq, top_n)
}

message("\nTop G1 (Price) terms:")
print(count_word_freq(dt_pass$g1_words))

message("\nTop G2 (Economic) terms:")
print(count_word_freq(dt_pass$g2_words))

message("\nTop G3 (Measurement) terms:")
print(count_word_freq(dt_pass$g3_words))

# ------------------------------------------------------------------------------
# EXPORT FOR MANUAL REVIEW
# ------------------------------------------------------------------------------

# Create QC export
dt_qc <- dt_pass[, .(
  DATE,
  TITLE,
  SOURCE_TYPE = if("SOURCE_TYPE" %in% names(dt_pass)) SOURCE_TYPE else NA,
  groups_matched,
  g1, g2, g3,
  excl, override,
  g1_words, g2_words, g3_words,
  g1_sentences, g2_sentences, g3_sentences
)]

message("\n=== OUTPUTS ===")
message("  dt        - all ", format(nrow(dt), big.mark = ","), " articles with flags")
message("  dt_pass   - ", format(nrow(dt_pass), big.mark = ","), " passing articles with words & sentences")
message("  dt_qc     - QC export table (without FULL_TEXT)")

message("\n=== DONE ===")
message("Total time: ", round(difftime(Sys.time(), start_time, units = "mins"), 2), " minutes")

# Optional: Save QC sample to CSV for review
# fwrite(dt_qc[sample(.N, min(1000, .N))], "inflation_qc_sample.csv")