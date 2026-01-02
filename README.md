



![](ai.jpg)



# GIMES istraživački projekt 

## Sažetak

**GIMES** (Gospodarski (i Društveni) Indeksi iz Medijskog Ekosustava) je sveobuhvatna istraživačka infrastruktura koja konstruira visokofrekventne socioekonomske indikatore za Hrvatsku primjenom semantičke analize na online medijske sadržaje. Projekt transformira nestrukturirani tekst iz približno 25 milijuna medijskih članaka u strukturirane kvantitativne indekse koji prate ekonomske uvjete, političke dinamike, kvalitetu institucija i društveno raspoloženje.

Sustav proizvodi osam tematskih obitelji indeksa koje pokrivaju inflaciju, gospodarsku aktivnost, tržište rada, geopolitički rizik, institucionalno okruženje, političku polarizaciju, društveno povjerenje i sigurnost. Ovi indeksi služe kao alternativne ili komplementarne mjere službenim statistikama, potencijalno nudeći ranije signale i širu pokrivenost društvenih fenomena.

---

## Podatkovna infrastruktura

### Izvorna baza podataka

| Komponenta | Specifikacija |
|-----------|---------------|
| Sustav baze podataka | DuckDB |
| Veličina baze | ~25 milijuna članaka |
| Vremensko pokrivanje | 01.01.2021. do 31.05.2024. |
| Alokacija memorije | 48GB |
| Tipovi izvora | Web, društvene mreže, tisak |

### Taksonomija medijskih izvora

Projekt prati 80+ verificiranih hrvatskih news portala organiziranih u pet kategorija:

**Nacionalni mediji** (16 izvora)
- Glavne platforme: index.hr, jutarnji.hr, vecernji.hr, 24sata.hr, tportal.hr
- Televizijski: rtl.hr, hrt.hr, dnevnik.hr, n1info.hr
- Agencije: hina.hr
- Digitalno native: telegram.hr, nacional.hr, direktno.hr, net.hr, novosti.hr

**Poslovni mediji** (12 izvora)
- Primarni: poslovni.hr, seebiz.eu, lidermedia.hr, lider.media
- Specijalizirani: bloombergadria.com, hrportfolio.hr, energypress.net
- Sektorski specifični: energetika-net.com, jatrgovac.com, gospodarski.hr, privredni.hr, ictbusiness.info

**Regionalni mediji** (50+ izvora)
- Dalmacija: slobodnadalmacija.hr, dalmatinskiportal.hr, antenazadar.hr, dulist.hr
- Istra/Kvarner: glasistre.hr, novilist.hr, istra24.hr, rijekadanas.com
- Slavonija: glas-slavonije.hr, icv.hr, brodportal.hr, epodravina.hr
- Sjeverna Hrvatska: varazdinske-vijesti.hr, medjimurjepress.net, zagorje.com
- Središnja Hrvatska: zagreb.info, karlovacki.hr, likaclub.eu

**Specijalizirani mediji**
- Poljoprivreda: agroklub.com
- Pravo: legalis.hr, pravosudje.hr
- Državna uprava: gov.hr, fino.hr
- Graditeljstvo: gradnja.org, graditeljstvo.hr

**Opinion portali**
- Analitički orijentirani: 7dnevno.hr, dnevno.hr, otvoreno.hr
- Komentatorski: politikaplus.com, geopolitika.news, liberoportal.hr

---

## Podatkovni proces 

Projekt koristi trostupanjski cjevovod:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         STUPANJ 1: DOHVAT IZ BAZE                           │
│                                                                             │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐ │
│  │   DuckDB    │───▶│  Tematski       │───▶│  Sirovi korpus članaka      │ │
│  │  (25M reda) │    │  regex uzorci   │    │  (RDS datoteke, 100K-500K)  │ │
│  └─────────────┘    └─────────────────┘    └─────────────────────────────┘ │
│                                                                             │
│  Skripte: database_fetch_{tema}.R                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      STUPANJ 2: VIŠESTRUKO FILTRIRANJE                      │
│                                                                             │
│  Filter 1: SOURCE_TYPE == "web"                                             │
│  Filter 2: FROM ∈ {verificirani news portali}                               │
│  Filter 3: text_length >= 500 znakova                                       │
│  Filter 4: TITLE sadrži ključne riječi teme                                 │
│  Filter 5: FULL_TEXT sadrži core pojmove teme                               │
│  Filter 6: NOT (sport/zabava) OR ima override pojmove                       │
│  Filter 7: Verifikacija hrvatskog konteksta                                 │
│                                                                             │
│  Skripte: 2nd_filter_{tema}.R                                               │
│  Output: {tema}_filtered.xlsx (5K-50K članaka po temi)                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   STUPANJ 3: SEMANTIČKA ANALIZA I INDEKSIRANJE              │
│                                                                             │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────────┐   │
│  │ Semantička      │   │ Konstrukcija    │   │ Analiza                 │   │
│  │ taksonomija     │──▶│ indeksa         │──▶│ vremenskih serija       │   │
│  │ (regex korjeni) │   │ (normalizacija) │   │ (MA, volatilnost, itd.) │   │
│  └─────────────────┘   └─────────────────┘   └─────────────────────────┘   │
│                                                                             │
│  Skripte: report_{tema}.qmd (Quarto)                                        │
│  Output: HTML izvještaj + Excel indeksi                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Tematske domene

### 1. Inflacija [izvještaj](https://raw.githack.com/lusiki/GIMES_HR-inflacija/main/code/03_analysis/report_inflacija.html)

**Fokus**: Dinamika potrošačkih cijena, kupovna moć, troškovi života

**Ključni regex uzorci**:
- Direktni pojmovi: inflacij*, dezinflacij*, hiperinflacij*, stagflacij*
- Cjenovni indeksi: HICP, indeks potrošačkih cijena
- Kretanje cijena: poskupljenj*, pojeftinjenj*, rast/pad cijena
- Troškovi života: troškovi života, životni standard, kupovna moć
- Specifične cijene: cijena goriva/hrane/struje/plina/benzina



---

### 2. Gospodarska aktivnost [izvještaj]()

**Fokus**: Performanse realnog sektora, BDP, industrijska proizvodnja, poslovno povjerenje

**Ključni regex uzorci**:
- BDP: BDP, bruto domaći proizvod
- Rast/pad: gospodarski rast/pad/oporavak, recesij*
- Industrija: industrijska proizvodnja, prerađivačka industrija
- Turizam: turistički promet, broj dolazaka/noćenja
- Trgovina: vanjska trgovina, izvoz/uvoz, trgovinska bilanca
- Statistički kontekst: DZS, Eurostat, kvartalni podaci, sezonski prilagođeno

---

### 3. Tržište rada [izvještaj]()

**Fokus**: Dinamika zaposlenosti, plaće, radni uvjeti, migracije radne snage

**Ključni regex uzorci**:
- Zaposlenost: zaposlenost, nezaposlenost, zapošljavanje
- Plaće: plaća, primanja, prosječna plaća, minimalna plaća
- Radna snaga: radna snaga, radnici, kadrovi
- Uvjeti: radni uvjeti, radno vrijeme, kolektivni ugovor
- Migracije: odljev radnika, iseljavanje, uvoz radne snage

---

### 4. Geopolitički rizik [izvještaj]()

**Fokus**: Međunarodna sigurnost, sukobi, savezi, diplomatski odnosi

**Ključni regex uzorci**:
- NATO/EU sigurnost: NATO članstvo, europska obrana, članak 5
- Rusija: ruska invazija/agresija, Kremlj, Putin, sankcije
- Ukrajinski sukob: ukrajinski rat/sukob, Kijev, Donbas, ofenziva
- Bliski istok: Gaza, Izrael, Hamas, Hezbollah, iranski nuklearni
- Balkan: Srbija/Kosovo napetost, BiH kriza, Dodik, destabilizacija
- Hibridne prijetnje: hibridni rat, cyber napad, dezinformacije

---

### 5. Institucionalno okruženje [izvještaj]()

**Fokus**: Percepcija korupcije, učinkovitost pravosuđa, kvaliteta upravljanja

**Ključni regex uzorci**:
- Korupcija: korupcij*, mito, podmićivanje, USKOK, afera
- Pravosuđe: sudstvo, pravosuđe, presuda, optužnica, DORH
- Upravljanje: transparentnost, odgovornost, učinkovitost
- Vladavina prava: vladavina prava, pravna država, zakonitost
- Javna uprava: javna uprava, birokracija, birokratski

---

### 6. Politička polarizacija [izvještaj]()

**Fokus**: Društvene podjele, stranački sukobi, govor mržnje, povijesne traume

**Ključni regex uzorci**:
- Ideološki: lijevo/desno, lijevi/desni, ideološk*
- Stranački sukob: sukob stranaka, međustranački, koalicij*
- Govor mržnje: govor mržnje, diskriminacija, netrpeljivost
- Povijesni: ustaš*, partizan*, Jasenovac, Bleiburg, NDH
- Društvena pitanja: pobačaj, LGBT, tradicija vs. liberalizam

---

### 7. Društveno povjerenje [izvještaj]()

**Fokus**: Institucionalno povjerenje, zadovoljstvo životom, društveno raspoloženje, perspektive budućnosti

**Ključni regex uzorci**:
- Indeksi povjerenja: indeks povjerenja, barometar povjerenja
- Istraživanja: Eurobarometar, Gallup, anketa povjerenja
- Institucionalno povjerenje: povjerenje u vladu/sabor/sudstvo/policiju/medije/crkvu
- Zadovoljstvo životom: zadovoljstvo životom, kvaliteta života
- Perspektive: optimizam/pesimizam građana, očekivanja za budućnost

---

### 8. Sigurnost [izvještaj](https://raw.githack.com/lusiki/GIMES_HR-inflacija/main/code/03_analysis/report%20sigurnost.html)

**Fokus**: Kriminal, nesreće, prirodne katastrofe, hitne službe

**Ključni regex uzorci**:
- Kriminal: kriminal*, ubojstvo, pljačka, provala, USKOK
- Promet: prometna nesreća, smrtno stradao, ozlijeđen
- Požari/katastrofe: požar, poplava, potres, katastrofa
- Hitne službe: policija, vatrogasci, HGSS, hitna pomoć
- Institucije: MUP, DORH, sigurnosne službe

---

## Analitička metodologija

### Konstrukcija semantičke taksonomije

Svaka tema koristi hijerarhijsku taksonomiju s:

1. **Makro kategorije** (široke tematske domene)
2. **Mezo kategorije** (specifične podteme)
3. **Regex uzorci** (morfološki fleksibilni hrvatski korjeni riječi)

**Morfološko rukovanje**:
```
Uzorak: inflacij[aeiou]?[mj]?[ao]?
Prepoznaje: inflacija, inflacije, inflaciji, inflaciju, inflacijom, inflacijska, inflacijsko
```

### Konstrukcija indeksa

**Standardni indeksi kroz sve teme**:

| Indeks | Naziv | Opis |
|-------|------|-------------|
| VAI/VXI | Volume Activity Index | Gustoća semantičkih pojmova po članku |
| SCI/SXI | Sectoral Composite Index | Ponderirani prosjek ključnih sektorskih kategorija |
| SAI | Sentiment Adjusted Index | Volumen moduliran pozitivnim/negativnim tonom |
| UCI/UXI | Uncertainty Index | Frekvencija pojmova vezanih uz neizvjesnost |
| FLI/FXI | Forward Looking Index | Frekvencija pojmova očekivanja/prognoza |
| PCI | Principal Component Index | Prva glavna komponenta svih sektorskih indeksa |

**Formula normalizacije**:
$$Index_t = \frac{X_t - X_{min}}{X_{max} - X_{min}} \times 100$$

**Izračun sentimenta**:
$$SR_i = \frac{P_i - N_i}{P_i + N_i}$$

gdje je $P_i$ = broj pozitivnih pojmova, $N_i$ = broj negativnih pojmova

### Analiza vremenskih serija

- **Klizni prosjeci**: 3-mjesečni centrirani MA za izglađivanje trenda
- **Volatilnost**: Rolling 3-mjesečna standardna devijacija
- **Momentum**: Mjesečne i tromjesečne promjene
- **Koncentracija**: Herfindahl-Hirschman indeks za disperziju tema

---

## Struktura izvještaja

Svaki tematski izvještaj slijedi standardiziranu strukturu:

```
1. Uvod
   1.1 Motivacija i kontekst
   1.2 Struktura izvještaja

2. Metodologija identifikacije članaka
   2.1 Pregled procesa filtriranja (7 koraka filtriranja)

3. Eksploratorni pregled podataka
   3.1 Osnovne statistike
   3.2 Distribucija po kategorijama izvora
   3.3 Top izvori
   3.4 Vremenska distribucija

4. Semantička taksonomija
   4.1 Hijerarhijska struktura pojmova
   4.2 Kategorije i podkategorije

5. Konstrukcija indeksa
   5.1 [Naziv indeksa] (KRATICA) - za svaki indeks
   5.2 Opis indeksa (sumarni tablični prikaz)

6. Vizualizacija indeksa
   6.1 Glavni indeksi
   6.2 Pojedinačne vizualizacije

7. Sektorska analiza
   7.1 Dinamika po sektorima
   7.2 Heatmapa aktivnosti
   7.3 Korelacijska struktura

8. Sentiment analiza

9. Volatilnost i momentum

10. Koncentracija tema

11. Korelacije između indeksa

12. Export

13. Sažetak
```

---

## Izlazni proizvodi

### Po temi

| Proizvod | Format | Sadržaj |
|---------|--------|---------|
| HTML izvještaj | .html (self-contained) | Potpuna analiza s interaktivnim vizualizacijama |
| Podaci indeksa | .xlsx | Mjesečni indeksi, kategorije, dinamike, korelacije |
| Filtrirani korpus | .xlsx/.rds | Čisti dataset članaka za daljnju analizu |

### Struktura Excel radne knjige

| Radni list | Sadržaj |
|-----------|---------|
| Indeksi | Svi izračunati indeksi s kliznim prosjecima |
| Semanticke_kategorije | Mjesečni brojevi za svaku semantičku kategoriju |
| Dinamike | Mjere volatilnosti i momentuma |
| Korelacije | Korelacijska matrica indeksa |

---

## Tehnički stack

### Obrada podataka
- **DuckDB**: Visokoučinkovita analitička baza podataka
- **data.table**: Brza manipulacija podataka u R-u
- **stringi**: Unicode-aware obrada stringova s regexom

### Vizualizacija
- **ggplot2**: Primarno crtanje
- **plotly**: Interaktivne vizualizacije
- **patchwork**: Kompozicija grafova
- **corrplot**: Korelacijske matrice

### Izvještavanje
- **Quarto**: Framework za literate programming
- **kableExtra**: Formatirane tablice
- **openxlsx**: Excel izlaz

### Vremenske serije
- **zoo**: Rolling funkcije
- **forecast**: Dekompozicija vremenskih serija

---

## Osiguranje kvalitete

### QC filtriranja članaka
- Nasumično uzorkovanje naslova (20 članaka nakon filtriranja)
- Ekstrakcija prepoznatih pojmova i analiza frekvencija
- Verifikacija distribucije izvora

### Validacija indeksa
- Korelacija sa službenim statistikama (Eurostat, DZS)
- Lead/lag analiza za prediktivnu valjanost
- Provjere koherentnosti među temama

---

## Istraživačke primjene

1. **Ekonomski nowcasting**: Rani indikatori prije službenih objava
2. **Praćenje politika**: Praćenje javnog diskursa o reformama
3. **Procjena rizika**: Geopolitički i institucionalni indeksi rizika
4. **Društvena istraživanja**: Praćenje povjerenja, polarizacije, sentimenta
5. **Medijske studije**: Analiza ponašanja izvora i koncentracije tema

---

## Metapodaci projekta

| Atribut | Vrijednost |
|-----------|-------|
| Organizacija | GIMES Research |
| Verzija | 2.0 |
| Jezik | Hrvatski (hr) |
| Primarni autor | L. Sikic |
| Framework za izvještaje | Quarto (.qmd) |
| Programski jezik | R |

---

*Dokument generiran: Siječanj 2026.*
*GIMES istraživački projekt - pregled v2.0*