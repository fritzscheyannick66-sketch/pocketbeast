#!/usr/bin/env node
/* ============================================================
   PocketBeast — Was ein Wächter wirklich beiträgt
   ============================================================

   Die Schadensstatistik in testlauf.js zählt ausgeteilten Schaden. Damit
   sieht sie einen Wächter nicht, der Gegner festhält, verlangsamt,
   markiert oder seine Nachbarn stärkt — und genau diese Blindheit hat mich
   zu dem Schluss verleitet, acht der elf Familien seien spät wertlos.

   Sie sind es nicht. Sie tun nur etwas anderes als Schaden.

   Dieses Werkzeug rechnet die Nebenwirkungen in dieselbe Einheit um wie den
   Schaden, damit sie vergleichbar werden. Das geht nicht exakt, aber
   nachvollziehbar:

     FELD        Der Psycho-Wächter hebt seine Nachbarn. Ohne ihn wäre ihr
                 Schaden um den Faktor (1 + aDmg) kleiner. Dieser Anteil
                 wird ihm gutgeschrieben. Nicht geschätzt — das Spiel
                 notiert bei jedem Treffer, wer die Verstärkung geliefert
                 hat.

     BREMSE      Ein Gegner, der zwei Sekunden lang halb so schnell läuft,
                 steht eine Sekunde länger im Feuer. Diese gewonnene
                 Standzeit wird mit dem gemessenen Schaden je Gegner-Sekunde
                 multipliziert — also mit dem, was ein Gegner in dieser Runde
                 tatsächlich je Sekunde eingesteckt hat.

     FESSEL      Dasselbe, nur mit voller Wirkung: Ein festgehaltener
                 Gegner bewegt sich gar nicht.

     MARKE       Wie viel Schaden durch die erhöhte Verwundbarkeit
                 zusätzlich anfiel.

   WAS DAS NICHT KANN
   Die Umrechnung nimmt an, dass gewonnene Standzeit auch genutzt wird.
   Steht ein Gegner dort fest, wo niemand hinfeuert, ist die Fessel wertlos
   — die Rechnung sieht das nicht und überschätzt Bremse und Fessel eher.

   Und sie nimmt an, dass sich der Schaden gleichmäßig über die Lebenszeit
   verteilt. In Wahrheit sterben viele Gegner in einem Feuerstoß, andere
   laufen lange unbehelligt. Der Kurs ist ein Mittelwert, kein Gesetz.

   Beides gehört mitgedacht, wenn man aus diesen Zahlen etwas ableitet.
   Sie sind ehrlicher als reiner Schaden, aber sie sind nicht die Wahrheit.

   Aufruf:
     node tools/beitrag.js                 zwei Karten, je zwei Läufe
     node tools/beitrag.js --karte 4       eine bestimmte
     node tools/beitrag.js --laeufe 3
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

const spiel = ladeSpiel(path.join(WURZEL, "index.html"));
const laeufe = parseInt(arg("laeufe", "2"), 10);
const nurKarte = arg("karte", null);
const karten = nurKarte !== null
  ? [parseInt(nurKarte, 10)]
  : [0, 5];   // Grünpfad und Traumhain — letztere ist die Heimat des Feld-Wächters

/* Die Messung einschalten. Ohne das zählt das Spiel keine Nebenwirkungen —
   im normalen Betrieb sollen diese Zeilen nichts kosten. */
spiel.G.messen = true;

const konten = {};   // typ -> { schaden, feld, bremse, fessel, marke, stueck }
let schadenGesamt = 0, gegnerSekunden = 0;

for (const k of karten) {
  for (let i = 0; i < laeufe; i++) {
    spiel.G.messen = true;
    spieleRunde(spiel, k, { maxTuerme: 45, behalteStand: false });
    spiel.G.messen = true;

    /* Der Umrechnungskurs, gemessen statt geschätzt: Gesamtschaden geteilt
       durch Gegner-Sekunden sagt, wie viel ein Gegner je Sekunde am Leben
       tatsächlich einsteckt. Genau so viel ist eine Sekunde mehr Standzeit
       wert.

       Ein erster Anlauf setzte hier die aufsummierte Feuerkraft aller
       fünfundvierzig Wächter an, mal einem geschätzten Anteil von zwanzig
       Prozent. Das ergab 5.833 Schaden je Bremssekunde und damit für Eis
       das Siebenundvierzigfache seines eigenen Schadens — offensichtlich
       Unsinn, aber erst beim Hinsehen als solcher erkennbar. */
    for (const t of spiel.G.towers) schadenGesamt += t.dealt || 0;
    gegnerSekunden += spiel.G.gegnerSekunden || 0;
    spiel.G.gegnerSekunden = 0;

    for (const t of spiel.G.towers) {
      const typ = t.def.type;
      const k2 = konten[typ] || (konten[typ] = {
        schaden: 0, feld: 0, bremse: 0, fessel: 0, marke: 0, stueck: 0,
      });
      k2.schaden += t.dealt || 0;
      k2.feld += t.feldWirkung || 0;
      k2.bremse += t.bremsWirkung || 0;
      k2.fessel += t.fesselWirkung || 0;
      k2.marke += t.markWirkung || 0;
      k2.stueck++;
    }
  }
}

/* Was ein Gegner je Sekunde einsteckt. Gemessen aus denselben Läufen. */
const kurs = gegnerSekunden > 0 ? schadenGesamt / gegnerSekunden : 0;

const zeilen = [];
for (const [typ, k] of Object.entries(konten)) {
  const bremse = k.bremse * kurs;
  const fessel = k.fessel * kurs;
  const gesamt = k.schaden + k.feld + bremse + fessel + k.marke;
  zeilen.push({ typ, ...k, bremseW: bremse, fesselW: fessel, gesamt });
}
zeilen.sort((a, b) => b.gesamt - a.gesamt);

const gesamtAlle = zeilen.reduce((a, z) => a + z.gesamt, 0) || 1;
const schadenAlle = zeilen.reduce((a, z) => a + z.schaden, 0) || 1;

function balken(anteil, breite) {
  const n = Math.round(Math.max(0, Math.min(1, anteil)) * breite);
  return "█".repeat(n) + "░".repeat(breite - n);
}
const pz = (x, g) => (x / g * 100).toFixed(1).padStart(5) + " %";

console.log("");
console.log("Beitrag je Wächterfamilie — " + karten.length + " Karte(n), " +
  laeufe + " Läufe je Karte");
console.log("Umrechnungskurs: " + Math.round(kurs) +
  " Schaden je Gegner-Sekunde (gemessen: " + Math.round(schadenGesamt).toLocaleString("de-DE") +
  " Schaden auf " + Math.round(gegnerSekunden).toLocaleString("de-DE") + " Gegner-Sekunden)");
console.log("");
console.log("Familie     nur Schaden   →   voller Beitrag        davon nicht Schaden");
console.log("─".repeat(78));
for (const z of zeilen) {
  const nurSch = pz(z.schaden, schadenAlle);
  const voll = pz(z.gesamt, gesamtAlle);
  const anders = z.gesamt - z.schaden;
  const teile = [];
  if (z.feld > 0) teile.push("Feld " + pz(z.feld, z.gesamt).trim());
  if (z.bremseW > 0) teile.push("Bremse " + pz(z.bremseW, z.gesamt).trim());
  if (z.fesselW > 0) teile.push("Fessel " + pz(z.fesselW, z.gesamt).trim());
  if (z.marke > 0) teile.push("Marke " + pz(z.marke, z.gesamt).trim());
  const pfeil = z.gesamt > z.schaden * 1.15 ? " ↑" : "  ";
  console.log("  " + z.typ.padEnd(9) + nurSch + "   " + balken(z.gesamt / gesamtAlle, 14) +
    " " + voll + pfeil + "  " + (teile.join(", ") || "—"));
}
console.log("─".repeat(78));

const gestiegen = zeilen.filter(z => z.gesamt > z.schaden * 1.15);
if (gestiegen.length) {
  console.log("");
  console.log("Die reine Schadensstatistik unterschätzt: " +
    gestiegen.map(z => z.typ + " (×" + (z.gesamt / Math.max(1, z.schaden)).toFixed(1) + ")").join(", "));
}
console.log("");
