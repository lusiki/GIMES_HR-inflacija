# Rječnik podataka - GIMES Projekt

## Pregled

Ovaj dokument sadrži detaljne definicije svih varijabli korištenih u GIMES projektu analize medijske pokrivenosti inflacije u Hrvatskoj.

---

## Glavni dataset: `inflacija_filtered.xlsx` 

### Osnovne identifikacijske varijable

#### `DATE`
- **Tip**: Date (YYYY-MM-DD)
- **Opis**: Datum objave članka
- **Format**: ISO 8601 standard (npr. 2023-05-15)
- **Raspon**: 2021-01-01 do 2024-11-30
- **Obvezno**: Da
- **Nedostajuće vrijednosti**: Nisu dozvoljene
- **Primjer**: `2023-03-15`

#### `TITLE`
- **Tip**: Text (String)
- **Opis**: Naslov ili zaglavlje članka
- **Duljina**: 10-500 znakova
- **Obvezno**: Da
- **Nedostajuće vrijednosti**: Rijetke (< 0.1%)
- **Napomena**: Koristi se u Title Relevance filtru
- **Primjer**: `"Inflacija u Hrvatskoj dosegla 12,7 posto u studenom"`

#### `FULL_TEXT`
- **Tip**: Text (String)
- **Opis**: Kompletan tekst tijela članka
- **Duljina**: 500-50,000 znakova (nakon filtriranja)
- **Obvezno**: Da
- **Nedostajuće vrijednosti**: Nisu dozvoljene nakon filtriranja
- **Kodiranje**: UTF-8
- **Napomena**: Ključno polje za text mining i sentiment analizu
- **Sadržaj**: Isključuje HTML tagove, retke za dijeljenje, reklame
- **Primjer**: `"Državni zavod za statistiku objavio je danas da je godišnja stopa inflacije..."`

#### `FROM`
- **Tip**: Text (Categorical)
- **Opis**: Ime izvora ili portala koji je objavio članak
- **Format**: Domena bez protokola (npr. index.hr, ne https://www.index.hr)
- **Jedinstvene vrijednosti**: ~80-100 portala
- **Obvezno**: Da
- **Nedostajuće vrijednosti**: Nisu dozvoljene
- **Kategorije**: Mapirano u `source_category`
- **Primjeri**: 
  - `index.hr`
  - `poslovni.hr`
  - `jutarnji.hr`
  - `vecernji.hr`

---

### Klasifikacijske varijable

#### `SOURCE_TYPE`
- **Tip**: Text (Categorical)
- **Opis**: Tip medijskog izvora
- **Moguće vrijednosti**: 
  - `web` - Online portali (primarna kategorija)
  - `print` - Tiskovni mediji (rijetko)
  - `tv` - Televizija (rijetko)
  - `radio` - Radio (rijetko)
- **Obvezno**: Da
- **Filter**: Samo `web` vrijednosti zadržane u finalnom datasetu
- **Distribucija**: >99% web nakon filtriranja

#### `source_category`
- **Tip**: Text (Categorical)
- **Opis**: Kategorija medijskog izvora (kreirana tijekom filtriranja)
- **Moguće vrijednosti**:
  - `national` - Nacionalni mediji (index.hr, 24sata.hr, jutarnji.hr, itd.)
  - `business` - Poslovni i ekonomski mediji (poslovni.hr, seebiz.eu, lider.media)
  - `regional` - Regionalni mediji (slobodnadalmacija.hr, glasistre.hr, novilist.hr)
  - `specialized` - Specijalizirani portali (agroklub.com, mirovina.hr)
  - `opinion` - Opinion portali (otvoreno.hr, narod.hr, politikaplus.com)
- **Obvezno**: Da (nakon filtriranja)
- **Kreirana iz**: Mapping `FROM` varijable
- **Distribucija tipična**:
  - national: ~45%
  - business: ~25%
  - regional: ~20%
  - specialized: ~5%
  - opinion: ~5%

---

### Metričke varijable

#### `text_length`
- **Tip**: Numeric (Integer)
- **Opis**: Duljina teksta članka u znakovima
- **Jedinica**: Broj znakova
- **Raspon**: 500-50,000 (nakon filtriranja)
- **Obvezno**: Da
- **Izračun**: `nchar(FULL_TEXT)`
- **Filter prag**: >= 500 znakova
- **Koristi se u**: GIMES indeksu (Intensity komponenta)
- **Statistike tipične**:
  - Medijan: ~1,800 znakova
  - Srednja vrijednost: ~2,200 znakova
  - Std. devijacija: ~1,500 znakova

#### `AUTO_SENTIMENT`
- **Tip**: Numeric (Integer)
- **Opis**: Automatski generirani sentiment članka
- **Moguće vrijednosti**:
  - `-1` = Negativan sentiment
  - `0` = Neutralan sentiment
  - `1` = Pozitivan sentiment
- **Obvezno**: Ne
- **Nedostajuće vrijednosti**: Moguće (5-10% članaka)
- **Metoda**: Automatska NLP sentiment analiza (specifičan algoritam ovisi o izvoru podataka)
- **Ograničenja**: 
  - Može imati ograničenu točnost za hrvatski jezik
  - Ne detektira ironiju ili sarkazam
  - Ternarna klasifikacija (bez nijansi)
- **Koristi se u**: GIMES indeksu (Sentiment komponenta)
- **Distribucija tipična**:
  - Negativan: ~75%
  - Neutralan: ~20%
  - Pozitivan: ~5%
- **Validacija**: Manualnom provjerom uzoraka za točnost

#### `REACH`
- **Tip**: Numeric (Integer)
- **Opis**: Procijenjeni doseg ili broj pregleda članka
- **Jedinica**: Broj pregleda/čitatelja
- **Raspon**: 0-1,000,000+
- **Obvezno**: Ne
- **Nedostajuće vrijednosti**: Česte (20-40% članaka)
- **Izvor**: Metapodaci portala ili analytics platforma
- **Napomena**: Kvaliteta i dostupnost varira po izvoru
- **Koristi se u**: GIMES indeksu (Reach komponenta)
- **Tretman nedostajućih**: Zamjena srednjom vrijednosti (50) u normalizaciji

#### `INTERACTIONS`
- **Tip**: Numeric (Integer)
- **Opis**: Broj korisničkih interakcija (komentari, lajkovi, dijeljenja)
- **Jedinica**: Broj interakcija
- **Raspon**: 0-10,000+
- **Obvezno**: Ne
- **Nedostajuće vrijednosti**: Česte (30-50% članaka)
- **Komponente mogu uključivati**:
  - Broj komentara
  - Facebook reakcije
  - Twitter/X dijeljenja
  - Interni lajkovi portala
- **Napomena**: Definicija može varirati po izvoru

---

### Vremenske varijable (generirane)

Ove varijable se generiraju iz `DATE` polja tijekom pripreme podataka:

#### `date`
- **Tip**: Date
- **Opis**: Kopija `DATE` polja u standardnom formatu
- **Format**: Date objekt u R

#### `year`
- **Tip**: Numeric (Integer)
- **Opis**: Godina objave
- **Raspon**: 2021-2024
- **Izračun**: `year(DATE)`
- **Primjer**: `2023`

#### `month`
- **Tip**: Numeric (Integer)
- **Opis**: Mjesec objave (1-12)
- **Raspon**: 1 (Siječanj) do 12 (Prosinac)
- **Izračun**: `month(DATE)`
- **Primjer**: `5` (Svibanj)

#### `week`
- **Typ**: Numeric (Integer)
- **Opis**: ISO tjedan u godini
- **Raspon**: 1-53
- **Izračun**: `isoweek(DATE)`
- **Standard**: ISO 8601 (tjedan počinje ponedjeljkom)

#### `yearmonth`
- **Tip**: Date
- **Opis**: Prvi dan mjeseca za agregaciju
- **Format**: YYYY-MM-01
- **Izračun**: `floor_date(DATE, "month")`
- **Koristi se u**: Mjesečnim agregacijama i GIMES indeksu
- **Primjer**: `2023-05-01` za sve članke iz svibnja 2023.

#### `yearweek`
- **Tip**: Date
- **Opis**: Prvi dan tjedna za agregaciju
- **Format**: YYYY-MM-DD (ponedjeljak)
- **Izračun**: `floor_date(DATE, "week")`
- **Koristi se u**: Tjednim agregacijama
- **Primjer**: `2023-05-01` (ponedjeljak)

#### `weekday`
- **Tip**: Factor
- **Opis**: Dan u tjednu
- **Razine**: Ponedjeljak, Utorak, Srijeda, Četvrtak, Petak, Subota, Nedjelja
- **Izračun**: `wday(DATE, week_start = 1)`
- **Koristi se u**: Analizi distribucije po danima

---

### Filtri i indikatorske varijable (privremene)

Ove varijable koriste se tijekom filtriranja ali mogu biti uklonjene u finalnom datasetu:

#### `title_relevant`
- **Tip**: Logical (Boolean)
- **Opis**: Indikator prolazi li naslov Filter 4
- **Vrijednosti**: TRUE/FALSE
- **Koristi se**: Tijekom filtriranja
- **Finalni dataset**: Sve vrijednosti TRUE (inače uklonjeno)

#### `has_core`
- **Tip**: Logical (Boolean)
- **Opis**: Indikator prolazi li tekst Filter 5 (core pojmovi)
- **Vrijednosti**: TRUE/FALSE
- **Koristi se**: Tijekom filtriranja
- **Finalni dataset**: Sve vrijednosti TRUE (inače uklonjeno)

#### `croatian_context`
- **Tip**: Logical (Boolean)
- **Opis**: Indikator prolazi li Filter 6 (hrvatski kontekst)
- **Vrijednosti**: TRUE/FALSE
- **Koristi se**: Tijekom filtriranja
- **Finalni dataset**: Sve vrijednosti TRUE (inače uklonjeno)

#### `matched_terms`
- **Tip**: Text (String)
- **Opis**: Lista inflacijskih pojmova pronađenih u tekstu
- **Format**: Pojmovi odvojeni znakom "; "
- **Obvezno**: Ne
- **Primjer**: `"inflacija; poskupljenje; cijene hrane"`
- **Koristi se u**: Analizi frekvencije pojmova

---

## Agregacijski dataseti

### `index_data` - Mjesečni GIMES indeks

Mjesečno agregirani podaci korišteni za konstrukciju GIMES indeksa:

| Varijabla | Tip | Opis |
|-----------|-----|------|
| `yearmonth` | Date | Mjesec (prvi dan) |
| `volume` | Integer | Broj članaka u mjesecu |
| `avg_length` | Numeric | Prosječna duljina članaka (znakovi) |
| `avg_sentiment` | Numeric | Prosječni sentiment (-1 do 1) |
| `avg_reach` | Numeric | Prosječni doseg |
| `total_reach` | Numeric | Ukupni doseg svih članaka |
| `avg_interactions` | Numeric | Prosječne interakcije |
| `volume_norm` | Numeric | Normalizirani volumen (0-100) |
| `length_norm` | Numeric | Normalizirani intenzitet (0-100) |
| `sentiment_norm` | Numeric | Normalizirani sentiment (0-100) |
| `reach_norm` | Numeric | Normalizirani doseg (0-100) |
| `gimes_index` | Numeric | GIMES indeks (0-100) |
| `gimes_index_ma3` | Numeric | 3-mjesečni klizni prosjek GIMES-a |
| `gimes_yoy` | Numeric | Godišnja promjena GIMES-a (%) |

---

## Eksterni podaci

### Eurostat HICP podaci

Službeni podaci o inflaciji za Hrvatsku:

| Varijabla | Tip | Opis |
|-----------|-----|------|
| `date` | Date | Mjesec (prvi dan) |
| `hicp_yoy` | Numeric | Headline HICP inflacija, YoY % |
| `core_yoy` | Numeric | Core HICP inflacija (bez energije i hrane), YoY % |

**Izvor**: Eurostat dataset `prc_hicp_manr`  
**Geografija**: Hrvatska (HR)  
**Jedinica**: Postotna promjena, godine na godinu  
**Frekvencija**: Mjesečna  
**Raspon**: Siječanj 2021 - Studeni 2024

---

## Napomene o kvaliteti podataka

### Nedostajuće vrijednosti

| Varijabla | Očekivana stopa nedostajućih | Tretman |
|-----------|-------------------------------|---------|
| DATE | 0% | Obvezan filter |
| TITLE | <0.1% | Obvezan filter |
| FULL_TEXT | 0% (nakon filtriranja) | Obvezan filter |
| FROM | 0% | Obvezan filter |
| AUTO_SENTIMENT | 5-10% | Isključi iz sentiment agregacija |
| REACH | 20-40% | Zamjena srednjom u GIMES indeksu |
| INTERACTIONS | 30-50% | Opciono korištenje |

### Outlieri

- **text_length**: Članci >10,000 znakova pregledani za kvalitetu
- **REACH**: Vrijednosti >1M provjerene za točnost
- **INTERACTIONS**: Ekstremne vrijednosti mogu biti viralni članci (zadržani)

### Duplikati

- **Kriterij**: Isti TITLE + FROM + DATE (± 1 dan)
- **Tretman**: Zadržan prvi, ostali uklonjeni
- **Očekivana stopa**: <1%

### Enkodiranje

- **Sve tekstualne varijable**: UTF-8
- **Specijalni znakovi**: Hrvatski dijakritici (č, ć, đ, š, ž) očuvani
- **HTML entiteti**: Dešifrirani u FULL_TEXT

---

## Primjer retka podataka

```r
DATE:            2023-05-15
TITLE:           "Inflacija u Hrvatskoj usporila na 8,4 posto"
FULL_TEXT:       "Državni zavod za statistiku objavio je danas da je godišnja stopa inflacije..."
FROM:            "poslovni.hr"
SOURCE_TYPE:     "web"
source_category: "business"
text_length:     1847
AUTO_SENTIMENT:  -1
REACH:           12540
INTERACTIONS:    87
year:            2023
month:           5
yearmonth:       2023-05-01
```

---

## Verzija dokumenta

**Verzija**: 1.0  
**Datum**: Prosinac 2024  
**Autor**: GIMES tim  
**Zadnje ažurirano**: 2024-12-23

Za pitanja ili izmjene kontaktirajte održavatelja projekta.