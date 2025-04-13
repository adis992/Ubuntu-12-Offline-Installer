# Ubuntu 12.04 Offline Installer (i386)

**Ovaj projekat je offline instalacijski paket za Ubuntu 12.04 i386**, napravljen jer na čistom sistemu jedino `wget` funkcioniše.  
Svi `.deb` paketi su ručno preuzeti sa `old-releases.ubuntu.com`, jer zvanični repozitoriji više ne rade.

---

## 📦 Šta se nalazi u ovom paketu?

**Folder `debs/` sadrži ručno preuzete .deb pakete za:**

- `apt`, `dpkg`, `wget`, `sudo`, `curl` – osnovni sistemski alati
- `build-essential`, `make`, `gcc`, `g++`, `headers` – za kompajliranje koda i drajvera
- `git` – za kloniranje repoa
- `nano`, `mc`, `htop`, `bash`, `coreutils`, `tar` – korisni CLI alati
- svi paketi su za **Ubuntu 12.04 i386**

---

## 🛠️ Kako se koristi?

1. Prebaciš kompletan folder `Ubuntu-12-Offline-Installer/` na mašinu sa Ubuntu 12.04 (npr. USB-om)
2. U terminalu pokreneš:

```bash
chmod +x install_all_packages.sh
./install_all_packages.sh




Skripta će:

Ući u debs/

Instalirati sve .deb fajlove

Pokrenuti apt-get -f install -y za zavisnosti

Na kraju pokrenuti apt-get update da provjeri da li apt sada radi, moguce da trebas jos repository source list izmijeniti rucno.

🔧 Zašto ovo postoji?
Zato što kad instaliraš Ubuntu 12.04 danas, ništa ne radi osim wget.
Ova kolekcija omogućava ti da bez interneta postaviš kompletan build okruženje sa svim alatima.

👤 Autor
Repo sastavio: @adis992
Sve ručno preuzeto, testirano, složeno da radi offline.

📝 Licenca
Slobodno koristiš, širiš, forkaš, pomažeš. Nema ograničenja.


---

