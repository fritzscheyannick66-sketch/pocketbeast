# PocketBeast — Analyse

Stand: 25.08.2026 · Grundlage: [pocketbeast.html](pocketbeast.html) (Artifact-Version vom 24.08.2026)

Methode: Code gelesen, im Browser gespielt, danach mit einem Autoplay-Bot mehrere
komplette 40-Wellen-Runden auf allen drei Karten simuliert
(~2.500 simulierte Spielsekunden, rund 80 Wellen).

---

## Was das Spiel ist

Kreaturen-Tower-Defense, **~2.900 Zeilen Vanilla-JS in einer einzigen Datei**, ohne
Framework und ohne eine einzige Asset-Datei — alle Grafik ist prozedural auf Canvas
gezeichnet, aller Sound prozedural über WebAudio erzeugt.

| | |
|---|---|
| Elementtypen | 8, mit Effektivitätstabelle (`CHART`) — Eis und Stahl am 25.08. ergänzt |
| Türme | 8 Familien à 3 Stufen + 15 Trainingsstufen |
| Gegner | 32 Arten + 8 Bosse |
| Karten | 3 (Grünpfad / Glutschlucht / Flutruine) |
| Wellen | 40 pro Runde, Boss alle 8 |
| Systeme | Wellen-Launen, Segnungen (alle 5 Wellen), Meta-Talentbaum, Speicherstand |

---

## Was gut funktioniert

**Performance.** Gemessen bei 60 Türmen und 24 gleichzeitigen Gegnern:

| | |
|---|---|
| `update()` | 0,04 ms |
| `draw()` | 1,45 ms |
| **Frame gesamt** | **1,49 ms** |
| Kopfraum bei 1× | ~670 fps |
| Kopfraum bei 3× | ~640 fps |

Die Logik ist praktisch gratis, das Zeichnen dominiert — und selbst das ist bei
40× Kopfraum unkritisch. Auch mit 167 Türmen auf der Karte kein Einbruch.

**Robustheit.** Über ~2.500 simulierte Spielsekunden und rund 80 Wellen
**kein einziger Konsolenfehler**. `localStorage` ist sauber in `try/catch` gekapselt,
das Spiel läuft auch ohne Speicherzugriff durch.

**Handwerk.** Präsentation, Detailtiefe (Kombos wie „nass + Elektro leitet",
Türme mit Auren, sich teilende Gegner) und die deutsche Textarbeit sind auf
hohem Niveau und durchgehend konsistent.

---

## Befund 1: zackige Wellenkurve — **behoben**

> Status: gefixt am 24.08.2026, verifiziert. Details unten unter
> [Der Fix](#der-fix). Der Abschnitt beschreibt den Zustand davor.

Drei Bot-Runden, überall dasselbe Muster:

| Karte | Türme | Verlauf |
|---|---|---|
| Grünpfad | 20 | W1–32: **kein einziger Lebensverlust** → W33: −17 Leben → W39: tot |
| Grünpfad | 167 | W1–39: **kein einziger Lebensverlust** → W40: alle 20 auf einmal |
| Flutruine „Brutal" | 20 | W1–31: **exakt 15 Leben, nie einer verloren** → W32: alle 15 auf einmal |

Man verliert nie ein Leben, bis man plötzlich fast alle verliert. Es gibt kein
„es wird eng" — keine Phase, in der Spannung entsteht.

### Ursache

Die Ursache steht in `genWave()`. `waveHP()` liefert eine glatte Exponentialkurve:

```js
function waveHP(w, mul) {
  let base = 30 * Math.pow(1.16, Math.min(w, 10) - 1);
  if (w > 10) base *= Math.pow(1.135, w - 10);
  return base * mul;
}
```

Die tatsächliche Gesamt-HP einer Welle ist aber `waveHP(w) × s.hp` der
**zufällig gezogenen** Arten — und `s.hp` reicht von **0,7** (Aschfalter) bis
**5,2** (Monolithor), ein Faktor 7,4. Die Wellen-Launen multiplizieren mit
weiteren ×0,74 (Brut) bis ×1,7 (Koloss).

Gemessen als Abweichung von der Sollkurve (Vollständige Daten:
[daten/wellenkurve-gruenpfad.csv](daten/wellenkurve-gruenpfad.csv)):

```
W22  ×0.83   Glutwelp + Zippel
W24  ×6.29   Sturzflut + Enigmotte, Laune "Koloss", Boss Titanwurz
W33  ×4.30   Monolithor + Sturzflut        ← hier stirbt man
W36  ×0.88   Pfützling + Glutwelp + Aschfalter
```

**Faktor 6 Unterschied zwischen Nachbarwellen.** Welle 33 ist fünfmal härter als
Welle 36, die danach kommt. Welle 22 ist leichter als Welle 11. Die Kurve ist
nicht monoton — nach der Klippe kommt Erholung.

### Vorgeschlagener Fix

Das HP-Budget der Welle gegen den Durchschnitt der gezogenen `s.hp` normalisieren.
Dann bestimmt die Artenwahl nur noch die *Verteilung* (viele dünne vs. wenige dicke
Gegner), nicht mehr die Gesamtmenge — und die Kurve wird so glatt, wie `waveHP`
sie eigentlich meint. Eingriff: wenige Zeilen in `genWave()`.

Getrennt davon das Finale: Welle 40 springt von 420k auf 900k Gesamt-HP, weil dort
**zwei** Gorgolithe mit je 173.220 HP stehen:

```js
count: w >= 40 && w % 40 === 0 ? 2 : 1
```

---

## Der Fix

Umgesetzt in `genWave()`, zwei Stellen:

```js
function refSpecHP(w) {
  return 1.0 + 0.7 * Math.min(1, Math.max(0, (w - 1) / 11));
}
```

```js
const pickedAvg = picked.reduce((a, s) => a + s.hp, 0) / picked.length;
const norm = refSpecHP(w) / pickedAvg;
// ...
hp: hpBase * s.hp * norm,
```

Die Lebenspunkte jeder Gruppe werden so skaliert, dass die *mittlere* Zähigkeit der
gezogenen Arten immer der Referenz entspricht. Damit hängt die Stärke einer Welle
allein an `waveHP()`. Die Artenwahl bestimmt weiterhin die **Verteilung** — wenige
dicke Brocken oder viele dünne, was taktisch verschieden bleibt (Einzelziel gegen
Fläche) — aber nicht mehr die Gesamtmenge.

`refSpecHP` läuft glatt von 1,0 auf 1,7 über die ersten elf Wellen, parallel zur
Freischaltung der schwereren Arten. Eine feste Referenz von 1,7 hätte den Einstieg
verdoppelt (Welle 1 von 192 auf 408 HP); im Bot-Test kostete das gleich in den
ersten beiden Wellen 3 Leben. Mit der Rampe bleibt Welle 1 bei 240 HP.

### Ergebnis, gemessen

Abweichung von der Sollkurve jetzt **exakt 1,00 in jeder Welle** — außer wo die
Wellen-Launen bewusst eingreifen (0,74 bei „Brut", 1,70 bei „Koloss"). Die sollen
wirken: sie werden dem Spieler vor der Welle angekündigt.

Vorher/Nachher im Vergleich — die Ausreißer verschwinden in beide Richtungen:

| Welle | vorher | nachher | |
|---|---|---|---|
| W22 | 13.766 | 28.366 | war zu leicht → angehoben |
| W25 | 97.434 | 46.659 | war Ausreißer → gesenkt |
| W33 | 397.255 | 157.054 | tötete den Bot → gesenkt |
| W36 | 130.167 | 250.510 | war Erholung → angehoben |
| W39 | 420.145 | 396.803 | Endniveau bleibt erhalten |

Vollständig: [daten/wellenkurve-gruenpfad-vorher.csv](daten/wellenkurve-gruenpfad-vorher.csv)
gegen [daten/wellenkurve-gruenpfad-nachher.csv](daten/wellenkurve-gruenpfad-nachher.csv).

Verifiziert außerdem: drei komplette Bot-Runden auf allen Karten, **kein einziger
Konsolenfehler**, Darstellung und Spielablauf unverändert.

---

## Gestaltung: Gelände und Routen — **überarbeitet**

Die drei Karten unterschieden sich nur in der Farbe. Ihre Wege waren dasselbe
rechteckige Zickzack, der Boden eine flache Fläche mit weichen Flecken, der
Bewuchs gleichmäßig hingestreut. Man erkannte keine Karte an ihrer Form.

### Routen: jede Karte bekommt eine Handschrift

Zuerst musste eine technische Sperre fallen. `blockedTiles()` lief von Wegpunkt
zu Wegpunkt erst in Spalten-, dann in Zeilenrichtung und markierte damit eine
L-Form. Für rein achsenparallele Wege stimmte das zufällig — bei einem schrägen
Segment hätte die Sperre **neben** dem Weg gelegen, und man hätte Wächter mitten
auf die Route setzen können. Jetzt wird der Weg abgetastet und jedes Feld
gesperrt, dessen Mittelpunkt näher als eine halbe Wegbreite liegt. Das gilt für
jede Wegform. Verifiziert: für die alten Routen kommt exakt dasselbe heraus
(Grünpfad 2072 px, 204 freie Felder).

Dazu eine optionale Chaikin-Glättung (`smooth`), die aus einem Polygonzug einen
geschwungenen Weg macht. Damit:

| Karte | Charakter | Länge |
|---|---|---|
| Grünpfad | mäandernder Waldweg, geglättet, weiche S-Bögen | 2233 px |
| Glutschlucht | schroffe Spalte, spitze Winkel und Diagonalen, ungeglättet | 2588 px |
| Flutruine | Straßenzug, streng rechtwinklig, mit Kehre nach links | 2408 px |

Die Längen liegen einheitlich rund 8 % über den alten — gemessen ohne Wirkung auf
die Balance: der Bot endet auf denselben Wellen wie vorher (W40 / W30 / W27).

### Bewuchs in Gruppen statt gestreut

Vorher wurde für jedes Feld einzeln gewürfelt, was gleichmäßiges Rauschen ergibt.
Jetzt liegt ein Dichtefeld aus wenigen Gaußglocken über der Karte; jedes Zentrum
hat eine Leitart, damit ein Nadelwald nicht zum Mischmasch wird.

Zwei Dinge waren dabei nicht offensichtlich und wurden erst durch Messen klar:

1. **Feste Schwellen funktionieren nicht.** Wie stark sich die Zentren überlappen,
   ist Zufall — gemessen lag der Median einer Karte bei 1,52 bei Randwerten von
   0,23 bis 3,10. Meine ersten Schwellen lagen alle unter dem Median, also wurde
   fast überall gepflanzt (451 statt ~120 Objekte). Die Dichte wird jetzt gegen
   den Median der Karte normiert; damit heißt 1,0 überall dasselbe.
2. **Große Objekte brauchen kleine Ballungen.** „pool" wurde Leitart eines weiten
   Clusters und überzog die halbe Flutruine mit Pfützen. Der Radius richtet sich
   jetzt nach der Leitart — Gras darf Flächen füllen, Pfützen und Säulen bleiben
   ein Nest. Pfützen danach: 3 statt rund 40.

Ergebnis: konstant ~250 Objekte pro Karte, mit sichtbaren Wäldchen und echten
Lichtungen.

### Boden und Wegkante

Der Boden bestand aus 46 großen, weichen Ellipsen — die lasen sich wie
Nebelschwaden. Jetzt zwei Ebenen: 14 breite Lagen als Geländeform, darüber 150
kleine, kontrastreichere Sprenkel als Bodenkorn. Erst der Größenunterschied lässt
eine Fläche wie Grund wirken.

Die Wegkante war exakt gleichmäßig, weil der Weg aus übereinandergelegten Strichen
besteht. `drawPathFringe()` tastet den Weg ab, bestimmt die Normale und setzt
beidseits Tupfen — außen in Geländefarbe (Bewuchs wächst herein), innen in
Bodenfarbe (Erde wurde heraus getragen).

**Kosten:** Zeichnen 0,99 ms pro Bild (vorher 1,45 ms — die Fläche ist trotz mehr
Details günstiger geworden), Hintergrund einmalig 4,4 ms und danach gecacht.
Keine Konsolenfehler.

---

## Kreaturen: Individualität, neue Typen, Entwicklung — **umgesetzt**

Drei Anforderungen: sichtbar unterschiedliche Entwicklungsstufen, mehr Typen,
eine Animation des Aufstiegs.

### Entwicklungsstufen

Alle drei Stufen eines Wächters sahen identisch aus — nur die Größe wuchs
(`13 + tier * 1.7`). Jetzt trägt jede Stufe Aufsätze, während der **Grundkörper
unverändert bleibt**, damit die Art erkennbar bleibt:

| Stufe | Merkmale |
|---|---|
| 1 | Grundform |
| 2 | Stachelkranz über dem Kopf, Halskragen |
| 3 | höherer Kranz in Elementfarbe, Schulterplatten, Zeichen der Art, Bodenreif |

Das Zeichen der dritten Stufe richtet sich nach dem **Element**, nicht nach der
Körperform — Flamme, Flosse, Blatt, Zacke, Platte, Kugel, Kristall, Niete. So
unterscheiden sich zwei Wächter derselben Form deutlich.

Beim ersten Entwurf saß der Kranz auf Rückenhöhe und verschwand hinter dem
Körper — Stufe 2 war von Stufe 1 nicht zu unterscheiden. Er sitzt jetzt als
Halbkranz über der Kopflinie.

### Zwei neue Typen

**Eis** (`#7FDBF0`) und **Stahl** (`#A9BECD`), samt Effektivitätstabelle,
je einem Wächter, sieben Gegnerarten und zwei Bossen. Beide bekamen eine eigene
Körperform statt einer Umfärbung:

- **Zottel** (Eis): gezackte Pelzsilhouette mit Frosthauch
- **Bolzen** (Stahl): kantiger Plattenkörper mit Nieten und Visierschlitz

Der Stahl-Wächter führt `pierce` ein — festen Panzerungsdurchschlag, in
`damage()` vor der Segnung Steinbrecher verrechnet.

### Animation des Aufstiegs

Der Wächter sinkt kurz ein (×0,70), schießt über seine neue Größe hinaus
(×1,32) und schwingt ein; dazu ein Halo, eine Lichtsäule und Partikel in
Elementfarbe. Dauer 0,85 s.

Der erste Entwurf legte eine gefüllte weiße Scheibe über die Figur — im
entscheidenden Moment war der Wächter unsichtbar. Jetzt ist es ein Saum plus
weicher Radialverlauf, die Kreatur bleibt durchgehend lesbar.

### Zwei Balance-Fehler, die dabei aufgedeckt wurden

**1. Freischaltung ignorierte Panzerung.** Der Pool-Filter staffelte nur nach
Lebenspunkten. Der Nietkäfer (wenig HP, viel Panzerung) erschien dadurch ab
Welle 5 mit Panzerung 17 — bei Wächtern, die dort 10 bis 26 Schaden machen, und
da Panzerung fest pro Treffer abgezogen wird, praktisch unknackbar. Jetzt
entscheidet der höhere von HP- und Panzerungsstufe.

**2. Panzerung skalierte nicht mit der Kartenschwierigkeit.** `mul` erhöhte die
Lebenspunkte, ließ die Panzerung aber unberührt. Auf der schweren Route fiel sie
damit relativ weniger ins Gewicht als auf der leichten — die Routen **kehrten
ihre Rangfolge um**: die „brutale" Flutruine kam weiter als der „ruhige"
Grünpfad. Ein Fehler, der schon vorher bestand und durch die gepanzerten
Stahl-Arten erst sichtbar wurde.

Zusätzlich hob die Erweiterung den Panzerungsschnitt des Pools von 2,7 auf 3,7
(29 % → 39 % gepanzerte Arten). Das gleicht die HP-Normierung aus Befund 1
nicht aus, weil Panzerung fest abgezogen wird. Gegengesteuert durch gedämpfte
Werte und vier zusätzliche leichte Arten — Schnitt jetzt 2,88 bei 32 Arten.

### Ergebnis, gemessen

Je drei Bot-Läufe pro Route, Staffelung wieder korrekt:

| Route | Endwelle | vor der Erweiterung |
|---|---|---|
| Grünpfad (mul 1,0) | 40, 40, 40 | 40 |
| Glutschlucht (mul 1,22) | 38, 32, 32 | 30 |
| Flutruine (mul 1,5) | 31, 27, 27 | 27 |

Keine Konsolenfehler. Bestand jetzt: 8 Wächter, 32 Gegnerarten, 8 Bosse.

---

## Wegkreuzungen — **umgesetzt, mit erheblichem Balance-Eingriff**

Jede Route kreuzt sich jetzt einmal selbst. Technisch ging das ohne Umbau: der Weg
wird pro Lage als ein durchgehender Strich gezeichnet, Überschneidungen überlagern
sich dadurch sauber wie eine echte Kreuzung. `blockedTiles()` sperrt seit dem
Routen-Umbau ohnehin nach tatsächlicher Weglage, nicht nach Wegpunkten.

| Route | Kreuzung | Länge |
|---|---|---|
| Grünpfad | weiche Schlinge, geglättet | 2580 px |
| Glutschlucht | spitzwinklig, Diagonalen erhalten | 2995 px |
| Flutruine | rechtwinklige Straßenkreuzung | 2576 px |

### Warum das die Balance kippt

Eine Kreuzung schafft **Doppeldeckung**: Felder, von denen aus ein Wächter zwei
getrennte Wegabschnitte bestreicht und denselben Gegner zweimal beschießt.

| | Doppeldeckungsfelder |
|---|---|
| Grünpfad ohne Kreuzung | 9 |
| mit Kreuzung | 22–25 |

Das ist spielerisch gut — die Kreuzung wird zum wertvollsten Bauplatz und belohnt
gute Platzierung. Aber der Bot sortiert Bauplätze nach Wegabdeckung und setzt
deshalb **zuerst** dorthin. Gemessen, vor jedem Ausgleich:

| Route | ohne Kreuzung | mit Kreuzung |
|---|---|---|
| Grünpfad | 40 | 40 |
| Glutschlucht | 34 | 38 |
| Flutruine | 28 | 37 |

Neun Wellen Unterschied auf der schwersten Route. Dazu kommt, dass Kreuzungen
einen Rückläufer brauchen und den Weg dadurch verlängern — mehr Schusszeit obendrauf.

### Ausgleich

Die Wellenstärke wurde angehoben: `mul` von 1,0 / 1,22 / 1,5 auf **1,25 / 1,5 / 1,95**.
Empirisch kalibriert über je drei bis vier Bot-Läufe pro Kandidat; getestet wurden
sechs Wertepaare zwischen 1,25 und 1,6 für die erste Route.

Ergebnis (je drei Läufe): 40 / 24–32 / 32–39. Das Ziel war 40 / 34 / 28 — die
verbleibende Abweichung liegt innerhalb der Streuung des Bots, die bei diesen
Routen deutlich zugenommen hat (auf der Flutruine 32 bis 39 bei identischen
Bedingungen).

**Einordnung:** Der Bot spielt die Kreuzung optimal aus, weil er strikt nach
Wegabdeckung baut. Ein Mensch, der die Stelle nicht erkennt, bekommt eine
spürbar schwerere Runde als vorher. Wer sie erkennt, wird belohnt — genau das
ist die Absicht, aber der Sprung zwischen beiden Spielweisen ist jetzt größer.

### Nicht umgesetzt: echte Verzweigungen

Eine Gabelung, an der Gegner zwischen zwei Wegen wählen, wäre ein anderer Umbau:
`G.path` ist ein linearer Streckenzug, `pathAt(d)` bildet eine einzelne Strecke ab.
Verzweigungen bräuchten einen Wegegraph, eine Route pro Gegner und Anpassungen an
Wellenvorschau, Kräfteschätzung und Bot. Machbar, aber ein eigener Arbeitsschritt.

---

## Befund 4: keine Vorwarnung — **behoben, ohne Balance-Eingriff**

Nach den Kurvenfixes blieb ein Rest: der Spieler hält jede Welle mühelos, bis eine
ihn auf einen Schlag erledigt. Ich hatte das im vorigen Durchgang dem Boss
zugeschrieben („bindet alle Türme, halbe Welle läuft mit"). **Auch das war eine
Vermutung aus dem Code, keine Messung — und sie war falsch.**

Gemessen kommt der Massendurchbruch genauso ohne Boss vor:

```
Karte 1: W30 → 17 normale Gegner durch, kein Boss beteiligt
Karte 2: W27 → 14 normale Gegner durch, kein Boss beteiligt
```

Der wahre Grund ist der Sättigungspunkt: reicht die Feuerkraft, stirbt *alles*
unterwegs; reicht sie nicht, kommt *fast alles* durch. Bei 15–20 Startleben und
40+ Gegnern pro Welle heißt das Spielende.

### Entscheidung: an der Balance nichts ändern

Der scharfe Übergang ist genretypisch und die Balance ist nach den Fixes gut
kalibriert — Karte 0 endet je nach Lauf mit 0–11 Leben in Welle 40. Ein weiterer
Eingriff hätte etwas verschlimmbessert, das funktioniert.

Das eigentliche Problem ist kein Balance-, sondern ein **Feedback-Problem**: Der
Spieler hat keine Möglichkeit zu erkennen, dass es eng wird, bevor es zu spät ist.
Also habe ich das Feedback ergänzt und die Balance unangetastet gelassen.

### Die Wellenvorschau zeigt jetzt das Kräfteverhältnis

`estimateDefense()` rechnet aus, wie viel Schaden eine Gegnergruppe auf dem
gesamten Weg abbekommt, und stellt das ihren Lebenspunkten gegenüber:

- **Feuerzeit** je Wächter = (bestrichene Wegstrecke + Länge der Kolonne) ÷ Tempo
- **Schaden je Schuss** mit Typenvorteil, Flieger-Bonus und Rüstungsabzug
- **Flächen- und Kettenwirkung** über die Gegnerdichte (Abstand = `gap` × Tempo)

Eine Ampel über der Liste nennt die Lage, jede Gruppe bekommt ihren Faktor.

Die Schwellen sind **an gemessenen Läufen kalibriert**, nicht geschätzt — drei
Karten, 120 Wellen:

| | Wert |
|---|---|
| Wellen, bei denen etwas durchbrach | 0,58 – 1,54 |
| Median der gehaltenen Wellen | 3,11 |
| → Schwelle „reicht nicht" | unter 1,5 |
| → Schwelle „trägt" | ab 2,5 |

Verlauf eines vollständigen Durchgangs — der Trend ist das eigentliche Signal:

```
W5:2.5  W10:4.0  W12:1.6→2 durch  W20:3.7  W30:2.1  W35:1.8  W40:1.4→2 durch
```

Die erste Fassung der Formel rechnete pro Einzelgegner und lag systematisch zu
hoch (Werte 6–9, praktisch immer „grün"). Sie unterstellte, alle Wächter feuerten
auf denselben Gegner — bei 40 gleichzeitigen Wilden verteilt sich das Feuer.

**Balance nachweislich unverändert:** die Bosssprünge sind vor und nach dem Einbau
exakt identisch (1,60 / 1,51 / 1,51 / 1,29 / 1,12). Kosten: 0,41 ms, zweimal pro
Welle. Die Schätzung ist bewusst konservativ — Brand, Verlangsamung, Schilde und
Selbstheilung bleiben außen vor.

---

## Befund 2: die Flachheit bleibt — sie hat eine andere Ursache

**Das ist eine Korrektur meiner ersten Analyse.** Ich hatte „flach, dann Klippe" als
*einen* Befund beschrieben und beides der Zackigkeit zugeschrieben. Nach dem Fix
zeigt die Messung: es sind zwei getrennte Probleme. Die Zacken waren real und sind
weg — der Tod in Welle 33 im ersten Lauf war tatsächlich ein Zacken-Effekt. Aber die
generelle Flachheit ist **strukturell** und bleibt bestehen.

Der aussagekräftige Wert ist das Verhältnis von Wellenstärke zu Turmfeuerkraft
(`Wellen-HP ÷ Gesamt-DPS aller Türme`) — grob: wie viele Sekunden die gesamte
Verteidigung braucht, um eine Welle zu zerlegen. Bot mit 20 Türmen, Grünpfad:

```
W1: 4.6   W10: 6.1   W20: 10.3   W30: 33.8   W35: 57.2   W38: 85.1   W40: 176.1
```

Der Wert steigt jetzt sauber monoton — die Kurve tut, was sie soll. Aber Leben gehen
erst ab etwa 150 verloren. Die gesamte Gefahrenzone liegt damit zwischen Welle 39
und 40, alles davor läuft mit großem Sicherheitspuffer.

Die Ursache ist die Natur des Systems: solange die Feuerkraft reicht, stirbt *jeder*
Gegner vor dem Ziel (null Leckage); sobald sie nicht mehr reicht, kommt *fast alles*
durch. Der Übergang ist von sich aus scharf. Eine glatte HP-Kurve allein erzeugt
daraus keine Spannungsrampe.

### Was der Fix trotzdem gebracht hat

Auf den schwereren Karten entsteht jetzt eine echte Rampe mit Vorwarnung:

| Karte | vorher | nachher |
|---|---|---|
| Flutruine „Brutal" | W1–31 **exakt 15 Leben**, dann alle 15 auf einmal | W8 −5, W31 −9, dann W32 |
| Glutschlucht | — | W32 −5, dann W38 |
| Grünpfad | W1–39 ohne Verlust, dann W40 | unverändert ohne Verlust bis W40 |

Zwei von drei Karten warnen jetzt vor, bevor sie töten. Die leichteste Karte bleibt
bis zum Finale ungefährlich.

### Ansätze für den nächsten Schritt

1. **Mehr Startleben bei feinerer Leckage** — Teilverluste werden verkraftbar und
   bauen sich über mehrere Wellen auf, statt dass eine Welle sofort alles kostet.
2. ~~**Die Kurve früher steiler, später flacher**~~ → umgesetzt, siehe `waveHP()`:
   die Wachstumsrate fällt jetzt per Sigmoid von ×1,21 auf ×1,035 mit Wendepunkt
   bei Welle 26.
3. ~~**Das Finale entschärfen**~~ → erledigt durch den Bosswellen-Fix unten.

---

## Befund 3: Bosswellen lagen obendrauf statt im Budget — **behoben**

Nach den ersten beiden Fixes war die Kurve glatt, die Klippe aber nicht weg — sie war
nur von Welle 33 auf **Welle 24 gewandert**. Über fünf Wiederholungen kostete Welle 24
reproduzierbar **14–18 Leben** und war dabei die *einzige* Verlustwelle im ganzen Lauf.

### Ursache

Der Boss wurde zusätzlich zur vollen Welle gestellt:

```js
hp: waveHP(w, mul) * b.hp     // unabhängig vom Rest der Welle
```

Das ergab 33–93 % obendrauf und damit Sprünge von **1,5× bis 2,7×** gegenüber der
Vorwelle — unabhängig davon, wie glatt die Kurve darunter lief:

```
W8  2.71x     W16 2.06x     W24 1.85x     W32 1.49x     W40 1.69x
```

### Der Fix

Boss und normale Gegner teilen sich jetzt ein gemeinsames Budget. Die Bosswelle liegt
um `BOSS_SURGE` über der Kurve, davon entfällt `BOSS_SHARE` auf den Boss:

```js
const BOSS_SURGE = 1.20, BOSS_SHARE = 0.25;
const BOSS_REF = BOSSES.reduce((a, b) => a + b.hp, 0) / BOSSES.length;
```

`BOSS_REF` erhält die relative Stärke der Bosse untereinander (Vulkanox 0,82 …
Gorgolith 1,17). Ergebnis:

| | vorher | nachher |
|---|---|---|
| W8 | 2,71× | 1,60× |
| W16 | 2,06× | 1,51× |
| W24 | 1,85× | 1,51× |
| W32 | 1,49× | 1,29× |
| W40 | 1,69× | 1,12× |

### Warum die Werte moderat ausfallen

Sie sind **empirisch kalibriert**, je fünf Bot-Läufe pro Kandidat — nicht geschätzt.
Der erste Versuch (`1.35 / 0.45`) machte den Boss mit 68.746 HP sogar *stärker* als
vorher (53.141) und verschlechterte das Ergebnis.

Getestet wurden `0.45 / 0.38 / 0.34 / 0.30 / 0.28 / 0.25`. Bei allen Werten über 0,25
war das Ergebnis **bimodal**: Welle 24 kostete entweder 13–17 Leben oder null, nie
etwas dazwischen.

Der Grund ist strukturell — ein Boss-Durchbruch ist binär. Entweder die Feuerkraft
tötet ihn vor dem Ziel, oder er kommt durch. Und wenn er durchkommt, bindet er
sämtliche Türme (Zielmodus „Erster"), sodass die halbe Welle mitläuft: der Boss selbst
kostet 5 Leben, die durchlaufenden Gegner den Rest.

Höhere Werte machten das Spiel also nicht schwieriger, sondern nur zufälliger.

### Ergebnis, gemessen

Verluste verteilen sich jetzt über mehrere Wellen, statt sich in einer zu bündeln:

| Karte | vorher | nachher (3 Läufe, 20 Türme) |
|---|---|---|
| Grünpfad | nur W24 (−17) | W24+W32 · W24+W32 · W35+W39 |
| Flutruine | nur W24 | W24 · keine · W17+W22 |

Verifiziert: alle drei Karten, je drei Läufe mit 20 und 30 Türmen,
**kein einziger Konsolenfehler**, Darstellung und Spielablauf unverändert.

> **Einordnung:** Der Bot nutzt *keine* Typenvorteile — er rotiert stumpf durch die
> sechs Turmarten und setzt nach Wegabdeckung. Ein Spieler, der Feuer gegen Pflanze
> stellt, macht doppelten Schaden. Die Bot-Zahlen sind damit eine Untergrenze, kein
> Spielerlebnis.

---

## Kleinere Punkte

### ~~Ökonomie kippt ab ~Welle 20~~ — **zurückgezogen, war ein Messfehler**

Ich hatte berichtet, der Bot habe durchgehend „2.000–6.000 Beeren übrig", weshalb Gold
aufhöre, eine Entscheidung zu sein. **Das war falsch.** Beim Nachmessen für den Fix
stellte sich heraus: der Fehler lag in meiner Messung, nicht im Spiel.

Zwei Ursachen:

1. **Falscher Messzeitpunkt.** Der Bot kaufte nur in den Wellenpausen, das Gold wurde
   aber *während* der Welle abgelesen. Gemessen wurde damit die Kaufkraft *vor* dem
   Einkauf, nicht der Rest *danach*.
2. **Leerlauf-Bug im Bot.** Seine Trainingsschleife prüfte `TRAIN_MAX` nicht und
   meldete Erfolg, obwohl `trainTower()` still abbrach. Die Abbruchsicherung griff
   nach 200 Leerläufen — mit unausgegebenem Gold.

Korrekt gemessen, direkt **nach** jeder Bauphase über einen ganzen Durchlauf:

```
W0:25  W1:3  W2:15  W5:76  W10:16  W15:17  W20:11  W25:176  W30:2  W35:538
```

Der Rest liegt durchgehend **unter der nächsten Kaufoption** (447–688 Beeren in der
Spätphase). Das Gold wird also vollständig ausgegeben, und der Ausbau sättigt nicht
einmal: Training erreichte Stufe 12 von 15.

**Die Ökonomie ist gesund. Hier ist nichts zu tun.** Ein Fix hätte das Spiel
verschlechtert.

### Toter Eintrag in der Typentabelle — **behoben**

```js
electric: { water: 2, flying: 2, ... }   // vorher
```

`CHART.electric.flying` wurde nie erreicht — `eff()` bekommt immer einen echten Typ
(`en.spec.type`), während `flying` eine Boolean-Eigenschaft der Spezies ist. Der
Flieger-Bonus läuft über eine Sonderregel in `damage()`:

```js
if (type === "electric" && en.flying) m *= 1.5;
```

Das Bestiarium weist korrekt 1,5× aus, die Tabelle rendert nur die sechs echten Typen —
das Spiel verhielt sich also richtig, nur der Code las sich falsch. Eintrag entfernt und
durch einen Kommentar ersetzt, der auf `damage()` verweist. **Keine Balance-Änderung.**

### Duplikate in der Artenwahl — **behoben**

```js
do { s = pool[Math.floor(rng() * pool.length)]; } while (picked.includes(s) && guard++ < 20);
```

Nach 20 Fehlversuchen konnte dieselbe Art zweimal in eine Welle gelangen. Ersetzt durch
Ziehen ohne Zurücklegen (der Pool ist mit mindestens 10 Arten immer größer als die
maximal 3 gezogenen).

Die Auswahl verschiebt sich dadurch — der Index bezieht sich jetzt auf den schrumpfenden
Restpool. Dank der Normierung aus Befund 1 ist das **stärkeneutral**: gemessen sind die
Bosssprünge exakt identisch (1,60 / 1,51 / 1,51 / 1,29 / 1,12), es kommen nur andere
Arten. Duplikate: 0 über alle 40 Wellen.

### Duplikate in der Artenwahl möglich

```js
do { s = pool[Math.floor(rng() * pool.length)]; } while (picked.includes(s) && guard++ < 20);
```

Nach 20 Fehlversuchen kann dieselbe Art zweimal in eine Welle gelangen. Rein
kosmetisch — die Gesamtzahl der Gegner stimmt weiterhin.

---

## Nicht als Problem bestätigt

- **Frühstart-Bonus stapeln** (`startWave()` bei laufender Welle) gibt Gold, bringt
  aber alle Gegner gleichzeitig — Risiko gegen Belohnung, funktioniert wie gedacht.
- **Segnung „Feilschen"** (100 % Rückerstattung) erlaubt kostenloses Umsetzen von
  Türmen, aber keinen Gold-Gewinn: `towerValue()` zählt nur tatsächlich Ausgegebenes
  (`trainSpent`), und die Gratis-Trainingsstufen aus „Feldtraining" erhöhen es nicht.
- **Rüstung** kann Schaden auf minimal 18 % drücken (`Math.max(d * .18, ...)`) —
  es gibt keine Immunität durch Stapeln.
