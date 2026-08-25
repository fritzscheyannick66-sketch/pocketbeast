extends Node2D
##
## PocketBeast — Godot-Prototyp
##
## Zweck: zeigen, wie sich derselbe Spielabschnitt in Godot anfühlt, bevor
## jemand Wochen in einen vollständigen Umbau steckt. Enthalten ist nur der
## Kern: ein Weg, Gegner die ihm folgen, Wächter die schießen, und Grafik die
## wie im Original zur Laufzeit gezeichnet wird — keine Bilddateien.
##
## Bewusst NICHT enthalten: Entwicklungsstufen, acht Elementtypen, Wellen-
## Launen, Segnungen, Talentbaum, Klang, Speicherstand. Das ist der Rest der
## Arbeit, und er ist der weitaus größere Teil.
##

const TILE := 56
const SPALTEN := 20
const ZEILEN := 12
const BREITE := SPALTEN * TILE
const HOEHE := ZEILEN * TILE

# Dieselbe Route wie im Browserspiel: eine Schlinge, die sich selbst kreuzt.
const WEGPUNKTE: Array[Vector2i] = [
	Vector2i(-1, 6), Vector2i(3, 6), Vector2i(3, 2), Vector2i(9, 2),
	Vector2i(9, 9), Vector2i(5, 9), Vector2i(5, 5), Vector2i(13, 5),
	Vector2i(13, 10), Vector2i(17, 10), Vector2i(17, 4), Vector2i(20, 5),
]

# Farben aus dem Browserspiel übernommen, damit der Vergleich fair ist
const C_BODEN := Color("16261c")
const C_BODEN2 := Color("1a2e21")
const C_WEG := Color("5a4632")
const C_WEGRAND := Color("2a2117")
const C_FEUER := Color("ff6e45")
const C_PFLANZE := Color("57ce7c")

var weg: PackedVector2Array = []
var weg_laenge: float = 0.0
var _weg_abschnitte: Array[float] = []   # aufsummierte Länge bis zu jedem Punkt

var gegner: Array[Dictionary] = []
var tuerme: Array[Dictionary] = []
var schuesse: Array[Dictionary] = []

var zeit := 0.0
var spawn_uhr := 0.0
var durchgebrochen := 0
var erledigt := 0


func _ready() -> void:
	baue_weg()
	# Wächter bewusst früh am Weg, damit gleich nach dem Start etwas passiert.
	# Weiter hinten platziert dauerte der erste Kontakt rund 30 Sekunden.
	setze_turm(Vector2(2 * TILE + TILE / 2.0, 4 * TILE + TILE / 2.0), C_FEUER, 150.0, 1.6, 14.0)
	setze_turm(Vector2(7 * TILE + TILE / 2.0, 6 * TILE + TILE / 2.0), C_PFLANZE, 150.0, 1.3, 11.0)


## Wandelt die Kachelkoordinaten in Weltpunkte und misst die Gesamtlänge.
## Godot bringt mit Curve2D etwas Fertiges mit — hier bewusst von Hand, damit
## der Vergleich zum JavaScript-Original eins zu eins sichtbar bleibt.
func baue_weg() -> void:
	weg.clear()
	for p in WEGPUNKTE:
		weg.append(Vector2(p.x * TILE + TILE / 2.0, p.y * TILE + TILE / 2.0))
	_weg_abschnitte.clear()
	weg_laenge = 0.0
	_weg_abschnitte.append(0.0)
	for i in range(weg.size() - 1):
		weg_laenge += weg[i].distance_to(weg[i + 1])
		_weg_abschnitte.append(weg_laenge)


## Position auf dem Weg nach zurückgelegter Strecke.
func punkt_bei(strecke: float) -> Vector2:
	if strecke <= 0.0:
		return weg[0]
	if strecke >= weg_laenge:
		return weg[weg.size() - 1]
	for i in range(weg.size() - 1):
		if strecke <= _weg_abschnitte[i + 1]:
			var anteil := (strecke - _weg_abschnitte[i]) / (_weg_abschnitte[i + 1] - _weg_abschnitte[i])
			return weg[i].lerp(weg[i + 1], anteil)
	return weg[weg.size() - 1]


func setze_turm(pos: Vector2, farbe: Color, reichweite: float, takt: float, schaden: float) -> void:
	tuerme.append({
		"pos": pos, "farbe": farbe, "reichweite": reichweite,
		"takt": takt, "schaden": schaden, "abklingen": 0.0, "blick": 0.0,
	})


func spawne_gegner() -> void:
	gegner.append({
		"strecke": 0.0, "pos": weg[0], "tempo": 46.0 + randf() * 18.0,
		"leben": 40.0, "max_leben": 40.0, "wackel": randf() * 6.0,
	})


func _process(delta: float) -> void:
	zeit += delta

	spawn_uhr -= delta
	if spawn_uhr <= 0.0:
		spawne_gegner()
		spawn_uhr = 1.1

	# Gegner vorwärts bewegen
	for g in gegner:
		g["strecke"] += g["tempo"] * delta
		g["pos"] = punkt_bei(g["strecke"])

	# Wächter feuern auf den weitesten Gegner in Reichweite
	for t in tuerme:
		t["abklingen"] -= delta
		var ziel: Dictionary = {}
		var beste_strecke := -1.0
		for g in gegner:
			if g["pos"].distance_to(t["pos"]) <= t["reichweite"] and g["strecke"] > beste_strecke:
				beste_strecke = g["strecke"]
				ziel = g
		if not ziel.is_empty():
			t["blick"] = (ziel["pos"] - t["pos"]).angle()
			if t["abklingen"] <= 0.0:
				t["abklingen"] = 1.0 / t["takt"]
				schuesse.append({
					"pos": t["pos"], "ziel": ziel, "farbe": t["farbe"],
					"schaden": t["schaden"], "tempo": 340.0,
				})

	# Schüsse fliegen
	var uebrige_schuesse: Array[Dictionary] = []
	for s in schuesse:
		var z: Dictionary = s["ziel"]
		if z.is_empty() or z["leben"] <= 0.0:
			continue
		var richtung: Vector2 = z["pos"] - s["pos"]
		if richtung.length() < 10.0:
			z["leben"] -= s["schaden"]
			continue
		s["pos"] += richtung.normalized() * s["tempo"] * delta
		uebrige_schuesse.append(s)
	schuesse = uebrige_schuesse

	# Aufräumen: erledigt oder durchgebrochen
	var uebrige: Array[Dictionary] = []
	for g in gegner:
		if g["leben"] <= 0.0:
			erledigt += 1
		elif g["strecke"] >= weg_laenge:
			durchgebrochen += 1
		else:
			uebrige.append(g)
	gegner = uebrige

	queue_redraw()


func _draw() -> void:
	zeichne_gelaende()
	zeichne_weg()
	for t in tuerme:
		zeichne_turm(t)
	for g in gegner:
		zeichne_gegner(g)
	for s in schuesse:
		draw_circle(s["pos"], 3.5, s["farbe"])
	zeichne_anzeige()


func zeichne_gelaende() -> void:
	draw_rect(Rect2(0, 0, BREITE, HOEHE), C_BODEN)
	# grobe Bodenstruktur, damit die Fläche nicht tot wirkt
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = 12345
	for i in range(90):
		var x := wuerfel.randf() * BREITE
		var y := wuerfel.randf() * HOEHE
		var r := 6.0 + wuerfel.randf() * 22.0
		draw_circle(Vector2(x, y), r, C_BODEN2)


## Der Weg entsteht aus mehreren Strichen übereinander — genau wie im
## Browserspiel. Dadurch sieht die Selbstkreuzung sauber aus statt zerschnitten.
func zeichne_weg() -> void:
	draw_polyline(weg, C_WEGRAND, TILE * 0.96, true)
	draw_polyline(weg, C_WEG, TILE * 0.78, true)


func zeichne_turm(t: Dictionary) -> void:
	var p: Vector2 = t["pos"]
	# Reichweite andeuten
	draw_arc(p, t["reichweite"], 0, TAU, 48, Color(t["farbe"], 0.18), 1.5)
	# Körper: dieselbe Idee wie im Original — Rundung, Augen, kein Bild nötig
	draw_circle(p + Vector2(0, 3), 15.0, Color(0, 0, 0, 0.35))
	draw_circle(p, 14.0, t["farbe"])
	draw_circle(p, 14.0, Color(0, 0, 0, 0.55), false, 2.0)
	var winkel: float = t["blick"]
	var blick := Vector2(cos(winkel), sin(winkel)) * 3.0
	draw_circle(p + Vector2(-5, -3) + blick, 2.6, Color.WHITE)
	draw_circle(p + Vector2(5, -3) + blick, 2.6, Color.WHITE)
	draw_circle(p + Vector2(-5, -3) + blick, 1.3, Color("0d1418"))
	draw_circle(p + Vector2(5, -3) + blick, 1.3, Color("0d1418"))


func zeichne_gegner(g: Dictionary) -> void:
	var p: Vector2 = g["pos"]
	var wackel: float = g["wackel"]
	var huepf := sin(zeit * 6.0 + wackel) * 2.0
	var mitte := p + Vector2(0, huepf)
	draw_circle(p + Vector2(0, 8), 9.0, Color(0, 0, 0, 0.3))
	draw_circle(mitte, 11.0, Color("c382ff"))
	draw_circle(mitte, 11.0, Color(0, 0, 0, 0.5), false, 1.8)
	draw_circle(mitte + Vector2(-4, -2), 2.2, Color.WHITE)
	draw_circle(mitte + Vector2(4, -2), 2.2, Color.WHITE)
	# Lebensbalken
	var anteil: float = clampf(g["leben"] / g["max_leben"], 0.0, 1.0)
	draw_rect(Rect2(p.x - 12, p.y - 20, 24, 4), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(p.x - 12, p.y - 20, 24 * anteil, 4), C_PFLANZE)


func zeichne_anzeige() -> void:
	var schrift := ThemeDB.fallback_font
	var text := "Prototyp · erledigt: %d · durchgebrochen: %d · Wilde im Feld: %d" % [
		erledigt, durchgebrochen, gegner.size()
	]
	draw_string(schrift, Vector2(16, 26), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e6eef2"))
