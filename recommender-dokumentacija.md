# Sistem preporuka – HeartForCharity

Dvije nezavisne preporuke za prijavljenog korisnika:
- **Volonterski poslovi** (top 10)
- **Kampanje za donacije** (top 10)

API endpointi (zahtijevaju JWT):
- `GET /api/recommender/jobs` → vraca `{ job, score, reasons[] }`
- `GET /api/recommender/campaigns` → isto

## Preporuka poslova (content-based + cosine similarity)

**Signali:** vještine (težina 0.5), kategorije obavljenih poslova (0.3), lokacija (0.2)

**Bodovanje:**
- Vještine: kosinusna sličnost između vektora korisnikovih vještina i vektora potrebnih vještina posla
- Kategorija: kosinusna sličnost sa vektorom kategorije posla (binarno)
- Lokacija: +0.2 ako je isti grad, +0.1 ako je remote

**Filtri:** aktivan, ima slobodnih mjesta, korisnik se nije prijavio

**Razlozi (UI):** "Matches your skills: First Aid", "In your city (Sarajevo)", ...

## Preporuka kampanja

- Ako korisnik nema donacija → vraća 10 najpopularnijih kampanja (po prikupljenom iznosu)
- Ako ima donacije: težina kategorije 0.8, lojalnost (donirao već na tu kampanju) 0.2

**Razlozi:** "You donated to 3 Children campaigns", "Matches your interest in Health"

## Persistiranje

Preporuke se čuvaju u tabeli `Recommendations` (brišu se stare pri svakom zahtjevu) – za audit i potencijalni keš.

> Detalji implementacije: [RecommenderService.cs](...), kosinusna sličnost standardna, nema kolaborativnog filtriranja.