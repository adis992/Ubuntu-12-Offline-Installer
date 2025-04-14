#!/bin/bash

LOGFILE="/var/log/offline_installer.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[*] Pokrećem instalaciju svih .deb paketa iz ./debs..."

cd "$(dirname "$0")/debs" || { echo "Folder ./debs ne postoji. Prekida se."; exit 1; }

for deb in *.deb; do
    echo "[+] Instaliram: $deb"
    dpkg -i "$deb"
done

echo "[*] Rješavam zavisnosti..."
apt-get -f install -y

echo "[*] Testiram apt-get update (repo check)..."
apt-get update

echo ""
echo "[✓] Instalacija .deb paketa završena."
echo "[*] Učitavam fix_repo_error.sh..."
source /putanja/do/fix_repo_error.sh

echo "[i] Ako vidite greške, ponovite ručno: dpkg -i *.deb && apt-get -f install"
echo "[i] Ako je sve prošlo OK, možete obrisati .deb fajlove: rm -f *.deb"
