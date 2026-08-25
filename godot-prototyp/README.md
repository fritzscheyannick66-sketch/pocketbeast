# Godot-Prototyp

Ein Machbarkeitstest, kein Spiel. Er beantwortet eine einzige Frage:
**Wie fühlt sich PocketBeast an, wenn man es in Godot baut?**

Hintergrund: Das Spiel im übergeordneten Ordner läuft im Browser
(HTML und JavaScript). Für eine Veröffentlichung bei Steam oder in einem
App-Store reicht das nicht — dafür braucht es eine Engine. Godot kann jedoch
kein JavaScript ausführen, ein Umzug bedeutet also **vollständiges Neuschreiben**.

Bevor jemand Wochen investiert, zeigt dieser Prototyp den Kern in klein.

## Starten

Godot 4.7 öffnen → *Import* → diesen Ordner wählen → *Run* (F5).

## Was drin ist

- Der Weg des Grünpfads, samt Selbstkreuzung
- Gegner, die ihm folgen, mit Lebensbalken
- Zwei Wächter, die Ziele suchen, feuern und treffen
- Grafik vollständig zur Laufzeit gezeichnet, wie im Original — keine Bilddateien
- Zähler für erledigte und durchgebrochene Gegner

Getestet: läuft ohne Fehler, nach neun Sekunden waren drei Gegner erledigt
und keiner durchgebrochen.

## Was bewusst fehlt

Und das ist der eigentliche Punkt dieses Ordners — die Liste ist lang:

| Bereich | Im Browserspiel | Hier |
|---|---|---|
| Elementtypen | 8 mit Effektivitätstabelle | 0 |
| Wächter | 8 Familien à 3 Entwicklungsstufen | 2 feste |
| Gegnerarten | 32 plus 8 Bosse | 1 |
| Wellen | 40, mit Launen und Segnungen | Dauerstrom |
| Karten | 3, davon eine mit Gabelung | 1 |
| Klang | 12 Arten, prozedural erzeugt | keiner |
| Speicherstand, Talentbaum | vorhanden | fehlt |
| Wegglättung | ja, geschwungen | nein, eckig |

**227 Zeilen gegenüber 3.914.** Der Prototyp deckt grob fünf bis zehn Prozent ab —
und zwar den einfachsten Teil. Balance, Darstellung und Feinschliff sind der
weitaus größere Aufwand, und sie stecken im Browserspiel bereits durchgemessen
drin.

## Was er zeigt

Dass es geht. Die Zeichenbefehle sind ähnlich (`draw_circle` statt `arc`), die
Spielschleife ebenso (`_process(delta)` statt `requestAnimationFrame`). Wer
JavaScript lesen kann, findet sich in GDScript schnell zurecht.

Der Unterschied liegt nicht in der Schwierigkeit, sondern in der **Menge**.
