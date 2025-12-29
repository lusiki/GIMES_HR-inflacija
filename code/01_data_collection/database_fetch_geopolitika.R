# ==============================================================================
# GEOPOLITICAL STABILITY ARTICLE SEARCH - REGEX VERSION
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
# GEOPOLITICAL REGEX PATTERN
# ------------------------------------------------------------------------------

geopolitical_regex <- paste0(
  "(",
  
  
  # === NATO/COLLECTIVE DEFENSE ===
  "nato.+(vojn|obran|[cč]lanic|pro[sš]irenj|misij|snag|kontingent|vje[zž]b)|",
  "(vojn|obran|[cč]lanic|pro[sš]irenj|kontingent).+nato|",
  "[cč]lanak 5|",
  "kolektivn[aeiou]+ obran|",
  "sjevernoatlantsk[aeiou]+ (savez|ugovor|vije[cć]e)|",
  "euroatlantsk[aeiou]+ (integracij|savezni[sš]tv|suradnj)|",
  
  # === EU SECURITY/FOREIGN POLICY ===
  "(eu|europsk[aeiou]+ unij).+(sigurnost|obran|sankcij|vanjsk[aeiou]+ politik)|",
  "(sigurnost|obran|sankcij|vanjsk[aeiou]+ politik).+(eu|europsk[aeiou]+ unij)|",
  "zajedni[cč]k[aeiou]+ (vanjsk[aeiou]+ i sigurnosn[aeiou]+ politik|sigurnosn[aeiou]+ politik)|",
  "europsk[aeiou]+ (obran|vojn)[aeiou]+ (politik|suradnj|snag)|",
  
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
  "(kin|peking).+(vojn|prijetn|sankcij|napetost|sukob|tajvan|utjecaj na|teritorijal)|",
  "(prijetn|napetost|sukob|trgovinski rat).+(kin|peking)|",
  "kinesk[aeiou]+ (vojn|prijetn|ekspanzij|utjecaj)|",
  
  # === USA GEOPOLITICAL ===
  "(sad|ameri[cč]k|washington|pentagon|bijel[aeiou]+ ku[cć]).+(vojn|sankcij|prijetn|napad|operacij|strateg)|",
  "ameri[cč]k[aeiou]+ (vojsk|sankcij|prijetn|intervencij|udari|strateg)|",
  
  # === UKRAINE CONFLICT ===
  "(ukrajin|kijev|donbas|krim).+(rat|invazij|sukob|ofenziv|obran|vojn|napad|oku?pacij)|",
  "(rat|invazij|sukob|ofenziv) (u|na|protiv) ukrajin|",
  "rusk[aeiou]+ (invazij|agresij) (na|u|protiv) ukrajin|",
  "ukrajinsk[aeiou]+ (rat|sukob|front|obran)|",
  
  # === MIDDLE EAST CONFLICTS ===
  "(gaza|izrael|hamas|hezbollah|palestin).+(rat|sukob|napad|bombardiranj|ofenziv|prijetn)|",
  "(rat|sukob|napad|bombardiranj) (u|na) (gaz|izrael)|",
  "bliskoisto[cč]n[aeiou]+ (sukob|rat|kriza|napetost)|",
  "(iran|teheran).+(nuklearn|prijetn|sankcij|napad|raket)|",
  "irasnk[aeiou]+ nuklearn|",
  
  # === BALKANS GEOPOLITICAL ===
  "(srbij|beograd).+(napetost|sukob|provokacij|prijetnj|vojn[aeiou]+ vje[zž]b)|",
  "(kosov|pri[sš]tin).+(napetost|sukob|kriza|priznanj|dijalog)|",
  "srbij[aeiou]?.+(kosov|pri[sš]tin).+(napetost|sukob|pregovor|dijalog|odnos)|",
  "(bih|bosn[aeiou]|republika srpska|dodik).+(kriza|napetost|secesij|destabiliz|prijetn)|",
  "balkansk[aeiou]+ (nestabilnost|napetost|kriza)|",
  "zapadn[aeiou]+ balkan.+(stabilnost|sigurnost|integracij|pro[sš]irenj)|",
  
  # === HYBRID THREATS ===
  "hibridn[aeiou]+ (rat|prijetn|napad|djelovanj)|",
  "hibridno ratovanj|",
  "cyber (rat|napad|prijetn).+(dr[zž]av|vojn|obavje[sš]tajn|rusij|kin)|",
  "kibernetsk[aeiou]+ (napad|prijetn|sigurnost).+(dr[zž]av|vojn)|",
  "dezinformacij[aeiou]+.+(rusij|kin|kampanj|ratovanj)|",
  "informacijski rat|",
  
  # === NUCLEAR/WMD ===
  "nuklearn[aeiou]+ (prijetn|oru[zž]j|program|naouru[zž]|razouru[zž]|proliferacij)|",
  "(nuklearn|atomsk)[aeiou]+ (bomb|bojev[aeiou]+ gla|raket)|",
  "balisti[cč]k[aeiou]+ raket|",
  "(kemijsk|biolo[sš]k)[aeiou]+ oru[zž]j|",
  "neproliferacij|",
  "razouru[zž]anj|",
  
  # === SANCTIONS ===
  "sankcij[aeiou]+.+(rusij|kin|iran|sjevernu koreju|bjelorusij)|",
  "(rusij|kin|iran).+sankcij|",
  "(ekonomsk|financijsk|trgovinsk)[aeiou]+ sankcij[aeiou]+.+(uvest|pro[sš]iri|poja[cč]a|ukinu)|",
  "embargo.+(oru[zž]j|nafta?|plin)|",
  "zamrzavanj[aeu]+ imovine|",
  
  # === MILITARY OPERATIONS ===
  "vojn[aeiou]+ (operacij|intervencij|akcij|ofenziv|udar)|",
  "(vojn|oru[zž]an)[aeiou]+ sukob|",
  "oru[zž]an[aeiou]+ (agresij|intervencij)|",
  "vojn[aeiou]+ vje[zž]b[aeiou]+.+(nato|rusij|kin|granica)|",
  "prisustvo vojnih snaga|",
  "raspore[dđ]ivanje (vojsk|trupa|snaga)|",
  "vojn[aeiou]+ pomo[cć]|",
  "isporuk[aeiou]+ oru[zž]ja|",
  
  # === TERRITORIAL DISPUTES ===
  "teritorijaln[aeiou]+ (integritet|sukob|spor|cjelovitost)|",
  "oku?pacij[aeiou]+.+(teritorij|podru[cč]j)|",
  "(aneksij|pripojenje).+(krim|teritorij)|",
  "separatiz[ao]m|",
  "secesij[aeiou]?|",
  
  # === DIPLOMATIC INCIDENTS ===
  "diplomatsk[aeiou]+ (kriza|incident|sukob|napetost)|",
  "protjerivanje diplomat|",
  "persona non grata|",
  "(povla[cč]enj|opoziv) veleposlanika|",
  "zatvaranje (veleposlanstv|ambasad|konzulat)|",
  "prekid diplomatskih odnosa|",
  
  # === ALLIANCES/TREATIES (geopolitical) ===
  "vojn[aeiou]+ (savez|savezni[sš]tv|pakt)|",
  "strate[sš]k[aeiou]+ partnerstvo.+(sad|rusij|kin|nato)|",
  "sigurnosn[aeiou]+ (sporazum|ugovor|garancij)|",
  "obrambeni sporazum|",
  
  # === INTEGRATION/ENLARGEMENT ===
  "pro[sš]irenj[aeu]+ (nato|eu|europsk[aeiou]+ unij)|",
  "(pristupanj|[cč]lanstvo).+(nato|eu).+(pregovor|[cč]lan|kandidat)|",
  "[cč]lanstv[aou]+ u (nato|eu)|",
  "pristupni pregovor|",
  "kandidatski status|",
  
  # === GEOPOLITICAL ANALYSIS ===
  "geopoliti[cč]k[aeiou]+|",
  "me[dđ]unarodn[aeiou]+ (sigurnost|odnos[aei]?|poredak)|",
  "globaln[aeiou]+ (sigurnost|poredak|nestabilnost)|",
  "ravnote[zž][aeu]? (snaga|mo[cć]i)|",
  "sfer[aeu]? utjecaja|",
  "multipolarnost|",
  "unilateraliz[ao]m|",
  
  # === INTELLIGENCE/ESPIONAGE ===
  "[sš]pijuna[zž][aeiou]?|",
  "[sš]pijunsk[aeiou]+ (afar|skandal|mre[zž])|",
  "obavje[sš]tajn[aeiou]+ (slu[zž]b|operacij|aktivnost).+(stran|rusij|kin)|",
  "tajn[aeiou]+ (operacij|misij)|",
  
  # === BORDER SECURITY (geopolitical) ===
  "grani[cč]n[aeiou]+ (incident|napetost|sukob|kriza)|",
  "kr[sš]enj[aeu]+ (granice|teritorij|zra[cč]nog prostor|suverenitet)|",
  "zatvaranje granic[aeiou]+.+(sigurnost|vojn|kriza)|",
  
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
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(geopolitical_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving geopolitical articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

geopolitical_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(geopolitical_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(geopolitical_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(geopolitical_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(geopolitical_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(geopolitical_articles), min(10, nrow(geopolitical_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(geopolitical_articles$TITLE[sample_idx[i]], 1, 80))
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

write_path <- "C:/Users/lsikic/Desktop/geopolitical_articles.rds"
saveRDS(geopolitical_articles, write_path)
message("Saved to: ", write_path)