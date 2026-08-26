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
| Wächter setzen | frei wählbar | vier feste beim Start |
| Entwicklung, Mega, Training | ja | nein |
| Wellen | 100, mit Launen und Segnungen | Dauerstrom, eine Art je Welle |
| Sonderfelder | Wasser, Vulkan, Kraft, Höhe | nein |
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
