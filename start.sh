#!/bin/sh
# Startet die Webanwendung lokal unter http://localhost:8000
cd "$(dirname "$0")"
echo "Aorta-Animation läuft unter http://localhost:8000  (Beenden: Strg+C)"
python3 -m http.server 8000
