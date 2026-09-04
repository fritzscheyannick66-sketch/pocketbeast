/* ============================================================
   PocketBeast — Prüfstand
   ============================================================

   Lädt das Spiel aus index.html in Node und macht es taktbar, ohne
   Browser und ohne Bildschirm.

   Warum nicht im Browser? Der alte Bot lief in der Entwicklerkonsole:
   Seite öffnen, Datei einfügen, ausführen, Zahlen ablesen. Das ist nichts,
   was nach jeder Änderung von selbst läuft. Hier genügt ein Aufruf, und
   ein Lauf über hundert Wellen dauert Sekunden statt Minuten, weil nichts
   gezeichnet wird.

   Der Kniff: Das Spiel braucht vom Browser erstaunlich wenig — 19 Zugriffe
   auf document, 13 auf window, zwei auf localStorage. Alles davon wird hier
   durch Attrappen ersetzt. Die Spiellogik selbst läuft unverändert, aus
   derselben Datei, die auch im Browser ausgeliefert wird. Damit misst der
   Prüfstand wirklich das Spiel und nicht eine Nachbildung davon.

   requestAnimationFrame ist bewusst wirkungslos: Die Bildschleife des Spiels
   darf nicht von selbst anlaufen. Der Takt kommt von hier.
   ============================================================ */

const fs = require("fs");
const path = require("path");
const vm = require("vm");

/* Eine Zeichenfläche, die nichts zeichnet. Jede Methode, die das Spiel
   aufruft, tut nichts und gibt etwas Brauchbares zurück. Fehlt eine, fliegt
   der Lauf auf — besser als still falsch zu messen. */
function machKontext() {
  const nichts = () => {};
  const ctx = {
    canvas: null,
    save: nichts, restore: nichts, translate: nichts, scale: nichts,
    rotate: nichts, beginPath: nichts, closePath: nichts, moveTo: nichts,
    lineTo: nichts, arc: nichts, ellipse: nichts, rect: nichts,
    roundRect: nichts, quadraticCurveTo: nichts, bezierCurveTo: nichts,
    fill: nichts, stroke: nichts, clip: nichts, fillRect: nichts,
    strokeRect: nichts, clearRect: nichts, fillText: nichts,
    strokeText: nichts, drawImage: nichts, setLineDash: nichts,
    setTransform: nichts, resetTransform: nichts, transform: nichts,
    putImageData: nichts, arcTo: nichts,
    measureText: () => ({ width: 10 }),
    getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    createLinearGradient: () => ({ addColorStop: nichts }),
    createRadialGradient: () => ({ addColorStop: nichts }),
    createPattern: () => null,
  };
  return ctx;
}

/* Die Attrappe muss vollständig genug sein, dass das Spiel sie nicht von
   einem echten Element unterscheidet. Fehlt eine Eigenschaft, bricht der Lauf
   — deshalb lieber einmal großzügig ausstatten, als bei jedem neuen
   Bedienelement nachzuziehen.

   tiefe begrenzt die Elternkette: Ohne sie erzeugte jedes parentElement ein
   neues Elternteil und der Aufruf liefe endlos. */
function machElement(tag, tiefe) {
  tiefe = tiefe || 0;
  const el = {
    tagName: (tag || "div").toUpperCase(),
    style: {}, dataset: {}, children: [], classList: {
      add: () => {}, remove: () => {}, toggle: () => {}, contains: () => false,
    },
    width: 1120, height: 672, hidden: false,
    textContent: "", innerHTML: "", value: "",
    appendChild(c) { this.children.push(c); return c; },
    append(...c) { this.children.push(...c); },
    prepend(...c) { this.children.unshift(...c); },
    insertBefore(c) { this.children.push(c); return c; },
    replaceChildren() { this.children.length = 0; },
    closest() { return null; },
    contains() { return false; },
    removeChild() {}, remove() {},
    addEventListener() {}, removeEventListener() {},
    setAttribute() {}, removeAttribute() {}, getAttribute() { return null; },
    querySelector() { return machElement("div"); },
    querySelectorAll() { return []; },
    getBoundingClientRect() { return { left: 0, top: 0, width: 1120, height: 672 }; },
    focus() {}, blur() {}, click() {},
    scrollIntoView() {},
    getContext() { const c = machKontext(); c.canvas = this; return c; },
    toDataURL() { return ""; },
    // Baumbeziehungen — flach gehalten, damit nichts endlos erzeugt wird
    parentElement: tiefe < 2 ? machElement("div", tiefe + 1) : null,
    parentNode: tiefe < 2 ? machElement("div", tiefe + 1) : null,
    firstChild: null, lastChild: null,
    firstElementChild: null, lastElementChild: null,
    nextSibling: null, previousSibling: null,
    nextElementSibling: null, previousElementSibling: null,
    // Maße und Rollzustand
    offsetWidth: 1120, offsetHeight: 672,
    clientWidth: 1120, clientHeight: 672,
    scrollWidth: 1120, scrollHeight: 672,
    scrollTop: 0, scrollLeft: 0,
    offsetTop: 0, offsetLeft: 0,
    checked: false, disabled: false, selected: false,
    scrollTo() {}, scrollBy() {},
    insertAdjacentHTML() {}, insertAdjacentElement() {},
    animate() { return { cancel() {}, finish() {} }; },
    getElementsByClassName() { return []; },
    getElementsByTagName() { return []; },
  };
  return el;
}

/* Lädt index.html und gibt die laufende Spielwelt zurück. */
/* umbau darf den Quelltext vor dem Laden anfassen. Gedacht fuer Messungen,
   die eine Konstante durchprobieren wollen — BEUTE_FAKTOR etwa steht als
   const im Skript und laesst sich von aussen nicht mehr umsetzen. Wer eine
   Reihe von Werten vergleichen will, laedt das Spiel je Wert einmal neu.

   Der Umbau muss etwas zurueckgeben, sonst laeuft das Original weiter. */
function ladeSpiel(datei, umbau) {
  const html = fs.readFileSync(datei, "utf8");
  const treffer = html.match(/<script>([\s\S]*)<\/script>/);
  if (!treffer) throw new Error("Kein <script>-Block in " + datei);
  let quelltext = treffer[1];
  if (umbau) {
    const umgebaut = umbau(quelltext);
    if (typeof umgebaut !== "string" || !umgebaut.length)
      throw new Error("umbau() hat keinen Quelltext geliefert");
    quelltext = umgebaut;
  }

  const speicher = {};
  const sandkasten = {};

  const fenster = {
    devicePixelRatio: 1,
    innerWidth: 1440, innerHeight: 900,
    addEventListener() {}, removeEventListener() {},
    AudioContext: undefined, webkitAudioContext: undefined,
    matchMedia: () => ({ matches: false, addEventListener() {} }),
    requestAnimationFrame: () => 0,
    setTimeout: () => 0, clearTimeout: () => {},
    setInterval: () => 0, clearInterval: () => {},
  };

  const dokument = {
    getElementById: (id) => machElement("div"),
    createElement: (tag) => machElement(tag),
    createElementNS: (ns, tag) => machElement(tag),
    createTextNode: () => machElement("text"),
    createDocumentFragment: () => machElement("fragment"),
    querySelector: () => machElement("div"),
    querySelectorAll: () => [],
    getElementsByClassName: () => [],
    getElementsByTagName: () => [],
    addEventListener() {}, removeEventListener() {},
    body: machElement("body"),
    head: machElement("head"),
    documentElement: machElement("html"),
    hidden: false,
    visibilityState: "visible",
    activeElement: null,
    fonts: { ready: Promise.resolve(), load: () => Promise.resolve() },
  };

  Object.assign(sandkasten, {
    window: fenster,
    document: dokument,
    localStorage: {
      getItem: (k) => (k in speicher ? speicher[k] : null),
      setItem: (k, v) => { speicher[k] = String(v); },
      removeItem: (k) => { delete speicher[k]; },
      clear: () => { for (const k in speicher) delete speicher[k]; },
    },
    navigator: { userAgent: "pruefstand" },
    performance: { now: () => Date.now() },
    /* Wirkungslos: Die Bildschleife des Spiels darf nicht von selbst
       anlaufen, sonst liefe sie neben unserem Takt her. */
    requestAnimationFrame: () => 0,
    cancelAnimationFrame: () => {},
    setTimeout: () => 0, clearTimeout: () => {},
    setInterval: () => 0, clearInterval: () => {},
    console,
    Math, Date, JSON, Object, Array, String, Number, Boolean, Error,
    Uint8ClampedArray, Float32Array, isNaN, isFinite, parseInt, parseFloat,
  });
  sandkasten.globalThis = sandkasten;
  sandkasten.self = sandkasten;

  const welt = vm.createContext(sandkasten);

  /* Am Ende des Spielskripts wird alles, was der Bot braucht, auf das globale
     Objekt gelegt.

     Nötig, weil top-level const im vm-Kontext eine lexikalische Bindung
     erzeugt und keine Eigenschaft von globalThis. Ohne diesen Anhang wäre
     nach dem Laden zwar alles vorhanden, aber von außen nicht erreichbar. */
  const anhang = `
;globalThis.__spiel = {
  G, MAPS, TOWERS, TOWER_BY_ID, SPECIES, BOSSES, TYPES, CHART, eff,
  TILE, COLS, ROWS, W, H, MEGA_NAMEN, LEGENDAER_GABE,
  WELLEN_JE_KARTE, BOSS_WAVES, isBossWave, bossFuerWelle, waveHP, refSpecHP,
  MEGA_KILLS, MEGA_TRAIN, MEGA_KOSTEN, TRAIN_MAX,
  newRun, startWave, endWave, update,
  placeTower, upgradeTower, sellTower, trainTower, trainCost,
  megaBereit, megaEntwickeln, megaStand, darfEntwickeln,
  canPlace, feldArt, darfHier, baueFelder,
  tierOf, statDmg, statRange, towerValue, sellValue, recalcAuras,
  istNacht, nachtAnteil, boon, rank,
  TALENTS, talCost, talentPointsLeft,
  sterne, sternVergeben, legendaerFrei,
  save, offerBoon, takeBoon,
  pathAt, genWave, estimateDefense, pickMod, pathCoverage,
  BOONS, takeBoon,
  HAIN, hainStufe, hainPreis, hainKaufen, trainGrenze, karteHatWasser, familieSetzbar,
  AUFSTELLUNG_MAX, WAECHTER_JE_KARTE, aufstellungFuer, aufstellung, waechterFrei,
  karteHatWasserAuf,
  sterneGesamt,
  FELD_VULKAN_BONUS, FELD_KRAFT_BONUS, FELD_HOEHE_BONUS,
  heimTyp, istHeimWaechter, HEIM_WAECHTER_SCHADEN, legendaerDef,
  beerenAbrechnen, BEEREN_JE_PUNKT, BEEREN_PUNKTE_MAX,
};`;

  vm.runInContext(quelltext + anhang, welt, { filename: "index.html:script" });
  if (!welt.__spiel) throw new Error("Export fehlgeschlagen");
  return welt.__spiel;
}

module.exports = { ladeSpiel };

/* Direkt aufgerufen: prüfen, ob das Laden klappt. */
if (require.main === module) {
  const datei = process.argv[2] || path.join(__dirname, "..", "index.html");
  const s = ladeSpiel(datei);
  console.log("Spiel geladen aus", path.basename(datei));
  console.log("  Wächterfamilien:", s.TOWERS.length);
  console.log("  Gegnerarten:    ", s.SPECIES.length, "+", s.BOSSES.length, "Anführer");
  console.log("  Wellen je Karte:", s.WELLEN_JE_KARTE);
  console.log("  Karten:         ", s.MAPS.map((m) => m.name).join(", "));
  console.log("  Kurve:          ", [1, 25, 50, 75, 100]
    .map((w) => "W" + w + "=" + Math.round(s.waveHP(w, 1))).join("  "));
}
