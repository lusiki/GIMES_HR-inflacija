# ==============================================================================
# SECURITY & STABILITY ARTICLE SEARCH - REGEX VERSION
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
# SECURITY REGEX PATTERN
# ------------------------------------------------------------------------------

security_regex <- paste0(
  "(",
  
  # === VIOLENT CRIME WITH INSTITUTIONAL FRAMING ===
  
  # --- Murder/homicide ---
  "ubojstv[aou]?.+(policij|istra[zž]|uhićen|osumnji[cč]en|optužen|pritvoren)|",
  "(policij|dorh|dr[zž]avno odvjetni[sš]tvo).+ubojstv|",
  "osumnji[cč]en[aei]? za ubojstvo|",
  "ubijena?.+prona[dđ]en|",
  
  # --- Physical attacks (not sports/metaphorical) ---
  "(fizi[cč]ki|no[zž]em|oru[zž]jem|pal[ci]om) napad|",
  "napad[aeu]?.+(policij|hitna|ozlije[dđ]en|uhićen|prijavljen)|",
  "napada[cč].+(uhićen|priveden|identificiran)|",
  "brutalan napad|",
  
  # --- Sexual violence ---
  "silovanj[aeu]?|",
  "seksualn[aeiou]+ (napad|nasilj|zlostavljanj)|",
  "spolno zlostavljanj|",
  
  # --- Robbery with institutional frame ---
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
  
  # === PROSECUTION/ARRESTS (strong institutional markers) ===
  "dorh|",
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
  "pnuskok|",
  "eppo|",
  
  # === TRAFFIC ACCIDENTS ===
  "prometn[aeiou]+ nesre[cć][aeiou]?|",
  "(poginuo|poginula|smrtno stradao) u prometu|",
  "(sudar|slijetanje).+(ozlije[dđ]en|poginuo|policij)|",
  "te[sš]k[aeu]+ prometn[aeu]+ nesre[cć]|",
  "alkohol za volanom|",
  "pijan za volanom|",
  
  # === FIRES (real, not metaphorical) ===
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
  "hgss|",
  "hrvatska gorska slu[zž]ba spa[sš]avanj|",
  "sto[zž]er civilne za[sš]tite|",
  "civiln[aeu]+ za[sš]tit[aeu]?.+(aktivira|progla[sš]|koordin)|",
  "evakuacij[aeiou]+ (stanovni|zgrada|naselja|stanovni[sš]tva)|",
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
  
  # === CYBER CRIME (institutional frame) ===
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
  "narančasti meteoalarm|",
  
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
  AND REGEXP_MATCHES(LOWER(FULL_TEXT), '", tolower(security_regex), "')
")

# ------------------------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------------------------

message("Retrieving security articles using regex pattern...")
message("This searches ~25M rows for matching articles...")
start_time <- Sys.time()

security_articles <- dbGetQuery(con, query)

elapsed <- round(difftime(Sys.time(), start_time, units = "mins"), 2)
message("Done in ", elapsed, " minutes")
message("Articles retrieved: ", format(nrow(security_articles), big.mark = ","))

# ------------------------------------------------------------------------------
# QUICK STATS
# ------------------------------------------------------------------------------

if(nrow(security_articles) > 0) {
  message("\n=== QUICK STATS ===")
  message("By SOURCE_TYPE:")
  print(table(security_articles$SOURCE_TYPE))
  
  message("\nTop 10 Sources:")
  print(head(sort(table(security_articles$FROM), decreasing = TRUE), 10))
  
  message("\nSample Titles:")
  set.seed(123)
  sample_idx <- sample(nrow(security_articles), min(10, nrow(security_articles)))
  for(i in seq_along(sample_idx)) {
    message("  ", i, ". ", substr(security_articles$TITLE[sample_idx[i]], 1, 80))
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

write_path <- "C:/Users/lsikic/Desktop/security_articles.rds"
saveRDS(security_articles, write_path)
message("Saved to: ", write_path)