# PocketBeast

Kreaturen-Tower-Defense. Eine einzelne HTML-Datei, kein Build, keine Abhängigkeiten,
**keine Asset-Dateien** — jede Grafik ist prozedural auf Canvas gezeichnet, jeder Klang
prozedural über WebAudio erzeugt. Was du siehst, steht als Code da.

## Spielen

**▶ [Im Browser spielen](https://fritzscheyannick66-sketch.github.io/pocketbeast/)**

Oder lokal — Datei doppelklicken, beziehungsweise:

```bash
open index.html
```

Läuft direkt über `file://`, ohne Server. Die einzige Netzwerkanfrage geht an
Google Fonts; ohne Internet greifen die Ersatzschriften.

Der Spielstand hängt an der Herkunft: Die online gespielte Runde und die lokal
geöffnete Datei führen getrennte Fortschritte.

## Was drin ist

| | |
|---|---|
| **11 Routen** | Je eine für jedes baubare Element, mit eigener Wegführung, eigenem Bewuchs und eigenem Wetter |
| **100 Wellen je Route** | Dreistufige Kurve: erst steil, dann zweimal abgeflacht — sonst wären die letzten dreißig Wellen unerreichbar |
| **11 Wächterfamilien** | Je drei Stufen, dazu eine vierte, die sich nicht kaufen lässt |
| **11 legendäre Wächter** | Einer je Route, verdient durch alle 100 Wellen |
| **12 Elementtypen** | Mit voller Wirksamkeitstabelle |
| **44 Gegnerarten, 11 Anführer** | Flieger, Gepanzerte, Heiler, Schilde, Beschwörer |
| **8 Wetter, 11 Fassungen** | Regen, Sturm, Böen, Schnee, Nebel, Staub, Ruß, Pollen, Glut, Sonne, Traum |

## Wie es sich spielt

**Typen** schlagen einander. Feuer zerlegt Pflanze, prallt an Wasser ab. Über
getroffenen Gegnern steht, ob der Treffer wirkt.

**Entwickeln statt vermehren.** Zwei entwickelte Wächter schlagen fünf schwache.
Auf der Endstufe geht es mit Training weiter, und wer einen Wächter über die
ganze Runde pflegt — 40 erledigte Gegner, Training 6 — erreicht die
**Megaentwicklung**.

**Der Ort entscheidet.** Wasser-Wächter stehen ausschließlich auf Wasserstellen.
Vulkanschlote nehmen nur Feuer auf. Erhöhungen geben Gestein und Wind mehr
Sicht. Jede Route kreuzt sich einmal selbst — dort feuert ein Wächter auf zwei
Abschnitte.

**Jede Route hat ein Heimatelement.** Dessen Wächter sind dort stärker — dessen
Wilde aber auch zäher. Auf dem Firnfeld ist Eis beides.

**Tag und Nacht** wechseln alle vier Wellen. Feen entwickeln sich nur bei Tag,
Unlicht nur bei Nacht.

**Sterne** zählen die höchste je gehaltene Welle, 100 je Route. Wer alle hält,
erweckt den legendären Wächter der Route — und erst mit ihm lässt sich ihr
**Endlosmodus** bestreiten. Dort werden übrige Beeren zu Trainerpunkten, und im
**Hain der Ahnen** lassen sich dauerhafte Aufwertungen kaufen.

## Steuerung

`Leertaste` Welle starten · `P` Pause · `1`–`9` Wächter wählen · `U` entwickeln ·
`V` entlassen · `Esc` abwählen

Am Handy zeigt der erste Tipp die Reichweite, der zweite setzt den Wächter.

## Dateien

| Datei | Inhalt |
|---|---|
| [index.html](index.html) | Das Spiel. Heißt so, damit GitHub Pages es direkt ausliefert. |
| [tools/](tools/) | Prüfstand, Bot und Messwerkzeuge — siehe [tools/README.md](tools/README.md) |
| [godot-3d/](godot-3d/) | Die 3D-Fassung, im Bau — siehe [godot-3d/README.md](godot-3d/README.md) |
| [ANALYSE.md](ANALYSE.md) | Was gemessen wurde, was sich als Messfehler herausstellte |
| [daten/](daten/) | Gemessene Wellenkurven, vor und nach dem Balance-Fix |
| [pocketbeast.original.html](pocketbeast.original.html) | Fassung vor dem Balance-Fix, zum Vergleich |
| [godot-prototyp/](godot-prototyp/) | Erster Godot-Versuch, abgelöst durch `godot-3d/` |

## Werkzeuge

Das Spiel lässt sich ohne Browser durchspielen. `tools/pruefstand.js` lädt
`index.html` in Node, `tools/bot.js` spielt eine Runde, `tools/testlauf.js`
misst über alle Karten:

```bash
node tools/testlauf.js --laeufe 5
```

Das dauert etwa 25 Minuten und sagt, wie weit jede Karte trägt. `tools/varianten.js`
dreht einzelne Stellschrauben, ohne `index.html` anzufassen.

**Der Bot ist ein Messgerät, und Messgeräte gehen kaputt.** Drei seiner blinden
Flecken haben die Ergebnisse um jeweils über vierzig Wellen verschoben, ohne dass
sich am Spiel etwas geändert hätte. Wer ihm glaubt, ohne zu prüfen, ob er selbst
oder das Spiel falsch liegt, ändert die falsche Sache. Die Fälle stehen in
[ANALYSE.md](ANALYSE.md) — sie sind lehrreicher als die Befunde.

## Zwei Fassungen

Das Browserspiel ist die maßgebliche Fassung. Die Godot-Fassung zieht nach:
`node tools/daten-nach-godot.js` erzeugt `godot-3d/scripts/daten.gd` aus
`index.html`. Eine von Hand gepflegte zweite Fassung wäre binnen Tagen falsch,
ohne dass es jemandem auffiele.

## Speicherstand

Fortschritt liegt in `localStorage` unter `wildwacht.v1` — der Schlüssel trägt
noch den früheren Namen, damit vorhandene Spielstände die Umbenennung überlebt
haben. Getrennt pro Herkunft: Die Datei über `file://` zu öffnen ergibt einen
anderen Stand als über einen Server. Zurücksetzen im Hauptmenü über
„Fortschritt zurücksetzen".

## Historie

Die ausführliche Fassung steht in der Git-Historie; hier nur die Wendepunkte.

- **Wellenstärke schwankte um Faktor 6** zwischen benachbarten Wellen, je nachdem
  welche Arten der Zufall zog. Die Abweichung von der Sollkurve liegt jetzt bei 1,00.
- **Bosswellen kamen zusätzlich** zur vollen Welle und sprangen aufs 2,7-fache.
  Boss und Gegner teilen sich jetzt ein Budget.
- **Heilung stapelte sich unbegrenzt.** Zwanzig Heiler heilten 24 % der Lebenskraft
  je Sekunde — mehr, als die meisten Aufstellungen austeilen. Beide „Brutal"-Karten
  kippten genau bei der Welle, in der der Heiler auftauchte. Gedeckelt auf 4,5 %.
- **Zurückgezogen:** Ein gemeldeter Gold-Überschuss ab Welle 20 war ein Messfehler
  meinerseits. Die Ökonomie ist gesund.

## Lizenz

[MIT](LICENSE) — benutzen, verändern und weitergeben ist erlaubt, auch
kommerziell. Einzige Bedingung: Der Copyright-Hinweis aus `LICENSE` bleibt
erhalten.

Zwei Dinge im Projekt stammen nicht von mir und fallen nicht unter diese Lizenz:

- **`icon.svg`** ist das Standard-Projektsymbol von Godot, das die Engine in jedes
  neue Projekt legt. Es gehört dem Godot-Projekt und steht unter
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- **Die Schriften** (Fraunces, Sora, JetBrains Mono) werden zur Laufzeit von Google
  Fonts geladen und liegen nicht in diesem Repository. Sie stehen unter der SIL Open
  Font License beziehungsweise der Apache-Lizenz 2.0.

Alles Übrige — Spielcode, Grafik, Klang, Dokumentation — ist eigenständig. Kreaturen,
Namen und Regeln sind frei erfunden und haben keinen Bezug zu bestehenden Marken.
