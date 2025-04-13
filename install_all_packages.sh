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
echo "[✓] Instalacija završena."
echo "[i] Ako vidite greške, ponovi ručno: dpkg -i *.deb && apt-get -f install"
echo "[i] Ako je sve prošlo OK, možeš obrisati .deb fajlove: rm -f *.deb"
