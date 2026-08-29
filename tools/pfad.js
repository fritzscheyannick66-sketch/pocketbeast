#!/usr/bin/env node
/* ============================================================
   PocketBeast — Trägt der Trainerpfad?
   ============================================================

   Der Trainerpfad soll ein Versprechen sein: Was du in einer Runde erspielst,
   macht die nächste möglich. Nur hat das Versprechen nie eingelöst werden
   müssen — die Runden waren auch ohne ihn zu halten, und die Punkte häuften
   sich an, weil es nichts gab, wofür man sie gebraucht hätte.

   Dieses Werkzeug misst beide Enden derselben Frage:

   Gemessen wird gegen einen PUNKTEVORRAT, nicht gegen eine Stufe. Der Pfad
   hat kein Ende mehr, also gibt es kein "voll ausgebaut":

     0      Der erste Lauf eines neuen Spielers. Kein einziger Punkt.
     220    Ungefähr drei Anläufe: einer, der früh scheitert, einer, der
            weiter kommt, einer, der hält.
     700    Ein gewonnener Durchgang und seine Vorgeschichte.

   Kommt schon der Lauf mit null Punkten bis hundert, ist der Pfad Zierat.
   Kommt auch der mit 700 nicht durch, ist er eine Mauer. Dazwischen liegt
   das, was er sein soll.

   Weil BEEREN_MULT als const im Skript steht und sich von außen nicht mehr
   umsetzen lässt, wird das Spiel je Wert einmal neu geladen. Das kostet
   Sekunden und ist den Preis wert: gemessen wird dieselbe Datei, die auch
   im Browser läuft, nur mit einer anderen Zahl.

   ACHTUNG: Genau deshalb darf index.html während eines Laufs nicht geändert
   werden. Das Neuladen je Faktor holt jedes Mal den aktuellen Stand — eine
   Änderung mittendrin macht die obere Hälfte der Tabelle mit dem alten und
   die untere mit dem neuen Spiel. Die Zeilen sehen dann vergleichbar aus und
   sind es nicht. Einmal passiert; die Messung war zu verwerfen.

   Aufruf:
     node tools/pfad.js                          Ist-Zustand, beide Enden
     node tools/pfad.js --faktoren 0.7,0.55,0.45
     node tools/pfad.js --karten 0,3,9 --laeufe 4
     node tools/pfad.js --punkte 0,220,700
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
function liste(name, standard) {
  const v = arg(name, null);
  return v === null ? standard : String(v).split(",").map(Number);
}
function median(z) {
  if (!z.length) return 0;
  const s = z.slice().sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

const faktoren = liste("faktoren", null);
/* Feldzugsmodus: jede Karte mit genau den Punkten, die man beim Ankommen
   hätte. Nicht mit einem runden Vorrat, sondern mit der Summe dessen, was
   die vorigen Karten eingebracht haben.

   Das ist die einzige Messung, die den Entwurf wirklich prüft. Ein Vorrat
   von 220 auf Karte 11 sagt nichts — dort ist niemand mit 220 Punkten. Die
   Frage ist, ob die Kette trägt: Reicht, was Karte 1 bis 10 abgeworfen
   haben, für Karte 11? */
const feldzug = arg("feldzug", false);
const stufen = liste("punkte", liste("stufen", [0, 220, 700]));
const laeufe = parseInt(arg("laeufe", "4"), 10);
/* Drei Karten aus drei Schwierigkeitsstufen statt aller elf: Grünpfad ist
   die Einstiegsroute, Gewitterkamm liegt in der Mitte, Nachtgrund gehörte
   bei der letzten Prüfung zu den beiden, die einmal von acht Läufen
   scheiterten. Wer alle elf will, sagt es. */
const karten = liste("karten", [0, 3, 9]);

const NAME_STUFE = (s) => (s === 0 ? "ohne Punkte" : s + " Punkte");

function messe(faktor) {
  /* null heißt: Datei nehmen wie sie ist. Sonst die Konstante ersetzen —
     und prüfen, dass sie wirklich getroffen wurde. Ein stillschweigend
     wirkungsloser Umbau produzierte Zahlenreihen, in denen jede Zeile
     gleich aussieht, ohne dass der Grund sichtbar wäre. */
  const umbau = faktor === null ? null : (q) => {
    /* Geprüft wird, ob die Stelle GEFUNDEN wurde — nicht, ob sich der Text
       geändert hat. Der Unterschied ist keine Feinheit: Steht in der Datei
       schon der Wert, den die Reihe gerade misst, ändert die Ersetzung
       nichts, und eine Prüfung auf "Text ungleich" hielte den Normalfall für
       einen Fehler. Genau so ist der erste Lauf abgestürzt. */
    const stelle = /const BEEREN_MULT = [\d.]+;/;
    if (!stelle.test(q)) throw new Error("BEEREN_MULT nicht im Quelltext gefunden");
    return q.replace(stelle, `const BEEREN_MULT = ${faktor};`);
  };
  const spiel = ladeSpiel(path.join(WURZEL, "index.html"), umbau);

  const zeilen = [];
  for (const stufe of stufen) {
    /* Je Karte einzeln sammeln. Der zusammengeworfene Mittelwert verbirgt
       genau das, worauf es hier ankommt: Ein neuer Spieler faengt auf dem
       Gruenpfad an, nicht auf dem Nachtgrund. Steht dort Welle 40 und hier
       Welle 12, ist der Median von 21 eine Zahl, die auf keiner der beiden
       Karten je vorkommt. */
    const jeKarte = [];
    const alle = [];
    for (const k of karten) {
      const wellen = [], leben = [], gold = [];
      for (let i = 0; i < laeufe; i++) {
        const r = spieleRunde(spiel, k, {
          maxTuerme: TUERME_MAX,
          talente: stufe,
          behalteStand: false,
        });
        wellen.push(r.welle);
        leben.push(r.lebenUebrig);
        gold.push(r.goldUebrig);
        alle.push(r.welle);
      }
      jeKarte.push({
        name: spiel.MAPS[k].name,
        art: spiel.MAPS[k].diff,
        welle: median(wellen),
        min: Math.min(...wellen),
        durch: wellen.filter((w) => w >= 100).length,
        von: wellen.length,
        leben: median(leben),
        gold: median(gold),
      });
    }
    zeilen.push({
      stufe,
      welle: median(alle),
      durch: alle.filter((w) => w >= 100).length,
      von: alle.length,
      jeKarte,
    });
  }
  return zeilen;
}

function balken(w) {
  const n = Math.round(Math.max(0, Math.min(1, w / 100)) * 24);
  return "█".repeat(n) + "░".repeat(24 - n);
}

/* Was ein Durchgang über eine Karte an Trainerpunkten abwirft. Dieselbe
   Rechnung wie im Spiel, nur ohne zu spielen — sie hängt allein an der
   Wellenzahl und am Kartenindex. */
function ertrag(spiel, idx) {
  const faktor = 1 + idx * 0.2;
  let summe = 0;
  for (let w = 1; w <= spiel.WELLEN_JE_KARTE; w++) {
    const grund = Math.ceil(w / 4);
    summe += Math.round((spiel.isBossWave(w) ? grund * 6 : grund) * faktor);
  }
  return summe + Math.round(150 * faktor);
}

if (feldzug) {
  const spiel = ladeSpiel(path.join(WURZEL, "index.html"));
  const voll = spiel.TALENTS.length * (100 * 101 / 2);
  console.log("");
  console.log("Feldzug — jede Karte mit den Punkten, die man beim Ankommen hätte");
  console.log("Voller Pfad: " + voll.toLocaleString("de-DE") + " Punkte");
  console.log("");
  console.log("  Karte              mul   Vorrat   Rang   Welle" + " ".repeat(21) + " gehalten");
  console.log("  " + "─".repeat(86));
  let vorrat = 0;
  for (let i = 0; i < spiel.MAPS.length; i++) {
    const wellen = [];
    for (let n = 0; n < laeufe; n++)
      wellen.push(spieleRunde(spiel, i, {
        maxTuerme: TUERME_MAX, talente: vorrat, behalteStand: false,
      }).welle);
    const m = median(wellen);
    const durch = wellen.filter((w) => w >= 100).length;
    /* Der Rang, den der Vorrat gleichmäßig verteilt ergibt — die Zahl, die
       im Menü stünde. */
    let rang = 0, rest = vorrat;
    for (;;) {
      const preis = (rang + 1) * spiel.TALENTS.length;
      if (preis > rest) break;
      rest -= preis; rang++;
    }
    console.log("  " + (i + 1 + ". " + spiel.MAPS[i].name).padEnd(18) +
      String(spiel.MAPS[i].mul).padStart(5) +
      String(vorrat.toLocaleString("de-DE")).padStart(9) +
      String(rang).padStart(7) +
      String(m).padStart(8) + "  " + balken(m) +
      String(durch + "/" + wellen.length).padStart(7));
    vorrat += ertrag(spiel, i);
  }
  console.log("");
  console.log("  Nach allen elf Karten: " + vorrat.toLocaleString("de-DE") + " Punkte");
  console.log("");
  process.exit(0);
}

console.log("");
console.log("Trainerpfad — " + karten.length + " Karten, " + laeufe +
  " Läufe je Karte und Stufe (" + (karten.length * laeufe) + " Läufe je Zeile)");
console.log("");

const reihen = faktoren || [null];
for (const f of reihen) {
  const titel = f === null ? "BEEREN_MULT wie in der Datei" : "BEEREN_MULT " + f;
  console.log("  " + titel);
  console.log("  " + "─".repeat(74));
  for (const z of messe(f)) {
    console.log("  " + NAME_STUFE(z.stufe) + " — Median " + z.welle +
      ", " + z.durch + "/" + z.von + " bis Welle 100");
    for (const m of z.jeKarte) {
      console.log("    " + m.name.padEnd(14) + (m.art || "").padEnd(10) +
        String(m.welle).padStart(4) + "  " + balken(m.welle) +
        String(m.durch + "/" + m.von).padStart(7) +
        "  min " + String(m.min).padStart(3) +
        "  Leben " + String(m.leben).padStart(3) +
        "  übrig " + String(Math.round(m.gold)).padStart(7));
    }
    console.log("");
  }
}
