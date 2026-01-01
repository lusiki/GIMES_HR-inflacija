# GIMES: Semantički indeksi hrvatskog gospodarstva i društva

[![Quarto](https://img.shields.io/badge/Quarto-1.4+-blue)](https://quarto.org)
[![R](https://img.shields.io/badge/R-4.3+-276DC3)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**GIMES** (Gospodarski Indeksi iz Medijskog Sadržaja) je istraživački projekt koji konstruira semantičke indekse ekonomske, društvene i političke aktivnosti analizom hrvatskog medijskog diskursa. Projekt koristi NLP tehnike za ekstrakciju ekonomskih signala iz novinskih članaka.

---

## 📊 Izvještaji

| Izvještaj | Opis | Ključni indeksi |
|-----------|------|-----------------|
| [report_aktivnost.qmd](code/03_analysis/report_aktivnost.qmd) | Agregatna gospodarska aktivnost | VAI, TWI, SCI, SAI, PCI |
| [report_inflacija.qmd](code/03_analysis/report_inflacija.qmd) | Inflacija i cjenovne dinamike | Inflacijski sentiment, očekivanja |
| [report_rad.qmd](code/03_analysis/report_rad.qmd) | Tržište rada | Zaposlenost, plaće, nezaposlenost |
| [report_geo.qmd](code/03_analysis/report_geo.qmd) | Geografska distribucija | Regionalna pokrivenost, prostorni fokus |
| [report_institucije.qmd](code/03_analysis/report_institucije.qmd) | Institucionalni akteri | HNB, DZS, Vlada, HGK |

---

## 🏗️ Struktura projekta

```
GIMES/
├── code/
│   ├── 01_data_preparation/
│   ├── 02_preprocessing/
│   └── 03_analysis/
│       ├── report_aktivnost.qmd
│       ├── report_inflacija.qmd
│       ├── report_rad.qmd
│       ├── report_geo.qmd
│       └── report_institucije.qmd
├── data/
│   ├── activity_filtered.xlsx
│   ├── inflation_filtered.xlsx
│   └── ...
├── output/
│   └── semantic_*.xlsx
└── README.md
```

---

## 🚀 Brzi početak

### Preduvjeti

- R ≥ 4.3
- Quarto ≥ 1.4
- Potrebni R paketi:

```r
install.packages(c(
  "data.table", "ggplot2", "lubridate", "stringi", 
  "knitr", "kableExtra", "zoo", "openxlsx", "here",
  "corrplot", "patchwork", "viridis"
))
```

### Renderiranje izvještaja

```bash
# Pojedinačni izvještaj
quarto render code/03_analysis/report_aktivnost.qmd

# Svi izvještaji
quarto render code/03_analysis/
```

---

## 📈 Metodologija

### Semantička taksonomija

Svaki izvještaj koristi hijerarhijsku taksonomiju pojmova s dvije razine:
- **Makro kategorije**: BDP, industrija, trgovina, turizam, investicije...
- **Meso kategorije**: specifični pojmovi unutar svake makro kategorije

### Indeksi

| Indeks | Puni naziv | Opis |
|--------|-----------|------|
| **VAI** | Volume Activity Index | Ukupan broj ekonomskih pojmova / broj članaka |
| **TWI** | TF-IDF Weighted Index | TF-IDF ponderirani score |
| **SCI** | Sectoral Composite Index | Kompozit realnih sektora |
| **SAI** | Sentiment Adjusted Index | Volume × sentiment ratio |
| **UCI** | Uncertainty Index | Mjera ekonomske neizvjesnosti |
| **FLI** | Forward Looking Index | Orijentacija na budućnost |
| **PCI** | Principal Component Index | PC1 svih makro kategorija |

### Sentiment i neizvjesnost

- **Sentiment leksikon**: pozitivni/negativni ekonomski izrazi
- **Uncertainty leksikon**: pojmovi neizvjesnosti i rizika
- **Forward-looking leksikon**: prognoze, očekivanja, planovi

---

## 📁 Podaci

### Ulazni podaci (`data/`)

| Datoteka | Opis |
|----------|------|
| `activity_filtered.xlsx` | Članci o gospodarskoj aktivnosti |
| `inflation_filtered.xlsx` | Članci o inflaciji |
| `labor_filtered.xlsx` | Članci o tržištu rada |

### Izlazni podaci (`output/`)

Svaki izvještaj generira Excel datoteku s više listova:
- **Indeksi**: mjesečne vrijednosti svih indeksa
- **Sektori**: disagregirani sektorski podaci
- **Sentiment**: sentiment komponente
- **Volatilnost**: momentum i volatilnost indeksa

---

## 🔧 Konfiguracija

Izvještaji koriste zajedničku paletu boja i temu:

```r
pal <- list(
  dark = "#1a1a2e",
  primary = "#16213e",
  accent = "#0f3460",
  highlight = "#e94560",
  ...
)
theme_set(theme_minimal(base_size = 12))
```

---

## 📝 Citiranje

```bibtex
@misc{gimes2025,
  author = {GIMES Research},
  title = {Semantički indeksi hrvatskog gospodarstva},
  year = {2025},
  url = {https://github.com/...}
}
```

---

## 📄 Licenca

MIT License — vidi [LICENSE](LICENSE)

---

*GIMES Research | Semantički indeksi gospodarstva v2.0*