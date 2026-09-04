# PocketBeast 3D

Die dreidimensionale Fassung. **Spielbar** — eine Runde läuft von Anfang bis
Ende: Wellen kommen, Wächter schießen, Gegner brechen durch, man gewinnt oder
verliert.

Das Browserspiel im übergeordneten Ordner ist weiterhin die vollständigere
Fassung. Was hier fehlt, steht unten.

## Spielen

Godot 4.7 öffnen → *Import* → diesen Ordner wählen → *Run* (F5).

### Steuerung

| | |
|---|---|
| `1`–`9` | Wächter wählen, dann auf eine freie Fläche klicken |
| Klick auf einen Wächter | anwählen, dann Entwickeln / Training / Mega / Entlassen |
| `Leertaste` | nächste Welle rufen |
| `M` | nächste Karte (lädt neu) |
| `E` | Endlosmodus, sobald eine Route gehalten ist |
| `Esc` | Auswahl aufheben |

## Was funktioniert

- **Elf Karten** mit eigener Wegführung, eigenen Boden-, Weg-, Laub- und
  Himmelsfarben. Sie kommen aus dem Browserspiel über
  `node tools/daten-nach-godot.js`.
- **Kreaturen** statt Kugeln: Rumpf, Hals, Kopf, Augen und je Gestalt eigene
  Teile — Ohren, Hörner, Schwingen, Flossen, Blätter, Zacken, Visierschlitz.
- **Dreizehn Wächterfamilien** mit drei Stufen, Training und Megaentwicklung.
- **Nebenwirkungen**: Fläche, Kette, Bremse, Fessel, Brand, Gift, Marke. Sie
  waren lange exportiert und von niemandem gelesen — `_setze_turm()` nahm
  fünf Zahlen entgegen, und damit waren alle Familien dasselbe.
- **44 Gegnerarten** mit Typenvorteil, Panzerung und Flugfähigkeit, je Karte
  gefiltert: Der Grünpfad kennt drei Elemente, die letzten Routen alle elf.
- **Anführer** alle acht Wellen, aus der Fauna der Karte und nach Panzerung
  sortiert; auf der Schlusswelle der des Heimatelements.
- **Hundert Wellen**, danach Sieg und Endlosmodus.
- **Speicherstand** unter `user://stand.json`: Sterne, Trainerpunkte, Ränge,
  gemeisterte Karten, Aufstellungen.
- **Trainerpfad** bis Rang 100 in zehn Zweigen, mit denselben zwei
  Kurvenformen wie im Browserspiel — geprüft, dass beide bei Rang 50
  dieselben Werte liefern.
- **Freischaltung**: vier Familien von Anfang an, sieben über Sterne.
- Gelände mit Höhen, eingesenktem Weg, Bewuchs, Licht und Schatten.

Gemessen mit dem Selbstlauf (siehe unten), neun Wächter auf Stufe 0:

```
nur Schaden      16 Wellen, 241 erledigt, 20 Durchbrüche, verloren
mit Wirkungen    18 Wellen, 315 erledigt,  2 Durchbrüche, 22 von 24 Leben
```

## Was noch fehlt

Gegenüber dem Browserspiel: Wetter, Tag und Nacht, Sonderfelder (Wasser,
Vulkan, Erhöhung), Segnungen, Anführerfähigkeiten, Hain der Ahnen, Statistik,
Bestiarium, Klang — und die **Bedienoberfläche** für das, was jetzt darunter
schon läuft: Trainerpfad, Aufstellung und Sterne haben noch kein Menü. Die
Logik steht, sie ist nur nicht zu bedienen.

## Prüfen ohne hinzusehen

Godot kopflos zu starten zeichnet gar nichts — und vier der Fehler in dieser
Fassung zeigten sich ausschließlich beim Hinsehen, ohne je eine Fehlermeldung
zu werfen: Scheitelfarben, die linear statt sRGB gelesen werden, Nebel, der
nach unten wirkt, Moiré aus zu feinen Mustern, ein milchiger Schleier über
allem.

Deshalb vier Umgebungsschalter:

```bash
G=/Users/yannick/Desktop/Godot.app/Contents/MacOS/Godot

# Bild der Karte ablegen
POCKETBEAST_SCHAU=/tmp/bild.png $G --path . --resolution 1280x720

# vorher Wächter aufstellen und eine Welle rufen
POCKETBEAST_SCHAU=/tmp/bild.png POCKETBEAST_AUTO=300 $G --path .

# Kamera dicht an die Figuren
POCKETBEAST_SCHAU=/tmp/bild.png POCKETBEAST_AUTO=120 POCKETBEAST_NAH=1 $G --path .

# eine bestimmte Karte
POCKETBEAST_KARTE=6 POCKETBEAST_SCHAU=/tmp/bild.png $G --path .

# Wellen selbsttätig spielen, Bericht nach user://bericht.txt
POCKETBEAST_AUTO=1 POCKETBEAST_SPIEL=25 $G --path .
```

Der Bericht liegt unter
`~/Library/Application Support/Godot/app_userdata/PocketBeast 3D/bericht.txt`
— Godots Ausgabe wird beim Umleiten gepuffert und kam auf der Kommandozeile
nicht an.

**Bedienung**

| | |
|---|---|
| Wächter wählen | auf eine Karte unten klicken, oder Taste **1**–**9** |
| Setzen | auf eine freie Fläche klicken |
| Ansehen und ausbauen | ohne Auswahl auf einen gesetzten Wächter klicken |
| Auswahl abbrechen | **Esc** |
| Welle rufen | **Leertaste** oder der Knopf unten links |
| Tempo | Knopf **1×** — bis dreifach |

Der Ring um die Bauvorschau zeigt die Reichweite. Ist er blass, reichen die
Beeren nicht. Auf dem Weg und direkt daneben lässt sich nicht bauen.

Beeren kommen aus erledigten Gegnern und einem Bonus nach jeder gehaltenen
Welle. Jeder durchgelassene Gegner kostet ein Leben.

## Was steht

- **Beleuchtete Szene** mit Himmel, Umgebungslicht, Sonne und Schattenwurf
- **Welliges Gelände** als eigenes Mesh, Höhe entlang der Route abgeflacht
- **Weg** als eigene Geometrie über dem Boden, geglättet wie im Browserspiel
- **Bewuchs** aus vier Arten (Nadelbaum, Laubbaum, Busch, Totholz), jede
  Pflanze mit eigenen Proportionen, eigenem Farbton, eigener Neigung
- **Bodenschicht** aus Gras, Steinen und Blumen als MultiMesh
- **Waldsaum** über das Spielfeld hinaus, damit der Bewuchs nicht an einer
  geraden Linie endet
- **Wächter und Gegner** als Körper im Raum, mit Zielsuche und Treffern
- **Dunst in der Ferne** als räumliche Tiefe

Getestet mit Godot 4.7.2: läuft ohne Fehler, 150 Pflanzen im Spielfeld, 420
im Waldsaum, rund 14.000 Grasbüschel. Die Szene hält durchgehend 60 Bilder je
Sekunde — das ist der Deckel der Anzeige. Wie viel Reserve darüber liegt, ließ
sich nicht messen: VSync lässt sich auf diesem Mac weder zur Laufzeit noch
über die Projekteinstellung abschalten. Bei 3.239 Zeichenaufrufen je Bild
(jeder Baum besteht aus Stamm und mehreren Kronenteilen) ist das der erste
Punkt, an dem es später eng werden dürfte.

## Spieldaten

Alle Werte kommen aus dem Browserspiel und werden erzeugt, nicht
abgeschrieben:

```
node tools/daten-nach-godot.js
```

Das schreibt `scripts/daten.gd` — zwölf Elementtypen mit
Effektivitätstabelle, zwölf Wächterfamilien mit je drei Stufen und allen
Sonderwirkungen, zweiunddreißig Gegnerarten, acht Anführer, die Wellenkurve
als Tabelle und die drei Karten.

**Diese Datei nicht von Hand ändern** — beim nächsten Lauf ist die Änderung
weg. Werte gehören ins Browserspiel, hierher ziehen sie nach.

Der Grund: An einem einzigen Abend wurden sämtliche Reichweiten neu gesetzt,
eine zwölfte Familie kam dazu und die Panzerungsformel wurde umgestellt. Eine
von Hand gepflegte zweite Fassung wäre binnen Tagen falsch gewesen, ohne dass
es jemandem aufgefallen wäre.

## Was fehlt

Der größere Teil:

| Bereich | Browserspiel | Hier |
|---|---|---|
| Elementtypen | 12 mit Effektivitätstabelle | ✓ übernommen |
| Wächterwerte | 12 Familien à 3 Stufen | ✓ übernommen |
| Gegnerarten | 32 plus 8 Anführer | ✓ übernommen, 1 Art je Welle |
| Typenvorteil und Panzerung | ja | ✓ wirkt |
| Flieger | ja | ✓ schweben, nur von Luftwächtern treffbar |
| Wächter setzen | frei wählbar | ✓ per Klick, mit Vorschau |
| Beeren, Leben, Punkte | ja | ✓ |
| Wellen rufen | ja | ✓ zwei Arten je Welle, Bodengarantie |
| Entwicklung in drei Stufen | ja | ✓ |
| Training | bis 15 Stufen | ✓ |
| Megaentwicklung | ja | ✓ mit denselben Schwellen |
| Entlassen | ja | ✓ 60 % zurück |
| Wächtergestalt | 16 gezeichnete Formen | Kugeln in Elementfarbe |
| Launen und Segnungen | ja | nein |
| Sonderfelder | Wasser, Vulkan, Kraft, Höhe | nein |
| Tag und Nacht | ja | nein |
| Klang | 12 Arten, prozedural | keiner |
| Bedienung, Menüs, Speicherstand | vollständig | nichts |

## Fünf Fallstricke, die schon aufgetreten sind

Wer hier weiterbaut, spart sich damit Zeit:

**0. Prüfschalter dürfen sich nicht gegenseitig voraussetzen.** Der Aufbau
hing zuerst an `POCKETBEAST_SCHAU`: Ohne Schaubild lief die Prüfung ins
Leere, und der Selbstlauf startete nie eine Welle. Das habe ich behoben —
und denselben Fehler eine Ebene tiefer stehen lassen: `POCKETBEAST_SPIEL`
wurde erst *innerhalb* von `_auto_aufbau()` gelesen, und das lief nur bei
gesetztem `POCKETBEAST_AUTO`.

Ein Lauf mit `POCKETBEAST_SPIEL` allein tat deshalb nichts. Er stürzte nicht
ab und meldete nichts — er saß bei **2,7 Prozent Rechenlast** auf einer
leeren Karte und wartete auf eine Eingabe, die nie kam. Zehn Minuten lang sah
das aus wie ein hängender Selbstlauf, und ich habe zweimal die falsche
Ursache geraten, bevor ich die Rechenlast gemessen habe.

Zweimal derselbe Fehler heißt: Jeder Schalter zieht jetzt den Aufbau selbst.

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

**5. Vertexfarben liest Godot als Linearwerte.** Wer sie wie gewohnt als
sRGB hinschreibt, bekommt sie stark aufgehellt und entsättigt zurück: aus
0,22/0,36/0,19 wurde am Schirm 0,50/0,63/0,47 — ein milchiger Schleier über
der ganzen Fläche. Deshalb steht hinter jedem `set_color` und
`set_instance_color` ein `.srgb_to_linear()`. Für `albedo_color` eines
Materials gilt das *nicht*, das wird korrekt als sRGB behandelt.

**6. Höhen-Nebel greift nach unten.** `fog_height = 6.0` legt Nebel über
alles *unterhalb* von sechs Einheiten — also über das ganze Gelände. Gemeint
war das Gegenteil.

**7. Feine Muster erzeugen in der Ferne Moiré.** Ein Farbrauschen mit rund
zwei Einheiten Wellenlänge fiel am Horizont unter die Pixelauflösung und
zeichnete regelmäßige Streifenbänder. Dasselbe Muster entsteht aus zu weit
gespannten Schattenkarten (Schattenakne) — beide Ursachen sahen im Bild
identisch aus und mussten einzeln ausgeschlossen werden.

## Warum das ein eigener Ordner ist

Godot führt kein JavaScript aus. Der Umzug ist ein vollständiges Neuschreiben,
nicht eine Umwandlung. Solange die 3D-Fassung nicht mindestens den Umfang des
Browserspiels erreicht, bleibt jene die spielbare — und dieser Ordner wächst
daneben.
