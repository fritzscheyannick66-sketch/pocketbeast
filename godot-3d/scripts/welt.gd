extends Node3D
##
## PocketBeast 3D — Grundgerüst
##
## Erster Schritt der Umstellung auf echte dreidimensionale Darstellung.
## Enthalten ist die Grundlage, auf der alles Weitere aufbaut: beleuchtete
## Szene mit Schattenwurf, welliges Gelände, ein Weg darauf, Wächter und
## Gegner als Körper im Raum.
##
## Was hier NICHT steht, ist der weitaus größere Teil: zehn Wächterfamilien mit
## Entwicklungsstufen, 32 Gegnerarten, Wellenaufbau, Elementtabelle, Segnungen,
## Talentbaum, Klang, Speicherstand, Oberfläche. Siehe README.
##

# Ausdrücklich geladen statt über class_name: Godot kennt Klassennamen erst
# nach einem Projekt-Scan, was einen frisch geklonten Ordner beim ersten Start
# scheitern ließe.
const Gelaende = preload("res://scripts/gelaende.gd")
const Weg = preload("res://scripts/weg.gd")
const Pflanzen = preload("res://scripts/pflanzen.gd")
const Daten = preload("res://scripts/daten.gd")
const Spiel = preload("res://scripts/spiel.gd")
const Bedienung = preload("res://scripts/bedienung.gd")

# Route des Grünpfads, in Kachelkoordinaten wie im Browserspiel
const ROUTE := [
	# Dieselbe Führung wie der Grünpfad im Browserspiel — Kachelkoordinaten,
	# damit beide Fassungen dieselbe Karte zeigen. Wird die Route dort
	# geändert, gehört sie auch hier nachgezogen.
	Vector2(-1, 6), Vector2(3, 6), Vector2(3, 3), Vector2(9, 3),
	Vector2(9, 9), Vector2(5, 9), Vector2(5, 5), Vector2(13, 5),
	Vector2(13, 10), Vector2(17, 10), Vector2(17, 4), Vector2(20, 5),
]

var weg_punkte: PackedVector3Array
var weg_laenge: float

var gegner: Array[Dictionary] = []
var tuerme: Array[Dictionary] = []

var zeit := 0.0
var spawn_uhr := 0.0
var erledigt := 0
var durchgebrochen := 0

## Welche Karte gespielt wird — bestimmt den Schwierigkeitsfaktor.
var spiel = Spiel.new()
var bedienung: CanvasLayer
var kamera: Camera3D

## Was gerade zum Bauen gewählt ist, und wo der Zeiger hindeutet.
var gewaehlt := ""
var zeiger_kachel := Vector2i(-99, -99)
var vorschau: Node3D
var tempo := 1

## Welche Kacheln schon belegt sind — Wegkacheln und gesetzte Wächter.
var belegt: Dictionary = {}

@onready var _wurzel_gegner := Node3D.new()
@onready var _wurzel_schuesse := Node3D.new()


func _ready() -> void:
	add_child(_wurzel_gegner)
	add_child(_wurzel_schuesse)
	_baue_umgebung()
	_baue_licht()
	_baue_kamera()
	_baue_welt()
	_baue_bewuchs()
	_sperre_wegkacheln()

	spiel.starte(0)
	bedienung = Bedienung.new()
	add_child(bedienung)
	bedienung.waechter_gewaehlt.connect(_auf_auswahl)
	bedienung.welle_gerufen.connect(_auf_wellenruf)
	bedienung.tempo_gewechselt.connect(_auf_tempo)
	bedienung.zeige(spiel)

	print("PocketBeast 3D — ", Daten.KARTEN[0]["name"],
		"   ", Daten.WAECHTER.size(), " Wächterfamilien, ",
		Daten.ARTEN.size(), " Gegnerarten")


## Kacheln, durch die der Weg läuft, dürfen nicht bebaut werden.
##
## Statt die Route nachzurechnen wird sie abgeschritten: An jedem Punkt
## werden die Kachel darunter und ihre acht Nachbarn gesperrt, soweit sie
## nah genug liegen. Das ist derselbe Ansatz wie im Browserspiel und
## verträgt jede Wegform, auch eine, die sich selbst kreuzt.
func _sperre_wegkacheln() -> void:
	var schritt := 0.4
	var d := 0.0
	while d < weg_laenge:
		var p := Weg.punkt_bei(weg_punkte, d)
		var k := _welt_zu_kachel(p)
		for dc in range(-1, 2):
			for dr in range(-1, 2):
				var nachbar := Vector2i(k.x + dc, k.y + dr)
				var mitte := _kachel_zu_welt(nachbar)
				if Vector2(mitte.x - p.x, mitte.z - p.z).length() < Gelaende.KACHEL * 0.85:
					belegt[nachbar] = "weg"
		d += schritt


func _welt_zu_kachel(p: Vector3) -> Vector2i:
	var breite: float = Gelaende.SPALTEN * Gelaende.KACHEL
	var tiefe: float = Gelaende.ZEILEN * Gelaende.KACHEL
	return Vector2i(
		int(floor((p.x + breite * 0.5) / Gelaende.KACHEL)),
		int(floor((p.z + tiefe * 0.5) / Gelaende.KACHEL)))


func _kachel_zu_welt(k: Vector2i) -> Vector3:
	var breite: float = Gelaende.SPALTEN * Gelaende.KACHEL
	var tiefe: float = Gelaende.ZEILEN * Gelaende.KACHEL
	var x := (float(k.x) + 0.5) * Gelaende.KACHEL - breite * 0.5
	var z := (float(k.y) + 0.5) * Gelaende.KACHEL - tiefe * 0.5
	return Vector3(x, Gelaende.hoehe_bei(x, z, 99.0), z)


func _kachel_frei(k: Vector2i) -> bool:
	if k.x < 0 or k.x >= Gelaende.SPALTEN or k.y < 0 or k.y >= Gelaende.ZEILEN:
		return false
	return not belegt.has(k)


## Himmel und Umgebungslicht. Ohne beides wirken Körper wie ausgeschnitten:
## Flächen, die von der Sonne abgewandt sind, wären sonst schlicht schwarz.
func _baue_umgebung() -> void:
	var himmel := ProceduralSkyMaterial.new()
	himmel.sky_top_color = Color(0.28, 0.45, 0.70)
	himmel.sky_horizon_color = Color(0.65, 0.74, 0.80)
	himmel.ground_bottom_color = Color(0.52, 0.60, 0.55)
	himmel.ground_horizon_color = Color(0.68, 0.75, 0.72)
	himmel.sun_angle_max = 12.0

	var umgebung := Environment.new()
	umgebung.background_mode = Environment.BG_SKY
	umgebung.background_energy_multiplier = 1.0
	umgebung.sky = Sky.new()
	umgebung.sky.sky_material = himmel
	umgebung.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	umgebung.ambient_light_sky_contribution = 0.55
	umgebung.ambient_light_energy = 0.55
	# Weiche Verdunklung in Ecken und Ritzen — lässt Objekte aufsitzen
	umgebung.ssao_enabled = true
	umgebung.ssao_radius = 1.4
	umgebung.ssao_intensity = 2.2
	umgebung.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	umgebung.tonemap_white = 2.0
	# leichter Dunst in der Ferne, wie die Luftperspektive im Browserspiel
	umgebung.fog_enabled = true
	umgebung.fog_light_color = Color(0.58, 0.66, 0.72)
	umgebung.fog_sky_affect = 0.0
	umgebung.fog_density = 0.0011
	# Höhen-Dunst greift NACH UNTEN von fog_height aus. Bei 6,0 lag das ganze
	# Gelände darunter und bekam den vollen Nebel ab — ein grauer Schleier über
	# der Fläche statt Tiefe in der Ferne. Deshalb bleibt es beim reinen
	# Entfernungsnebel.
	umgebung.fog_height = 0.0
	umgebung.fog_height_density = 0.0

	# Nachbearbeitung: Sättigung und Kontrast anheben. Ohne das bleibt eine
	# prozedural gebaute Szene blass — es fehlen die satten Stellen, die ein
	# Foto hat.
	umgebung.adjustment_enabled = true
	umgebung.adjustment_saturation = 1.15
	umgebung.adjustment_contrast = 1.10
	umgebung.adjustment_brightness = 0.98

	var we := WorldEnvironment.new()
	we.environment = umgebung
	add_child(we)


func _baue_licht() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	sonne.light_energy = 1.55
	sonne.light_color = Color(1.0, 0.94, 0.82)
	sonne.shadow_enabled = true
	# Die Schattenkarte über 90 Einheiten zu spannen machte sie in der Ferne so
	# grob, dass sich das Gelände in regelmäßigen Bändern selbst beschattete
	# (Schattenakne). Kürzere Reichweite plus Normalenversatz nimmt das heraus.
	sonne.directional_shadow_max_distance = 55.0
	sonne.directional_shadow_split_1 = 0.10
	sonne.directional_shadow_split_2 = 0.28
	sonne.directional_shadow_split_3 = 0.60
	sonne.directional_shadow_blend_splits = true
	sonne.shadow_bias = 0.06
	sonne.shadow_normal_bias = 2.5
	add_child(sonne)


## Schräge Draufsicht: flach genug, dass Körper Höhe zeigen, steil genug,
## dass der Weg als Ganzes lesbar bleibt.
func _baue_kamera() -> void:
	kamera = Camera3D.new()
	kamera.position = Vector3(0.0, 21.0, 19.5)
	kamera.rotation_degrees = Vector3(-46.0, 0.0, 0.0)
	kamera.fov = 52.0
	add_child(kamera)


func _baue_welt() -> void:
	weg_punkte = Weg.glaetten(Weg.punkte_aus_kacheln(ROUTE), 3)
	weg_laenge = Weg.laenge_von(weg_punkte)

	# Gelände
	var boden := MeshInstance3D.new()
	boden.mesh = Gelaende.baue(weg_punkte)
	var mb := StandardMaterial3D.new()
	mb.vertex_color_use_as_albedo = true
	mb.roughness = 0.95
	mb.metallic_specular = 0.05
	boden.material_override = mb
	boden.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(boden)

	# Weg
	var pfad := MeshInstance3D.new()
	pfad.mesh = Weg.baue(weg_punkte)
	var mp := StandardMaterial3D.new()
	mp.vertex_color_use_as_albedo = true
	mp.roughness = 1.0
	mp.metallic_specular = 0.0
	pfad.material_override = mp
	add_child(pfad)


## Bewuchs.
##
## Statt 90 gleicher Nadelbäume stehen hier vier Arten in wechselnden Größen,
## Farbtönen und Neigungen, dazu eine Bodenschicht aus Gras, Steinen und
## Blumen. Die Verteilung folgt Ballungen: Ein Wald hat dichte Stellen und
## Lichtungen, keine gleichmäßige Streuung.
func _baue_bewuchs() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 20260826
	var breite: float = Gelaende.SPALTEN * Gelaende.KACHEL
	var tiefe: float = Gelaende.ZEILEN * Gelaende.KACHEL

	# Ballungszentren, um die sich der Bewuchs sammelt
	var zentren := []
	for i in range(9):
		zentren.append(Vector3(
			rnd.randf_range(-breite * 0.55, breite * 0.55), 0.0,
			rnd.randf_range(-tiefe * 0.55, tiefe * 0.55)))

	var baeume := Node3D.new()
	baeume.name = "Baeume"
	add_child(baeume)

	var gras_plaetze := []
	var stein_plaetze := []
	var blumen_plaetze := []

	var gesetzt := 0
	var versuche := 0
	# Kernbereich — das eigentliche Spielfeld. Hier bestimmt die Dichte, wie
	# voll die Wiese wirkt; zu viel verdeckt den Weg.
	while gesetzt < 150 and versuche < 4000:
		versuche += 1
		var x := rnd.randf_range(-breite * 0.62, breite * 0.62)
		var z := rnd.randf_range(-tiefe * 0.62, tiefe * 0.62)
		var p := Vector3(x, 0, z)
		var nah := _abstand_zum_weg(p)
		if nah < Weg.BREITE + 1.0:
			continue

		# Dichte aus der Nähe zum nächsten Ballungszentrum
		var d_zentrum := 999.0
		for c in zentren:
			d_zentrum = minf(d_zentrum, p.distance_to(c))
		var dichte: float = clampf(1.0 - d_zentrum / 14.0, 0.0, 1.0)
		if rnd.randf() > 0.18 + dichte * 0.82:
			continue

		gesetzt += 1
		var y := Gelaende.hoehe_bei(x, z, nah)
		var wahl := rnd.randf()
		var pflanze: Node3D
		if wahl < 0.46:
			pflanze = Pflanzen.nadelbaum(rnd, rnd.randf_range(1.3, 2.6))
		elif wahl < 0.74:
			pflanze = Pflanzen.laubbaum(rnd, rnd.randf_range(1.2, 2.2))
		elif wahl < 0.94:
			pflanze = Pflanzen.busch(rnd, rnd.randf_range(0.35, 0.7))
		else:
			pflanze = Pflanzen.totholz(rnd, rnd.randf_range(1.1, 1.9))
		pflanze.position = Vector3(x, y, z)
		# Jede Pflanze eigene Drehung und leichte Neigung — nichts steht exakt
		# senkrecht, das nimmt der Fläche das Aufgestellte.
		pflanze.rotation = Vector3(
			rnd.randf_range(-0.05, 0.05),
			rnd.randf() * TAU,
			rnd.randf_range(-0.05, 0.05))
		baeume.add_child(pflanze)

	# Randgürtel: außerhalb des Spielfelds, dichter Waldsaum. Ohne ihn endete
	# der Bewuchs an einer geraden Linie, dahinter lag leerer Rasen bis zum
	# Horizont — nichts verrät eine gebaute Szene schneller.
	var rand_gesetzt := 0
	var rand_versuche := 0
	while rand_gesetzt < 420 and rand_versuche < 14000:
		rand_versuche += 1
		var x := rnd.randf_range(-breite * 1.55, breite * 1.55)
		var z := rnd.randf_range(-tiefe * 1.9, tiefe * 1.9)
		var draussen: float = maxf(absf(x) / (breite * 0.62), absf(z) / (tiefe * 0.62))
		if draussen < 1.0:
			continue   # Kern ist oben schon bepflanzt
		# nach außen hin zuwachsend, mit Lücken für Lichtungen
		var p_setz: float = clampf((draussen - 1.0) * 1.1 + 0.30, 0.0, 0.92)
		if rnd.randf() > p_setz:
			continue
		rand_gesetzt += 1
		var y := Gelaende.hoehe_bei(x, z, 99.0)
		var w := rnd.randf()
		var pf: Node3D
		if w < 0.62:
			pf = Pflanzen.nadelbaum(rnd, rnd.randf_range(1.6, 3.2))
		elif w < 0.88:
			pf = Pflanzen.laubbaum(rnd, rnd.randf_range(1.5, 2.6))
		else:
			pf = Pflanzen.busch(rnd, rnd.randf_range(0.4, 0.9))
		pf.position = Vector3(x, y, z)
		pf.rotation = Vector3(
			rnd.randf_range(-0.05, 0.05), rnd.randf() * TAU, rnd.randf_range(-0.05, 0.05))
		baeume.add_child(pf)

	# Bodenschicht: dicht am Weg und in den Ballungen, dünn dazwischen
	for i in range(16000):
		var x := rnd.randf_range(-breite * 0.62, breite * 0.62)
		var z := rnd.randf_range(-tiefe * 0.62, tiefe * 0.62)
		var p := Vector3(x, 0, z)
		var nah := _abstand_zum_weg(p)
		if nah < Weg.BREITE + 0.15:
			continue
		var y := Gelaende.hoehe_bei(x, z, nah)
		gras_plaetze.append(Vector3(x, y, z))
		if rnd.randf() < 0.010:
			stein_plaetze.append(Vector3(x, y, z))
		if rnd.randf() < 0.012:
			blumen_plaetze.append(Vector3(x, y, z))

	add_child(Pflanzen.grasfeld(rnd, gras_plaetze))
	add_child(Pflanzen.steinfeld(rnd, stein_plaetze))
	add_child(Pflanzen.blumenfeld(rnd, blumen_plaetze))
	print("Bewuchs: ", gesetzt, "+", rand_gesetzt, " Pflanzen, ", gras_plaetze.size(), " Gras, ",
		stein_plaetze.size(), " Steine, ", blumen_plaetze.size(), " Blumen")


## ============================================================
## Eingabe
## ============================================================

func _auf_auswahl(id: String) -> void:
	gewaehlt = id
	if vorschau:
		vorschau.queue_free()
		vorschau = null
	if id == "":
		bedienung.setze_hinweis("Wächter wählen, dann auf eine freie Fläche klicken")
	else:
		var def := spiel.waechter_def(id)
		bedienung.setze_hinweis("%s — %d Beeren. Auf eine freie Fläche klicken." %
			[def["stufen"][0]["name"], spiel.baukosten(id)])


func _auf_wellenruf() -> void:
	spiel.rufe_welle()
	bedienung.zeige(spiel)


func _auf_tempo() -> void:
	tempo = 1 if tempo >= 3 else tempo + 1
	bedienung.setze_tempo(tempo)


func _unhandled_input(ereignis: InputEvent) -> void:
	if ereignis is InputEventKey and ereignis.pressed and not ereignis.echo:
		var taste: int = ereignis.keycode
		if taste == KEY_SPACE:
			_auf_wellenruf()
			return
		if taste == KEY_ESCAPE:
			gewaehlt = ""
			bedienung.auswahl_loeschen()
			_auf_auswahl("")
			return
		# Zifferntasten wählen die Wächter der Reihe nach
		if taste >= KEY_1 and taste <= KEY_9:
			var i := taste - KEY_1
			var liste: Array = []
			for d in Daten.WAECHTER:
				if not d.get("legendaer", false):
					liste.append(d)
			if i < liste.size():
				_auf_auswahl(liste[i]["id"])
			return

	if ereignis is InputEventMouseButton and ereignis.pressed \
			and ereignis.button_index == MOUSE_BUTTON_LEFT:
		_versuche_bauen()


## Welche Kachel liegt unter dem Mauszeiger?
##
## Der Boden ist ein welliges Mesh; einen Strahl dagegen zu prüfen wäre
## aufwendig und ungenau. Stattdessen wird der Strahl mit der Ebene y = 0
## geschnitten — das Gelände weicht davon nur um weniger als eine
## Kachelhöhe ab, und für die Frage "welche Kachel" reicht das genau.
func _kachel_unter_maus() -> Vector2i:
	if kamera == null:
		return Vector2i(-99, -99)
	var maus := get_viewport().get_mouse_position()
	var ursprung := kamera.project_ray_origin(maus)
	var richtung := kamera.project_ray_normal(maus)
	if absf(richtung.y) < 0.0001:
		return Vector2i(-99, -99)
	var t := -ursprung.y / richtung.y
	if t < 0.0:
		return Vector2i(-99, -99)
	return _welt_zu_kachel(ursprung + richtung * t)


func _versuche_bauen() -> void:
	if gewaehlt == "" or spiel.verloren:
		return
	var k := _kachel_unter_maus()
	if not _kachel_frei(k):
		bedienung.setze_hinweis("Hier ist kein Platz — der Weg oder ein Wächter belegt die Stelle")
		return
	var kosten := spiel.baukosten(gewaehlt)
	if spiel.beeren < kosten:
		bedienung.setze_hinweis("Zu wenig Beeren: %d von %d" % [spiel.beeren, kosten])
		return
	spiel.beeren -= kosten
	belegt[k] = "turm"
	_setze_waechter(gewaehlt, 0, _kachel_zu_welt(k))
	bedienung.zeige(spiel)
	bedienung.setze_hinweis("%s gesetzt" % spiel.waechter_def(gewaehlt)["stufen"][0]["name"])


## Ein durchscheinender Umriss dort, wo gebaut würde.
func _pflege_vorschau() -> void:
	if gewaehlt == "":
		return
	var k := _kachel_unter_maus()
	if k == zeiger_kachel:
		return
	zeiger_kachel = k
	if vorschau:
		vorschau.queue_free()
		vorschau = null
	if not _kachel_frei(k):
		return

	var def := spiel.waechter_def(gewaehlt)
	if def.is_empty():
		return
	var st: Dictionary = def["stufen"][0]
	var farbe: Color = Daten.TYPEN[def["typ"]]["farbe"]
	var reicht: bool = spiel.beeren >= int(st["kosten"])

	vorschau = Node3D.new()
	vorschau.position = _kachel_zu_welt(k)
	add_child(vorschau)

	# Reichweitenring, flach auf dem Boden
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	var reich: float = float(st["reichweite"]) / Spiel.PIXEL_JE_METER
	tm.inner_radius = reich - 0.09
	tm.outer_radius = reich
	tm.rings = 48
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(farbe.r, farbe.g, farbe.b, 0.55 if reicht else 0.3)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rm
	ring.position.y = 0.06
	vorschau.add_child(ring)

	# Platzhalter für den Wächter selbst
	var koerper := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 1.1
	koerper.mesh = sm
	var km := StandardMaterial3D.new()
	km.albedo_color = Color(farbe.r, farbe.g, farbe.b, 0.42 if reicht else 0.2)
	km.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	koerper.material_override = km
	koerper.position.y = 0.85
	vorschau.add_child(koerper)


## Kürzester Abstand eines Punktes zur Route.
func _abstand_zum_weg(p: Vector3) -> float:
	var nah := 999.0
	for i in range(weg_punkte.size() - 1):
		nah = minf(nah, _abstand_strecke(p, weg_punkte[i], weg_punkte[i + 1]))
	return nah


## Setzt einen Wächter anhand seiner Kennung und Stufe.
##
## Die Werte kommen aus daten.gd, also aus dem Browserspiel — Reichweite,
## Schaden und Feuerrate sind dieselben. Die Umrechnung Pixel/Meter steht in
## spiel.gd, weil beide Fassungen sie brauchen.

func _setze_waechter(id: String, stufe: int, pos: Vector3) -> void:
	var def: Dictionary = {}
	for w in Daten.WAECHTER:
		if w["id"] == id:
			def = w
			break
	if def.is_empty():
		push_error("Unbekannte Wächterkennung: " + id)
		return
	var st: Dictionary = def["stufen"][clampi(stufe, 0, 2)]
	var typ: String = def["typ"]
	var farbe: Color = Daten.TYPEN[typ]["farbe"]
	_setze_turm(pos, farbe,
		float(st["reichweite"]) / Spiel.PIXEL_JE_METER,
		float(st["rate"]),
		float(st["schaden"]),
		typ, def["luft"], float(st.get("durchschlag", 0)))


func _setze_turm(pos: Vector3, farbe: Color, reichweite: float, takt: float, schaden: float,
		typ: String = "", luft: bool = true, durchschlag: float = 0.0) -> void:
	var y := Gelaende.hoehe_bei(pos.x, pos.z, 99.0)
	var wurzel := Node3D.new()
	wurzel.position = Vector3(pos.x, y, pos.z)
	add_child(wurzel)

	# Sockel
	var sockel := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.85
	sm.bottom_radius = 1.0
	sm.height = 0.35
	sockel.mesh = sm
	var mat_sockel := StandardMaterial3D.new()
	mat_sockel.albedo_color = Color(0.34, 0.30, 0.25)
	mat_sockel.roughness = 1.0
	sockel.material_override = mat_sockel
	sockel.position.y = 0.175
	wurzel.add_child(sockel)

	# Körper als Kugel — steht stellvertretend für die Kreatur
	var koerper := MeshInstance3D.new()
	var kugel := SphereMesh.new()
	kugel.radius = 0.62
	kugel.height = 1.24
	koerper.mesh = kugel
	var mat := StandardMaterial3D.new()
	mat.albedo_color = farbe
	mat.roughness = 0.55
	mat.rim_enabled = true
	mat.rim = 0.5
	koerper.material_override = mat
	koerper.position.y = 0.95
	wurzel.add_child(koerper)

	tuerme.append({
		"knoten": wurzel, "koerper": koerper, "pos": wurzel.position,
		"reichweite": reichweite, "takt": takt, "schaden": schaden, "abklingen": 0.0,
		"farbe": farbe, "typ": typ, "luft": luft, "durchschlag": durchschlag,
	})


func _spawne_gegner() -> void:
	if spiel.warteschlange.is_empty():
		return
	var eintrag: Dictionary = spiel.warteschlange.pop_front()
	var art: Dictionary = eintrag["art"]
	var leben: float = float(eintrag["leben"])
	var faktor: float = float(spiel.karte()["faktor"])
	var typ: String = art["typ"]
	var farbe: Color = Daten.TYPEN[typ]["farbe"]
	var fliegt: bool = art.get("fliegt", false)

	var knoten := MeshInstance3D.new()
	var kapsel := SphereMesh.new()
	var groesse := float(art["groesse"]) / 34.0        # 34 px entsprechen etwa 1 m
	kapsel.radius = 0.32 * groesse + 0.16
	kapsel.height = kapsel.radius * 2.0
	knoten.mesh = kapsel
	var mat := StandardMaterial3D.new()
	mat.albedo_color = farbe
	mat.roughness = 0.6
	# Flieger leuchten schwach, damit man sie von Läufern unterscheidet
	if fliegt:
		mat.emission_enabled = true
		mat.emission = farbe
		mat.emission_energy_multiplier = 0.35
	knoten.material_override = mat
	_wurzel_gegner.add_child(knoten)

	gegner.append({
		"knoten": knoten, "strecke": 0.0,
		"tempo": 2.6 * float(art["tempo"]),
		"leben": leben, "max_leben": leben,
		"wackel": randf() * 6.0,
		"typ": typ, "fliegt": fliegt,
		"art": art,
		"panzer": Spiel.panzerung(float(art.get("panzer", 0)), spiel.welle, faktor),
		"name": art["name"],
		"hoehe": 1.6 if fliegt else 0.0,
	})


func _process(delta: float) -> void:
	zeit += delta
	_pflege_vorschau()

	if spiel.verloren:
		bedienung.setze_hinweis("Das Dorf ist gefallen — %d Wellen gehalten" % (spiel.welle - 1))
		return

	# Spieltempo: mehrere Rechenschritte je Bild statt größerer Schritte,
	# damit schnelle Gegner keine Treffer überspringen.
	for _i in range(tempo):
		_takt(delta)

	bedienung.zeige(spiel)


func _takt(delta: float) -> void:
	if spiel.welle_laeuft and not spiel.warteschlange.is_empty():
		spawn_uhr -= delta
		if spawn_uhr <= 0.0:
			_spawne_gegner()
			spawn_uhr = 0.85

	# Gegner den Weg entlang
	for g in gegner:
		g["strecke"] += g["tempo"] * delta
		var strecke: float = g["strecke"]
		var p := Weg.punkt_bei(weg_punkte, strecke)
		var wackel: float = g["wackel"]
		# Läufer wippen dicht über dem Grund, Flieger schweben weiter oben
		# und in einem weiteren Bogen — daran liest man die Flughöhe ab.
		var hoehe: float = g.get("hoehe", 0.0)
		if hoehe > 0.0:
			p.y += 0.42 + hoehe + sin(zeit * 2.1 + wackel) * 0.28
		else:
			p.y += 0.42 + sin(zeit * 7.0 + wackel) * 0.08
		var knoten: MeshInstance3D = g["knoten"]
		knoten.position = p

	# Wächter feuern auf den weitesten Gegner in Reichweite
	for t in tuerme:
		t["abklingen"] -= delta
		var ziel: Dictionary = {}
		var beste := -1.0
		for g in gegner:
			var kn: MeshInstance3D = g["knoten"]
			# Wer nicht in die Luft trifft, sieht Flieger nicht als Ziel
			if g.get("fliegt", false) and not t.get("luft", true):
				continue
			if kn.position.distance_to(t["pos"]) <= t["reichweite"] and g["strecke"] > beste:
				beste = g["strecke"]
				ziel = g
		if ziel.is_empty():
			continue
		# Körper dreht sich zum Ziel
		var koerper: MeshInstance3D = t["koerper"]
		var zk: MeshInstance3D = ziel["knoten"]
		var tpos: Vector3 = t["pos"]
		var richtung := zk.position - tpos
		koerper.rotation.y = atan2(richtung.x, richtung.z)
		if t["abklingen"] <= 0.0:
			t["abklingen"] = 1.0 / t["takt"]
			ziel["leben"] -= _schaden(t, ziel)
			_blitz(t["pos"] + Vector3.UP * 0.95, zk.position, t["farbe"])

	# Aufräumen
	var uebrig: Array[Dictionary] = []
	for g in gegner:
		var kn: MeshInstance3D = g["knoten"]
		if g["leben"] <= 0.0:
			erledigt += 1
			spiel.erledigt(g["art"])
			kn.queue_free()
		elif g["strecke"] >= weg_laenge:
			durchgebrochen += 1
			spiel.durchbruch()
			kn.queue_free()
		else:
			uebrig.append(g)
	gegner = uebrig

	# Welle vorbei, wenn nichts mehr unterwegs und nichts mehr in der Schlange
	if spiel.welle_laeuft and gegner.is_empty() and spiel.warteschlange.is_empty():
		spiel.welle_geschafft()
		bedienung.setze_hinweis("Welle %d gehalten — bau aus, dann ruf die nächste" % spiel.welle)


## Kurzer Lichtstrahl als Treffer. Ein eigener Körper statt einer gezeichneten
## Linie, damit der Schuss im Raum liegt und von der Perspektive erfasst wird.
## Was ein Treffer wirklich anrichtet.
##
## Zwei Dinge stehen zwischen Angriff und Wirkung, und beide entscheiden das
## Spiel: der Typenvorteil und die Panzerung.
##
## Der Typenvorteil vervielfacht — Feuer richtet gegen Pflanze das Doppelte
## an und gegen Wasser die Hälfte. Die Panzerung wird dagegen von jedem
## einzelnen Treffer ABGEZOGEN, nicht anteilig gemindert. Deshalb ist sie für
## einen schnellen Kleinschützen tödlich und für einen schweren Schläger nur
## lästig: Der Wind-Wächter macht fünfzehn Schaden je Treffer und kommt gegen
## Panzerung achtzehn auf null, der Stahl-Wächter mit hundertachtundfünfzig
## kaum ins Stocken.
##
## Ein Rest bleibt immer: Ein Treffer, der gar nichts bewirkt, sieht wie ein
## Fehler aus, auch wenn er rechnerisch richtig ist.
func _schaden(turm: Dictionary, ziel: Dictionary) -> float:
	return Spiel.schaden(
		float(turm["schaden"]),
		turm.get("typ", ""),
		ziel.get("typ", ""),
		float(ziel.get("panzer", 0.0)),
		float(turm.get("durchschlag", 0.0)))


func _blitz(von: Vector3, nach: Vector3, farbe: Color) -> void:
	var strahl := MeshInstance3D.new()
	var box := BoxMesh.new()
	var d := von.distance_to(nach)
	box.size = Vector3(0.06, 0.06, d)
	strahl.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = farbe
	mat.emission_enabled = true
	mat.emission = farbe
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strahl.material_override = mat
	strahl.position = (von + nach) * 0.5
	strahl.look_at_from_position(strahl.position, nach, Vector3.UP)
	_wurzel_schuesse.add_child(strahl)
	# nach kurzer Zeit wieder entfernen
	var zeitgeber := get_tree().create_timer(0.09)
	zeitgeber.timeout.connect(func(): if is_instance_valid(strahl): strahl.queue_free())


static func _abstand_strecke(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var l := ab.length_squared()
	if l < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / l, 0.0, 1.0)
	return p.distance_to(a + ab * t)
