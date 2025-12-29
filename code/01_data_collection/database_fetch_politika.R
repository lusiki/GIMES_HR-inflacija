# ==============================================================================
# POLITICAL POLARIZATION ARTICLE SEARCH - REGEX VERSION
# ==============================================================================

library(duckdb)
library(DBI)

# ------------------------------------------------------------------------------
# CONNECTION
# ------------------------------------------------------------------------------

duckdb_file_path <- "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb"
con <- dbConnect(duckdb::duckdb(), dbdir = duckdb_file_path, read_only = TRUE)
dbExecute(con, "SET memory_limit='48GB';")
message("Connected to database")

# ------------------------------------------------------------------------------
# POLARIZATION REGEX PATTERN
# ------------------------------------------------------------------------------

polarization_regex <- paste0(
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
  "(lijevi|desni) (protiv|i) (lijevi|desni)|",
  
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
  
  # === HISTORICAL MEMORY CONFLICTS (Croatian specific) ===
  "(usta[sš]|partizan).+(sukob|rasprav|polemik|podjel|provokacij)|",
  "(jasenovac|bleiburg|kri[zž]ni put).+(podjel|sukob|rasprav|politi[zk]|instrumentaliz)|",
  "(ndh|za dom spremni).+(rasprav|polemik|sukob|provokacij|zabran)|",
  "revizij[aeu]+ povijesti|",
  "politi[ck]a instrumentalizacija (pro[sš]losti|povijesti|[zž]rtava)|",
  
  # === INTOLERANCE TERMS ===
  "(ksenofobij|homofobij|rasiz|antisemitiz|mizoginij)[aeiou]?[mj]?|",
  "(ksenofobi[cč]n|homofobi[cč]n|rasisti[cč]k|antisemitsk|mizogi)[aeiou]+|",
  "netrpeljivost prema|",
  "nesno[sš]ljivost prema|",
  
  # === DISINFORMATION/PROPAGANDA WAR ===
  "dezinformacij[aeiou]?.+(politi[cč]k|stranka|kampanj|izbor)|",
  "(politi[cč]k|stranka[cč]k|izborna)[aeiou]+ (propaganda|manipulacij)|",
  "la[zž]n[aeiou]+ vijesti.+(politi[cč]k|stranka|izbor)|",
  "informacijski rat|",
  "medijski rat|",
  "botov[aei]?.+(politi[cč]k|stranka|kampanj)|",
  "trolanje.+(politi[cč]k|stranka)|",
  
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
  "(prosvjed|demonstracij|marš).+(protiv|za).+(vlad|hdz|sdp|poba[cč]aj|lgbti?|migran|crkv)|",
  "kontra.?prosvjed|",
  "sukob (prosvjednika|demonstranata)|",
  
  # === DISCOURSE ANALYSIS META ===
  "(politi[cč]k|javni) diskurs.+(polariz|radikaliz|mr[zž]nj|netrpelj)|",
  "(toxi[cč]n|otrovan)[aeiou]+ (atmosfer|diskurs|javnost)|",
  "nepomirljiv[aeiou]+ (stajali[sš]t|stav|pozicij)|",
  
  ")"
)

# ------------------------------------------------------------------------------
# BUILD QUERY
# ------------------------------------------------------------------------------

query <- paste0("
SELECT *
FROM media_data
WHERE DATE >= '2021-01-01' 
  AND DATE <= '2024-05-31'
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(polarization_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving polarization articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

polarization_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(polarization_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(polarization_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(polarization_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(polarization_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(polarization_articles), min(10, nrow(polarization_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(polarization_articles$TITLE[sample_idx[i]], 1, 80))
  }
}

# ------------------------------------------------------------------------------
# CLEANUP
# ------------------------------------------------------------------------------

dbDisconnect(con, shutdown = TRUE)
message("\nDatabase connection closed")

# ------------------------------------------------------------------------------
# SAVE
# ------------------------------------------------------------------------------

write_path <- "C:/Users/lsikic/Desktop/polarization_articles.rds"
saveRDS(polarization_articles, write_path)
message("Saved to: ", write_path)