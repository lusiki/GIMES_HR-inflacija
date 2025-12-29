# ==============================================================================
# ECONOMIC ACTIVITY ARTICLE SEARCH - REGEX VERSION
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
# ECONOMIC ACTIVITY REGEX PATTERN
# ------------------------------------------------------------------------------

activity_regex <- paste0(
  "(",
  
  # --- GDP CORE TERMS ---
  "bdp-?[aeu]?|",
  "bruto doma[cć][ie]g? proizvod|",
  
  # --- ECONOMIC GROWTH/DECLINE PHRASES ---
  "(gospodars[aeikou]+|ekonoms[aeikou]+) (rast|pad|oporavak|usporavanj)|",
  "(rast|pad|stagnacij[aeu]?|oporavak|usporavanj[aeu]?) gospodar|",
  "stop[aeu]? rasta|",
  "negativn[aeiou]+ rast|",
  
  # --- INDUSTRIAL PRODUCTION (key statistical indicator) ---
  "industrijske? proizvodnj[aeiou]?|",
  "prera[dđ]iva[cč]k[aeiou]+ industrij[aeiou]?|",
  "proizvodni[mh]? sektor|",
  
  # --- RECESSION/CONTRACTION ---
  "recesij[aeiou]?[mj]?[aoe]?|",
  "kontrakcij[aeiou]+ gospodar|",
  
  # --- CONSTRUCTION ACTIVITY ---
  "gra[dđ]evins[aeikou]+ (aktivnost|sektor)|",
  "gra[dđ]evinarstv[aou]+ (rast|pad|u [0-9])|",
  
  # --- TOURISM ECONOMIC (not travel blogs) ---
  "turisti[cč]k[aeiou]+ (promet|prihod[aei]?|rezultat)|",
  "broj (dolazaka|no[cć]enja)|",
  "(dolasci|no[cć]enja) turist|",
  "turisti[cč]k[aeiou]+ sezon[aeiou]+ [0-9]|",
  
  # --- TRADE BALANCE/EXTERNAL ---
  "vanjsk[aeiou]+ trgovin[aeiou]?|",
  "trgovins[aeikou]+ (bilanca|deficit|suficit|saldo)|",
  "robn[aeiou]+ razmjen[aeiou]?|",
  "(rast|pad|pove[cć]anje|smanjenje) (izvoz|uvoz)|",
  "izvoz[aeu]? (rast|pad|u)|",
  
  # --- OFFICIAL STATISTICS CONTEXT ---
  "(prema |po )?(podacima )?(dzs|eurostat|fina|hnb)|",
  "dr[zž]avn[aeiou]+ zavod za statistik|",
  "kvartaln[aeiou]+ (podac|rast|pad|bdp)|",
  "sezonski prilag|",
  "me[dđ]ugodi[sš]nj[aeiou]+|",
  "na godi[sš]njoj razini|",
  
  # --- VALUE ADDED ---
  "bruto dodan[aeiou]+ vrijednost|",
  
  # --- PRODUCTIVITY/COMPETITIVENESS ---
  "produktivnost[i]? rad[aeu]?|",
  "konkurentnost[i]? gospodar|",
  
  # --- REAL SECTOR ---
  "realn[io]+ (sektor|gospodar)|",
  
  # --- BUSINESS CONFIDENCE INDICATORS ---
  "indeks (povjerenja|poslovn)|",
  "poslovn[aeiou]+ (klim[aeiou]|o[cč]ekivanj)|",
  "anketa povjerenja|",
  
  # --- RETAIL/CONSUMPTION (economic framing) ---
  "maloprodaj[aeiou]+ (promet|rast|pad)|",
  "promet u trgovini|",
  "osobn[aeiou]+ potro[sš]nj[aeiou]?|",
  
  # --- INVESTMENT (macro level) ---
  "bruto investicij[aeiou]?|",
  "kapitalne investicij|",
  "fdi|",
  "stran[aeiou]+ (ulaganj|investicij)|",
  
  # --- EMPLOYMENT AS ACTIVITY INDICATOR ---
  "zaposlenost[i]? (rast|pad|u)|",
  "nezaposlenost[i]? (rast|pad|u)|",
  
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
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(activity_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving economic activity articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

activity_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(activity_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(activity_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(activity_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(activity_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(activity_articles), min(10, nrow(activity_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(activity_articles$TITLE[sample_idx[i]], 1, 80))
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

write_path <- "C:/Users/lsikic/Desktop/activity_articles.rds"
saveRDS(activity_articles, write_path)
message("Saved to: ", write_path)