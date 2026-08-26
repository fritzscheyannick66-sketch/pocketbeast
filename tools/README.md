# Werkzeuge

Drei Dateien, die zusammen das Spiel messbar machen.

## Schnellstart

```
node tools/testlauf.js
```

Spielt drei Runden je Karte durch — dauert etwa zwei Minuten — und druckt,
wie weit der Bot kam, woran er scheiterte und welche Wächter die Arbeit
gemacht haben.

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

## Die drei Teile

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

## Zwei Lehren aus dem Bau dieses Bots

Beide zeigen, wie leicht ein Messinstrument in die Irre führt.

**Segnungen.** Der erste Anlauf nahm keine einzige an — der Aufruf lief ins
Leere und der Fehler wurde stillschweigend verschluckt. Der Bot starb bei
Welle 32. Mit Segnungen kam er auf 40.

**Die Feldwirkung.** Der Psycho-Wächter macht selbst kaum Schaden, hebt aber
jeden Nachbarn um bis zu 28 Prozent. Wer nur den eigenen Schaden je Beere
rechnet, baut ihn nie. Nachdem der Bot die Feldwirkung mitrechnete, sprang
sein Ergebnis von Welle 40 auf 88 — dieselbe Spielfassung, nur ein
Messinstrument, das eine Regel mehr verstand.

Wer hier weiterbaut, sollte bei jedem überraschenden Ergebnis zuerst fragen,
ob der Bot etwas nicht kennt, und erst danach, ob das Spiel unausgewogen ist.
