# PocketBeast 3D

Der Anfang der Umstellung auf echte dreidimensionale Darstellung. Ein
Grundgerüst, kein Spiel.

Das Browserspiel im übergeordneten Ordner bleibt davon unberührt und ist
weiterhin die spielbare Fassung.

## Starten

Godot 4.7 öffnen → *Import* → diesen Ordner wählen → *Run* (F5).

## Was steht

- **Beleuchtete Szene** mit Himmel, Umgebungslicht, Sonne und Schattenwurf
- **Welliges Gelände** als eigenes Mesh, Höhe entlang der Route abgeflacht
- **Weg** als eigene Geometrie über dem Boden, geglättet wie im Browserspiel
- **Bäume** aus Grundkörpern, prozedural verteilt und nicht auf dem Weg
- **Wächter und Gegner** als Körper im Raum, mit Zielsuche und Treffern
- **Dunst in der Ferne** als räumliche Tiefe

Getestet mit Godot 4.7.2: läuft ohne Fehler, nach acht Sekunden waren vier
Gegner erledigt.

## Was fehlt

Der weitaus größere Teil:

| Bereich | Browserspiel | Hier |
|---|---|---|
| Elementtypen | 10 mit Effektivitätstabelle | 0 |
| Wächter | 10 Familien à 3 Stufen + Mega | 2 feste |
| Gegnerarten | 32 plus 8 Bosse | 1 |
| Wellen | 40, mit Launen und Segnungen | Dauerstrom |
| Karten | 3, mit Gabelung und Sonderfeldern | 1 |
| Tag und Nacht | ja | nein |
| Klang | 12 Arten, prozedural | keiner |
| Bedienung, Menüs, Speicherstand | vollständig | nichts |

## Vier Fallstricke, die schon aufgetreten sind

Wer hier weiterbaut, spart sich damit Zeit:

**1. `class_name` greift beim ersten Start nicht.** Godot kennt eigene
Klassennamen erst nach einem Projekt-Scan; ein frisch geklonter Ordner
scheitert daran. Die Skripte werden deshalb ausdrücklich per `preload`
eingebunden.

**2. Dictionary-Werte haben keinen Typ.** `var x := irgendwas["schluessel"]`
lässt sich nicht übersetzen. Zieltyp angeben: `var x: Vector3 = …`

**3. Die Reihenfolge der Ecken entscheidet, wohin eine Fläche schaut.** Im
ersten Anlauf zeigten die Normalen des Geländes nach unten — das Mesh war
mit 23.040 Ecken vorhanden, aber von der Kamera aus unsichtbar.

**4. Bei schräger Draufsicht sieht man nie den oberen Himmel**, sondern dessen
Bodenanteil. Steht der auf Dunkelgrün, rahmt sich die Szene schwarz ein.

## Warum das ein eigener Ordner ist

Godot führt kein JavaScript aus. Der Umzug ist ein vollständiges Neuschreiben,
nicht eine Umwandlung. Solange die 3D-Fassung nicht mindestens den Umfang des
Browserspiels erreicht, bleibt jene die spielbare — und dieser Ordner wächst
daneben.
