#!/usr/bin/env node
/* ============================================================
   PocketBeast — Variantenprüfer
   ============================================================

   Dreht einzelne Stellschrauben einer Karte und misst, was dabei
   herauskommt. Ändert nichts an index.html — die Werte werden nur im
   geladenen Spiel gesetzt, für die Dauer der Messung.

   Zweck: Vor einer Balanceänderung wissen, welche Schraube wie stark wirkt.
   Zwei Werte, die beide "die Karte leichter machen", können sich sehr
   verschieden anfühlen: Mehr Startbeeren helfen nur am Anfang, ein
   niedrigerer Multiplikator wirkt über die ganze Runde.

   Aufruf:
     node tools/varianten.js --karte 2 --laeufe 4
   ============================================================ */

const path = require("path");
const { ladeSpiel } = require("./pruefstand.js");
const { spieleRunde } = require("./bot.js");

const WURZEL = path.join(__dirname, "..");
const TUERME_MAX = 45;

function arg(name, standard) {
  const i = process.argv.indexOf("--" + name);
  if (i === -1) return standard;
  const v = process.argv[i + 1];
  return v && !v.startsWith("--") ? v : true;
}

function median(z) {
  if (!z.length) return 0;
  const s = z.slice().sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

function balken(anteil, breite) {
  const n = Math.round(Math.max(0, Math.min(1, anteil)) * breite);
  return "█".repeat(n) + "░".repeat(breite - n);
}

/* Eine Variante messen. Die Karte wird vor dem Lauf verstellt und danach
   auf ihre Ausgangswerte zurückgesetzt — sonst schleppte jede Messung die
   Änderungen der vorigen mit sich. */
function messe(spiel, kartenIdx, aenderung, laeufe) {
  const karte = spiel.MAPS[kartenIdx];
  const alt = { mul: karte.mul, gold: karte.gold, lives: karte.lives };
  Object.assign(karte, aenderung);

  const ergebnisse = [];
  for (let i = 0; i < laeufe; i++) {
    ergebnisse.push(spieleRunde(spiel, kartenIdx, { maxTuerme: TUERME_MAX }));
  }
  Object.assign(karte, alt);

  return {
    welle: median(ergebnisse.map((r) => r.welle)),
    min: Math.min(...ergebnisse.map((r) => r.welle)),
    max: Math.max(...ergebnisse.map((r) => r.welle)),
    tuerme: median(ergebnisse.map((r) => r.tuerme)),
    mega: median(ergebnisse.map((r) => r.mega)),
    typen: median(ergebnisse.map((r) => r.typen)),
    durch: ergebnisse.filter((r) => r.ergebnis === "durchgespielt").length,
  };
}

const kartenIdx = parseInt(arg("karte", "2"), 10);
const laeufe = parseInt(arg("laeufe", "4"), 10);

const spiel = ladeSpiel(path.join(WURZEL, "index.html"));
const karte = spiel.MAPS[kartenIdx];
const ist = { mul: karte.mul, gold: karte.gold, lives: karte.lives };

/* Die Varianten. Erst jede Schraube einzeln, damit sich ihre Wirkung
   ablesen lässt, dann Kombinationen. */
const varianten = [
  ["wie jetzt", {}],
  ["Multiplikator 1,75", { mul: 1.75 }],
  ["Startbeeren 560", { gold: 560 }],
  ["1,80 + 480 Beeren", { mul: 1.80, gold: 480 }],
];

console.log("");
console.log("Karte: " + karte.name + "   (" + laeufe + " Läufe je Variante)");
console.log("Ist-Zustand: Multiplikator " + ist.mul + ", " + ist.gold +
  " Startbeeren, " + ist.lives + " Leben");
console.log("");
console.log("Variante                    Welle    Spanne     Wächter  Mega  Typen");
console.log("─".repeat(74));

const t0 = Date.now();
for (const [name, aend] of varianten) {
  const r = messe(spiel, kartenIdx, aend, laeufe);
  console.log(
    name.padEnd(26) +
    String(r.welle).padStart(4) + "   " +
    balken(r.welle / 100, 12) + " " +
    (r.min + "–" + r.max).padEnd(8) + "  " +
    String(r.tuerme).padStart(4) + "  " +
    String(r.mega).padStart(4) + "  " +
    String(r.typen).padStart(4) +
    (r.durch ? "   " + r.durch + "× ganz durch" : "")
  );
}
console.log("─".repeat(74));
console.log("Dauer: " + ((Date.now() - t0) / 1000).toFixed(0) + " s");
console.log("");
