# Werkzeuge

Zehn Dateien, die zusammen das Spiel messbar machen.

## Schnellstart

```
node tools/testlauf.js
```

Spielt drei Runden je Karte durch und druckt, wie weit der Bot kam, woran
er scheiterte und welche Wächter die Arbeit gemacht haben.

Das dauert. Gemessen: fünf Läufe über alle elf Karten brauchen 25 Minuten,
drei entsprechend rund 15. Als die Karten noch vierzig Wellen hatten und es
drei davon gab, waren es zwei Minuten — die Zahl ist mit dem Spiel gewachsen.
Für den schnellen Blick zwischendurch lieber eine Karte einzeln:

```
node tools/testlauf.js --karte 2 --laeufe 3
```

Nach einer Änderung:

```
node tools/testlauf.js --vergleich
```

Zeigt, was sich gegenüber dem abgelegten Stand verschoben hat. Wenn das
Ergebnis passt, den neuen Stand festhalten:

```
node tools/testlauf.js --merken
```

Weitere Schalter: `--laeufe 5` für mehr Läufe, `--karte 0` für eine einzelne.

## Die zehn Teile

**`pruefstand.js`** lädt das Spiel aus `index.html` in Node und macht es
taktbar. Das Spiel braucht vom Browser wenig — 19 Zugriffe auf `document`,
13 auf `window`, zwei auf `localStorage`; alles davon wird durch Attrappen
ersetzt. Die Spiellogik läuft unverändert, aus derselben Datei, die auch
ausgeliefert wird. Deshalb misst der Prüfstand wirklich das Spiel und nicht
eine Nachbildung. Ein Lauf über hundert Wellen dauert Sekunden statt
Minuten, weil nichts gezeichnet wird.

**`bot.js`** spielt eine Runde. Er kennt Wasserstellen, Kraftfelder, Tag und
Nacht, die Megaentwicklung, Typenvorteile und die Feldwirkung des
Psycho-Wächters — und liest die kommende Welle vorher, so wie ein Spieler
auch.

**`testlauf.js`** führt mehrere Läufe aus, fasst zusammen und vergleicht
gegen einen früheren Stand.

**`varianten.js`** dreht einzelne Stellschrauben einer Karte und misst, was
dabei herauskommt — ohne `index.html` anzufassen. Nützlich, weil zwei Werte,
die beide „die Karte leichter machen", sich sehr verschieden verhalten
können: Auf der Flutruine war es eine Schwelle (unter 480 Startbeeren kam die
Runde nie in Gang, darüber schon), auf dem Nachtgrund half mehr Geld gar
nicht — 700 statt 470 Beeren ergaben unverändert Welle 34.

**`daten-nach-godot.js`** erzeugt `godot-3d/scripts/daten.gd` aus
`index.html`. Eine von Hand gepflegte zweite Fassung wäre binnen Tagen
falsch, ohne dass es jemandem auffiele.

**`pfad.js`** misst, ob der Trainerpfad trägt. Er spielt dieselbe Karte mit
verschiedenen Punktevorräten — null, 55, 220, 700 — und dreht dazu
`BEEREN_MULT` durch. Damit beantwortet er die einzige Frage, die über den
Aufbau des Spiels entscheidet: *Wie viel Fortschritt braucht man, um hundert
Wellen zu halten?* Weil `BEEREN_MULT` als `const` im Skript steht, lädt er
das Spiel je Wert einmal neu. Deshalb darf `index.html` während eines Laufs
nicht angefasst werden — sonst misst die obere Tabellenhälfte ein anderes
Spiel als die untere.

Mit `--feldzug` spielt er die ganze Kampagne durch: jede Karte mit genau
dem Punktevorrat, den die vorigen Karten abgeworfen haben. Das ist die
einzige Messung, die den Aufbau wirklich prüft — ein runder Vorrat von 220
auf Karte 11 sagt nichts, weil dort niemand mit 220 Punkten steht.

Er schlüsselt bewusst **je Karte** auf. Der zusammengeworfene Median verbirgt
genau das, worauf es ankommt: Bei `BEEREN_MULT 0,52` ohne Punkte hielt der
Grünpfad bis Welle 62 und der Traumhain bis 9 — beide sind als „Ruhig"
ausgewiesen. Der gemeinsame Median von 21 kam auf keiner der beiden Karten
vor.

**`invarianten.js`** prüft nach jedem Bild, ob der Spielzustand noch möglich
ist — nicht ob er gut ist. Neunzehn Regeln: Leben unter null, Gegner über
Höchstleben, zwei Wächter auf einem Feld, Wasser-Wächter auf dem Trockenen.
Solche Fehler werfen keine Ausnahme und drucken nichts; sie sind nur zu
sehen, wenn man im richtigen Moment auf den richtigen Wert schaut.

**`konzept-bauen.js`** erzeugt `KONZEPT-ASSETS.md` aus `index.html` — die
Beschreibung aller Wächter, Gegner, Karten und Farben für die
Assetgenerierung. Von Hand gepflegt wäre sie binnen Tagen falsch.

**`server.js`** liefert das Spiel über HTTP aus, damit `localStorage` sich
so verhält wie beim Spieler. Nicht `python3 -m http.server`: dessen
Argumentaufbau ruft beim Starten `os.getcwd()` auf und bricht ab, wenn die
Umgebung das Arbeitsverzeichnis nicht preisgibt — mit einer Meldung, die
aussieht, als läge es am Verzeichnis.

**`beitrag.js`** misst, was ein Wächter beiträgt — nicht nur, was er
austeilt. Die Schadensstatistik des Testlaufs sieht einen Wächter nicht,
der Gegner festhält, verlangsamt, markiert oder Nachbarn stärkt. Sie hat
mich deshalb zu dem Schluss verleitet, acht der elf Familien seien spät
wertlos. Gemessen mit Nebenwirkungen steht Eis ganz oben und Psycho auf
Platz fünf — beide hatten in der reinen Schadensstatistik unter sechs
Prozent.

## Was der Bot nicht kann

Wichtig zu kennen, bevor man seinen Zahlen glaubt:

- Er **baut nie um**. Steht ein Bodenwächter falsch, wenn eine Flugwelle
  kommt, bleibt er stehen. Ein Mensch würde entlassen und neu setzen.
- Er **ruft nie früher** eine Welle, verzichtet also auf den Frühstart-Bonus.
- Er nutzt **keine Zielauswahl** — jeder Wächter feuert auf den Ersten.
- Er spielt standardmäßig **ohne Talente des Trainerpfads**; der Spielstand
  wird vor jedem Lauf zurückgesetzt, damit die Läufe unabhängig bleiben.
  `opt.talente` gibt ihm einen Punktevorrat, den er vom billigsten Rang an
  gleichmäßig über alle Zweige verteilt — nicht optimal, sondern so, wie
  jemand ausgibt, der nichts durchgerechnet hat.
- Er **spart nicht**. Kann er keine Stufe bezahlen, kauft er den nächsten
  billigen Wächter. Das klingt nach einem Fehler und ist gemessen keiner:
  Eine Sparregel kostete auf dem Grünpfad sechzehn Wellen (40 → 24). Sie
  steht abgeschaltet in `bot.js` unter `opt.sparen`.

Er soll nicht optimal spielen, sondern wie jemand, der die Regeln verstanden
hat. Was er nicht schafft, ist für einen aufmerksamen Menschen vermutlich
auch schwer — aber der Umkehrschluss gilt nicht.

## Warum es den Vorgänger nicht mehr gibt

`autoplay-bot.js` lief in der Entwicklerkonsole des Browsers: Seite öffnen,
Datei einfügen, ausführen, Zahlen ablesen. Vor allem aber kannte er die
Regeln nicht mehr, die im Lauf der Zeit dazukamen. In einem gemessenen Lauf
nutzte er null Megaentwicklungen bei zwanzig Wächtern, baute fünf von zehn
Typen, keinen einzigen Wasser-Wächter bei vier Wasserfeldern, und neun seiner
zwanzig Wächter waren derselbe billige Typ. Was er maß, war seine eigene
veraltete Strategie.

## Neun Lehren aus dem Messen

Alle zeigen, wie leicht ein Messinstrument in die Irre führt — und jede
einzelne verschob die Ergebnisse um mehr als vierzig Wellen, ohne dass sich
am Spiel etwas geändert hätte.

**Segnungen.** Der erste Anlauf nahm keine einzige an — der Aufruf lief ins
Leere und der Fehler wurde stillschweigend verschluckt. Der Bot starb bei
Welle 32. Mit Segnungen kam er auf 40.

**Die Feldwirkung.** Der Psycho-Wächter macht selbst kaum Schaden, hebt aber
jeden Nachbarn um bis zu 28 Prozent. Wer nur den eigenen Schaden je Beere
rechnet, baut ihn nie. Nachdem der Bot die Feldwirkung mitrechnete, sprang
sein Ergebnis von Welle 40 auf 88 — dieselbe Spielfassung, nur ein
Messinstrument, das eine Regel mehr verstand.

**Der Abstand zum Weg.** Der Bot maß ihn über die Wegpunkte der Route statt
über den tatsächlichen Verlauf. Die Flutruine hat nur zehn Wegpunkte; ein
Feld, das 57 Pixel vom Weg entfernt lag, maß er als 177 und baute nicht
darauf. Ich stand kurz davor, die Feldverteilung der Karte zu ändern —
aufgrund einer Zahl, die mein Messgerät erfunden hatte. Gerettet hat nur die
Frage, ob mein Maß oder das Spiel falsch liegt.

**Nebenwirkungen.** Fläche, Bremse, Fessel, Brand, Kette, Marke,
Durchschlag — nichts davon zählte er. Der Wasser-Wächter hat den geringsten
Schaden je Beere im ganzen Spiel und eine der stärksten Flächenwirkungen; er
wurde nie gebaut. Nachdem die Nebenwirkungen mitzählten, ging die Flutruine
von Welle 38 auf 100.

**Und zweimal falscher Alarm aus zu wenigen Läufen.** „Glutschlucht bricht
bei Welle 40 ein" und „Flutruine nur bis 27" — mit fünf Läufen statt vier
lagen beide Mediane bei 97 und 100. Bei dieser Streuung trägt ein Median aus
vier Läufen keine Aussage.

**Und einmal beim Bau des Beitragsmessers, direkt danach.** Er zählte bei
jedem Treffer die volle Bremsdauer — aber Bremsen stapeln sich nicht, sie
setzen ein Maximum. Ein Wächter mit sechs Schuss je Sekunde trifft
denselben Gegner sechsmal, ohne dass sich dessen Bremszeit verlängert.
Eis kam dadurch auf das Siebenundvierzigfache seines Schadens. Dazu ein
geschätzter Umrechnungskurs, der um den Faktor zwei zu hoch lag.

Beides fiel nur auf, weil das Ergebnis offensichtlich absurd war. Ein
Messfehler, der ein *plausibles* Ergebnis liefert, bleibt liegen — das
ist der eigentliche Grund, Zahlen zu misstrauen, die man selbst erzeugt
hat.

**Und einmal ein Befund ohne Erklärung.** Die Flutruine scheiterte mit
sieben Kraftfeldern in fünf von acht Läufen, mit vier in null von acht. Der
Unterschied hielt über drei verschiedene Bewertungsfassungen des Bots — er
ist also echt.

Nur ergibt er keinen Sinn: Ein Kraftfeld gibt dreißig Prozent mehr
Reichweite und schränkt nichts ein. Mehr davon sollte eine Karte nicht
schwerer machen.

Meine Erklärung lag nahe: Der Bot bewertet Kraftfelder mit dem 1,9-fachen
der Wegabdeckung, obwohl sie nur dreißig Prozent Reichweite geben — er
stellt Wächter also auf Bonusfelder mit schlechter Lage. Ich habe die
Bewertung berichtigt, sodass der Suchradius um denselben Faktor wächst wie
die Reichweite, und nachgemessen: **sechs von acht statt fünf von acht.**
Schlechter. Die Berichtigung ist zurückgenommen.

Zwei Dinge daran sind wichtig. Erstens: Eine Änderung am Messgerät, deren
Begründung gut klingt, muss trotzdem gemessen werden — sonst tauscht man
einen unverstandenen Zustand gegen einen anderen. Zweitens: Ein
reproduzierbarer Befund ohne Erklärung ist ein unangenehmes, aber gültiges
Ergebnis. Er wurde umgesetzt (die Flutruine bekam vier Felder) und als
ungeklärt vermerkt, statt eine hübsche Geschichte darüberzulegen.

**Und einmal eine Erklärung, die beim Messen durchfiel — zum zweiten Mal.**
Mit gedrosseltem Beerenzufluss endete der Traumhain bei Welle 10: sieben
Wächter, alle auf Stufe 0, drei Familien. Die Erklärung lag auf der Hand —
der Bot kann nicht sparen, also kauft er in der Knappheit lauter billige
Wächter, statt für eine Stufe zurückzulegen. Ich habe ihm das Sparen
beigebracht, mit derselben Werteinheit für beide Optionen, und nachgemessen:

```
ohne Sparen   Grünpfad Welle 40,  Traumhain Welle 10
mit Sparen    Grünpfad Welle 24,  Traumhain Welle  9
```

Sechzehn Wellen schlechter. Vermutlich zählt früh die Abdeckung und nicht
die Stufe: Ein zweiter Wächter beschießt einen Wegabschnitt, den vorher
niemand sah; eine zweite Stufe beschießt nur härter denselben.

Dasselbe Muster wie beim Kraftfeld — eine gute Begründung, eine plausible
Änderung, ein schlechteres Ergebnis. Zweimal hintereinander ist kein Zufall
mehr, sondern eine Eigenschaft dieses Systems: Wer eine Erklärung hat, hat
noch keinen Befund.

**Und einmal die Turmgrenze des Bots als Befund verkleidet.** Auf der
Böenkuppe blieben bei Rang 39 noch 392.268 Beeren übrig. Mein Schluss: Ab
etwa Rang 40 tun die Wirtschaftszweige des Trainerpfads nichts mehr, weil
die Armee längst vollständig ist. Klingt zwingend — die Karte hat aber 187
freie Bauplätze, und der Bot hört bei 45 auf. Dieselbe Messung mit 100:

```
mul 13, höchstens  45 Wächter    Rang 62:  0/3
mul 13, höchstens 100 Wächter    Rang 62:  2/3
```

Aus sicherem Scheitern wird knappes Halten. Die überschüssigen Beeren
kaufen also sehr wohl noch Armee — wenn Platz da ist. Der Überschuss war zur
Hälfte eine Eigenschaft des Messgeräts.

**Und einmal ein Ergebnis, das zu glatt war, um Balance zu sein.** Nachdem
jede Karte ihre eigene Fauna bekam, endete der Grünpfad in jedem Lauf bei
*exakt* Welle 16 — oder bei 100. Nie dazwischen. Neun Wächterfamilien
schnitten schlechter ab als sieben.

Eine Schwierigkeitskurve sieht nicht so aus. Zwei Werte und nichts dazwischen
heißt: eine Bedingung, die erfüllt ist oder nicht. Die Runde endete mit zehn
Lebenspunkten und dreiundzwanzig ausgebauten Wächtern — also nicht an
Schwäche.

Es war die **Panzerung** des Anführers auf Welle 16. Sie wird je Treffer
abgezogen, nicht multipliziert, und trifft deshalb früh ungleich härter: Ein
Keimling mit zehn Schaden macht gegen Panzerung 11 noch 1,8, ein ausgebauter
Wächter mit 300 Schaden verliert kaum etwas. Der Grünpfad hatte durch seine
Fauna ausgerechnet die zwei bestgepanzerten Anführer im Vorrat, und ihre
Reihenfolge war die der Deklaration — also Zufall.

Die Lehre ist nicht "Panzerung beachten", sondern: **Eine Verteilung ohne
Mitte ist kein Balanceproblem.** Wenn ein Messwert nur zwei Zustände kennt,
sucht man nach einer Bedingung, nicht nach einer Zahl.

Wer hier weiterbaut, sollte bei jedem überraschenden Ergebnis zuerst fragen,
ob der Bot etwas nicht kennt, und erst danach, ob das Spiel unausgewogen ist.
Und die eigene Erklärung immer messen, bevor sie stehenbleibt. Dreimal an
einem Tag hat hier die Messung eine gut begründete Erklärung kassiert.
