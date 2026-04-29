# HeartForCharity

Platforma za povezivanje donatora, volontera i humanitarnih organizacija. Donatori finansiraju kampanje preko PayPal-a; volonteri se prijavljuju za poslove; organizacije kreiraju kampanje i poslove i upravljaju prijavama.

## Tehnologije

- **Backend**: ASP.NET Core 8 (`HeartForCharity.WebAPI`), Entity Framework Core, SQL Server
- **Worker servis**: Odvojeni RabbitMQ subscriber (`HeartForCharity.Subscriber`)
- **Frontend**: Flutter (desktop i mobile aplikacija) + zajednički Dart paket (`heartforcharity_shared`)
- **Message broker**: RabbitMQ
- **Plaćanja**: PayPal Sandbox

Sistem preporuke je dokumentovan u [recommender-dokumentacija.md](recommender-dokumentacija.md).

## Preduslovi

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) sa uključenim WSL2 backend-om (Windows)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.11+) — za pokretanje desktop i mobile aplikacije
- Android Studio sa konfigurisanim AVD-om — za mobilnu aplikaciju

## Pokretanje aplikacije

### 1. Pokrenuti backend (API + Subscriber + DB + RabbitMQ)

Iz root foldera repozitorija:

```bash
docker compose up -d --build
```

Compose podiže 4 servisa:
- `db` — SQL Server (port 1433)
- `rabbitmq` — RabbitMQ sa management UI-em (port 5672 AMQP, 15672 UI)
- `api` — Web API (port 5145)
- `subscriber` — RabbitMQ konzumer (notifikacije za approve/reject)

Pri prvom pokretanju, API automatski:
- Primjenjuje sve EF Core migracije
- Seed-uje bazu sa demo podacima

Provjera:
- Swagger UI: **http://localhost:5145/swagger**
- RabbitMQ UI: **http://localhost:15672** (`guest` / `guest`)

### 2. Pokrenuti desktop aplikaciju (administrator i organizacija)

```bash
cd HeartForCharity/UI/heartforcharity_desktop
flutter pub get
flutter run -d windows
```

Default API URL je `http://localhost:5145/api/` — odgovara docker mapping-u, ne treba override.

### 3. Pokrenuti mobilnu aplikaciju (donator/volonter)

Pokrenuti Android emulator (AVD), zatim:

```bash
cd HeartForCharity/UI/heartforcharity_mobile
flutter pub get
flutter run
```

Default API URL za mobile build je `http://10.0.2.2:5145/api/` (AVD-ova adresa za host-ov localhost).

## Korisnički podaci za pristup aplikaciji

| Kontekst | Korisničko ime | Lozinka |
|---|---|---|
| Desktop — administrator | `admin` | `Admin123!` |
| Desktop — organizacija | `careshare_org` | `Test123!` |
| Mobilna — donator/volonter | `lisa_taylor` | `Test123!` |

`careshare_org` i `lisa_taylor` imaju najkompletnije seed podatke (kampanje sa slikama, donacije, prijave, recenzije, notifikacije) — preporučeni su za demonstraciju end-to-end funkcionalnosti.

### Dodatni demo nalozi

Lozinka za sve dolje navedene naloge: `Test123!`

**Organizacije (desktop):** `hope_org`, `globalaid_org`, `helping_org`, `bright_org`

**Donatori/volonteri (mobile):** `john_doe`, `jane_smith`, `mike_johnson`, `emily_davis`, `chris_wilson`, `sarah_brown`, `david_miller`, `james_anderson`, `emma_thomas`

## Build za predaju (release)

### Android APK

```bash
cd HeartForCharity/UI/heartforcharity_mobile
flutter clean
flutter build apk --release
```

Generiše: `build/app/outputs/flutter-apk/app-release.apk`

### Windows desktop EXE

```bash
cd HeartForCharity/UI/heartforcharity_desktop
flutter clean
flutter build windows --release
```

Generiše: `build/windows/x64/runner/Release/`

## Konfiguracija

Sve konfiguracijske vrijednosti (DB connection string, JWT, RabbitMQ, PayPal) nalaze se u [HeartForCharity/HeartForCharity.WebAPI/.env](HeartForCharity/HeartForCharity.WebAPI/.env). Docker compose taj fajl koristi preko `env_file`, sa container-specific override-ima za hostnames (`db` umjesto `localhost`).

API URL za frontend može se override-ati preko `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://<host>:5145/api/
```

## Resetovanje baze (čisti seed)

```bash
docker compose down -v
docker compose up -d --build
```

`-v` briše Docker volume sa SQL Server podacima. Sljedeći `up` će ponovo seed-ovati bazu od nule.
