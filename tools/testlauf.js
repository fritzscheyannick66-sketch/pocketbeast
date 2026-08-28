#!/usr/bin/env node
/* ============================================================
   PocketBeast — Testlauf
   ============================================================

   Spielt das Spiel mehrfach durch und sagt, was dabei herauskam.

   Aufruf:
     node tools/testlauf.js                  drei Läufe je Karte
     node tools/testlauf.js --laeufe 5       fünf Läufe je Karte
     node tools/testlauf.js --karte 0        nur Grünpfad
     node tools/testlauf.js --merken         Ergebnis als Vergleichsstand ablegen
     node tools/testlauf.js --vergleich      gegen den abgelegten Stand prüfen

   Der Vergleich ist der eigentliche Zweck: Nach einer Änderung zeigt er, ob
   sich etwas verschoben hat, das nicht verschoben werden sollte. Eine
   Balanceänderung, die man für harmlos hält, verschiebt oft mehr als gedacht
   — und ohne Vorher-Nachher merkt man das erst, wenn jemand es spielt.

   Die Läufe würfeln. Ein einzelner Lauf sagt fast nichts; erst der Median
   über mehrere trägt eine Aussage. Deshalb steht in jedem Bericht auch die
   Streuung — wenn die groß ist, ist die Mitte wenig wert.
   ============================================================ */

const fs = require("fs");
const path = require("path");
const { ladeSpiel } = require("./pruefstand.js");
const { spieleRunde } = require("./bot.js");

const WURZEL = path.join(__dirname, "..");

/* Wie viele Wächter der Bot höchstens baut.

   Gemessen mit 22, 40 und 80: Bei 22 blieben 310.000 Beeren ungenutzt liegen
   und der Lauf endete bei Welle 82; bei 80 wurden alle hundert Wellen
   gehalten. Das Limit war also die Bremse, nicht die Balance.

   45 ist der Kompromiss: mehr als ein zurückhaltender Spieler baut, weniger
   als das Feld hergibt (129 Plätze liegen nah genug am Weg, um zu feuern).
   Wer die Grenze verschiebt, verschiebt das Ergebnis — deshalb steht sie
   hier oben und nicht irgendwo im Code. */
const TUERME_MAX = 45;
const STAND_DATEI = path.join(__dirname, "vergleichsstand.json");

function arg(name, standard) {
  const i = process.argv.indexOf("--" + name);
  if (i === -1) return standard;
  const v = process.argv[i + 1];
  return v && !v.startsWith("--") ? v : true;
}

function median(zahlen) {
  if (!zahlen.length) return 0;
  const s = zahlen.slice().sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

function balken(anteil, breite) {
  const n = Math.round(Math.max(0, Math.min(1, anteil)) * breite);
  return "█".repeat(n) + "░".repeat(breite - n);
}

/* ------------------------------------------------------------
   Läufe
   ------------------------------------------------------------ */
function fuehreAus(laeufeJeKarte, nurKarte) {
  const spiel = ladeSpiel(path.join(WURZEL, "index.html"));
  const karten = nurKarte !== null ? [nurKarte] : spiel.MAPS.map((_, i) => i);
  const bericht = { zeit: new Date().toISOString(), karten: [] };

  for (const idx of karten) {
    const laeufe = [];
    for (let n = 0; n < laeufeJeKarte; n++) {
      laeufe.push(spieleRunde(spiel, idx, { maxTuerme: TUERME_MAX }));
    }

    const wellen = laeufe.map((l) => l.welle);
    const geschafft = laeufe.filter((l) => l.ergebnis === "durchgespielt").length;

    /* Todesfallen: an welchen Wellen es besonders oft endet. Eine Welle, die
       in mehreren Läufen die letzte ist, ist keine Pechsträhne — dort stimmt
       etwas nicht. */
    const enden = {};
    for (const l of laeufe) if (l.ergebnis === "verloren") enden[l.welle] = (enden[l.welle] || 0) + 1;

    /* Lebensverlust je Welle, über alle Läufe gemittelt. Zeigt, wo es eng
       wird, bevor es tödlich wird. */
    const verlustJeWelle = {};
    for (const l of laeufe) {
      for (let i = 0; i < l.verlauf.length - 1; i++) {
        const w = l.verlauf[i].welle;
        const verlust = l.verlauf[i].lebenVorher - l.verlauf[i + 1].lebenVorher;
        if (verlust > 0) {
          if (!verlustJeWelle[w]) verlustJeWelle[w] = [];
          verlustJeWelle[w].push(verlust);
        }
      }
    }

    // Welche Typen tragen die Runde?
    const typSchaden = {};
    for (const l of laeufe) {
      for (const [id, d] of Object.entries(l.proTyp)) {
        typSchaden[id] = (typSchaden[id] || 0) + d.schaden;
      }
    }
    const schadenGesamt = Object.values(typSchaden).reduce((a, b) => a + b, 0) || 1;

    bericht.karten.push({
      name: spiel.MAPS[idx].name,
      /* Welche Typen auf dieser Karte überhaupt stehen dürfen.

         Ohne das meldete der Bericht auf der Glutschlucht dauerhaft
         "nie gebaut: water — prüfen, ob zu teuer oder zu schwach". Dort
         gibt es aber keine Wasserstellen, also KANN kein Wasser-Wächter
         gesetzt werden; das ist Absicht, kein Balanceproblem. Ein Werkzeug,
         das immer denselben Fehlalarm gibt, bringt einem bei, seine
         Warnungen zu überlesen. */
      setzbar: [...setzbareTypen(spiel, idx)],
      idx,
      laeufe: laeufe.length,
      geschafft,
      welleMedian: median(wellen),
      welleMin: Math.min(...wellen),
      welleMax: Math.max(...wellen),
      tuermeMedian: median(laeufe.map((l) => l.tuerme)),
      megaMedian: median(laeufe.map((l) => l.mega)),
      typenMedian: median(laeufe.map((l) => l.typen)),
      goldUebrigMedian: median(laeufe.map((l) => l.goldUebrig)),
      enden,
      verlustJeWelle: Object.fromEntries(
        Object.entries(verlustJeWelle)
          .map(([w, v]) => [w, +(v.reduce((a, b) => a + b, 0) / laeufe.length).toFixed(2)])
      ),
      typAnteil: Object.fromEntries(
        Object.entries(typSchaden)
          .map(([id, s]) => [id, +(s / schadenGesamt).toFixed(3)])
          .sort((a, b) => b[1] - a[1])
      ),
    });
  }
  return bericht;
}

/* Welche Wächtertypen lassen sich auf dieser Karte irgendwo setzen?

   Gefragt wird das Spiel selbst — für jeden Typ, ob es mindestens ein Feld
   gibt, das ihn aufnimmt. Eine Liste von Sonderfällen hier wäre dasselbe
   Problem eine Ebene höher: Sie ginge irgendwann auseinander. */
function setzbareTypen(spiel, kartenIdx) {
  spiel.newRun(kartenIdx, true);
  const frei = new Set();
  for (const def of spiel.TOWERS) {
    if (def.legendaer || frei.has(def.type)) continue;
    aussen:
    for (let c = 0; c < spiel.COLS; c++)
      for (let r = 0; r < spiel.ROWS; r++)
        if (spiel.canPlace(c, r) && spiel.darfHier(def.id, c, r)) { frei.add(def.type); break aussen; }
  }
  return frei;
}

/* ------------------------------------------------------------
   Ausgabe
   ------------------------------------------------------------ */
function drucke(bericht, alleTypen) {
  for (const k of bericht.karten) {
    console.log("");
    console.log("═".repeat(66));
    console.log("  " + k.name + "   (" + k.laeufe + " Läufe)");
    console.log("═".repeat(66));

    const anteil = k.welleMedian / 100;
    console.log("  Welle erreicht   " + balken(anteil, 30) + "  " +
      k.welleMedian + " / 100     (" + k.welleMin + "–" + k.welleMax + ")");
    console.log("  Durchgespielt    " + k.geschafft + " von " + k.laeufe);
    console.log("  Wächter          " + k.tuermeMedian +
      "   davon Mega " + k.megaMedian + "   Typen " + k.typenMedian);
    console.log("  Beeren übrig     " + k.goldUebrigMedian);

    const enden = Object.entries(k.enden).sort((a, b) => b[1] - a[1]);
    if (enden.length) {
      console.log("");
      console.log("  Endete bei Welle:");
      for (const [w, n] of enden.slice(0, 6)) {
        console.log("    W" + String(w).padStart(3) + "   " + "×".repeat(n) +
          (n > 1 ? "   ← wiederholt, keine Pechsträhne" : ""));
      }
    }

    const heikel = Object.entries(k.verlustJeWelle)
      .filter(([, v]) => v >= 0.6)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8);
    if (heikel.length) {
      console.log("");
      console.log("  Wellen mit Lebensverlust (Schnitt je Lauf):");
      for (const [w, v] of heikel) {
        console.log("    W" + String(w).padStart(3) + "   " + v.toFixed(1) + " Leben   " +
          balken(v / 6, 18));
      }
    }

    const typen = Object.entries(k.typAnteil).slice(0, 12);
    if (typen.length) {
      console.log("");
      console.log("  Anteil am Gesamtschaden:");
      for (const [id, a] of typen) {
        console.log("    " + id.padEnd(9) + balken(a, 22) + "  " + (a * 100).toFixed(1) + " %");
      }
      /* Die Typenliste wird abgelesen, nicht aufgeschrieben. Vorher stand
         sie fest im Code und kannte "wind" nicht — ein nie gebauter
         Wind-Wächter wäre nie aufgefallen. */
      const ungenutzt = [], gesperrt = [];
      for (const t of alleTypen) {
        if (t in k.typAnteil) continue;
        ((k.setzbar || []).includes(t) ? ungenutzt : gesperrt).push(t);
      }
      if (ungenutzt.length) {
        console.log("    nie gebaut: " + ungenutzt.join(", ") +
          "   ← prüfen, ob zu teuer oder zu schwach");
      }
      if (gesperrt.length) {
        console.log("    nicht setzbar: " + gesperrt.join(", ") +
          "   (kein passendes Feld auf dieser Karte)");
      }
    }
  }
  console.log("");
}

/* ------------------------------------------------------------
   Vergleich gegen den abgelegten Stand
   ------------------------------------------------------------ */
function vergleiche(neu) {
  if (!fs.existsSync(STAND_DATEI)) {
    console.log("Kein Vergleichsstand vorhanden. Mit --merken einen anlegen.");
    return;
  }
  const alt = JSON.parse(fs.readFileSync(STAND_DATEI, "utf8"));
  console.log("");
  console.log("═".repeat(66));
  console.log("  Vergleich gegen " + new Date(alt.zeit).toLocaleString("de-DE"));
  console.log("═".repeat(66));

  for (const k of neu.karten) {
    const v = alt.karten.find((x) => x.idx === k.idx);
    if (!v) { console.log("  " + k.name + ": kein Vorwert"); continue; }
    const d = k.welleMedian - v.welleMedian;
    const dm = k.megaMedian - v.megaMedian;
    const dt = k.typenMedian - v.typenMedian;

    const pfeil = d > 0 ? "▲" : d < 0 ? "▼" : "=";
    console.log("");
    console.log("  " + k.name);
    console.log("    Welle    " + v.welleMedian + " → " + k.welleMedian +
      "   " + pfeil + " " + (d >= 0 ? "+" : "") + d);
    console.log("    Mega     " + v.megaMedian + " → " + k.megaMedian +
      "   " + (dm >= 0 ? "+" : "") + dm);
    console.log("    Typen    " + v.typenMedian + " → " + k.typenMedian +
      "   " + (dt >= 0 ? "+" : "") + dt);

    /* Eine Verschiebung um mehr als fünf Wellen ist bei drei Läufen noch
       Zufall. Ab zehn lohnt das Hinsehen. */
    if (Math.abs(d) >= 10) {
      console.log("    ⚠ Deutliche Verschiebung — war das beabsichtigt?");
    }
  }
  console.log("");
}

/* ------------------------------------------------------------ */
const laeufe = parseInt(arg("laeufe", "3"), 10);
const karteArg = arg("karte", null);
const nurKarte = karteArg === null ? null : parseInt(karteArg, 10);

console.log("Spiele " + laeufe + " Läufe je Karte …");
const t0 = Date.now();
const bericht = fuehreAus(laeufe, nurKarte);
console.log("Fertig in " + ((Date.now() - t0) / 1000).toFixed(1) + " s");

/* Die Typen kommen aus dem Spiel. Legend bleibt draußen: Der legendäre
   Wächter ist eine Belohnung, kein Baustein — dass der Bot ihn nie baut,
   ist richtig und keine Meldung wert. */
drucke(bericht, Object.keys(ladeSpiel(path.join(WURZEL, "index.html")).TYPES)
  .filter((t) => t !== "legend"));

if (arg("vergleich", false)) vergleiche(bericht);
if (arg("merken", false)) {
  fs.writeFileSync(STAND_DATEI, JSON.stringify(bericht, null, 1));
  console.log("Vergleichsstand abgelegt: tools/vergleichsstand.json");
}
