# PocketBeast — Konzept für die Assetgenerierung

Stand: 2026-08-29. Erzeugt aus `index.html` mit `node tools/konzept-bauen.js` —
die Tabellen sind der tatsächliche Spielinhalt, keine Wunschliste.

---

## 1. Worum es geht

Kreaturen-Tower-Defense. Wilde Wesen ziehen von der Wildnis zum Dorf; der
Spieler stellt Wächter an den Weg. Jeder Wächter und jedes Wilde gehört einem
von zwölf Elementen, die einander schlagen. Wächter entwickeln sich über drei
Stufen und eine vierte, verdiente.

Das Spiel hat **keine Asset-Dateien**. Jede Grafik entsteht heute aus
Zeichenbefehlen, jeder Klang aus Schwingungen. Dieses Konzept beschreibt, was
erzeugt werden müsste, wenn es Dateien geben soll — für eine 3D-Fassung oder
eine Veröffentlichung.

## 2. Stil

**Freundlich, nicht niedlich.** Die Wesen haben große Augen und runde Körper,
aber die Landschaft ist ernst: gedämpfte Farben, echte Schatten, Wetter. Ein
Wilder soll bedrohlich wirken können, ohne das Bild zu brechen.

**Silhouette vor Feinzeichnung.** Die Figuren stehen im Spiel 13 bis 19 Pixel
hoch. Was sie unterscheidbar macht, sind zwei oder drei Merkmale — spitze
Ohren, Hörner, Schwingen — nicht die Zeichnung darauf.

**Licht von oben links.** Alle Schatten fallen nach rechts unten. Erhöhte
Dinge haben eine helle Oberkante und eine dunkle Unterseite.

**Keine schwarzen Umrisse.** Formen trennen sich durch Helligkeitsunterschied,
nicht durch Konturlinien.

**Bewegung gehört zur Figur.** Jedes Wesen atmet im Stand und stößt beim
Gehen ab. Ohren, Schweife und Flügel schwingen der Körperbewegung verzögert
nach — diese Verzögerung liest das Auge als Masse.

## 3. Elemente und Farben

| Element | Name | Farbe |
|---|---|---|
| `fire` | Feuer | `#FF6E45` |
| `water` | Wasser | `#48A6FF` |
| `grass` | Pflanze | `#57CE7C` |
| `electric` | Elektro | `#FFD645` |
| `rock` | Gestein | `#C08F67` |
| `psychic` | Psycho | `#C382FF` |
| `ice` | Eis | `#7FDBF0` |
| `steel` | Stahl | `#A9BECD` |
| `fairy` | Fee | `#FF9ED2` |
| `dark` | Unlicht | `#8C7BB8` |
| `wind` | Wind | `#9FE3D6` |
| `legend` | Legendär | `#F5C542` |

Die Farbe eines Wesens ist immer die seines Elements. Abweichungen gibt es
nur als Aufhellung oder Abdunklung derselben Farbe.

## 4. Wächter

Elf baubare Familien, je drei Stufen. Die Stufen zeigen dieselbe Kreatur,
gewachsen: Stufe 2 bekommt einen Stachelkranz über dem Kopf, Stufe 3 einen
höheren Kranz in Elementfarbe und ein Zeichen des Elements.

### Zündling → Glutkatze → Flammenkralle

- **Element:** Feuer (`#FF6E45`)
- **Gestalt:** Katzenartig. Gedrungener Rumpf, spitze Dreiecksohren, langer beweglicher Schweif, Schnurrhaare.
- **Trifft Flieger:** ja
- **Rolle:** Schnelle Einzelziele, entzündet Gegner.
- **Meganame:** Flammenfürst

### Tröpfling → Flutwelpe → Wogenfürst

- **Element:** Wasser (`#48A6FF`)
- **Gestalt:** Wassertropfen. Oben spitz, unten breit, durchscheinend mit Lichtreflexen.
- **Trifft Flieger:** ja
- **Rolle:** Flächenschaden, verlangsamt alles im Umkreis.
- **Meganame:** Tiefenherr

### Keimling → Dornbock → Rankenschlund

- **Element:** Pflanze (`#57CE7C`)
- **Gestalt:** Keimling. Runder Körper, zwei große Blätter als Ohren, Blattadern sichtbar.
- **Trifft Flieger:** ja
- **Rolle:** Günstig und verlässlich, fesselt mit Ranken.
- **Meganame:** Urwaldwächter

### Blitzmilbe → Wetterfuchs → Donnerrachen

- **Element:** Elektro (`#FFD645`)
- **Gestalt:** Fuchsartig. Schlanker als die Katze, sehr große spitze Ohren, buschiger Schweif, keilförmige Schnauze.
- **Trifft Flieger:** ja
- **Rolle:** Feuert sehr schnell, Blitze springen weiter.
- **Meganame:** Gewitterfang

### Kiesling → Felsochse → Bergwucht

- **Element:** Gestein (`#C08F67`)
- **Gestalt:** Ochsenartig. Breit und schwer, geschwungene helle Hörner, kurze Schnauze mit Nüstern, Rückenplatten.
- **Trifft Flieger:** nein
- **Rolle:** Wuchtige Erschütterung — trifft keine Flieger.
- **Meganame:** Bergbrecher

### Traumflaum → Traumeule → Weitseher

- **Element:** Psycho (`#C382FF`)
- **Gestalt:** Eulenartig. Rund und gedrungen, Federohren, Gesichtsscheiben, kurzer Schnabel, angelegte Flügel.
- **Trifft Flieger:** ja
- **Rolle:** Stärkt benachbarte Wächter und markiert Ziele.
- **Meganame:** Allseher

### Frostfell → Raureifer → Eisklamm

- **Element:** Eis (`#7FDBF0`)
- **Gestalt:** Pelztier. Runde Silhouette mit gezackter Fellkontur, kurze Ohrbüschel, Frosthauch.
- **Trifft Flieger:** ja
- **Rolle:** Friert Gegner ein — die stärkste Verlangsamung.
- **Meganame:** Ewigfrost

### Nietling → Schmiedstier → Ambosswacht

- **Element:** Stahl (`#A9BECD`)
- **Gestalt:** Metallwesen. Kantige Platten mit abgeschrägten Ecken, Nieten, Visierschlitz statt Augen, Mittelgrat.
- **Trifft Flieger:** nein
- **Rolle:** Schwere Treffer, durchschlägt Panzerung — bodengebunden.
- **Meganame:** Erzamboss

### Schimmerchen → Glanzfee → Morgenwacht

- **Element:** Fee (`#FF9ED2`)
- **Gestalt:** Irrlicht. Leuchtender Kern in einem weichen Schein, ohne feste Grenze, mit nachziehendem Schweif.
- **Trifft Flieger:** ja
- **Rolle:** Markiert Ziele und bricht Unlicht — entwickelt sich nur am Tag.
- **Meganame:** Sternenfee

### Schattling → Nachtzehrer → Finsterwacht

- **Element:** Unlicht (`#8C7BB8`)
- **Gestalt:** Ein großes Auge. Wimpernkranz ringsum, wandernde Pupille, kein Körper.
- **Trifft Flieger:** ja
- **Rolle:** Schlägt hart aus dem Dunkel — entwickelt sich nur nachts.
- **Meganame:** Nachtfürst

### Windling → Sturmfalke → Wirbelwacht

- **Element:** Wind (`#9FE3D6`)
- **Gestalt:** Greifvogelartig. Hoch und schmal, angelegte Schwingen, schmaler Kopf, Hakenschnabel, Augenstreif.
- **Trifft Flieger:** ja
- **Rolle:** Feuert unaufhörlich über große Weite und findet dabei jede Lücke im Panzer.
- **Meganame:** —

### Megaentwicklung

Die vierte Stufe. Ein Drittel größer als Stufe 3, neun statt sieben
Kranzzacken, zwei **gegenläufige** Ringe über dem Haupt und aufsteigende
Splitter, die oben vergehen. Am Boden ein zweiter, breiterer Sockel mit
goldenen Ecksteinen und einem umlaufenden Lichtband.

## 5. Legendäre Wächter

Einer je Karte, verdient durch alle 100 Wellen. Sie sehen
anders aus als alles andere im Spiel:

Der legendäre Wächter. Schwebt über dem Boden statt zu stehen, hat statt eines Gesichts einen leuchtenden Visierschlitz, trägt eine Krone aus frei kreisenden Elementsplittern und einen weiten Mantel ohne sichtbare Beine.

| Karte | Name | Element | Gabe |
|---|---|---|---|
| Grünpfad | Wurzelthron | Pflanze | hält Gegner fest (30 %, 1.1 s) |
| Glutschlucht | Schlundthron | Feuer | Brand wirkt 1.6-fach |
| Flutruine | Strömungsthron | Wasser | verlangsamt um 40 % für 2 s |
| Gewitterkamm | Wetterthron | Elektro | Blitze springen 3-mal weiter |
| Steinkessel | Grundthron | Gestein | Flächenschaden 1.5-fach |
| Traumhain | Gedankenthron | Psycho | stärkt Nachbarn um 22 % Schaden |
| Firnfeld | Ewigthron | Eis | verlangsamt um 55 % für 2.6 s |
| Erzwerk | Ambossthron | Stahl | durchschlägt 26 Panzerung zusätzlich |
| Glanzwiese | Morgenthron | Fee | markiert Ziele (+28 % Schaden) |
| Nachtgrund | Finsterthron | Unlicht | richtet 22 % mehr Schaden an |
| Böenkuppe | Wirbelthron | Wind | feuert 45 % schneller, sieht 60 weiter |

## 6. Wilde

44 Arten. Größe, Zähigkeit und Tempo stehen in den Daten; hier
zählt das Aussehen.

| Name | Element | Gestalt | Besonderheit |
|---|---|---|---|
| Moosnipp | Pflanze | blob | — |
| Rankling | Pflanze | sprout | — |
| Dornborst | Pflanze | ox | gepanzert 4 |
| Glutwelp | Feuer | cat | — |
| Aschfalter | Feuer | moth | fliegt |
| Magmaul | Feuer | ox | gepanzert 6 |
| Pfützling | Wasser | drop | — |
| Salzflosse | Wasser | fish | — |
| Sturzflut | Wasser | blob | heilt |
| Zippel | Elektro | crystal | — |
| Voltschwinge | Elektro | bird | fliegt |
| Sturmhorn | Elektro | fox | — |
| Kieselklotz | Gestein | crystal | gepanzert 7, Schild |
| Klippkralle | Gestein | ox | gepanzert 12 |
| Monolithor | Gestein | crystal | gepanzert 18, zäh |
| Irrlicht | Psycho | wisp | fliegt |
| Mesmirr | Psycho | owl | — |
| Enigmotte | Psycho | moth | fliegt |
| Knospling | Pflanze | blob | — |
| Schildling | Wasser | crystal | Schild |
| Grimmborst | Gestein | ox | gepanzert 10 |
| Flöckling | Eis | zottel | — |
| Raureifer | Eis | crystal | Rang 1 |
| Firnbär | Eis | zottel | gepanzert 5, Schild, Rang 2 |
| Eisschwinge | Eis | moth | fliegt, Rang 1 |
| Nietkäfer | Stahl | bolzen | gepanzert 7 |
| Walzling | Stahl | bolzen | gepanzert 13, zäh, Rang 2 |
| Spanling | Stahl | crystal | gepanzert 5, Rang 1 |
| Graupler | Eis | blob | — |
| Eisnadel | Eis | crystal | — |
| Federstahl | Stahl | moth | fliegt, gepanzert 3 |
| Schraubling | Stahl | wisp | gepanzert 2 |
| Glimmling | Fee | wisp | fliegt |
| Tanzmotte | Fee | moth | fliegt |
| Feenbalg | Fee | blob | Schild |
| Prunkfalter | Fee | moth | fliegt |
| Nachtschlick | Unlicht | blob | — |
| Düsterfalter | Unlicht | moth | fliegt |
| Grufthund | Unlicht | fox | — |
| Schlundaug | Unlicht | eye | gepanzert 8, zäh |
| Böling | Wind | wisp | fliegt |
| Fetzenflug | Wind | moth | fliegt |
| Sturmvogel | Wind | bird | fliegt |
| Wirbelbock | Wind | ox | gepanzert 4 |

### Anführer

Deutlich größer und zäher, mit einer Fähigkeit. Sie tragen einen Reif am
Boden, damit man sie im Gedränge findet.

| Name | Element | Gestalt | Fähigkeit |
|---|---|---|---|
| Vulkanox | Feuer | ox | stun, alle 6.5 s |
| Abyssgrund | Wasser | fish | cleanse, alle 5 s |
| Titanwurz | Pflanze | sprout | summon, alle 7 s |
| Fulmax | Elektro | bird, fliegt | haste, alle 8 s |
| Gorgolith | Gestein | crystal | shield, alle 9 s |
| Somnul | Psycho | eye | stun, alle 5 s |
| Glazior | Eis | zottel | shield, alle 8 s |
| Amboloss | Stahl | bolzen | stun, alle 7 s |
| Sylphara | Fee | wisp, fliegt | shield, alle 7 s |
| Umbraxis | Unlicht | eye | stun, alle 6 s |
| Zephyron | Wind | bird, fliegt | haste, alle 7 s |

## 7. Gestalten im Einzelnen

Jede Gestalt wird von mehreren Arten geteilt. Wer sie erzeugt, braucht sie
nur einmal — die Elementfarbe unterscheidet die Träger.

| Gestalt | Beschreibung |
|---|---|
| `bird` | Kleinvogel. Rundlicher Körper, schlagende Flügel, kurzer Schnabel, Schwanzfedern. |
| `blob` | Gallertwesen. Weiche Tropfenform, durchscheinend, wabbelnd, große Augen. |
| `bolzen` | Metallwesen. Kantige Platten mit abgeschrägten Ecken, Nieten, Visierschlitz statt Augen, Mittelgrat. |
| `cat` | Katzenartig. Gedrungener Rumpf, spitze Dreiecksohren, langer beweglicher Schweif, Schnurrhaare. |
| `crystal` | Kristall. Kantige Facetten, sechseckiger Umriss, innen heller. |
| `drop` | Wassertropfen. Oben spitz, unten breit, durchscheinend mit Lichtreflexen. |
| `eye` | Ein großes Auge. Wimpernkranz ringsum, wandernde Pupille, kein Körper. |
| `falke` | Greifvogelartig. Hoch und schmal, angelegte Schwingen, schmaler Kopf, Hakenschnabel, Augenstreif. |
| `fish` | Fischartig. Spindelförmig, Schwanzflosse, Rückenflosse, Brustflossen, Schuppen. |
| `fox` | Fuchsartig. Schlanker als die Katze, sehr große spitze Ohren, buschiger Schweif, keilförmige Schnauze. |
| `moth` | Falterartig. Schmaler Leib, zwei große gemusterte Flügelpaare, gefiederte Fühler, Flauschkragen. |
| `owl` | Eulenartig. Rund und gedrungen, Federohren, Gesichtsscheiben, kurzer Schnabel, angelegte Flügel. |
| `ox` | Ochsenartig. Breit und schwer, geschwungene helle Hörner, kurze Schnauze mit Nüstern, Rückenplatten. |
| `sprout` | Keimling. Runder Körper, zwei große Blätter als Ohren, Blattadern sichtbar. |
| `thron` | Der legendäre Wächter. Schwebt über dem Boden statt zu stehen, hat statt eines Gesichts einen leuchtenden Visierschlitz, trägt eine Krone aus frei kreisenden Elementsplittern und einen weiten Mantel ohne sichtbare Beine. |
| `wisp` | Irrlicht. Leuchtender Kern in einem weichen Schein, ohne feste Grenze, mit nachziehendem Schweif. |
| `zottel` | Pelztier. Runde Silhouette mit gezackter Fellkontur, kurze Ohrbüschel, Frosthauch. |

**Drei Erscheinungen je Gestalt.** Über allen Formen liegen drei
Merkmalssätze: schlicht, gescheckt (hellere Flecken, wärmerer Ton) und
gestreift (dunkle Querbänder, Stirnkamm, kühlerer Ton). Der Versatz bleibt
klein genug, dass die Familie erkennbar bleibt.

## 8. Karten

Elf Routen, je eine für ein baubares Element. Jede hat eigenen Boden, eigenen
Bewuchs, eigenes Wetter und einen eigenen Himmel.

### Grünpfad

- **Heimatelement:** Pflanze
- **Grad:** Ruhig
- **Boden:** `#1E3324` bis `#27422C`, Weg `#9C7B54`
- **Himmel:** `#3E5C6B` bis `#7C9689`
- **Bewuchs:** grass, bush, conifer, broadleaf, flower, mushroom, rock
- **Wetter:** pollen — Aufsteigende helle Pollenkörner, dazu wenige größere Leuchtpunkte. Warm, träge.
- **Sonderfelder:** 7× wasser, 6× kraft, 3× hoehe

### Glutschlucht

- **Heimatelement:** Feuer
- **Grad:** Fordernd
- **Boden:** `#241310` bis `#331914`, Weg `#9E7359`
- **Himmel:** `#3B1F1E` bis `#8F5238`
- **Bewuchs:** grass, rock, deadtree, crystalrock, vent
- **Wetter:** embers — Glut, die von unten aufsteigt und oben vergeht. Orange bis dunkelrot.
- **Sonderfelder:** 8× vulkan, 6× kraft, 3× hoehe

### Flutruine

- **Heimatelement:** Wasser
- **Grad:** Brutal
- **Boden:** `#1B2B3A` bis `#223447`, Weg `#6D7E8E`
- **Himmel:** `#33505F` bis `#7690A0`
- **Bewuchs:** grass, rubble, rock, pillar, pool, broadleaf
- **Wetter:** rain — Schräg fallende Tropfenstriche, zwei Geschwindigkeiten übereinander. Kühl, blaugrau.
- **Sonderfelder:** 5× wasser, 4× kraft, 5× hoehe

### Gewitterkamm

- **Heimatelement:** Elektro
- **Grad:** Fordernd
- **Boden:** `#2A2E3C` bis `#353B4C`, Weg `#8C8474`
- **Himmel:** `#2F3A52` bis `#6E7B96`
- **Bewuchs:** grass, rock, conifer, deadtree, bush, crystalrock, flower
- **Wetter:** storm — Stark geneigter Regen, dazu seltenes kurzes Wetterleuchten über der ganzen Fläche.
- **Sonderfelder:** 7× hoehe, 6× kraft, 4× wasser

### Steinkessel

- **Heimatelement:** Gestein
- **Grad:** Fordernd
- **Boden:** `#3A342C` bis `#463E34`, Weg `#A89478`
- **Himmel:** `#4A4038` bis `#8C7E6C`
- **Bewuchs:** rock, crystalrock, grass, bush, deadtree, rubble, pillar
- **Wetter:** dust — Bodennah waagerecht getriebene Körner, dazu breite Trübungsbahnen. Sandfarben.
- **Sonderfelder:** 6× hoehe, 6× kraft, 4× wasser

### Traumhain

- **Heimatelement:** Psycho
- **Grad:** Ruhig
- **Boden:** `#2E2440` bis `#3A2E50`, Weg `#9C8AB4`
- **Himmel:** `#4A3A62` bis `#9A86B4`
- **Bewuchs:** grass, mushroom, broadleaf, flower, bush, wisp
- **Wetter:** traum — Aufsteigende Motive, die ihre Farbe wechseln — Fliederrosa, Mint, Blassgold. Dazu sehr langsame breite Schwaden.
- **Sonderfelder:** 7× kraft, 5× wasser, 3× hoehe

### Firnfeld

- **Heimatelement:** Eis
- **Grad:** Fordernd
- **Boden:** `#3E4C5A` bis `#4E5E6E`, Weg `#B4BEC8`
- **Himmel:** `#54687E` bis `#AEC2D4`
- **Bewuchs:** conifer, rock, deadtree, crystalrock, grass, bush
- **Wetter:** snow — Langsam taumelnde helle Flocken, weich, mit seitlichem Driften.
- **Sonderfelder:** 7× wasser, 6× kraft, 4× hoehe

### Erzwerk

- **Heimatelement:** Stahl
- **Grad:** Brutal
- **Boden:** `#32363C` bis `#3E434A`, Weg `#8E8E92`
- **Himmel:** `#3A4048` bis `#7E868E`
- **Bewuchs:** rubble, rock, pillar, deadtree, crystalrock, grass
- **Wetter:** russ — Dunkle Flocken, die aus der Tiefe aufsteigen und dabei auskühlen: unten glühend, oben Asche. Am unteren Rand ein Essenschein.
- **Sonderfelder:** 5× hoehe, 6× kraft, 4× wasser

### Glanzwiese

- **Heimatelement:** Fee
- **Grad:** Ruhig
- **Boden:** `#3E3448` bis `#4C4058`, Weg `#C4A8B4`
- **Himmel:** `#6E5A72` bis `#C4A8BE`
- **Bewuchs:** flower, grass, broadleaf, bush, mushroom, wisp
- **Wetter:** sun — Schräge Lichtbahnen, die langsam über das Feld wandern, mit tanzenden Staubkörnern darin.
- **Sonderfelder:** 6× kraft, 5× wasser, 3× hoehe

### Nachtgrund

- **Heimatelement:** Unlicht
- **Grad:** Brutal
- **Boden:** `#1A1622` bis `#221E2E`, Weg `#6E6478`
- **Himmel:** `#1E1A2A` bis `#453C58`
- **Bewuchs:** deadtree, conifer, mushroom, rock, bush, wisp
- **Wetter:** fog — Breite, sehr weiche Schwaden, die waagerecht ziehen und den Grund verschlucken.
- **Sonderfelder:** 4× hoehe, 6× kraft, 5× wasser

### Böenkuppe

- **Heimatelement:** Wind
- **Grad:** Fordernd
- **Boden:** `#3A4A44` bis `#485A52`, Weg `#AEA890`
- **Himmel:** `#5A7280` bis `#A6C0C6`
- **Bewuchs:** grass, bush, conifer, rock, deadtree, flower
- **Wetter:** boen — Stoßweiser Wind: Eine Böe zieht in zwei Sekunden durch, dann Ruhe. Waagerechte Streifen und mitgerissene Blätter.
- **Sonderfelder:** 8× hoehe, 6× kraft, 4× wasser

## 9. Wetter

| Art | Beschreibung |
|---|---|
| `pollen` | Aufsteigende helle Pollenkörner, dazu wenige größere Leuchtpunkte. Warm, träge. |
| `embers` | Glut, die von unten aufsteigt und oben vergeht. Orange bis dunkelrot. |
| `rain` | Schräg fallende Tropfenstriche, zwei Geschwindigkeiten übereinander. Kühl, blaugrau. |
| `storm` | Stark geneigter Regen, dazu seltenes kurzes Wetterleuchten über der ganzen Fläche. |
| `snow` | Langsam taumelnde helle Flocken, weich, mit seitlichem Driften. |
| `fog` | Breite, sehr weiche Schwaden, die waagerecht ziehen und den Grund verschlucken. |
| `dust` | Bodennah waagerecht getriebene Körner, dazu breite Trübungsbahnen. Sandfarben. |
| `sun` | Schräge Lichtbahnen, die langsam über das Feld wandern, mit tanzenden Staubkörnern darin. |
| `russ` | Dunkle Flocken, die aus der Tiefe aufsteigen und dabei auskühlen: unten glühend, oben Asche. Am unteren Rand ein Essenschein. |
| `boen` | Stoßweiser Wind: Eine Böe zieht in zwei Sekunden durch, dann Ruhe. Waagerechte Streifen und mitgerissene Blätter. |
| `traum` | Aufsteigende Motive, die ihre Farbe wechseln — Fliederrosa, Mint, Blassgold. Dazu sehr langsame breite Schwaden. |

Es gibt zwei Familien: **weiche Schleier** (Nebel, Ruß, Sonne, Staub, Traum)
bedecken 5–20 Prozent der Fläche mit geringer Stärke; **scharfe Teilchen**
(Regen, Sturm, Böe, Pollen, Glut, Schnee) bedecken unter 2 Prozent, sind dort
aber deutlich sichtbar. Beide Familien braucht es — nur Schleier wirkt
verwaschen, nur Teilchen wirkt aufgeklebt.

## 10. Boden, Weg und Bewuchs

**Der Boden ist nirgends gleich.** Ein zusammenhängendes Feld bestimmt an
jeder Stelle die Fruchtbarkeit: Wo es satt ist, steht das Gras dichter,
länger und dunkler; wo es dürr ist, fällt jeder zweite Halm aus und die Erde
kommt durch. Als Übergang, nicht als Fleck.

**Der Weg ist getreten, nicht gezogen.** Zwei ausgetretene Rinnen, die
wandern und deren Tiefe an- und abläuft, sodass die Spur sich stellenweise
verliert. Die Kante ist keine Linie, sondern eine Zone: Buchten in Wegfarbe
greifen nach außen, Zungen in Bodenfarbe nach innen.

**Jede Pflanze hat ihren eigenen Ton.** Helligkeit ±13 Prozent, Wärme ±0,5.
Dreißig gleich grüne Kronen nebeneinander sind der künstlichste Zug an einem
Wald.

Bewuchsarten: grass, bush, conifer, broadleaf, flower, mushroom, rock, deadtree, crystalrock, vent, rubble, pillar, pool, wisp.

## 11. Klang

Alles heute prozedural. Was gebraucht würde:

| Ereignis | Charakter |
|---|---|
| Schuss je Element | kurz, elementtypisch — Feuer knackt, Wasser platscht, Elektro zischt |
| Treffer | trockenes Rauschen, sehr kurz |
| Gegner erledigt | weicher Abfall, beim Anführer tiefer und länger |
| Wächter setzen | zwei aufsteigende Töne |
| Entwickeln | aufsteigende Folge, drei Töne |
| Megaentwicklung | Siegfanfare mit Nachhall |
| Durchbruch | dumpfer Schlag, warnend |
| Welle gehalten | zwei helle Töne |
| Erfolg | zwei helle Töne, eine Quinte auseinander, plus Funkeln |
| Erweckung des Legendären | der längste Klang: tiefer Bordun, steigende Folge, Nachklang (3 s) |
| Niederlage | absteigende Folge, sägend |

Dazu Umgebung je Karte: Wald, Regen, Wind, Feuer, Höhle.

## 12. Hinweise für die Erzeugung

**Was zuerst gebraucht wird**, wenn nicht alles auf einmal entsteht:

1. Die 17 Gestalten, je in drei Stufen — das sind die Figuren, die man
   dauernd ansieht.
2. Die elf legendären Wächter — sie sind das Ziel des Spiels.
3. Boden und Weg je Karte.
4. Bewuchs.
5. Wetter.
6. Klang.

**Was nicht erzeugt werden muss:** Die Benutzeroberfläche. Sie besteht aus
Text und Flächen und bleibt besser gezeichnet als gerendert.

**Maßstab:** Eine Kachel ist 56 Pixel breit. Eine Kreatur steht 13 bis 19
Pixel hoch, ein Anführer bis 34. Ein Baum ragt bis 40 Pixel auf. In 3D
entspricht eine Kachel zwei Metern.

**Blickwinkel:** Das Spiel sieht schräg von oben auf eine gestauchte
Bodenebene (Faktor 0,78). Stehende Dinge heben diese Stauchung lokal wieder
auf — sie stehen aufrecht, während der Boden liegt. Wer Figuren erzeugt,
erzeugt sie **von vorn**, nicht von schräg oben.

