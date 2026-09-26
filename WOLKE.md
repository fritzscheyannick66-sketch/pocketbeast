# Spielstand in der Wolke einrichten

Etwa zwanzig Minuten, einmalig. Danach melden sich Spieler mit ihrer E-Mail
an und haben denselben Stand auf Handy, Tablet und Rechner.

**Bis das eingerichtet ist, ändert sich nichts.** Bleiben die beiden Werte in
`cloud-config.js` leer, erscheint die Anmeldung gar nicht erst und der
Spielstand liegt wie bisher im Browser. Das Spiel darf nie davon abhängen,
dass ein Dienst erreichbar ist.

---

## 1. Konto anlegen

[supabase.com](https://supabase.com) → **Start your project** → mit GitHub
anmelden. Kostenloses Kontingent: zwei Projekte, 500 MB Datenbank, 50.000
aktive Nutzer im Monat. Für PocketBeast ist das reichlich.

Neues Projekt anlegen. Als Region **Frankfurt (eu-central-1)** wählen — die
Daten deiner Spieler bleiben damit in der EU, was die Datenschutzfrage
erheblich vereinfacht.

> Das Datenbankpasswort, nach dem gefragt wird, brauchst du für PocketBeast
> nie. Leg es trotzdem in deinem Passwortspeicher ab.

## 2. Tabelle und Zeilenregeln

Im Projekt links auf **SQL Editor**, das Folgende einfügen und ausführen:

```sql
-- Ein Spielstand je Spieler, als JSON.
--
-- Warum JSON und keine ausgefalteten Spalten: Der Spielstand wächst mit dem
-- Spiel. Heute sind es Sterne, Punkte, Ränge und Aufstellungen, morgen kommt
-- etwas dazu — und dann müsste die Datenbank mitwandern, während alte
-- Fassungen des Spiels weiterlaufen. Als JSON ist das ein Feld, das jede
-- Fassung so liest, wie sie es versteht.
create table if not exists staende (
  spieler    uuid primary key references auth.users(id) on delete cascade,
  stand      jsonb not null,
  geaendert  timestamptz not null default now()
);

-- Zeilenregeln. OHNE DIESE ZEILEN KÖNNTE JEDER JEDEN STAND LESEN.
--
-- Der Schlüssel im Spiel ist öffentlich; er steht im Quelltext und jeder
-- kann ihn auslesen. Dass trotzdem niemand an fremde Stände kommt,
-- entscheidet allein die Datenbank hier. Ein Schutz, der im Browser liegt,
-- ist keiner.
alter table staende enable row level security;

create policy "nur den eigenen lesen"
  on staende for select
  using (auth.uid() = spieler);

create policy "nur den eigenen schreiben"
  on staende for insert
  with check (auth.uid() = spieler);

create policy "nur den eigenen ändern"
  on staende for update
  using (auth.uid() = spieler)
  with check (auth.uid() = spieler);

-- Ein Spieler darf seinen Stand auch löschen. Das ist keine Höflichkeit,
-- sondern nach DSGVO sein Recht.
create policy "nur den eigenen löschen"
  on staende for delete
  using (auth.uid() = spieler);
```

**Prüfen, dass es gewirkt hat:** Links auf **Table Editor** → `staende`. Oben
muss **RLS enabled** stehen. Steht dort **RLS disabled**, ist die Tabelle für
jeden lesbar — dann noch einmal `alter table … enable row level security;`
ausführen.

## 3. E-Mail auf Zahlencode umstellen

Supabase verschickt ab Werk einen anklickbaren Link. Der öffnet die Mail-App,
und die öffnet ihn im **Standardbrowser** — wer in Chrome spielt, aber Safari
als Standard hat, ist danach in Safari angemeldet und in Chrome nicht. Auf
dem Handy ist das der Normalfall, nicht der Randfall.

**Authentication** → **Emails** → Vorlage **Magic Link**. Den Inhalt
ersetzen durch:

```html
<h2>Dein Anmeldecode für PocketBeast</h2>
<p>Gib diesen Code im Spiel ein:</p>
<p style="font-size:28px;letter-spacing:6px"><strong>{{ .Token }}</strong></p>
<p>Er gilt eine Stunde. Hast du ihn nicht angefordert, ignoriere diese Mail.</p>
```

Entscheidend ist `{{ .Token }}` statt `{{ .ConfirmationURL }}`.

## 4. Die zwei Werte eintragen

**Project Settings** → **API**:

| Dort | In `cloud-config.js` |
|---|---|
| Project URL | `url` |
| `anon` / `publishable` key | `key` |

Beide sind öffentlich und gehören in den Quelltext.

> **Den `service_role`-Schlüssel niemals.** Er umgeht sämtliche
> Zeilenregeln. Wer ihn hat, liest und ändert jeden Spielstand. Er gehört
> nicht ins Spiel, nicht ins Verzeichnis und nicht in eine Nachricht.

Dann pushen — fertig.

## 5. Eigene Mailversand-Adresse (später)

Der eingebaute Versand ist auf **zwei Mails pro Stunde** gedeckelt. Das
reicht zum Ausprobieren und für niemanden sonst: Drei Freunde, die sich
gleichzeitig anmelden, bekommen schon keine Mail mehr.

Sobald mehr als du selbst spielen: **Authentication** → **Emails** → **SMTP
Settings**, und dort einen Versanddienst eintragen
([Resend](https://resend.com) und [Brevo](https://www.brevo.com) haben
kostenlose Kontingente von einigen tausend Mails im Monat).

---

## Was du damit übernimmst

Du speicherst **E-Mail-Adressen deiner Spieler**. Das sind personenbezogene
Daten, und damit gilt:

- **Datenschutzerklärung.** Sie muss sagen, was du speicherst (E-Mail und
  Spielstand), wozu (Anmeldung und geräteübergreifender Fortschritt), wo
  (Supabase, EU-Region) und wie lange.
- **Löschung auf Anfrage.** Ein Spieler kann verlangen, dass sein Konto
  verschwindet. In Supabase: **Authentication** → **Users** → Nutzer
  löschen; der Spielstand geht durch `on delete cascade` automatisch mit.
- **Alter.** Bei einem bunten Tower-Defense spielen Kinder mit. In
  Deutschland brauchen Einwilligungen unter sechzehn die der Eltern. Das ist
  ein Grund, die Anmeldung **freiwillig** zu lassen — genau so ist sie
  gebaut: Wer sich nie anmeldet, spielt vollständig.
- **App Store und Steam** fragen beide ab, welche Daten du erhebst. Mit
  E-Mail-Anmeldung lautet die Antwort nicht mehr „keine".

Wenn dir das zu viel wird: Die Anmeldung lässt sich abschalten, indem du die
beiden Werte in `cloud-config.js` wieder leerst. Das Spiel läuft dann wie
vorher, und die Sicherung über die Zwischenablage bleibt.

---

## Wenn etwas nicht geht

| Meldung | Grund |
|---|---|
| *Email rate limit exceeded* | Die zwei Mails pro Stunde sind aufgebraucht — siehe Schritt 5. |
| *Token has expired or is invalid* | Code älter als eine Stunde oder vertippt. Neuen anfordern. |
| *permission denied for table staende* | Die Zeilenregeln fehlen. Schritt 2 noch einmal. |
| Anmeldung klappt, Stand kommt nicht | In der Mail steht noch ein Link statt einer Zahl — Schritt 3. |
| Gar keine Anmeldung im Menü | `cloud-config.js` ist leer oder wurde nicht mit ausgeliefert. |
