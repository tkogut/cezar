# 🛸 Cezar Orchestrator & Cockpit (AGENTS-OS Swarm)

> **Cezar Runtime & Cockpit** — Asynchroniczny silnik orkiestracji agentów AI ("Fire and Forget") dla ekosystemu AGENTS-OS v6.5 oraz Open-Mercato.

---

## 🌐 Informacje o wdrożeniu na VPS

* **URL Panelu:** [https://cezar.srv1490214.hstgr.cloud](https://cezar.srv1490214.hstgr.cloud)
* **Host VPS:** `srv1490214.hstgr.cloud`
* **Ścieżka na serwerze:** `/docker/cezar`
* **Reverse Proxy:** Traefik + Let's Encrypt TLS + HTTP BasicAuth
* **Runner bazowy:** `pi` (OpenRouter / DeepSeek v4.1 Flash)

---

## 🚀 Szybki start (Lokalnie lub na serwerze)

### 1. Konfiguracja zmiennych środowiskowych
Skopiuj plik `.env.example` i uzupełnij klucze:
```bash
cp .env.example .env
```

### 2. Generowanie hasła dostępu do panelu
Skrypt `update-password.sh` automatycznie generuje bezpieczny hash Apache APR1 dla Traefika:
```bash
./update-password.sh "twoje_tajne_haslo"
```

### 3. Uruchomienie kontenera
```bash
docker compose up -d --build
```

---

## 📁 Struktura projektu

```
cezar/
├── .agents/                 # Złoty Standard AGENTS-OS (pamięć, skille)
├── .github/workflows/       # Automatyczny deploy na VPS (GitHub Actions)
├── Dockerfile               # Node 20 + @open-mercato/cezar + pi-coding-agent + gh
├── docker-compose.yml       # Konfiguracja kontenera, sieci traefik-proxy i wolumenów
├── entrypoint.sh            # Inicjalizacja środowiska, patche dla DeepSeek i start
├── update-password.sh       # Bezpieczna zmiana hasła HTTP BasicAuth
├── .env.example             # Szablon zmiennych środowiskowych
└── README.md
```

---

## 🛡️ GitOps & Deployment
Wszelkie commity na gałęzi `main`/`master` automatycznie uruchamiają workflow `.github/workflows/deploy.yml`, kopiując pliki na serwer VPS i przebudowując kontener.
