# ==============================================================================
# LABOR MARKET ARTICLE SEARCH - REGEX VERSION
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
# LABOR MARKET REGEX PATTERN
# ------------------------------------------------------------------------------

labor_regex <- paste0(
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
  "hzz|",
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
  "sindikaln[aeiou]+ (pregovor|zahtjev|akcij|pritisa|najav|prijetn|[sš]trajk)|",
  "sindikat[aei]? (tra[zž]|zahtijeva|najavljuj|prijeti|organizira)|",
  "sssh|",
  "matica hrvatskih sindikat|",
  
  # --- LABOR LAW ---
  "zakon o radu|",
  "radn[aeiou]+ prav[aou]?|",
  "radn[io]+ odnos[aei]?|",
  "inspekcij[aeiou]+ rada|",
  "inspektorat rada|",
  
  # --- JOB CREATION/DESTRUCTION (economic framing) ---
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
  
  # --- EMPLOYMENT TYPES (policy context) ---
  "prekarn[aeiou]+ rad|",
  "nesigurn[aeiou]+ poslov|",
  "rad na crno|",
  "agencijsk[aeiou]+ rad|",
  "sezonsk[aeiou]+ zapo[sš]ljavanj|",
  
  # --- PENSION SYSTEM ---
  "hzmo|",
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
  "broj nezaposlenih|",
  
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
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(labor_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving labor market articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

labor_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(labor_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(labor_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(labor_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(labor_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(labor_articles), min(10, nrow(labor_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(labor_articles$TITLE[sample_idx[i]], 1, 80))
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

write_path <- "C:/Users/lsikic/Desktop/labor_articles.rds"
saveRDS(labor_articles, write_path)
message("Saved to: ", write_path)