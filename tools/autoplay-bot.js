/* ============================================================
   PocketBeast — Autoplay-Bot
   Spielt eine komplette Runde ohne Zutun, um Balance zu messen.

   Verwendung: index.html im Browser oeffnen, dann in der
   Konsole den Inhalt dieser Datei einfuegen und ausfuehren:

     __B2.init(0, 20)     // Karte 0 (Gruenpfad), max. 20 Tuerme
     __B2.run(50000)      // 50.000 Simulationsschritte (~830 Spielsek.)
     __B2.state()         // Zwischenstand
     __B2.rep             // Verlauf: Leben/Gold/Tuerme je Welle

   run() gibt zurueck: "weiter" | "fertig" | "tot" | "over".
   Bei "weiter" einfach erneut aufrufen. Karten: 0 Gruenpfad,
   1 Glutschlucht, 2 Flutruine.

   Strategie: erst Aufwertungen, dann neue Tuerme (rotierend durch
   alle sechs Typen, Felder nach Wegabdeckung sortiert), zuletzt
   Training. Segnungen werden immer als erste Option genommen.
   ============================================================ */

(function(){
const B = window.__B2 = { rep: [], spots: [], oi: 0, lastWave: 0, livesAtStart: 20, steps: 0, limit: 20 };
B.init = function(mapIdx, limit){
  newRun(mapIdx, true);
  G.running = true; G.paused = false; G.over = false; closeVeil(true);
  B.rep=[]; B.dps=[]; B.oi=0; B.lastWave=0; B.steps=0; B.limit=limit;
  B.spots=[];
  for (let c=0;c<COLS;c++) for (let r=0;r<ROWS;r++){
    if (G.blocked.has(c+","+r)) continue;
    const x=c*TILE+TILE/2, y=r*TILE+TILE/2; let cover=0, best=1e9;
    for (let d=0; d<G.path.len; d+=14){ const p=pathAt(G.path,d); const dd=Math.hypot(p.x-x,p.y-y);
      if(dd<best)best=dd; if(dd<140)cover++; }
    B.spots.push({c,r,near:best,cover});
  }
  B.spots.sort((a,b)=> b.cover-a.cover || a.near-b.near);
  B.livesAtStart=G.lives;
  return {map:G.map.name, lives:G.lives, gold:G.gold};
};
const ORDER=["grass","fire","electric","water","rock","psychic"];
function build(){
  for (const t of G.towers.slice().sort((a,b)=>a.tier-b.tier))
    if (t.tier<2 && G.gold >= t.def.tiers[t.tier+1].cost){ upgradeTower(t); return true; }
  if (G.towers.length < B.limit){
    for (let k=0;k<ORDER.length;k++){
      const id=ORDER[(B.oi+k)%ORDER.length];
      if (G.gold < TOWER_BY_ID[id].tiers[0].cost) continue;
      const s=B.spots.find(s=>canPlace(s.c,s.r)); if(!s) break;
      placeTower(id,s.c,s.r); B.oi++; return true;
    }
  }
  for (const t of G.towers.slice().sort((a,b)=>(a.train||0)-(b.train||0)))
    if (t.tier>=2 && G.gold>=trainCost(t)){ trainTower(t); return true; }
  return false;
}
function boonOpen(){ return !document.getElementById("veil").hidden
  && document.querySelectorAll("#sheet .boon").length>0; }
B.run=function(n){
  const DT=1/60;
  for(let i=0;i<n;i++){
    if(G.over) return "over";
    if(boonOpen()){ const b=document.querySelectorAll("#sheet .boon"); b[0].click();
      if(boonOpen()) closeVeil(true); continue; }
    if(!G.waveActive){
      if(G.wave>B.lastWave){
        B.rep.push({w:G.wave,lives:G.lives,gold:G.gold,t:G.towers.length,
          lost:B.livesAtStart-G.lives,
          maxTrain: G.towers.reduce((m,t)=>Math.max(m,t.train||0),0)});
        B.lastWave=G.wave;
      }
      let guard=0; while(build()&&guard++<200){}
      B.livesAtStart=G.lives;
      if(!G.endless && G.sent>=G.maxWave) return "fertig";
      const _d = G.towers.reduce((a,t)=>a+statDmg(t)*tierOf(t).rate,0);
      const _g = genWave(G.sent+1, G.map.mul);
      let _hp=0; for(const x of _g) _hp+=x.hp*x.count;
      B.dps.push({w:G.sent+1, dps:Math.round(_d), hp:Math.round(_hp), q:+(_hp/Math.max(1,_d)).toFixed(1)});
      startWave();
    }
    update(DT); B.steps++;
    if(G.lives<=0) return "tot";
  }
  return "weiter";
};
B.state=function(){return {wave:G.wave,sent:G.sent,lives:G.lives,gold:G.gold,over:G.over,
  towers:G.towers.length,score:G.score,simSek:Math.round(B.steps/60),boons:G.boons};};
})(); "bot2";
