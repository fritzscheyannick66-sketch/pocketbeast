#!/usr/bin/env node
/* ============================================================
   PocketBeast — Assetkonzept erzeugen
   ============================================================

   Schreibt KONZEPT-ASSETS.md: eine vollständige Beschreibung aller Figuren,
   Karten, Wetter und Klänge des Spiels, brauchbar als Vorlage für die
   Erzeugung von Grafiken, Modellen und Ton.

   Warum erzeugt statt geschrieben: Das Spiel hat 11 Wächterfamilien mit je
   drei Stufen, 11 legendäre Wächter, 44 Gegnerarten, 11 Anführer und 11
   Karten. Von Hand gepflegt wäre die Liste binnen einer Woche falsch — die
   Namen und Werte ändern sich ständig. So genügt ein Aufruf:

     node tools/konzept-bauen.js

   Die Stilbeschreibung ist von Hand geschrieben und steht hier im Skript;
   die Tabellen kommen aus index.html.
   ============================================================ */

const fs = require("fs");
const path = require("path");
const { ladeSpiel } = require("./pruefstand.js");

const WURZEL = path.join(__dirname, "..");
const ZIEL = path.join(WURZEL, "KONZEPT-ASSETS.md");
const S = ladeSpiel(path.join(WURZEL, "index.html"));

/* Die Gaben stehen in den Daten als Wirkung, nicht als Satz. Hier werden sie
   in Worte gefasst — wer Assets erzeugt, muss wissen, was der Wächter TUT,
   damit sein Aussehen dazu passt. */
function gabeText(typ) {
  const g = (S.LEGENDAER_GABE || {})[typ];
  if (!g) return "—";
  if (g.root) return `hält Gegner fest (${Math.round(g.root.p * 100)} %, ${g.root.dur} s)`;
  if (g.burnMal) return `Brand wirkt ${g.burnMal}-fach`;
  if (g.slow) return `verlangsamt um ${Math.round(g.slow.amt * 100)} % für ${g.slow.dur} s`;
  if (g.chainPlus) return `Blitze springen ${g.chainPlus}-mal weiter`;
  if (g.splashMal) return `Flächenschaden ${g.splashMal}-fach`;
  if (g.aura) return `stärkt Nachbarn um ${Math.round(g.aura.dmg * 100)} % Schaden`;
  if (g.piercePlus) return `durchschlägt ${g.piercePlus} Panzerung zusätzlich`;
  if (g.mark) return `markiert Ziele (+${Math.round(g.mark * 100)} % Schaden)`;
  if (g.dmgMal) return `richtet ${Math.round((g.dmgMal - 1) * 100)} % mehr Schaden an`;
  if (g.ratePlus) return `feuert ${Math.round(g.ratePlus * 100)} % schneller, sieht ${g.rangePlus} weiter`;
  return "—";
}

const z = [];
const w = (t) => z.push(t === undefined ? "" : t);

/* Formbeschreibungen. Sie stehen hier, weil sie sich aus den Daten nicht
   ableiten lassen — im Spiel sind es Zeichenbefehle, keine Worte. */
const FORM = {
  cat: "Katzenartig. Gedrungener Rumpf, spitze Dreiecksohren, langer beweglicher Schweif, Schnurrhaare.",
  fox: "Fuchsartig. Schlanker als die Katze, sehr große spitze Ohren, buschiger Schweif, keilförmige Schnauze.",
  ox: "Ochsenartig. Breit und schwer, geschwungene helle Hörner, kurze Schnauze mit Nüstern, Rückenplatten.",
  falke: "Greifvogelartig. Hoch und schmal, angelegte Schwingen, schmaler Kopf, Hakenschnabel, Augenstreif.",
  owl: "Eulenartig. Rund und gedrungen, Federohren, Gesichtsscheiben, kurzer Schnabel, angelegte Flügel.",
  hueter: "Aufrechte Gestalt in einem Mantel. Gesenkter Kopf unter einer Kapuze, breite Schleppe, ein Ring über dem Haupt. Würde statt Drohung.",
  thron: "Der legendäre Wächter. Schwebt über dem Boden statt zu stehen, hat statt eines Gesichts einen leuchtenden Visierschlitz, trägt eine Krone aus frei kreisenden Elementsplittern und einen weiten Mantel ohne sichtbare Beine.",
  sprout: "Keimling. Runder Körper, zwei große Blätter als Ohren, Blattadern sichtbar.",
  drop: "Wassertropfen. Oben spitz, unten breit, durchscheinend mit Lichtreflexen.",
  crystal: "Kristall. Kantige Facetten, sechseckiger Umriss, innen heller.",
  moth: "Falterartig. Schmaler Leib, zwei große gemusterte Flügelpaare, gefiederte Fühler, Flauschkragen.",
  bird: "Kleinvogel. Rundlicher Körper, schlagende Flügel, kurzer Schnabel, Schwanzfedern.",
  fish: "Fischartig. Spindelförmig, Schwanzflosse, Rückenflosse, Brustflossen, Schuppen.",
  wisp: "Irrlicht. Leuchtender Kern in einem weichen Schein, ohne feste Grenze, mit nachziehendem Schweif.",
  eye: "Ein großes Auge. Wimpernkranz ringsum, wandernde Pupille, kein Körper.",
  zottel: "Pelztier. Runde Silhouette mit gezackter Fellkontur, kurze Ohrbüschel, Frosthauch.",
  bolzen: "Metallwesen. Kantige Platten mit abgeschrägten Ecken, Nieten, Visierschlitz statt Augen, Mittelgrat.",
  blob: "Gallertwesen. Weiche Tropfenform, durchscheinend, wabbelnd, große Augen.",
};

const WETTER = {
  pollen: "Aufsteigende helle Pollenkörner, dazu wenige größere Leuchtpunkte. Warm, träge.",
  embers: "Glut, die von unten aufsteigt und oben vergeht. Orange bis dunkelrot.",
  rain: "Schräg fallende Tropfenstriche, zwei Geschwindigkeiten übereinander. Kühl, blaugrau.",
  storm: "Stark geneigter Regen, dazu seltenes kurzes Wetterleuchten über der ganzen Fläche.",
  snow: "Langsam taumelnde helle Flocken, weich, mit seitlichem Driften.",
  fog: "Breite, sehr weiche Schwaden, die waagerecht ziehen und den Grund verschlucken.",
  dust: "Bodennah waagerecht getriebene Körner, dazu breite Trübungsbahnen. Sandfarben.",
  sun: "Schräge Lichtbahnen, die langsam über das Feld wandern, mit tanzenden Staubkörnern darin.",
  russ: "Dunkle Flocken, die aus der Tiefe aufsteigen und dabei auskühlen: unten glühend, oben Asche. Am unteren Rand ein Essenschein.",
  boen: "Stoßweiser Wind: Eine Böe zieht in zwei Sekunden durch, dann Ruhe. Waagerechte Streifen und mitgerissene Blätter.",
  traum: "Aufsteigende Motive, die ihre Farbe wechseln — Fliederrosa, Mint, Blassgold. Dazu sehr langsame breite Schwaden.",
};

// ------------------------------------------------------------

w("# PocketBeast — Konzept für die Assetgenerierung");
w();
w("Stand: " + new Date().toISOString().slice(0, 10) +
  ". Erzeugt aus `index.html` mit `node tools/konzept-bauen.js` —");
w("die Tabellen sind der tatsächliche Spielinhalt, keine Wunschliste.");
w();
w("---");
w();
w("## 1. Worum es geht");
w();
w("Kreaturen-Tower-Defense. Wilde Wesen ziehen von der Wildnis zum Dorf; der");
w("Spieler stellt Wächter an den Weg. Jeder Wächter und jedes Wilde gehört einem");
w("von zwölf Elementen, die einander schlagen. Wächter entwickeln sich über drei");
w("Stufen und eine vierte, verdiente.");
w();
w("Das Spiel hat **keine Asset-Dateien**. Jede Grafik entsteht heute aus");
w("Zeichenbefehlen, jeder Klang aus Schwingungen. Dieses Konzept beschreibt, was");
w("erzeugt werden müsste, wenn es Dateien geben soll — für eine 3D-Fassung oder");
w("eine Veröffentlichung.");
w();
w("## 2. Stil");
w();
w("**Freundlich, nicht niedlich.** Die Wesen haben große Augen und runde Körper,");
w("aber die Landschaft ist ernst: gedämpfte Farben, echte Schatten, Wetter. Ein");
w("Wilder soll bedrohlich wirken können, ohne das Bild zu brechen.");
w();
w("**Silhouette vor Feinzeichnung.** Die Figuren stehen im Spiel 13 bis 19 Pixel");
w("hoch. Was sie unterscheidbar macht, sind zwei oder drei Merkmale — spitze");
w("Ohren, Hörner, Schwingen — nicht die Zeichnung darauf.");
w();
w("**Licht von oben links.** Alle Schatten fallen nach rechts unten. Erhöhte");
w("Dinge haben eine helle Oberkante und eine dunkle Unterseite.");
w();
w("**Keine schwarzen Umrisse.** Formen trennen sich durch Helligkeitsunterschied,");
w("nicht durch Konturlinien.");
w();
w("**Bewegung gehört zur Figur.** Jedes Wesen atmet im Stand und stößt beim");
w("Gehen ab. Ohren, Schweife und Flügel schwingen der Körperbewegung verzögert");
w("nach — diese Verzögerung liest das Auge als Masse.");
w();

// ---------- Elemente ----------
w("## 3. Elemente und Farben");
w();
w("| Element | Name | Farbe |");
w("|---|---|---|");
for (const [id, t] of Object.entries(S.TYPES)) {
  w(`| \`${id}\` | ${t.name} | \`${t.col}\` |`);
}
w();
w("Die Farbe eines Wesens ist immer die seines Elements. Abweichungen gibt es");
w("nur als Aufhellung oder Abdunklung derselben Farbe.");
w();

// ---------- Wächter ----------
w("## 4. Wächter");
w();
w("Elf baubare Familien, je drei Stufen. Die Stufen zeigen dieselbe Kreatur,");
w("gewachsen: Stufe 2 bekommt einen Stachelkranz über dem Kopf, Stufe 3 einen");
w("höheren Kranz in Elementfarbe und ein Zeichen des Elements.");
w();
for (const t of S.TOWERS.filter((x) => !x.legendaer)) {
  const namen = t.tiers.map((s) => s.name).join(" → ");
  w(`### ${namen}`);
  w();
  w(`- **Element:** ${S.TYPES[t.type].name} (\`${S.TYPES[t.type].col}\`)`);
  w(`- **Gestalt:** ${FORM[t.shape] || t.shape}`);
  w(`- **Trifft Flieger:** ${t.air ? "ja" : "nein"}`);
  w(`- **Rolle:** ${t.blurb}`);
  w(`- **Meganame:** ${S.MEGA_NAMEN ? S.MEGA_NAMEN[t.type] || "—" : "—"}`);
  w();
}
w("### Megaentwicklung");
w();
w("Die vierte Stufe. Ein Drittel größer als Stufe 3, neun statt sieben");
w("Kranzzacken, zwei **gegenläufige** Ringe über dem Haupt und aufsteigende");
w("Splitter, die oben vergehen. Am Boden ein zweiter, breiterer Sockel mit");
w("goldenen Ecksteinen und einem umlaufenden Lichtband.");
w();

// ---------- Legendäre ----------
w("## 5. Legendäre Wächter");
w();
w("Einer je Karte, verdient durch alle " + S.WELLEN_JE_KARTE + " Wellen. Sie sehen");
w("anders aus als alles andere im Spiel:");
w();
w(FORM.thron);
w();
w("| Karte | Name | Element | Gabe |");
w("|---|---|---|---|");
for (const m of S.MAPS) {
  const L = m.legendaer;
  if (!L) continue;
  w(`| ${m.name} | ${L.namen[2]} | ${S.TYPES[L.typ].name} | ${gabeText(L.typ)} |`);
}
w();

// ---------- Gegner ----------
w("## 6. Wilde");
w();
w(S.SPECIES.length + " Arten. Größe, Zähigkeit und Tempo stehen in den Daten; hier");
w("zählt das Aussehen.");
w();
w("| Name | Element | Gestalt | Besonderheit |");
w("|---|---|---|---|");
for (const s of S.SPECIES) {
  const bes = [];
  if (s.flying) bes.push("fliegt");
  if (s.armor) bes.push("gepanzert " + s.armor);
  if (s.tough) bes.push("zäh");
  if (s.shield) bes.push("Schild");
  if (s.regen) bes.push("heilt");
  if (s.rang) bes.push("Rang " + s.rang);
  w(`| ${s.name} | ${S.TYPES[s.type].name} | ${s.shape} | ${bes.join(", ") || "—"} |`);
}
w();
w("### Anführer");
w();
w("Deutlich größer und zäher, mit einer Fähigkeit. Sie tragen einen Reif am");
w("Boden, damit man sie im Gedränge findet.");
w();
w("| Name | Element | Gestalt | Fähigkeit |");
w("|---|---|---|---|");
for (const b of S.BOSSES) {
  const f = b.ability ? `${b.ability}, alle ${b.abEvery} s` : "—";
  w(`| ${b.name} | ${S.TYPES[b.type].name} | ${b.shape}${b.flying ? ", fliegt" : ""} | ${f} |`);
}
w();

// ---------- Formen ----------
w("## 7. Gestalten im Einzelnen");
w();
w("Jede Gestalt wird von mehreren Arten geteilt. Wer sie erzeugt, braucht sie");
w("nur einmal — die Elementfarbe unterscheidet die Träger.");
w();
const genutzt = new Set([
  ...S.TOWERS.map((t) => t.shape),
  ...S.SPECIES.map((s) => s.shape),
  ...S.BOSSES.map((b) => b.shape),
]);
w("| Gestalt | Beschreibung |");
w("|---|---|");
for (const f of [...genutzt].sort()) {
  w(`| \`${f}\` | ${FORM[f] || "—"} |`);
}
w();
w("**Drei Erscheinungen je Gestalt.** Über allen Formen liegen drei");
w("Merkmalssätze: schlicht, gescheckt (hellere Flecken, wärmerer Ton) und");
w("gestreift (dunkle Querbänder, Stirnkamm, kühlerer Ton). Der Versatz bleibt");
w("klein genug, dass die Familie erkennbar bleibt.");
w();

// ---------- Karten ----------
w("## 8. Karten");
w();
w("Elf Routen, je eine für ein baubares Element. Jede hat eigenen Boden, eigenen");
w("Bewuchs, eigenes Wetter und einen eigenen Himmel.");
w();
for (const m of S.MAPS) {
  w(`### ${m.name}`);
  w();
  w(`- **Heimatelement:** ${S.TYPES[m.heim].name}`);
  w(`- **Grad:** ${m.diff}`);
  w(`- **Boden:** \`${m.ground[0]}\` bis \`${m.ground[1]}\`, Weg \`${m.path}\``);
  w(`- **Himmel:** \`${(m.himmel || [])[0]}\` bis \`${(m.himmel || [])[1]}\``);
  w(`- **Bewuchs:** ${[...new Set(m.flora || [])].join(", ")}`);
  w(`- **Wetter:** ${m.weather} — ${WETTER[m.weather] || ""}`);
  const sf = (m.sonderfelder || []).map((x) => `${x[1]}× ${x[0]}`).join(", ");
  w(`- **Sonderfelder:** ${sf}`);
  w();
}

// ---------- Wetter ----------
w("## 9. Wetter");
w();
w("| Art | Beschreibung |");
w("|---|---|");
for (const [k, v] of Object.entries(WETTER)) w(`| \`${k}\` | ${v} |`);
w();
w("Es gibt zwei Familien: **weiche Schleier** (Nebel, Ruß, Sonne, Staub, Traum)");
w("bedecken 5–20 Prozent der Fläche mit geringer Stärke; **scharfe Teilchen**");
w("(Regen, Sturm, Böe, Pollen, Glut, Schnee) bedecken unter 2 Prozent, sind dort");
w("aber deutlich sichtbar. Beide Familien braucht es — nur Schleier wirkt");
w("verwaschen, nur Teilchen wirkt aufgeklebt.");
w();

// ---------- Boden und Bewuchs ----------
w("## 10. Boden, Weg und Bewuchs");
w();
w("**Der Boden ist nirgends gleich.** Ein zusammenhängendes Feld bestimmt an");
w("jeder Stelle die Fruchtbarkeit: Wo es satt ist, steht das Gras dichter,");
w("länger und dunkler; wo es dürr ist, fällt jeder zweite Halm aus und die Erde");
w("kommt durch. Als Übergang, nicht als Fleck.");
w();
w("**Der Weg ist getreten, nicht gezogen.** Zwei ausgetretene Rinnen, die");
w("wandern und deren Tiefe an- und abläuft, sodass die Spur sich stellenweise");
w("verliert. Die Kante ist keine Linie, sondern eine Zone: Buchten in Wegfarbe");
w("greifen nach außen, Zungen in Bodenfarbe nach innen.");
w();
w("**Jede Pflanze hat ihren eigenen Ton.** Helligkeit ±13 Prozent, Wärme ±0,5.");
w("Dreißig gleich grüne Kronen nebeneinander sind der künstlichste Zug an einem");
w("Wald.");
w();
w("Bewuchsarten: " + [...new Set(S.MAPS.flatMap((m) => m.flora || []))].join(", ") + ".");
w();

// ---------- Klang ----------
w("## 11. Klang");
w();
w("Alles heute prozedural. Was gebraucht würde:");
w();
w("| Ereignis | Charakter |");
w("|---|---|");
w("| Schuss je Element | kurz, elementtypisch — Feuer knackt, Wasser platscht, Elektro zischt |");
w("| Treffer | trockenes Rauschen, sehr kurz |");
w("| Gegner erledigt | weicher Abfall, beim Anführer tiefer und länger |");
w("| Wächter setzen | zwei aufsteigende Töne |");
w("| Entwickeln | aufsteigende Folge, drei Töne |");
w("| Megaentwicklung | Siegfanfare mit Nachhall |");
w("| Durchbruch | dumpfer Schlag, warnend |");
w("| Welle gehalten | zwei helle Töne |");
w("| Erfolg | zwei helle Töne, eine Quinte auseinander, plus Funkeln |");
w("| Erweckung des Legendären | der längste Klang: tiefer Bordun, steigende Folge, Nachklang (3 s) |");
w("| Niederlage | absteigende Folge, sägend |");
w();
w("Dazu Umgebung je Karte: Wald, Regen, Wind, Feuer, Höhle.");
w();

// ---------- Für die Erzeugung ----------
w("## 12. Hinweise für die Erzeugung");
w();
w("**Was zuerst gebraucht wird**, wenn nicht alles auf einmal entsteht:");
w();
w("1. Die " + [...genutzt].length + " Gestalten, je in drei Stufen — das sind die Figuren, die man");
w("   dauernd ansieht.");
w("2. Die elf legendären Wächter — sie sind das Ziel des Spiels.");
w("3. Boden und Weg je Karte.");
w("4. Bewuchs.");
w("5. Wetter.");
w("6. Klang.");
w();
w("**Was nicht erzeugt werden muss:** Die Benutzeroberfläche. Sie besteht aus");
w("Text und Flächen und bleibt besser gezeichnet als gerendert.");
w();
w("**Maßstab:** Eine Kachel ist " + S.TILE + " Pixel breit. Eine Kreatur steht 13 bis 19");
w("Pixel hoch, ein Anführer bis 34. Ein Baum ragt bis 40 Pixel auf. In 3D");
w("entspricht eine Kachel zwei Metern.");
w();
w("**Blickwinkel:** Das Spiel sieht schräg von oben auf eine gestauchte");
w("Bodenebene (Faktor 0,78). Stehende Dinge heben diese Stauchung lokal wieder");
w("auf — sie stehen aufrecht, während der Boden liegt. Wer Figuren erzeugt,");
w("erzeugt sie **von vorn**, nicht von schräg oben.");
w();

fs.writeFileSync(ZIEL, z.join("\n") + "\n");
console.log("Geschrieben: " + path.relative(WURZEL, ZIEL));
console.log("  Zeilen:      " + z.length);
console.log("  Wächter:     " + S.TOWERS.filter((t) => !t.legendaer).length + " + " + S.MAPS.length + " legendäre");
console.log("  Wilde:       " + S.SPECIES.length + " + " + S.BOSSES.length + " Anführer");
console.log("  Gestalten:   " + [...genutzt].length);
console.log("  Karten:      " + S.MAPS.length);
