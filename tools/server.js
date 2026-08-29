#!/usr/bin/env node
/* ============================================================
   PocketBeast — Dateiserver zum Ausprobieren
   ============================================================

   index.html direkt aus dem Dateisystem zu öffnen genügt fast, aber nicht
   ganz: localStorage verhält sich unter file:// je nach Browser anders, und
   der Spielstand ist genau das, was man beim Ausprobieren braucht.

   Warum nicht python3 -m http.server: Dessen Argumentaufbau ruft beim
   Starten os.getcwd() auf. Läuft der Prozess in einer Umgebung, die das
   Arbeitsverzeichnis nicht preisgibt, bricht er noch vor der ersten Zeile
   ab — mit einer Meldung, die aussieht als läge es am Verzeichnis. Hier
   steht der Pfad fest im Skript, also kann das nicht passieren.

   Aufruf:
     node tools/server.js [Port]
   ============================================================ */

const http = require("http");
const fs = require("fs");
const path = require("path");

const WURZEL = path.join(__dirname, "..");
const PORT = parseInt(process.argv[2] || process.env.PORT || "8731", 10);

const TYPEN = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".md": "text/plain; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".ico": "image/x-icon",
};

http.createServer((req, res) => {
  let pfad = decodeURIComponent(req.url.split("?")[0]);
  if (pfad.endsWith("/")) pfad += "index.html";

  /* Nichts außerhalb der Wurzel ausliefern. Ohne diese Prüfung genügte ein
     ../../ in der Anfrage, um jede Datei des Rechners zu holen. */
  const ziel = path.normalize(path.join(WURZEL, pfad));
  if (!ziel.startsWith(WURZEL)) {
    res.writeHead(403).end("verboten");
    return;
  }

  fs.readFile(ziel, (fehler, daten) => {
    if (fehler) {
      res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      res.end("nicht gefunden: " + pfad);
      return;
    }
    res.writeHead(200, {
      "content-type": TYPEN[path.extname(ziel).toLowerCase()] || "application/octet-stream",
      "cache-control": "no-store",
    });
    res.end(daten);
  });
}).listen(PORT, () => {
  console.log("PocketBeast läuft auf http://localhost:" + PORT + "/");
});
