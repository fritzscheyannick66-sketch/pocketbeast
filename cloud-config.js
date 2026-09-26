/* ============================================================
   PocketBeast — Zugang zur Spielstandwolke
   ============================================================

   HIER TRÄGST DU ZWEI WERTE EIN. Beide sind öffentlich und dürfen im
   Quelltext stehen — sie erlauben für sich genommen nichts, was ein Spieler
   nicht ohnehin darf. Der geheime service_role-Schlüssel gehört NICHT
   hierher und wird vom Spiel nie gebraucht.

   Wo du sie findest, steht in WOLKE.md.

   Bleiben beide leer, läuft das Spiel genau wie vorher: Der Spielstand liegt
   im Browser, und die Anmeldung erscheint gar nicht erst. Das ist Absicht —
   das Spiel darf nie davon abhängen, dass ein Dienst erreichbar ist.
   ============================================================ */
window.POCKETBEAST_WOLKE = {
  url: "",   // z. B. https://abcdefghijklm.supabase.co
  key: "",   // der anon- bzw. publishable-Schlüssel
};
