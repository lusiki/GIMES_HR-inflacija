# ==============================================================================
# INFLATION ARTICLE SEARCH - REGEX VERSION
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
# INFLATION REGEX PATTERN
# ------------------------------------------------------------------------------

inflation_regex <- paste0(
  "(",
  
  # --- INFLATION WORD (all cases) ---
  "inflacij[aeiou]?[mj]?[ao]?|",
  "dezinflacij[aeiou]?[mj]?[ao]?|",
  "hiperinflacij[aeiou]?[mj]?[ao]?|",
  "stagflacij[aeiou]?[mj]?[ao]?|",
  
  # --- PRICE INDEX ---
  "indeks[a]? potro[sš]a[cč]kih cijena|",
  "hicp|",
  
  # --- PRICE MOVEMENT PHRASES ---
  "(rast|porast|pad|skok|sniženje|sni[zž]enje|korekcij[aeu]) cijena|",
  "cijena?e? (rastu|porasl[aeioe]|padaj[ue]|pal[aeioe]|sko[cč]il[aeioe])|",
  
  # --- POSKUPLJENJE/POJEFTINJENJE (all forms) ---
  "poskupljenj[aeiou]?|",
  "poskupljuj[ue]?|",
  "poskupjel[aoie]?|",
  "poskupil[aoie]?|",
  "pojeftinjenj[aeiou]?|",
  "pojeftinil[aoie]?|",
  
  # --- COST OF LIVING ---
  "tro[sš]kov[aei]? [zž]ivota|",
  "[zž]ivotn[aeiou]? tro[sš]kov[aei]?|",
  "kupovn[aeu] mo[cć]|",
  "[zž]ivotn[aeiou]?[gm]? standard[aeu]?|",
  "realn[aeiou]? pla[cć][aeu]?|",
  "realn[aeiou]? primanj[aeiou]?|",
  
  # --- SPECIFIC PRICES (cijena + product) ---
  "cijena?e? goriva|",
  "cijena?e? hrane|",
  "cijena?e? energenata|",
  "cijena?e? struje|",
  "cijena?e? plina|",
  "cijena?e? benzina|",
  "cijena?e? dizela|",
  "cijena?e? namirnica|",
  
  # --- POLICY RESPONSES ---
  "zamrzavanj[aeiou]? cijena|",
  "regulacij[aeiou]? cijena|",
  "antiinflacijs[aeikou]+[mh]?|",
  "suzbijanj[aeiou]? inflacije|",
  "borb[aeiou] protiv inflacije|",
  
  # --- CONSUMER BASKET ---
  "potro[sš]a[cč]k[aeiou]+ ko[sš]aric[aeiou]?|",
  
  # --- INFLATION CONTEXT PHRASES ---
  "inflacijs[aeikou]+ (pritisa?k|stopa?|o[cč]ekivanj)|",
  "stop[aeiou]? inflacije|",
  "(visok|nisk|rast)[aeiou]* inflacij[aeiou]?",
  
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
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(inflation_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving inflation articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

infla_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(infla_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(infla_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(infla_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(infla_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(infla_articles), min(10, nrow(infla_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(infla_articles$TITLE[sample_idx[i]], 1, 80))
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

write_path <- "C:/Users/lsikic/Desktop/inflacija_articles.rds"
saveRDS(infla_articles, write_path)
message("Saved to: ", write_path)

