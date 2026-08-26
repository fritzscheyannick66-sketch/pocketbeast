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

# Route des Grünpfads, in Kachelkoordinaten wie im Browserspiel
const ROUTE := [
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
	# Zwei Wächter an den Weg, damit gleich nach dem Start etwas geschieht
	_setze_turm(Vector3(-14.0, 0.0, 2.0), Color("ff6e45"), 7.0, 1.6, 14.0)
	_setze_turm(Vector3(-2.0, 0.0, 1.0), Color("57ce7c"), 7.0, 1.3, 11.0)


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
	umgebung.ambient_light_sky_contribution = 0.75
	umgebung.ambient_light_energy = 1.0
	# Weiche Verdunklung in Ecken und Ritzen — lässt Objekte aufsitzen
	umgebung.ssao_enabled = true
	umgebung.ssao_radius = 1.4
	umgebung.ssao_intensity = 1.6
	umgebung.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	umgebung.tonemap_white = 1.4
	# leichter Dunst in der Ferne, wie die Luftperspektive im Browserspiel
	umgebung.fog_enabled = true
	umgebung.fog_light_color = Color(0.66, 0.74, 0.82)
	umgebung.fog_sky_affect = 0.0
	umgebung.fog_density = 0.0022

	var we := WorldEnvironment.new()
	we.environment = umgebung
	add_child(we)


func _baue_licht() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	sonne.light_energy = 1.15
	sonne.light_color = Color(1.0, 0.96, 0.88)
	sonne.shadow_enabled = true
	sonne.directional_shadow_max_distance = 90.0
	sonne.shadow_bias = 0.04
	add_child(sonne)


## Schräge Draufsicht: flach genug, dass Körper Höhe zeigen, steil genug,
## dass der Weg als Ganzes lesbar bleibt.
func _baue_kamera() -> void:
	var kamera := Camera3D.new()
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


## Bäume aus Grundkörpern. Prozedural wie im Browserspiel — keine Modelldateien,
## damit das Projekt eine einzelne Quelle bleibt.
func _baue_bewuchs() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 20260826
	var breite := Gelaende.SPALTEN * Gelaende.KACHEL
	var tiefe := Gelaende.ZEILEN * Gelaende.KACHEL

	var stamm_mat := StandardMaterial3D.new()
	stamm_mat.albedo_color = Color(0.29, 0.20, 0.13)
	stamm_mat.roughness = 1.0
	var nadel_mat := StandardMaterial3D.new()
	nadel_mat.albedo_color = Color(0.20, 0.42, 0.24)
	nadel_mat.roughness = 0.9

	var gesetzt := 0
	var versuche := 0
	while gesetzt < 90 and versuche < 900:
		versuche += 1
		var x := rnd.randf_range(-breite * 0.5, breite * 0.5)
		var z := rnd.randf_range(-tiefe * 0.5, tiefe * 0.5)
		var p := Vector3(x, 0, z)
		# Nicht auf den Weg pflanzen
		var nah := 999.0
		for i in range(weg_punkte.size() - 1):
			nah = minf(nah, _abstand_strecke(p, weg_punkte[i], weg_punkte[i + 1]))
		if nah < Weg.BREITE + 1.2:
			continue
		gesetzt += 1
		var y := Gelaende.hoehe_bei(x, z, nah)
		var hoehe := rnd.randf_range(1.6, 3.2)
		var baum := Node3D.new()
		baum.position = Vector3(x, y, z)
		# Stamm
		var stamm := MeshInstance3D.new()
		var zyl := CylinderMesh.new()
		zyl.top_radius = 0.08
		zyl.bottom_radius = 0.13
		zyl.height = hoehe * 0.45
		stamm.mesh = zyl
		stamm.material_override = stamm_mat
		stamm.position.y = hoehe * 0.225
		baum.add_child(stamm)
		# Krone aus drei Kegeln
		for i in range(3):
			var kegel := MeshInstance3D.new()
			var km := CylinderMesh.new()
			km.top_radius = 0.0
			km.bottom_radius = (0.85 - i * 0.2) * (hoehe / 2.4)
			km.height = (1.1 - i * 0.15) * (hoehe / 2.4)
			kegel.mesh = km
			kegel.material_override = nadel_mat
			kegel.position.y = hoehe * (0.42 + i * 0.24)
			baum.add_child(kegel)
		add_child(baum)


func _setze_turm(pos: Vector3, farbe: Color, reichweite: float, takt: float, schaden: float) -> void:
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
		"farbe": farbe,
	})


func _spawne_gegner() -> void:
	var knoten := MeshInstance3D.new()
	var kapsel := SphereMesh.new()
	kapsel.radius = 0.42
	kapsel.height = 0.84
	knoten.mesh = kapsel
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.76, 0.51, 1.0)
	mat.roughness = 0.6
	knoten.material_override = mat
	_wurzel_gegner.add_child(knoten)
	gegner.append({
		"knoten": knoten, "strecke": 0.0, "tempo": randf_range(2.2, 3.4),
		"leben": 40.0, "max_leben": 40.0, "wackel": randf() * 6.0,
	})


func _process(delta: float) -> void:
	zeit += delta

	spawn_uhr -= delta
	if spawn_uhr <= 0.0:
		_spawne_gegner()
		spawn_uhr = 1.2

	# Gegner den Weg entlang
	for g in gegner:
		g["strecke"] += g["tempo"] * delta
		var strecke: float = g["strecke"]
		var p := Weg.punkt_bei(weg_punkte, strecke)
		var wackel: float = g["wackel"]
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
			ziel["leben"] -= t["schaden"]
			_blitz(t["pos"] + Vector3.UP * 0.95, zk.position, t["farbe"])

	# Aufräumen
	var uebrig: Array[Dictionary] = []
	for g in gegner:
		var kn: MeshInstance3D = g["knoten"]
		if g["leben"] <= 0.0:
			erledigt += 1
			kn.queue_free()
		elif g["strecke"] >= weg_laenge:
			durchgebrochen += 1
			kn.queue_free()
		else:
			uebrig.append(g)
	gegner = uebrig


## Kurzer Lichtstrahl als Treffer. Ein eigener Körper statt einer gezeichneten
## Linie, damit der Schuss im Raum liegt und von der Perspektive erfasst wird.
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
