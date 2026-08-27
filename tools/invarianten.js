#!/usr/bin/env node
/* ============================================================
   PocketBeast — Invariantenprüfer
   ============================================================

   Spielt Runden durch und prüft nach JEDEM Bild, ob der Spielzustand noch
   Sinn ergibt. Nicht ob er gut ist — ob er möglich ist.

   Warum das ein eigenes Werkzeug braucht: Der Fehler "Leben fallen unter
   null" warf keine Ausnahme, druckte nichts in die Konsole und ließ das
   Spiel weiterlaufen. Er war nur zu sehen, wenn man in genau dem Moment auf
   genau diesen Wert schaute. Ein Testlauf, der nur misst wie weit der Bot
   kommt, geht daran vorbei — die Runde endete ja korrekt.

   Der Unterschied zu testlauf.js:

     testlauf.js    Wie GUT läuft es?   — Balance, Wellen, Wächterwahl
     invarianten.js Ist es MÖGLICH?     — Werte, die es nicht geben darf

   Aufruf:
     node tools/invarianten.js                 alle Karten, je 1 Runde
     node tools/invarianten.js --karte 2       nur eine
     node tools/invarianten.js --laeufe 3      mehr Runden je Karte
   ============================================================ */

const path = require("path");
const { ladeSpiel } = require("./pruefstand.js");
const { spieleRunde } = require("./bot.js");

const WURZEL = path.join(__dirname, "..");

function arg(name, standard) {
  const i = process.argv.indexOf("--" + name);
  if (i === -1) return standard;
  const v = process.argv[i + 1];
  return v && !v.startsWith("--") ? v : true;
}

/* ------------------------------------------------------------
   Die Regeln.

   Jede bekommt den Spielzustand und meldet, was nicht stimmt. Bewusst
   kleinteilig: "irgendwas ist kaputt" hilft niemandem, "G.lives = -2 in
   Welle 34" schon.

   Sie prüfen NUR Unmögliches. Dass ein Wächter wenig Schaden macht, ist
   Balance und gehört nicht hierher — dass er negativen Schaden macht, schon.
   ------------------------------------------------------------ */
function regeln(S) {
  const zahl = (v) => typeof v === "number" && Number.isFinite(v);

  return [
    ["Leben unter null", (G) => G.lives < 0 ? `lives = ${G.lives}` : null],
    ["Leben keine Zahl", (G) => !zahl(G.lives) ? `lives = ${G.lives}` : null],
    ["Beeren unter null", (G) => G.gold < 0 ? `gold = ${G.gold}` : null],
    ["Beeren keine Zahl", (G) => !zahl(G.gold) ? `gold = ${G.gold}` : null],
    ["Punkte keine Zahl", (G) => !zahl(G.score) ? `score = ${G.score}` : null],
    ["Punkte gesunken", (G, vor) => G.score < vor.score ? `${vor.score} → ${G.score}` : null],
    ["Welle über dem Ziel", (G) =>
      !G.endless && G.wave > S.WELLEN_JE_KARTE ? `wave = ${G.wave}` : null],
    ["Welle gesunken", (G, vor) => G.wave < vor.wave ? `${vor.wave} → ${G.wave}` : null],

    ["Gegner über Höchstleben", (G) => {
      for (const e of G.enemies) if (e.hp > e.max + 0.01)
        return `${e.spec.name}: ${e.hp.toFixed(1)} von ${e.max.toFixed(1)}`;
      return null;
    }],
    ["Gegner mit unmöglichem Leben", (G) => {
      for (const e of G.enemies) if (!zahl(e.hp) || !zahl(e.max) || e.max <= 0)
        return `${e.spec.name}: hp ${e.hp}, max ${e.max}`;
      return null;
    }],
    ["Gegner hinter dem Wegende", (G) => {
      const len = G.route && G.route.len;
      for (const e of G.enemies) if (len && e.d > len + 1 && !e.dead)
        return `${e.spec.name}: ${e.d.toFixed(0)} von ${len.toFixed(0)}`;
      return null;
    }],
    ["Gegner ohne Position", (G) => {
      for (const e of G.enemies) if (!zahl(e.x) || !zahl(e.y))
        return `${e.spec.name}: ${e.x}, ${e.y}`;
      return null;
    }],

    ["Wächterstufe außerhalb 0–2", (G) => {
      for (const t of G.towers) if (t.tier < 0 || t.tier > 2)
        return `${t.def.id}: tier ${t.tier}`;
      return null;
    }],
    ["Training über der Grenze", (G) => {
      for (const t of G.towers) if ((t.train || 0) > S.TRAIN_MAX + 0.001)
        return `${t.def.id}: train ${t.train} über ${S.TRAIN_MAX}`;
      return null;
    }],
    ["Wächter mit unmöglichem Schaden", (G) => {
      for (const t of G.towers) {
        const d = S.statDmg(t);
        if (!zahl(d) || d <= 0) return `${t.def.id}: ${d}`;
      }
      return null;
    }],
    ["Wächter mit unmöglicher Reichweite", (G) => {
      for (const t of G.towers) {
        const r = S.statRange(t);
        if (!zahl(r) || r <= 0) return `${t.def.id}: ${r}`;
      }
      return null;
    }],
    ["Zwei Wächter auf einem Feld", (G) => {
      const belegt = new Set();
      for (const t of G.towers) {
        const k = t.c + "," + t.r;
        if (belegt.has(k)) return `Feld ${k} doppelt belegt`;
        belegt.add(k);
      }
      return null;
    }],
    ["Wasser-Wächter außerhalb des Wassers", (G) => {
      for (const t of G.towers) {
        if (t.def.type !== "water") continue;
        if (S.feldArt(t.c, t.r) !== "wasser")
          return `${t.def.id} auf ${S.feldArt(t.c, t.r) || "gewöhnlichem Feld"} @${t.c},${t.r}`;
      }
      return null;
    }],
    ["Wächter auf dem Weg", (G) => {
      for (const t of G.towers) if (G.blocked && G.blocked.has(t.c + "," + t.r))
        return `${t.def.id} @${t.c},${t.r} steht auf der Route`;
      return null;
    }],
  ];
}

/* Sterne prüfen sich nach der Runde, weil sie im Spielstand liegen. */
function standRegeln(S, save) {
  const meld = [];
  for (let i = 0; i < S.MAPS.length; i++) {
    const st = S.sterne(i);
    if (st > S.WELLEN_JE_KARTE) meld.push(`Karte ${i}: ${st} Sterne über ${S.WELLEN_JE_KARTE}`);
    if (st < 0) meld.push(`Karte ${i}: ${st} Sterne`);
  }
  if (save.points < 0) meld.push(`Trainerpunkte ${save.points}`);
  return meld;
}

// ------------------------------------------------------------

const spiel = ladeSpiel(path.join(WURZEL, "index.html"));
const nurKarte = arg("karte", null);
const laeufe = parseInt(arg("laeufe", "1"), 10);
const karten = nurKarte !== null
  ? [parseInt(nurKarte, 10)]
  : spiel.MAPS.map((_, i) => i);

const proben = regeln(spiel);
const verstoesse = [];
let bilder = 0;

/* Der Bot spielt, und nach jedem Bild schauen wir hin. Das kostet Zeit,
   deshalb prüft der Testlauf das nicht mit — hier ist es der Zweck. */
const echterUpdate = spiel.update;
let vorher = null;

console.log("");
console.log("Invariantenprüfung — " + proben.length + " Regeln, " +
  karten.length + " Karte(n), " + laeufe + " Runde(n) je Karte");
console.log("");

for (const k of karten) {
  const name = spiel.MAPS[k].name;
  process.stdout.write("  " + name.padEnd(14));
  const vorZahl = verstoesse.length;

  spiel.update = function (dt) {
    const G = spiel.G;
    const vor = vorher || { score: G.score, wave: G.wave };
    echterUpdate.call(this, dt);
    bilder++;
    for (const [was, pruef] of proben) {
      let hinweis = null;
      try { hinweis = pruef(G, vor); } catch (e) { hinweis = "Prüfung selbst fehlgeschlagen: " + e.message; }
      if (hinweis) {
        // Jede Regel nur einmal je Karte melden — sonst füllt ein
        // durchgehender Fehler die Ausgabe mit tausend gleichen Zeilen.
        if (!verstoesse.some(v => v.karte === name && v.was === was))
          verstoesse.push({ karte: name, welle: G.wave, was, hinweis });
      }
    }
    vorher = { score: G.score, wave: G.wave };
  };

  for (let i = 0; i < laeufe; i++) {
    vorher = null;
    try {
      spieleRunde(spiel, k, { maxTuerme: 45 });
    } catch (e) {
      verstoesse.push({ karte: name, welle: spiel.G.wave, was: "Ausnahme", hinweis: e.message });
    }
    for (const m of standRegeln(spiel, spiel.save))
      if (!verstoesse.some(v => v.karte === name && v.hinweis === m))
        verstoesse.push({ karte: name, welle: spiel.G.wave, was: "Spielstand", hinweis: m });
  }

  spiel.update = echterUpdate;
  const neu = verstoesse.length - vorZahl;
  console.log(neu ? "✗ " + neu + " Verstoß(e)" : "✓");
}

console.log("");
console.log("Geprüfte Bilder: " + bilder.toLocaleString("de-DE"));

if (!verstoesse.length) {
  console.log("Keine Verstöße.");
  console.log("");
  process.exit(0);
}

console.log("");
console.log(verstoesse.length + " Verstöße:");
for (const v of verstoesse)
  console.log("  ✗ " + v.karte.padEnd(14) + "W" + String(v.welle).padStart(3) + "  " +
    v.was + " — " + v.hinweis);
console.log("");
process.exit(1);
