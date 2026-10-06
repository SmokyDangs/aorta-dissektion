# Aortenaneurysma – Morphing-Animation

Interaktive 3D-Animation: eine gesunde Aorta (Pre-Scan) verformt sich schrittweise zum Aneurysma (Post-Scan).

## Starten

```sh
./start.sh
```

Dann im Browser http://localhost:8000 öffnen. Alternativ jeden anderen statischen Webserver auf diesen Ordner zeigen lassen
(z. B. `npx serve .`) oder den Ordner auf einen Webspace hochladen – es gibt kein Backend.

Die Anwendung braucht kein Internet: three.js und OrbitControls liegen in `lib/`.

## Blutfluss

Schalter „CFD-Blutfluss“: Im Inneren sind die CFD-Pathlines als leuchtende Stromfäden
gezeichnet, auf denen Lichtpulse mit der Partikelzeit der Simulation entlanglaufen (Pathlines aus `Pre/pathlines.vtp` und `Post/pathlines.vtp` (je 82 Linien, Partikelalter 0–0,8 s; standardmäßig in Echtzeit, per Regler bis 0,05× verlangsambar),
eingefärbt nach Geschwindigkeit. Die Pre-Strömung wird mit der Geometrie mitverformt und zwischen 35 % und 75 %
in die Post-Strömung überblendet; beide sind über (Bogenlänge, Umfangswinkel, relativer Radius) auf die jeweils
andere Form abgebildet. Die Zwischenstufen der Strömung sind damit interpoliert, keine eigene Simulation.

In den drei Abgängen wird über die ganze Zeitleiste die Strömung der Post-Simulation gezeigt (die Abgänge sind starr).
Dort gibt es wenige Linien: nur 8 der 82 Post-Pathlines laufen in die Abgänge; Pre-Pathlines, die in die beiden
kurzen Pre-Stümpfe laufen, werden abgeschnitten, weil diese Stümpfe in der Animation nicht vorkommen.
Für dichtere Strömung in den Abgängen bräuchte es mehr Pathlines aus der CFD (z. B. zusätzliche Saatpunkte in den Abgängen)
oder das Geschwindigkeitsfeld im Gefäßinneren.

## Datenbasis und drei Wandschichten

`Pre/vessel_wall_surfaces.vtp` enthält 164.850 Dreiecke mit Domain_ID 2 und 4.
`Post/vessel_wall_surfaces.vtp` enthält 430.598 Dreiecke mit Domain_ID 2, 4, 8 und 16.
Die bestehende Pipeline interpretiert Domain 2 als Flüssigkeitsgrenze und Domain 16 im Post als
Dissektionsmembran. Die IDs sind **keine Beschriftung von Intima, Media und Adventitia**.
Die Pre-Zeitfelder enthalten CFD-/FSI-Werte, keine zeitlich beobachtete Entstehung der Dissektion.
Die Quelldateien werden nicht verändert. Details: `data/source-report.json`.

„Drei Wandschichten“ zeigt modellierte Unterteilungen direkt auf dem gemeinsamen Pre-/Post-Wandnetz:
Adventitia außen (rosa), Media mittig (dunkelrosa) und Intima innen (sandfarben).
Die Gesamtdicke wird aus dem Abstand zur Flüssigkeitsgrenze geschätzt, auf 1,2–5 mm begrenzt
und geglättet. Die Anteile 25 % / 65 % / 10 % sind Darstellungsannahmen, keine Messung der Histologie.
„Schnitt öffnen“ öffnet einen Längsschnitt im absteigenden Gefäßbereich; farbige Schnittkanten zeigen
die Schichtaufteilung. Dieser Ansichtsschnitt ist unabhängig vom kleinen modellierten Einriss.

## Flap direkt aus dem Wandnetz

Die Anwendung lädt die alte separate Post-Flap-Fläche **nicht mehr**. `wall-flap-data.js`
enthält eine Verformung des vollständigen inneren Aortenwandnetzes. Dieses verwendet exakt dieselben
30.118 Vertex-IDs und 60.000 Dreiecke wie die Außenwand (`aorta-data.preIdx`). Die innere Wand wird
als modellierter Versatz der vorhandenen Wandoberfläche erzeugt; eine histologisch segmentierte
Intima liegt in den Quelldaten nicht vor.

Ein zusammenhängender Bereich dieser Wand löst sich schrittweise ab. Seine Randpunkte bleiben an
der übrigen inneren Wand; es wird keine separate Membran eingeblendet. Der Abstand zur verbleibenden
Außenwand veranschaulicht das falsche Lumen. Die Außenwand folgt weiterhin dem ursprünglichen Pre-/Post-Morph.
Die Post-Membran dient ausschließlich offline als Formvorgabe für ein geglättetes Verschiebungsfeld.
Der Endzustand ist eine **Annäherung** auf der Wandtopologie, keine exakte Kopie der Post-Membran.

„Innere Wand & Ablösung“ schaltet diese Wanddarstellung um. Die modellierte Einrissöffnung ist ein kleiner
Shaderausschnitt. Schichtunterteilung, Wandversatz und zeitliche Ausbreitung sind keine Gewebesimulation.

Aus den vorhandenen Daten neu erzeugen:

```sh
python3 pipeline/build_wall_flap.py
python3 pipeline/check_dissection_geometry.py
```

Das benötigt NumPy und SciPy sowie `aorta-data.js`, `wall-layers.js` und die Post-Referenz `flap-data.js`.
Die älteren Exporter `update_flap.py`, `export_flap_attachment.py` und `export_wall_layers.py`
bleiben für die Erzeugung der Offline-Referenz und der Schichtdaten erhalten. Nach Änderungen daran
muss `build_wall_flap.py` erneut ausgeführt werden.

### Lumen einfärben

Schalter „Wahres & falsches Lumen einfärben“: Das wahre Lumen (blau) ist alles, was die innere Wand samt abgelöstem
Flap umschließt; das falsche Lumen (magenta) ist der Raum zwischen Flap und Außenwand und wird nur dort gezeigt, wo sich
die Wand schon abgelöst hat. Beide sind halbtransparent mit Randaufhellung, die Strömung bleibt sichtbar.

## Erzählung

Die Zeitleiste ist in vier Kapitel gegliedert (Gesund · Einriss · Erweiterung · Aneurysma), jeweils mit kurzem Erklärtext
in der Karte oben links; ein Klick auf ein Kapitel springt dorthin. Die Kapitelgrenzen sind gestalterisch gewählt. Die Animation dauert 18 Sekunden und stoppt am Endzustand; erneutes Abspielen startet von vorn.

## Einführung: Kamerafahrt in den Oberkörper

Beim Start fliegt die Kamera in rund 36 Sekunden und in fünf Schritten von außen in den Brustkorb: Oberkörper → Brustkorb → Herz und Lunge →
Aorta (ascendens, Bogen, Abgänge, descendens) → Gefäßwand. Danach startet die Zeitleiste. Beschriftungen sind an Punkte im Raum
gebunden und wandern mit der Kamera mit. Auch in den vier Kapiteln zeigen sie, was wo passiert (Einriss, Flap, wahres und falsches Lumen,
Aneurysma mit Durchmesser aus dem Netz). Abschalten lassen sie sich mit „Beschriftungen“.

**Körpermodell:** Haut, Knochen (Rippen, Brustbein, Wirbelsäule, Schlüsselbeine), Herz, Bronchial- und Gefäßbaum der Lunge,
Luftröhre und Zwerchfell stammen aus **BodyParts3D, © The Database Center for Life Science, CC BY 4.0**
(https://dbarchive.biosciencedbc.jp/en/bodyparts3d/). Es ist ein Referenzkörper, nicht der Patient dieses Datensatzes.
`pipeline/register_body.py` passt dafür unsere Aorta per ICP (Drehung, Verschiebung, einheitliche Skalierung) an die Aorta von
BodyParts3D an. Mittlere Abweichung ~4 mm, Maßstab 0,73. Der Körper wird mit der Umkehrung dieser Transformation um unsere Aorta gelegt.
`pipeline/build_body.js` schneidet ihn unterhalb der Taille ab, vereinfacht die Netze mit meshoptimizer und schreibt `data/body-data.js`.
Annahmen: BodyParts3D enthält keine Lungenoberfläche. Die Lungenhülle ist deshalb eine geglättete Hülle um den Bronchial-/Gefäßbaum.
Die Herzkammerwände fehlen ebenfalls, also sind die Kammerhohlräume um 9 mm (links) bzw. 4 mm (rechts) aufgeweitet.

Neu erzeugen (Archiv `partof_BP3D_4.0_obj_99.zip`, die Listen `partof_element_parts.txt` und eine `wanted.tsv` mit Konzept-ID
und Datei-ID der benötigten Organe in einem Ordner, OBJ-Dateien entpackt nach `obj/`; NumPy/SciPy, Node mit `meshoptimizer`):

```sh
python3 pipeline/register_body.py . <bp3d-ordner> > reg.json
node pipeline/build_body.js <bp3d-ordner> reg.json data/body-data.js
```

„Einführung überspringen“, Ziehen in der Szene, Abspielen oder die Zeitleiste beenden das Intro; „Einführung ansehen“ startet es neu.
Bei „Bewegung reduzieren“ im Betriebssystem startet es nicht automatisch. Für Standbilder: `index.html?intro=17` hält das Intro bei 17 s an,
`index.html?t=0.5` springt ohne Intro auf 50 % der Zeitleiste. `index_ohne_intro.html` ist die Version davor.

## Bedienung

- Abspielen/Pause, Zeitleiste ziehen
- Linke Maustaste: drehen · Mausrad: zoomen · rechte Maustaste: verschieben

## Dateien

- `index.html` – Anwendung
- `data/aorta-data.js` – Geometrie: ein Netz (30.118 Punkte) mit Position im gesunden (`pre0`) und im kranken Zustand (`pre1`), Dreiecke (`preIdx`); Base64-kodierte Float32/Uint32-Arrays
- `data/wall-flap-data.js` – Verformungsziele und festgehaltene Ränder der echten Wandtopologie
- `data/flap-attachment.js` – ausschließlich Offline-Hilfsdaten für die Referenzzuordnung
- `data/wall-layers.js` – modellierte Schichten, Wandnormalen, Dicken und Ablösungsbereich
- `data/source-report.json` – Prüfung der tatsächlich vorhandenen Quelldaten
- `data/flap-data.js` – Post-Membran als Offline-Formvorgabe; nicht mehr in der Anwendung geladen
- `data/flow-data.js` – Pathlines Pre und Post mit Start-/Zielposition für das Morphing, Geschwindigkeit und Partikelalter
- `index_morph_only.html` – die Version ohne Blutfluss
- `lib/` – three.js r128, OrbitControls, Postprocessing (Bloom, FXAA) und die Schriften (`lib/fonts/`), alles lokal
- `index_vor_gestaltung.html` – die Version vor der Neugestaltung

Zwischenstufen sind interpoliert, kein gemessener Zeitverlauf.

Medizinischer Hintergrund: [Aortic Dissection, MSD Manual](https://www.msdmanuals.com/professional/cardiovascular-disorders/diseases-of-the-aorta-and-its-branches/aortic-dissection).

### Darstellungskorrektur

Die vollständige gläserne Gefäßhülle bleibt auch bei der Schichtinspektion sichtbar.
Der Schnitt ist standardmäßig geschlossen und wird mit „Wandschichten im Schnitt“ eingeschaltet.
Die Membran schreibt keinen unsichtbaren Tiefenpass mehr, der andere Gefäßflächen verdecken könnte.
Schnittkanten sind transparent und schreiben keine Tiefenwerte; Bloom wurde auf helle Strömungspulse begrenzt.

### Strömung im falschen Lumen

Kein Blut durchquert eine Wand: Das falsche Lumen ist der geschlossene Raum zwischen abgelöstem Flap und Außenwand.
`pipeline/export_false_lumen_flow.py` berechnet für 101 Zeitpunkte der Zeitleiste exakt den Wandzustand der Seite nach
und prüft jeden Strömungspunkt mit einem Innen-Test gegen diesen Raum (`data/false-lumen-flow.js`):

- **Orange, Post-CFD:** die echten Post-Pathlines, die im falschen Lumen der Post-Simulation verlaufen (6 Linienstücke,
  205 Punkte – mehr gibt `Post/pathlines.vtp` dort nicht her). Am Ende stehen sie an ihrer echten Position mit ihren
  echten Verwirbelungen; davor wandern sie mit Flap und Wand mit. Punkte, die nicht im falschen Lumen der App lägen,
  werden ausgeblendet (am Ende 23 von 205, weil der Flap nur eine Annäherung an die echte Membran ist).
- **Hellorange, modelliert:** Einstrom und Rückströmung. Das falsche Lumen der App hat keinen Wiedereintritt, das
  Blut muss also am geschlossenen Ende umkehren. 7 Schleifen kommen aus dem wahren Lumen, strömen durch die
  Einrissöffnung, laufen schnell an der Außenwand entlang bis zur Ablösungsfront, drehen dort in einer verdrehten
  U-Wende (Wirbel am Ende) und fließen langsamer (110 statt 260 mm/s) am Flap entlang zurück Richtung Einriss.
  Die Schleifen setzen ein, sobald sich hinter dem Einriss ein Spalt öffnet, und wachsen mit dem falschen Lumen mit.
  Nicht aus der CFD: Die Post-Pathlines erreichen das distale falsche Lumen nicht.
- **Blau:** Pre-/Post-Pathlines werden an jeder Stelle ausgeblendet, an der sie im falschen Lumen lägen. Weil die
  Zwischenstufen der Strömung interpoliert sind, betrifft das vor allem die Mitte der Animation.

Alle Linien werden geglättet: Die CFD-Pathlines (10 ms Punktabstand) zeichnet die App als Catmull-Rom-Splines;
die Linien im falschen Lumen glättet das Skript entlang der Linie und über die Zeit, wobei jeder verschobene Punkt im
falschen Lumen bleiben muss. Zwischen den Zeitpunkten können einzelne Punkte an sehr schmalen Stellen bis ca. 1–2 mm in
die modellierte Wandschicht ragen, nicht aus dem Gefäß hinaus.

Neu erzeugen (nach Änderungen an Wand, Flap oder `flow-data.js`): `python3 pipeline/export_false_lumen_flow.py` (ca. 4 min).
