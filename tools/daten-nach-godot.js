#!/usr/bin/env node
/* ============================================================
   PocketBeast — Spieldaten nach Godot übertragen
   ============================================================

   Liest Typen, Effektivitätstabelle, Wächter und Gegner aus index.html und
   schreibt sie als GDScript nach godot-3d/scripts/daten.gd.

   Warum erzeugt statt abgeschrieben: Die Werte ändern sich ständig — allein
   in dieser Nacht wurden alle Reichweiten neu gesetzt, eine zwölfte Familie
   kam dazu und die Panzerungsformel wurde umgestellt. Eine von Hand
   gepflegte zweite Fassung wäre binnen Tagen falsch, ohne dass es jemandem
   auffiele. So genügt ein Aufruf:

     node tools/daten-nach-godot.js

   Gelesen wird über den Prüfstand, also aus derselben Datei, die auch im
   Browser läuft — nicht aus einer Kopie.
   ============================================================ */

const fs = require("fs");
const path = require("path");
const { ladeSpiel } = require("./pruefstand.js");

const WURZEL = path.join(__dirname, "..");
const ZIEL = path.join(WURZEL, "godot-3d", "scripts", "daten.gd");

const spiel = ladeSpiel(path.join(WURZEL, "index.html"));

/* GDScript kennt keine verschachtelten Wörterbuchliterale mit beliebigen
   Werten so bequem wie JSON. Deshalb wird hier von Hand ausgegeben, mit
   festem Einzug — lesbar bleiben soll die Datei trotzdem. */
function wert(v) {
  if (v === null || v === undefined) return "null";
  if (typeof v === "number") return Number.isInteger(v) ? String(v) : v.toFixed(4).replace(/0+$/, "").replace(/\.$/, ".0");
  if (typeof v === "boolean") return v ? "true" : "false";
  if (typeof v === "string") return JSON.stringify(v);
  if (Array.isArray(v)) return "[" + v.map(wert).join(", ") + "]";
  const teile = Object.entries(v).map(([k, x]) => JSON.stringify(k) + ": " + wert(x));
  return "{ " + teile.join(", ") + " }";
}

const zeilen = [];
const z = (t) => zeilen.push(t);

z("extends RefCounted");
z("##");
z("## Spieldaten — ERZEUGT, NICHT VON HAND ÄNDERN.");
z("##");
z("## Quelle: index.html. Neu erzeugen mit");
z("##     node tools/daten-nach-godot.js");
z("##");
z("## Wer hier etwas ändert, verliert es beim nächsten Lauf. Die Werte");
z("## gehören ins Browserspiel; diese Datei zieht nach.");
z("##");
z("## Stand: " + new Date().toISOString().slice(0, 10));
z("##");
z("");

// ---------- Elementtypen ----------
z("## Elementfarben. Dieselben Hexwerte wie im Browserspiel, damit ein");
z("## Feuer-Wächter in beiden Fassungen gleich aussieht.");
z("const TYPEN := {");
for (const [id, t] of Object.entries(spiel.TYPES)) {
  z(`\t"${id}": { "name": ${JSON.stringify(t.name)}, "farbe": Color(${JSON.stringify(t.col)}) },`);
}
z("}");
z("");

// ---------- Effektivität ----------
z("## Angreifer -> Verteidiger. Fehlender Eintrag bedeutet 1.0 —");
z("## genau wie eff() im Browserspiel.");
z("const CHART := {");
for (const [angreifer, gegen] of Object.entries(spiel.CHART)) {
  const paare = Object.entries(gegen).map(([d, f]) => `"${d}": ${wert(f)}`).join(", ");
  z(`\t"${angreifer}": { ${paare} },`);
}
z("}");
z("");
z("static func wirksamkeit(angriff: String, ziel: String) -> float:");
z("\tif not CHART.has(angriff):");
z("\t\treturn 1.0");
z("\tvar reihe: Dictionary = CHART[angriff]");
z("\treturn float(reihe.get(ziel, 1.0))");
z("");

// ---------- Wächter ----------
z("## Wächterfamilien mit ihren drei Stufen.");
z("const WAECHTER := [");
for (const t of spiel.TOWERS) {
  const stufen = t.tiers.map((s) => {
    const felder = [
      `"name": ${JSON.stringify(s.name)}`,
      `"kosten": ${s.cost}`,
      `"schaden": ${wert(s.dmg)}`,
      `"rate": ${wert(s.rate)}`,
      `"reichweite": ${s.range}`,
    ];
    if (s.splash) felder.push(`"flaeche": ${s.splash}`);
    if (s.pierce) felder.push(`"durchschlag": ${s.pierce}`);
    if (s.chain) felder.push(`"kette": ${s.chain}`);
    if (s.mark) felder.push(`"marke": ${wert(s.mark)}`);
    if (s.burn) felder.push(`"brand": ${wert({ dps: s.burn.dps, dur: s.burn.dur })}`);
    if (s.gift) felder.push(`"gift": ${wert({ dps: s.gift.dps, dur: s.gift.dur })}`);
    if (s.slow) felder.push(`"bremse": ${wert({ amt: s.slow.amt, dur: s.slow.dur })}`);
    if (s.root) felder.push(`"fessel": ${wert({ p: s.root.p, dur: s.root.dur })}`);
    if (s.aura) felder.push(`"feld": ${wert({ dmg: s.aura.dmg, rng: s.aura.rng })}`);
    return "\t\t\t{ " + felder.join(", ") + " },";
  });
  z("\t{");
  z(`\t\t"id": ${JSON.stringify(t.id)}, "typ": ${JSON.stringify(t.type)}, "gestalt": ${JSON.stringify(t.shape)},`);
  z(`\t\t"luft": ${t.air ? "true" : "false"}, "stern": ${t.stern || 0},${t.nurBei ? ` "nur_bei": ${JSON.stringify(t.nurBei)},` : ""}${t.legendaer ? " \"legendaer\": true," : ""}`);
  z(`\t\t"beschreibung": ${JSON.stringify(t.blurb)},`);
  z("\t\t\"stufen\": [");
  for (const s of stufen) z(s);
  z("\t\t],");
  z("\t},");
}
z("]");
z("");

// ---------- Trainerpfad ----------
/* Die Kurven der Talente lassen sich nicht als Zahl exportieren — sie sind
   Funktionen. Exportiert werden deshalb ihre Bauteile: Art der Kurve, Schritt
   beziehungsweise Grenze und Halbwert. Godot baut daraus dieselbe Kurve.

   Der Umweg ist nötig, weil sonst zwei Fassungen zweier Formeln entstünden,
   die sich unbemerkt auseinanderentwickeln. */
z("## Alle acht Wellen ein Anfuehrer, und die Schlusswelle immer.");
z("static func ist_anfuehrerwelle(w: int) -> bool:");
z(`\treturn w > 0 and (w % 8 == 0 or w == ${spiel.WELLEN_JE_KARTE})`);
z("");
z("## Grenzen des Trainerpfads und der Aufstellung.");
z(`const TALENT_RANG_MAX := ${spiel.TALENT_RANG_MAX || 100}`);
z(`const AUFSTELLUNG_MAX := ${spiel.AUFSTELLUNG_MAX || 8}`);
z(`const WAECHTER_JE_KARTE := ${spiel.WAECHTER_JE_KARTE || 45}`);
z("");
z("## Die zehn Zweige. \"gerade\" waechst je Rang um schritt, \"satt\"");
z("## naehert sich grenze und erreicht sie nie: grenze * r / (r + halb).");
z("const TALENTE := [");
for (const t of spiel.TALENTS) {
  /* Die Kurve wird an zwei Punkten abgetastet und daraus zurückgerechnet.
     Bei einer Geraden ist wirkung(2) genau doppelt wirkung(1); weicht es ab,
     ist es die sättigende Kurve. Das ist robuster, als die Bauteile im Spiel
     zusätzlich abzulegen — dort stehen sie in der Kurve selbst. */
  /* Der Grenzwert wird bei sehr großem Rang abgetastet. Ein erster Anlauf
     nahm 100.000 und traf 899,82 statt 900 — die sättigende Kurve nähert
     sich der Decke, erreicht sie aber nie, und bei hunderttausend fehlt noch
     ein Fünftausendstel. Bei einer Milliarde liegt der Fehler unter der
     Auflösung der Zahl. */
  const w1 = t.wirkung(1), w2 = t.wirkung(2), w1000 = t.wirkung(1e9);
  const gerade = Math.abs(w2 - 2 * w1) < 1e-9;
  if (gerade) {
    z(`\t{ "id": ${JSON.stringify(t.id)}, "name": ${JSON.stringify(t.name)}, "kurve": "gerade", "schritt": ${wert(w1)} },`);
  } else {
    /* halb aus w1 = grenze * 1/(1+halb)  →  halb = grenze/w1 - 1 */
    const grenze = Math.round(w1000 * 1e6) / 1e6;
    const halb = Math.round((grenze / w1 - 1) * 1e6) / 1e6;
    z(`\t{ "id": ${JSON.stringify(t.id)}, "name": ${JSON.stringify(t.name)}, "kurve": "satt", "grenze": ${wert(grenze)}, "halb": ${wert(halb)} },`);
  }
}
z("]");
z("");

// ---------- Gegner ----------
z("## Gewöhnliche Gegnerarten.");
z("const ARTEN := [");
for (const sp of spiel.SPECIES) {
  const felder = [
    `"id": ${JSON.stringify(sp.id)}`,
    `"name": ${JSON.stringify(sp.name)}`,
    `"typ": ${JSON.stringify(sp.type)}`,
    `"gestalt": ${JSON.stringify(sp.shape)}`,
    `"leben": ${wert(sp.hp)}`,
    `"tempo": ${wert(sp.spd)}`,
    `"beute": ${wert(sp.bounty)}`,
    `"groesse": ${sp.size}`,
  ];
  if (sp.armor) felder.push(`"panzer": ${sp.armor}`);
  if (sp.flying) felder.push(`"fliegt": true`);
  if (sp.tough) felder.push(`"zaeh": true`);
  if (sp.shield) felder.push(`"schild": ${wert(sp.shield)}`);
  if (sp.regen) felder.push(`"heilt": ${wert(sp.regen)}`);
  if (sp.rang) felder.push(`"rang": ${sp.rang}`);
  z("\t{ " + felder.join(", ") + " },");
}
z("]");
z("");

// ---------- Anführer ----------
z("## Anführer. Deutlich größer und zäher als gewöhnliche Arten.");
z("const ANFUEHRER := [");
for (const b of spiel.BOSSES) {
  const felder = [
    `"name": ${JSON.stringify(b.name)}`,
    `"typ": ${JSON.stringify(b.type)}`,
    `"gestalt": ${JSON.stringify(b.shape)}`,
    `"leben": ${wert(b.hp)}`,
    `"tempo": ${wert(b.spd)}`,
    `"beute": ${wert(b.bounty)}`,
    `"groesse": ${b.size}`,
  ];
  if (b.armor) felder.push(`"panzer": ${b.armor}`);
  if (b.flying) felder.push(`"fliegt": true`);
  if (b.tough) felder.push(`"zaeh": true`);
  if (b.shield) felder.push(`"schild": ${wert(b.shield)}`);
  if (b.regen) felder.push(`"heilt": ${wert(b.regen)}`);
  z("\t{ " + felder.join(", ") + " },");
}
z("]");
z("");

// ---------- Wellenkurve ----------
z("## Wellenkurve, vorberechnet.");
z("##");
z("## Im Browserspiel entsteht sie aus drei Wachstumsraten, die in zwei");
z("## Stufen abfallen. Hier steht das Ergebnis als Tabelle: Die Formel");
z("## nachzubauen hieße, sie an zwei Orten pflegen zu müssen — und die eine");
z("## Fassung driftet dann von der anderen weg, ohne dass es auffällt.");
z("const WELLEN_JE_KARTE := " + spiel.WELLEN_JE_KARTE);
const kurve = [];
for (let w = 1; w <= spiel.WELLEN_JE_KARTE; w++) kurve.push(Math.round(spiel.waveHP(w, 1)));
z("const WELLE_LEBEN := [" + kurve.join(", ") + "]");
z("");
z("## Karten mit ihrem Schwierigkeitsfaktor.");
z("const KARTEN := [");
for (const m of spiel.MAPS) {
  /* Wegpunkte und Farben gehören dazu, sonst sehen alle elf Karten gleich
     aus: Die 3D-Fassung hatte eine fest verdrahtete Route und hätte auf
     jeder Karte dieselbe Landschaft gezeigt. */
  const wp = (m.wp || []).map((k) => `Vector2i(${k[0]}, ${k[1]})`).join(", ");
  const wpB = (m.wpB || []).map((k) => `Vector2i(${k[0]}, ${k[1]})`).join(", ");
  z(`\t{`);
  z(`\t\t"name": ${JSON.stringify(m.name)}, "grad": ${JSON.stringify(m.diff)},`);
  z(`\t\t"faktor": ${wert(m.mul)}, "beeren": ${m.gold}, "leben": ${m.lives},`);
  z(`\t\t"heim": ${JSON.stringify(m.heim)}, "wetter": ${JSON.stringify(m.weather)},`);
  /* Die Fauna der Karte: welche Elemente hier überhaupt auftauchen.
     Ohne sie liefen in Godot wieder alle vierundvierzig Arten überall,
     und die beiden Fassungen zeigten verschiedene Spiele. */
  z(`\t\t"wilde": [${(m.wilde || []).map((t) => JSON.stringify(t)).join(", ")}],`);
  z(`\t\t"boden": [Color("${m.ground[0]}"), Color("${m.ground[1]}")],`);
  z(`\t\t"weg": Color("${m.path}"), "wegkante": Color("${m.pathEdge}"),`);
  z(`\t\t"laub": Color("${m.foliage}"), "himmel": [Color("${(m.himmel||["#7FA8C4"])[0]}"), Color("${(m.himmel||["#BFD4D0"])[1]}")],`);
  z(`\t\t"gras": Color("${m.gras || m.ground[1]}"), "erde": Color("${m.erde || m.soil}"),`);
  z(`\t\t"bewuchs": ${JSON.stringify([...new Set(m.flora || [])])},`);
  z(`\t\t"route": [${wp}],`);
  if (wpB) z(`\t\t"route_b": [${wpB}],`);
  const L = m.legendaer;
  if (L) z(`\t\t"legendaer": { "typ": ${JSON.stringify(L.typ)}, "gestalt": ${JSON.stringify(L.gestalt)}, "namen": ${JSON.stringify(L.namen)} },`);
  z(`\t},`);
}
z("]");
z("");

fs.writeFileSync(ZIEL, zeilen.join("\n") + "\n");

console.log("Geschrieben: " + path.relative(WURZEL, ZIEL));
console.log("  Elementtypen:   " + Object.keys(spiel.TYPES).length);
console.log("  Wächter:        " + spiel.TOWERS.length + " Familien");
console.log("  Gegnerarten:    " + spiel.SPECIES.length + " + " + spiel.BOSSES.length + " Anführer");
console.log("  Wellenkurve:    " + kurve.length + " Werte, W1=" + kurve[0] + " bis W" + kurve.length + "=" + kurve[kurve.length - 1]);
console.log("  Zeilen:         " + zeilen.length);
