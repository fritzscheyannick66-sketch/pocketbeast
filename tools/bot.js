/* ============================================================
   PocketBeast — Spielbot
   ============================================================

   Spielt eine Runde von Anfang bis Ende und liefert Messdaten.

   Der Vorgänger war als Messinstrument wertlos geworden: Er nutzte in einem
   Lauf null Megaentwicklungen bei zwanzig Wächtern, baute fünf von zehn Typen,
   keinen einzigen Wasser-Wächter bei vier Wasserfeldern, und neun seiner
   zwanzig Wächter waren der billigste Typ. Was er maß, war seine eigene
   veraltete Strategie, nicht die Balance des Spiels.

   Dieser Bot kennt die Regeln, die inzwischen dazugekommen sind:

     Wasserstellen  nehmen nur Wasser-Wächter auf, und Wasser-Wächter dürfen
                    nirgends sonst stehen
     Kraftfelder    geben 30 % Reichweite — die besten Plätze der Karte
     Tag und Nacht  Feen steigen nur bei Tag auf, Unlicht nur bei Nacht
     Megaentwicklung der größte Machtzuwachs im Spiel, hängt aber an einem
                    Wächter, der lange genug gelebt und getroffen hat
     Typenvorteil   die kommende Welle steht vorher lesbar da

   Er spielt nicht optimal — das soll er auch nicht. Er soll spielen wie
   jemand, der die Regeln verstanden hat und vernünftige Entscheidungen
   trifft. Was er nicht schafft, ist für einen aufmerksamen Menschen
   vermutlich auch schwer.
   ============================================================ */

const TAKT = 1 / 30;          // Sekunden je Rechenschritt
const MAX_SCHRITTE = 400000;  // Notbremse gegen Endlosläufe

/* Wie gut trifft ein Wächtertyp gegen eine bevorstehende Welle?
   Gewichtet nach Lebenspunkten, nicht nach Stückzahl — zehn schwache Gegner
   wiegen weniger als ein Brocken mit demselben Gesamtleben. */
function nutzenGegen(spiel, typ, gruppen) {
  let summe = 0, gesamt = 0;
  for (const g of gruppen) {
    const gewicht = g.hp * g.count;
    gesamt += gewicht;
    summe += gewicht * spiel.eff(typ, g.spec.type);
  }
  return gesamt > 0 ? summe / gesamt : 1;
}

/* Fliegt ein nennenswerter Teil der kommenden Welle? */
function luftAnteil(gruppen) {
  let luft = 0, gesamt = 0;
  for (const g of gruppen) {
    const gewicht = g.hp * g.count;
    gesamt += gewicht;
    if (g.spec.flying) luft += gewicht;
  }
  return gesamt > 0 ? luft / gesamt : 0;
}

/* Was ein Feld-Wächter wert ist.

   Der Psycho-Wächter macht selbst kaum Schaden, hebt aber jeden Nachbarn um
   bis zu 28 Prozent an. Wer nur den eigenen Schaden je Beere rechnet, baut
   ihn nie — genau das tat dieser Bot im ersten Anlauf, auf allen drei Karten,
   in jedem Lauf. Sein Wert hängt daran, wie viele Wächter in Reichweite
   stehen und wie stark die sind. */
function auraWert(spiel, def, c, r) {
  const st = def.tiers[0];
  if (!st.aura) return 0;
  const { G, TILE } = spiel;
  const x = c * TILE + TILE / 2, y = r * TILE + TILE / 2;
  const reich = st.range * 1.15;
  let gewinn = 0;
  for (const t of G.towers) {
    if (Math.hypot(t.x - x, t.y - y) > reich) continue;
    // Was der Nachbar zusätzlich austeilt, wenn das Feld über ihm liegt
    gewinn += spiel.statDmg(t) * st.aura.dmg;
  }
  return gewinn;
}

/* Alle freien Plätze, bewertet. Je näher am Weg, desto besser — und
   Kraftfelder schlagen alles andere. */
function bewerteFelder(spiel) {
  const { G, TILE, COLS, ROWS } = spiel;
  const felder = [];
  for (let c = 0; c < COLS; c++) {
    for (let r = 0; r < ROWS; r++) {
      if (!spiel.canPlace(c, r)) continue;
      const x = c * TILE + TILE / 2, y = r * TILE + TILE / 2;
      let naeh = 1e9, deckung = 0;
      for (const rt of G.routes) {
        for (const p of rt.pts) {
          const d = Math.hypot(p.x - x, p.y - y);
          if (d < naeh) naeh = d;
          if (d < 140) deckung++;
        }
      }
      if (naeh > 150) continue;            // zu weit weg, feuert nie
      const art = spiel.feldArt(c, r);
      felder.push({
        c, r, art, naeh, deckung,
        wert: deckung * (art === "kraft" ? 1.9 : 1) - naeh * 0.02,
      });
    }
  }
  felder.sort((a, b) => b.wert - a.wert);
  return felder;
}

/* ============================================================
   Ein Spielzug zwischen zwei Wellen
   ============================================================
   Reihenfolge der Ausgaben, vom größten Zuwachs zum kleinsten. Der alte Bot
   hatte diese Reihenfolge nicht und fiel deshalb auf den billigsten Wächter
   zurück, sobald das Geld knapp wurde. */
function bauen(spiel, zustand) {
  const { G } = spiel;
  const naechste = G.sent + 1;
  const gruppen = naechste <= G.maxWave ? spiel.genWave(naechste, G.map.mul) : [];
  const luft = luftAnteil(gruppen);

  let handelte = true;
  let runden = 0;
  while (handelte && runden++ < 60) {
    handelte = false;

    // --- 1. Megaentwicklung: der größte Sprung im Spiel ---
    for (const t of G.towers) {
      if (spiel.megaBereit(t) && G.gold >= spiel.MEGA_KOSTEN) {
        spiel.megaEntwickeln(t);
        zustand.megaGesamt++;
        handelte = true;
        break;
      }
    }
    if (handelte) continue;

    // --- 2. Aufwerten, bevorzugt was gegen die kommende Welle wirkt ---
    let besterAufstieg = null, besterWert = 0;
    for (const t of G.towers) {
      if (t.tier >= 2 || t.mega) continue;
      if (!spiel.darfEntwickeln(t)) continue;   // Fee bei Nacht, Unlicht bei Tag
      const kosten = t.def.tiers[t.tier + 1].cost;
      if (G.gold < kosten) continue;
      const wirkung = nutzenGegen(spiel, t.def.type, gruppen);
      // Zuwachs an Schaden je Beere, gewichtet mit dem Typenvorteil
      const a = t.def.tiers[t.tier], b = t.def.tiers[t.tier + 1];
      let jetzt = a.dmg * a.rate, dann = b.dmg * b.rate;
      /* Auch beim Aufwerten zählt die Feldwirkung mit: Ein Traumflaum auf
         Stufe 3 hebt seine Nachbarn fast dreimal so stark wie auf Stufe 1. */
      if (b.aura) {
        const nachbarn = G.towers.filter((o) =>
          o !== t && Math.hypot(o.x - t.x, o.y - t.y) <= b.range * 1.15);
        const summe = nachbarn.reduce((n, o) => n + spiel.statDmg(o), 0);
        jetzt += summe * ((a.aura && a.aura.dmg) || 0);
        dann += summe * b.aura.dmg;
      }
      const wert = ((dann - jetzt) / kosten) * wirkung;
      if (wert > besterWert) { besterWert = wert; besterAufstieg = t; }
    }
    if (besterAufstieg) {
      spiel.upgradeTower(besterAufstieg);
      handelte = true;
      continue;
    }

    // --- 3. Neuen Wächter setzen ---
    if (G.towers.length < zustand.maxTuerme) {
      const kandidat = waehleNeuenWaechter(spiel, gruppen, luft);
      if (kandidat) {
        spiel.placeTower(kandidat.id, kandidat.c, kandidat.r);
        handelte = true;
        continue;
      }
    }

    // --- 4. Training, wenn sonst nichts ansteht ---
    let bestesTraining = null, trainWert = 0;
    for (const t of G.towers) {
      if (t.tier < 2) continue;                       // erst ausbauen
      if ((t.train || 0) >= spiel.TRAIN_MAX) continue;
      const kosten = spiel.trainCost(t);
      // Reserve halten, damit nicht alles ins Training fließt
      if (G.gold < kosten + 260) continue;
      const wirkung = nutzenGegen(spiel, t.def.type, gruppen);
      const wert = (spiel.statDmg(t) * 0.09 / kosten) * wirkung;
      if (wert > trainWert) { trainWert = wert; bestesTraining = t; }
    }
    if (bestesTraining) {
      spiel.trainTower(bestesTraining);
      handelte = true;
    }
  }
}

/* Welcher Wächter fehlt, und wo soll er stehen? */
function waehleNeuenWaechter(spiel, gruppen, luft) {
  const { G } = spiel;
  const felder = bewerteFelder(spiel);
  if (!felder.length) return null;

  // Wie oft ist jeder Typ schon vertreten?
  const vorhanden = {};
  for (const t of G.towers) vorhanden[t.def.id] = (vorhanden[t.def.id] || 0) + 1;

  let bester = null, besterWert = 0;
  for (const def of spiel.TOWERS) {
    if (def.legendaer && !spiel.legendaerFrei(G.mapIdx)) continue;
    const kosten = def.tiers[0].cost;
    if (G.gold < kosten) continue;

    const wirkung = nutzenGegen(spiel, def.type, gruppen);
    /* Wer nicht in die Luft trifft, ist gegen eine Flugwelle wertlos.
       Der alte Bot kannte diesen Unterschied nicht. */
    const luftStrafe = def.air ? 1 : (1 - luft * 0.85);
    /* Vielfalt zählt: der fünfte Wächter desselben Typs bringt weniger als
       der erste eines fehlenden. Genau hier fiel der Vorgänger durch — neun
       von zwanzig Wächtern waren bei ihm derselbe billige Typ. */
    const vielfalt = 1 / (1 + (vorhanden[def.id] || 0) * 0.85);
    const grund = def.tiers[0].dmg * def.tiers[0].rate / kosten;

    /* Passenden Platz suchen. Wasser-Wächter nur auf Wasser, sonst nirgends
       dort. Feld-Wächter wollen nicht an den Weg, sondern zwischen möglichst
       viele Kameraden — deshalb prüfen sie mehrere Plätze und nehmen den mit
       der größten Wirkung. */
    let platz = null, zusatz = 0;
    if (def.tiers[0].aura) {
      let bestesFeld = 0;
      for (const f of felder.slice(0, 40)) {
        if (!spiel.darfHier(def.id, f.c, f.r)) continue;
        const a = auraWert(spiel, def, f.c, f.r);
        if (a > bestesFeld || !platz) { bestesFeld = a; platz = f; }
      }
      zusatz = bestesFeld;
    } else {
      for (const f of felder) {
        if (!spiel.darfHier(def.id, f.c, f.r)) continue;
        platz = f;
        break;
      }
    }
    if (!platz) continue;

    // Eigener Schaden plus das, was der Wächter bei anderen auslöst
    const wert = (grund + zusatz / kosten) * wirkung * luftStrafe * vielfalt
      * (1 + platz.wert * 0.0015);
    if (wert > besterWert) {
      besterWert = wert;
      bester = { id: def.id, c: platz.c, r: platz.r };
    }
  }
  return bester;
}

/* Segnung wählen.

   Das Spiel zieht drei zufällige aus dem Vorrat; hier geschieht dasselbe.
   Bewertet wird grob nach Breitenwirkung: Was jeden Wächter stärker macht,
   schlägt was nur einen Sonderfall bedient. Leben nur, wenn es knapp wird —
   drei Leben nützen wenig, wenn die Wächter zu schwach bleiben. */
function nimmSegnung(spiel, zustand) {
  const { G } = spiel;
  const vorrat = spiel.BOONS.filter((b) => (G.boons[b.id] || 0) < b.max);
  if (!vorrat.length) return;

  const beutel = vorrat.slice();
  const auswahl = [];
  for (let i = 0; i < 3 && beutel.length; i++) {
    auswahl.push(beutel.splice(Math.floor(Math.random() * beutel.length), 1)[0]);
  }

  const gewicht = {
    dmg: 10, pierce: 7, rng: 6, crit: 6, gold: 5, train: 5,
    burn: 4, slow: 4, chain: 3, aura: 3, cash: 3, sell: 1,
    life: G.lives <= 8 ? 12 : 2,       // erst wertvoll, wenn es eng wird
  };
  auswahl.sort((a, b) => (gewicht[b.id] || 2) - (gewicht[a.id] || 2));
  spiel.takeBoon(auswahl[0]);
  zustand.segnungen.push(auswahl[0].id);
}

/* ============================================================
   Eine ganze Runde
   ============================================================ */
function spieleRunde(spiel, mapIdx, opt) {
  opt = opt || {};
  const { G } = spiel;
  const zustand = {
    maxTuerme: opt.maxTuerme || 22,
    megaGesamt: 0,
    letzteSegnung: 0,
    segnungen: [],
  };

  /* Spielstand zurücksetzen.

     save lebt so lange wie der geladene Prozess. Ohne das Zurücksetzen trägt
     der zweite Lauf die Sterne und Talentpunkte des ersten mit sich — und ab
     hundert Sternen steht ihm der legendäre Wächter zur Verfügung, den der
     erste Lauf nicht hatte. Die Läufe wären dann nicht mehr vergleichbar,
     sondern eine Kette, in der jeder auf dem vorigen aufbaut.

     Wer den Fortschritt gerade messen WILL, ruft mit opt.behalteStand auf. */
  if (!opt.behalteStand) {
    spiel.save.points = 0;
    spiel.save.spent = 0;
    spiel.save.ranks = {};
    spiel.save.cleared = {};
    spiel.save.sterne = {};
    spiel.save.endless = 0;
    spiel.save.best = 0;
  }

  spiel.newRun(mapIdx, true);
  G.running = true;
  G.paused = false;
  G.over = false;
  G.speed = 1;

  const verlauf = [];
  let schritte = 0;
  let ergebnis = "unklar";

  while (schritte < MAX_SCHRITTE) {
    // Zwischen den Wellen: bauen und die nächste rufen
    if (!G.waveActive && !G.over) {
      if (G.sent >= G.maxWave) { ergebnis = "durchgespielt"; break; }
      bauen(spiel, zustand);
      const lebenVorher = G.lives;
      const goldVorher = G.gold;
      spiel.startWave();
      verlauf.push({
        welle: G.sent,
        lebenVorher,
        goldVorher,
        tuerme: G.towers.length,
        mega: G.towers.filter((t) => t.mega).length,
        endstufe: G.towers.filter((t) => t.tier >= 2).length,
        typen: [...new Set(G.towers.map((t) => t.def.id))].length,
        training: G.towers.reduce((n, t) => n + (t.train || 0), 0),
        boss: spiel.isBossWave(G.sent),
        nacht: spiel.istNacht(G.sent),
      });
    }

    spiel.update(TAKT);
    schritte++;

    if (G.over) { ergebnis = "verloren"; break; }

    /* Segnung. Das Spiel bietet alle fünf Wellen drei zufällige zur Wahl und
       hält dafür an. Der Bot kann den Dialog nicht bedienen, also zieht er
       selbst drei aus demselben Vorrat und wählt daraus — dieselbe
       Einschränkung wie beim Spieler, der auch nicht aus allen wählen darf.

       Ohne das spielte der Bot die ganze Runde ohne eine einzige Segnung.
       Bis Welle 32 sind das sechs verpasste, und jede davon wirkt für den
       Rest der Runde. Ein Bot, der auf so viel Stärke verzichtet, misst
       nicht die Balance des Spiels, sondern seinen eigenen Verzicht. */
    if (G.paused && G.wave > zustand.letzteSegnung && G.wave % 5 === 0) {
      zustand.letzteSegnung = G.wave;
      nimmSegnung(spiel, zustand);
      G.paused = false;
    }
  }
  if (schritte >= MAX_SCHRITTE) ergebnis = "abgebrochen";

  // Schlussaufnahme
  const proTyp = {};
  for (const t of G.towers) {
    const k = t.def.id;
    if (!proTyp[k]) proTyp[k] = { n: 0, kills: 0, schaden: 0, mega: 0 };
    proTyp[k].n++;
    proTyp[k].kills += t.kills || 0;
    proTyp[k].schaden += Math.round(t.dealt || 0);
    if (t.mega) proTyp[k].mega++;
  }

  return {
    karte: spiel.MAPS[mapIdx].name,
    ergebnis,
    welle: G.sent,
    lebenUebrig: G.lives,
    durchgelassen: G.leaked,
    punkte: G.score,
    goldUebrig: G.gold,
    tuerme: G.towers.length,
    mega: G.towers.filter((t) => t.mega).length,
    typen: Object.keys(proTyp).length,
    segnungen: zustand.segnungen,
    proTyp,
    verlauf,
    schritte,
  };
}

module.exports = { spieleRunde, TAKT };
