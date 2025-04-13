
# 💾 Ubuntu 12.04 Offline Installer (i386)

Kompletan **offline installer** za čisti Ubuntu 12.04 i386 sistem, za mašine bez pristupa internetu.  
Svi `.deb` paketi su **ručno preuzeti** sa `old-releases.ubuntu.com` jer originalni repozitoriji više ne rade.  
Testirano i složeno tako da radi iz prve.

---

## 📦 Sadržaj

`debs/` sadrži sve potrebne pakete za:

- `apt`, `dpkg`, `wget`, `sudo`, `curl` – osnovni sistemski alati  
- `build-essential`, `make`, `gcc`, `g++`, `headers` – za kompajliranje izvornog koda i drajvera  
- `git` – za kloniranje repoa  
- `nano`, `mc`, `htop`, `bash`, `coreutils`, `tar`, `findutils` – korisni CLI alati  

Sve za **Ubuntu 12.04 i386**.

---

## 🛠️ Kako koristiti?

1. Prebaci cijeli folder na Ubuntu 12.04 mašinu (npr. putem USB-a)
2. U terminalu pokreni:

```
chmod +x install_all_packages.sh
./install_all_packages.sh
```

Skripta će:
- Ući u `debs/` direktorij
- Instalirati sve `.deb` pakete redom
- Pokrenuti `apt-get -f install -y` da riješi zavisnosti
- Pokrenuti `apt-get update` da provjeri da li apt radi

---

## ⚠️ Napomena

Ako `apt-get update` ne radi, trebaš ručno urediti `sources.list` i zamijeniti mirror sa:

```
http://old-releases.ubuntu.com/ubuntu
```

---

## 👤 Autor

Repo sastavio: [@adis992](https://github.com/adis992)  
Sve testirano, složeno i provjereno da radi offline.

---

## 📝 Licenca

Slobodno koristiš, širiš, forkaš – bez ograničenja.
```

---

Zalijepi ovo **tačno ovako** u `README.md` i vidjećeš kako izgleda brutala.

Ako hoćeš i `preview badge` ili da automatski prikaže `.sh` fajl u opisu — mogu ti i to složiti.
