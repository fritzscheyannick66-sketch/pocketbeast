# Wildwacht

Kreaturen-Tower-Defense. Eine einzelne HTML-Datei, kein Build, keine Abhängigkeiten,
keine Asset-Dateien — Grafik ist prozedural auf Canvas gezeichnet, Sound prozedural
über WebAudio erzeugt.

## Spielen

Datei doppelklicken, oder:

```bash
open wildwacht.html
```

Läuft direkt über `file://`. Die einzige Netzwerkanfrage ist Google Fonts —
ohne Internet greifen die Fallback-Schriften.

## Dateien

| Datei | Inhalt |
|---|---|
| [wildwacht.html](wildwacht.html) | Das Spiel. ~2.900 Zeilen JS, 147 KB, standalone. |
| [wildwacht.original.html](wildwacht.original.html) | Fassung vor dem Balance-Fix, zum Vergleich. |
| [ANALYSE.md](ANALYSE.md) | Review: Performance, Balance, gefundene Schwachstellen. |
| [daten/](daten/) | Gemessene HP-Kurven aller 40 Wellen, vor und nach dem Fix. |
| [tools/autoplay-bot.js](tools/autoplay-bot.js) | Bot, der eine komplette Runde ohne Zutun durchspielt. |

## Steuerung

`Leertaste` Welle starten · `P` Pause · `1`–`6` Wächter wählen · `U` entwickeln ·
`V` entlassen · `Esc` abwählen

## Stand

Spielbar und vollständig.

**Behoben (24.08.2026):** Die Wellenstärke schwankte um bis zu Faktor 6 zwischen
benachbarten Wellen, je nachdem welche Gegnerarten der Zufall zog. Die Abweichung
von der Sollkurve liegt jetzt in jeder Welle bei exakt 1,00.

**Behoben (24.08.2026):** Bosswellen wurden zusätzlich zur vollen Welle gestellt und
sprangen dadurch um das 1,5- bis 2,7-fache der Vorwelle. Welle 24 kostete reproduzierbar
14–18 Leben und war die einzige Verlustwelle im ganzen Durchlauf. Boss und normale
Gegner teilen sich jetzt ein Budget; die Sprünge liegen bei 1,12–1,60.

**Aufgeräumt (24.08.2026):** Toter `flying`-Eintrag in der Typentabelle entfernt,
Artenwahl zieht ohne Zurücklegen (keine doppelten Gruppen mehr). Beides ohne
Balance-Änderung, gemessen.

**Zurückgezogen:** Der zuvor gemeldete Gold-Überschuss ab Welle 20 war ein Messfehler
meinerseits — die Ökonomie ist gesund. Details in [ANALYSE.md](ANALYSE.md).

**Kreuzungen (25.08.2026):** Jede Route kreuzt sich jetzt einmal selbst — als weiche
Schlinge, spitzwinklig oder als Straßenkreuzung. Wächter an der Kreuzung bestreichen
zwei Wegabschnitte und feuern doppelt. Das machte die Karten deutlich leichter,
ausgeglichen über eine höhere Wellenstärke (`mul` 1,25 / 1,5 / 1,95).

**Kreaturen (25.08.2026):** Die drei Entwicklungsstufen sehen jetzt unterschiedlich
aus — der Grundkörper bleibt gleich, Kranz, Kragen, Schulterplatten und ein Zeichen
des Elements kommen hinzu. Neue Typen **Eis** und **Stahl** mit eigenen Körperformen,
je einem Wächter, sieben Gegnerarten und zwei Bossen. Der Aufstieg wird animiert.
Bestand: 8 Wächter, 32 Gegnerarten, 8 Bosse.

**Gestaltung (24.08.2026):** Die drei Karten unterschieden sich nur in der Farbe —
gleiches rechteckiges Zickzack, gleicher flacher Boden, gleichmäßig gestreuter
Bewuchs. Jetzt hat jede Route eine Handschrift (mäandernder Waldweg / schroffe
Spalte / rechtwinkliger Straßenzug), der Bewuchs bildet Wäldchen und Lichtungen,
der Boden hat zwei Texturebenen, und die Wegkante franst aus. Balance gemessen
unverändert.

**Neu (24.08.2026):** Die Wellenvorschau zeigt jetzt das Kräfteverhältnis — eine Ampel
sagt, ob die Verteidigung die nächste Welle trägt, und jede Gegnerart bekommt ihren
Faktor. Die Schwellen sind an 120 gemessenen Wellen kalibriert. Reines Feedback, die
Balance ist nachweislich unverändert.

**Offen:** Der Übergang bleibt scharf — reicht die Feuerkraft, stirbt alles unterwegs;
reicht sie nicht, kommt fast alles durch. Das ist genretypisch und bewusst so gelassen;
die Vorschau warnt jetzt rechtzeitig davor. Siehe „Befund 4" in [ANALYSE.md](ANALYSE.md).

## Speicherstand

Talentpunkte und Fortschritt liegen in `localStorage` unter dem Schlüssel
`wildwacht.v1`, getrennt pro Herkunft. Die Datei über `file://` zu öffnen ergibt
also einen anderen Speicherstand als über einen lokalen Server. Zurücksetzen geht
im Hauptmenü über „Fortschritt zurücksetzen".
