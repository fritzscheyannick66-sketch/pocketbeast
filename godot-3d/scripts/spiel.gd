extends RefCounted
##
## Spielzustand und Regeln der 3D-Fassung.
##
## Getrennt von welt.gd, weil dort das Zeichnen wohnt: Gelände, Bewuchs,
## Licht, Kamera. Was ein Wächter kostet, wie viele Leben bleiben und wann
## die nächste Welle kommt, hat damit nichts zu tun — und lässt sich so
## prüfen, ohne dass eine Szene laufen muss.
##
## Die Zahlen kommen aus daten.gd, also aus dem Browserspiel. Was hier steht,
## sind nur die Regeln, die beide Fassungen teilen.
##

const Daten = preload("res://scripts/daten.gd")

## Godot rechnet in Metern, das Browserspiel in Pixeln.
## Eine Kachel misst dort 56 Pixel und hier 2 Meter.
const PIXEL_JE_METER := 28.0

var karte_idx := 0
var beeren := 0
var leben := 0
var welle := 0
var punkte := 0
var durchgelassen := 0

## Läuft gerade eine Welle, oder wartet das Spiel auf den nächsten Ruf?
var welle_laeuft := false
var verloren := false
## Alle Wellen der Karte gehalten. Ohne das lief die Runde ins Leere: Bei
## Welle 100 kam einfach Welle 101, und die Kampagne hatte kein Ende.
var gewonnen := false
var endlos := false

## Was in dieser Welle noch zu schicken ist.
var warteschlange: Array[Dictionary] = []
var spawn_uhr := 0.0


func starte(idx: int) -> void:
	karte_idx = idx
	var k: Dictionary = Daten.KARTEN[idx]
	beeren = int(k["beeren"])
	leben = int(k["leben"])
	welle = 0
	punkte = 0
	durchgelassen = 0
	welle_laeuft = false
	verloren = false
	gewonnen = false
	warteschlange.clear()


func karte() -> Dictionary:
	return Daten.KARTEN[karte_idx]


func waechter_def(id: String) -> Dictionary:
	for w in Daten.WAECHTER:
		if w["id"] == id:
			return w
	return {}


## Was die erste Stufe eines Wächters kostet.
func baukosten(id: String) -> int:
	var def := waechter_def(id)
	if def.is_empty():
		return 999999
	return int(def["stufen"][0]["kosten"])


## Was die nächste Stufe kostet. -1, wenn schon auf Endstufe.
func ausbaukosten(id: String, stufe: int) -> int:
	if stufe >= 2:
		return -1
	var def := waechter_def(id)
	if def.is_empty():
		return -1
	return int(def["stufen"][stufe + 1]["kosten"])


## ============================================================
## Ausbau
## ============================================================

## Ab wann ein Wächter die Megaentwicklung erreichen kann.
## Dieselben Schwellen wie im Browserspiel.
const MEGA_ERLEDIGT := 40
const MEGA_TRAINING := 6
const MEGA_KOSTEN := 650
const TRAIN_MAX := 15


## Was die nächste Trainingsstufe kostet. Wächst um 24 Prozent je Stufe —
## dadurch bleibt Training früh günstig und wird spät zum Beerengrab.
func trainingskosten(stufe: int) -> int:
	return int(round(80.0 * pow(1.24, float(stufe))))


## Wieviel Schaden das Training zusätzlich bringt: neun Prozent je Stufe.
static func trainingsfaktor(stufe: int) -> float:
	return 1.0 + float(stufe) * 0.09


## Steht die Megaentwicklung bereit?
##
## Sie hängt nicht am Geld allein, sondern an einem Wächter, der lange genug
## gelebt und lange genug getroffen hat. Ein frisch gekaufter kommt nie
## dorthin — das belohnt Pflege statt Nachschub.
func mega_bereit(turm: Dictionary) -> bool:
	if turm.get("mega", false):
		return false
	if int(turm.get("stufe", 0)) < 2:
		return false
	if int(turm.get("erledigt", 0)) < MEGA_ERLEDIGT:
		return false
	if int(turm.get("training", 0)) < MEGA_TRAINING:
		return false
	return true


## Die Werte der Megaentwicklung, abgeleitet aus der Endstufe.
## Schaden mal 1,75, Feuerrate mal 1,15, Reichweite mal 1,18 —
## dieselben Faktoren wie im Browserspiel.
static func mega_werte(endstufe: Dictionary) -> Dictionary:
	var m := endstufe.duplicate(true)
	m["schaden"] = float(endstufe["schaden"]) * 1.75
	m["rate"] = float(endstufe["rate"]) * 1.15
	m["reichweite"] = float(endstufe["reichweite"]) * 1.18
	if endstufe.has("durchschlag"):
		m["durchschlag"] = float(endstufe["durchschlag"]) * 1.5
	return m


## Was ein Wächter beim Entlassen zurückbringt: sechzig Prozent des
## Gezahlten. Wer umbaut, verliert etwas — sonst wäre jede Aufstellung
## beliebig, weil man sie jederzeit kostenlos umwerfen könnte.
func entlassungswert(turm: Dictionary) -> int:
	var def := waechter_def(String(turm.get("id", "")))
	if def.is_empty():
		return 0
	var summe := 0
	for i in range(int(turm.get("stufe", 0)) + 1):
		summe += int(def["stufen"][i]["kosten"])
	summe += int(turm.get("trainingsausgaben", 0))
	if turm.get("mega", false):
		summe += MEGA_KOSTEN
	return int(round(float(summe) * 0.6))


## ============================================================
## Wellen
## ============================================================

## Stellt die nächste Welle zusammen.
##
## Anders als im Browserspiel, wo eine Welle aus bis zu drei Arten besteht
## und die Lebenspunkte gegen deren durchschnittliche Zähigkeit normiert
## werden, sind es hier zwei Arten mit fester Aufteilung. Der Feinschliff
## gehört ins Browserspiel, solange dieses die spielbare Fassung ist —
## zwei Fassungen derselben Rechnung driften auseinander.
func rufe_welle() -> void:
	if welle_laeuft or verloren:
		return
	if gewonnen and not endlos:
		return
	welle += 1
	welle_laeuft = true
	warteschlange.clear()

	var faktor: float = float(karte()["faktor"])
	# Typ ausdrücklich angeben: Array-Werte haben in GDScript keinen
	# abgeleiteten Typ, := scheitert daran.
	var stufe: float = float(Daten.WELLE_LEBEN[clampi(welle - 1, 0, Daten.WELLE_LEBEN.size() - 1)])
	var budget: float = stufe * faktor

	# Welche Arten dürfen schon auftreten? Zähigkeit wächst mit der Welle.
	var grenze := 0.9 + float(welle) * 0.055
	var moeglich: Array = []
	for a in Daten.ARTEN:
		if float(a["leben"]) <= grenze:
			moeglich.append(a)
	if moeglich.size() < 2:
		moeglich = Daten.ARTEN.slice(0, 4)

	## Bodengarantie wie im Browserspiel: Eine Welle darf nie vollständig aus
	## Fliegern bestehen. Gegen eine solche fällt jeder bodengebundene
	## Wächter aus, und wer nicht zufällig Luftabwehr stehen hat, verliert
	## die Welle vollständig.
	var arten: Array = []
	arten.append(moeglich[randi() % moeglich.size()])
	var zweite: Dictionary = moeglich[randi() % moeglich.size()]
	if arten[0].get("fliegt", false) and zweite.get("fliegt", false):
		var boden: Array = []
		for a in moeglich:
			if not a.get("fliegt", false):
				boden.append(a)
		if not boden.is_empty():
			zweite = boden[randi() % boden.size()]
	arten.append(zweite)

	var stueck := 8 + welle
	for i in range(stueck):
		var art: Dictionary = arten[i % arten.size()]
		warteschlange.append({
			"art": art,
			"leben": budget * float(art["leben"]) / float(stueck),
		})
	spawn_uhr = 0.0


## Ein Gegner ist durchgekommen.
func durchbruch() -> void:
	durchgelassen += 1
	leben -= 1
	if leben <= 0:
		leben = 0
		verloren = true


## Ein Gegner wurde erledigt.
func erledigt(art: Dictionary) -> void:
	beeren += int(round(float(art["beute"]) * (1.0 + float(welle) * 0.08)))
	punkte += 10 + welle


## Welle vorbei — Belohnung.
func welle_geschafft() -> void:
	welle_laeuft = false
	if welle >= Daten.WELLEN_JE_KARTE and not endlos:
		gewonnen = true
	var bonus := 22 + welle * 5
	beeren += bonus
	punkte += 120 + welle * 20


## ============================================================
## Schaden
## ============================================================

## Was ein Treffer wirklich anrichtet.
##
## Zwei Dinge stehen zwischen Angriff und Wirkung: der Typenvorteil
## vervielfacht, die Panzerung wird ABGEZOGEN. Deshalb ist Panzerung für
## einen schnellen Kleinschützen tödlich und für einen schweren Schläger nur
## lästig — der Wind-Wächter macht fünfzehn Schaden je Treffer und kommt
## gegen Panzerung achtzehn auf null, der Stahl-Wächter mit
## hundertachtundfünfzig kaum ins Stocken.
##
## Ein Rest bleibt immer: Ein Treffer, der gar nichts bewirkt, sieht wie ein
## Fehler aus, auch wenn er rechnerisch stimmt.
static func schaden(roh: float, angriffstyp: String, zieltyp: String,
		panzer: float, durchschlag: float) -> float:
	var d := roh * Daten.wirksamkeit(angriffstyp, zieltyp)
	var rest := maxf(0.0, panzer - durchschlag)
	return maxf(d * 0.06, d - rest)


## Panzerung eines Gegners in einer bestimmten Welle.
##
## Dieselbe Dämpfung wie im Browserspiel: 3,8 Prozent Wachstum je Welle, und
## der Schwierigkeitsfaktor der Karte geht nur zur Hälfte ein. Voll
## angewandt machte er die schwerste Karte undurchdringlich — Monolithor kam
## dort auf 216 Panzerung, während der stärkste gewöhnliche Wächter 158
## Schaden macht.
static func panzerung(grund: float, w: int, kartenfaktor: float) -> float:
	var wellenskala := 1.0 + float(w - 1) * 0.038
	var kartenskala := 1.0 + (kartenfaktor - 1.0) * 0.5
	return grund * wellenskala * kartenskala
