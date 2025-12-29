# ==============================================================================
# SOCIAL TRUST & OPTIMISM ARTICLE SEARCH - REGEX VERSION
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
# SOCIAL TRUST REGEX PATTERN
# ------------------------------------------------------------------------------

trust_regex <- paste0(
  "(",
  
  # --- CONFIDENCE/TRUST INDICES ---
  "indeks (povjerenja|optimizma|pesimizma|raspolo[zž]enja)|",
  "indeks potro[sš]a[cč]kog (povjerenja|optimizma|raspolo[zž]enja)|",
  "barometar (povjerenja|optimizma|raspolo[zž]enja)|",
  
  # --- EUROBAROMETER & MAJOR SURVEYS ---
  "eurobarometar|",
  "europsko dru[sš]tveno istra[zž]ivanj|",
  "europsko istra[zž]ivanje vrijednosti|",
  "gallup|",
  "ipsos.+(povjerenje|optimizam|zadovoljstvo|gra[dđ]an)|",
  "promocija plus.+(povjerenje|optimizam|zadovoljstvo|gra[dđ]an)|",
  
  # --- INSTITUTIONAL TRUST ---
  "povjerenje u (institucije|vladu|sabor|predsjednika|sudstvo|pravosu[dđ]e|policiju|vojsku|medije|crkvu|eu)|",
  "(ne)?povjerenje (gra[dđ]ana|javnosti|stanovni[sš]tva) u|",
  "(rast|pad|gubitak|kriza) povjerenja|",
  
  # --- LIFE SATISFACTION (survey term) ---
  "zadovoljstvo [zž]ivotom|",
  "zadovoljstvo (standardom|kvalitetom [zž]ivota)|",
  "kvalitet[aeu]+ [zž]ivota.+(istra[zž]ivanj|anket|indeks|posto)|",
  "[zž]ivotn[aeiou]+ (uvjet[aei]?|standard).+(istra[zž]ivanj|anket|indeks|posto)|",
  
  # --- SOCIAL MOOD/SENTIMENT (collective) ---
  "dru[sš]tven[aeiou]+ raspolo[zž]enj|",
  "raspolo[zž]enje (gra[dđ]ana|javnosti|stanovni[sš]tva|u dru[sš]tvu)|",
  "op[cć][aeiou]+ raspolo[zž]enj|",
  "atmosfera u dru[sš]tvu|",
  
  # --- COLLECTIVE OPTIMISM/PESSIMISM ---
  "(optimizam|pesimizam) (gra[dđ]ana|javnosti|stanovni[sš]tva|hrvata|u hrvatskoj)|",
  "(gra[dđ]ani|hrvati|stanovni[sš]tvo|javnost).+(optimisti[cč]n|pesimisti[cč]n)|",
  "(ve[cć]ina|manjina|polovica|tre[cć]ina).+(optimisti[cč]n|pesimisti[cč]n|zadovolj|nezadovolj)|",
  
  # --- COLLECTIVE SATISFACTION/DISSATISFACTION ---
  "(ne)?zadovoljstvo (gra[dđ]ana|javnosti|stanovni[sš]tva)|",
  "(gra[dđ]ani|hrvati|stanovni[sš]tvo).+(zadovolj|nezadovolj)|",
  
  # --- FEAR/WORRY (collective, with survey context) ---
  "(strah|zabrinutost|tjeskoba) (gra[dđ]ana|javnosti|stanovni[sš]tva)|",
  "(gra[dđ]ani|hrvati|stanovni[sš]tvo).+(strahuju|zabrinuti|boje se)|",
  "(ve[cć]ina|manjina|posto).+(strahuje|zabrinut|boji se)|",
  
  # --- SOCIAL COHESION ---
  "dru[sš]tven[aeiou]+ kohezij|",
  "socijalna kohezij|",
  "dru[sš]tven[aeiou]+ solidarnost|",
  "dru[sš]tven[aeiou]+ povjerenj|",
  "me[dđ]uljudsk[aeiou]+ povjerenj|",
  
  # --- FUTURE OUTLOOK (collective) ---
  "(o[cč]ekivanja|izgledi|perspektiv[aeu]) (gra[dđ]ana|za hrvatsku|za budu[cć]nost)|",
  "(gra[dđ]ani|hrvati|stanovni[sš]tvo).+(o[cč]ekuju|vjeruju|smatraju).+(budu[cć]nost|bolje|lo[sš]ije)|",
  "budu[cć]nost hrvatske.+(optimiz|pesimiz|istra[zž]ivanj)|",
  
  # --- SURVEY RESULTS ON SENTIMENT ---
  "(anket[aeu]?|istra[zž]ivanj[aeu]?) (pokazuje|pokazalo|otkriva|otkriva).+(zadovolj|optimiz|pesimiz|povjerenj|strah)|",
  "prema (anketi|istra[zž]ivanju).+(zadovolj|optimiz|pesimiz|povjerenj)|",
  "rezultati (ankete|istra[zž]ivanja).+(zadovolj|optimiz|pesimiz|povjerenj)|",
  
  # --- PERCENTAGE + SENTIMENT ---
  "[0-9]+.?posto.+(zadovolj|nezadovolj|optimist|pesimist|vjeruje|ne vjeruje|smatra)|",
  "(ve[cć]ina|manjina|polovica).+(gra[dđ]ana|ispitanika|hrvata).+(zadovolj|optimist|pesimist|vjeruje)|",
  
  # --- WELLBEING INDICES ---
  "indeks (dobrobiti|blagostanja|sre[cć]e)|",
  "indeks ljudskog razvoja|",
  "hdi.+hrvat|",
  
  # --- PERCEPTION OF PROGRESS ---
  "(hrvatska|zemlja|dr[zž]ava).+(napreduje|nazaduje|stagnira).+(istra[zž]ivanj|anket|smatraju gra[dđ]ani)|",
  "(napredak|nazadovanje|stagnacija) (dru[sš]tva|hrvatske)|",
  
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
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(trust_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving social trust articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

trust_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(trust_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(trust_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(trust_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(trust_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(trust_articles), min(10, nrow(trust_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(trust_articles$TITLE[sample_idx[i]], 1, 80))
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

write_path <- "C:/Users/lsikic/Desktop/trust_articles.rds"
saveRDS(trust_articles, write_path)
message("Saved to: ", write_path)