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
    if (s.slow) felder.push(`"bremse": ${wert({ amt: s.slow.amt, dur: s.slow.dur })}`);
    if (s.root) felder.push(`"fessel": ${wert({ p: s.root.p, dur: s.root.dur })}`);
    if (s.aura) felder.push(`"feld": ${wert({ dmg: s.aura.dmg, rng: s.aura.rng })}`);
    return "\t\t\t{ " + felder.join(", ") + " },";
  });
  z("\t{");
  z(`\t\t"id": ${JSON.stringify(t.id)}, "typ": ${JSON.stringify(t.type)}, "gestalt": ${JSON.stringify(t.shape)},`);
  z(`\t\t"luft": ${t.air ? "true" : "false"},${t.nurBei ? ` "nur_bei": ${JSON.stringify(t.nurBei)},` : ""}${t.legendaer ? " \"legendaer\": true," : ""}`);
  z(`\t\t"beschreibung": ${JSON.stringify(t.blurb)},`);
  z("\t\t\"stufen\": [");
  for (const s of stufen) z(s);
  z("\t\t],");
  z("\t},");
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
  z(`\t{ "name": ${JSON.stringify(m.name)}, "grad": ${JSON.stringify(m.diff)}, "faktor": ${wert(m.mul)}, "beeren": ${m.gold}, "leben": ${m.lives} },`);
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
