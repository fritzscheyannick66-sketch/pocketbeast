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
  /* Auch Sonderfelder und einzelne Wächterwerte lassen sich durchmessen.
     sonderfelder wird tief kopiert, sonst trüge die nächste Variante die
     Änderung der vorigen mit sich. */
  const alt = {
    mul: karte.mul, gold: karte.gold, lives: karte.lives,
    sonderfelder: karte.sonderfelder ? JSON.parse(JSON.stringify(karte.sonderfelder)) : undefined,
  };
  const towerAlt = [];
  if (aenderung.tower) {
    for (const [id, feld, wert] of aenderung.tower) {
      const def = spiel.TOWER_BY_ID[id];
      for (let i = 0; i < 3; i++) {
        towerAlt.push([id, i, feld, def.tiers[i][feld]]);
        def.tiers[i][feld] = Math.round(def.tiers[i][feld] * wert);
      }
    }
  }
  const kartenAend = Object.assign({}, aenderung);
  delete kartenAend.tower;
  Object.assign(karte, kartenAend);

  const ergebnisse = [];
  for (let i = 0; i < laeufe; i++) {
    ergebnisse.push(spieleRunde(spiel, kartenIdx, { maxTuerme: TUERME_MAX }));
  }
  Object.assign(karte, alt);
  for (const [id, i, feld, wert] of towerAlt) spiel.TOWER_BY_ID[id].tiers[i][feld] = wert;

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
  ["alle Reichweite +15 %", { tower: [["fire","range",1.15],["water","range",1.15],["grass","range",1.15],
    ["electric","range",1.15],["rock","range",1.15],["psychic","range",1.15],["ice","range",1.15],
    ["steel","range",1.15],["fairy","range",1.15],["dark","range",1.15],["wind","range",1.15]] }],
  ["Feuer+Stahl zurück", { tower: [["fire","range",1.35],["steel","range",1.38]] }],
  ["Nahkämpfer +25 %", { tower: [["fire","range",1.25],["steel","range",1.25],["grass","range",1.15],["dark","range",1.15]] }],
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
