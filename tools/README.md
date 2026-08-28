# Werkzeuge

Sechs Dateien, die zusammen das Spiel messbar machen.

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

## Die sechs Teile

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
- Er spielt **ohne Talente des Trainerpfads**; der Spielstand wird vor jedem
  Lauf zurückgesetzt, damit die Läufe unabhängig bleiben.

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

## Fünf Lehren aus dem Messen

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

Wer hier weiterbaut, sollte bei jedem überraschenden Ergebnis zuerst fragen,
ob der Bot etwas nicht kennt, und erst danach, ob das Spiel unausgewogen ist.
