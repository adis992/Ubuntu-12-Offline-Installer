# 💾 Ubuntu 12.04 Offline Installer (i386)

A complete **offline installer** for a fresh Ubuntu 12.04 i386 system, designed for machines with no internet access.  
All `.deb` packages were **manually downloaded** from `old-releases.ubuntu.com`, as the official repositories are no longer active.  
Tested and structured to work out of the box.

---

## 📦 Contents

The `debs/` folder includes all essential packages for:

- `apt`, `dpkg`, `wget`, `sudo`, `curl` – core system tools  
- `build-essential`, `make`, `gcc`, `g++`, `headers` – compiling code and drivers  
- `git` – for cloning repositories  
- `nano`, `mc`, `htop`, `bash`, `coreutils`, `tar`, `findutils` – common CLI utilities  

All packages are for **Ubuntu 12.04 i386**.

---

## 🛠️ How to Use

1. Transfer the entire folder to your Ubuntu 12.04 machine (e.g., via USB)
2. Open a terminal and run:

```
chmod +x install_all_packages.sh
./install_all_packages.sh
```

The script will:
- Navigate to the `debs/` folder
- Install all `.deb` packages in order
- Run `apt-get -f install -y` to fix dependencies
- Execute `apt-get update` to verify if APT is working

---

## ⚠️ Note

If `apt-get update` fails, manually edit your `sources.list` and use:

```
http://old-releases.ubuntu.com/ubuntu
```

as the mirror.

---

## 👤 Author

Repository by [@adis992](https://github.com/adis992)  
All packages were downloaded, tested, and bundled to work 100% offline.

---

## 📝 License

Feel free to use, share, fork — no restrictions.
