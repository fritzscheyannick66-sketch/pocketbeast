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
