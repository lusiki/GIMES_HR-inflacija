# ==============================================================================
# INSTITUTIONAL PERCEPTION ARTICLE SEARCH - REGEX VERSION
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
# INSTITUTIONAL PERCEPTION REGEX PATTERN
# ------------------------------------------------------------------------------

institutional_regex <- paste0(
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
  "rad (vlade|sabora|ministarstva|institucij)|",
  "ocjena rada (vlade|sabora|ministarstva)|",
  "(kritik|pohval)[aeiou]+.+(vlad|sabor|ministar)|",
  
  # === JUDICIARY ASSESSMENT ===
  "(ne)?u[cč]inkovitost (sudstv|pravosu[dđ]|sudov)|",
  "trajanje (sudskih postupaka|postupaka|procesa)|",
  "sudski zaostatci|",
  "zaostatci u sudstv|",
  "pristrani sud|",
  "nepristran[aeiou]+ sudov|",
  
  # === OVERSIGHT BODIES ===
  "dr[zž]avn[aeiou]+ (ured za )?revizij|",
  "pu[cč]ki pravobranitelj|",
  "ombudsman|",
  "povjereni[ck][aeiou]+ za informiranje|",
  "nadzorn[aeiou]+ (tijel|mehaniz)|",
  
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
  "uhljeb|",
  
  # === INSTITUTIONAL CRISIS ===
  "kriza (institucij|vladavine prava|pravosu[dđ]|sudstv)|",
  "uru[sš]avanje (institucij|sustava|vladavine prava)|",
  "erozij[aeiou]+ (institucij|vladavine prava|povjerenja)|",
  "slabljenje (institucij|vladavine prava)|",
  
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
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(institutional_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving institutional perception articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

institutional_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(institutional_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(institutional_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(institutional_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(institutional_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(institutional_articles), min(10, nrow(institutional_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(institutional_articles$TITLE[sample_idx[i]], 1, 80))
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

write_path <- "C:/Users/lsikic/Desktop/institutional_articles.rds"
saveRDS(institutional_articles, write_path)
message("Saved to: ", write_path)