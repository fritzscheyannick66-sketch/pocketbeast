extends RefCounted
##
## Bewuchs: Bäume, Büsche, Gras, Steine und Blumen.
##
## Das Vorgängergerüst setzte 90 gleiche Nadelbäume — dieselbe Form, dieselbe
## Farbe, nur die Höhe schwankte. Genau das lässt eine Szene künstlich wirken:
## In der Natur gleicht kein Baum dem anderen.
##
## Deshalb bekommt hier jede Pflanze eigene Proportionen, einen eigenen
## Farbton, eine leichte Neigung und eine zufällige Drehung. Dazu kommen vier
## verschiedene Arten und eine Bodenschicht aus Gras, Steinen und Blumen.
##
## Kleinteiliges (Gras, Steine, Blumen) läuft über MultiMesh: Tausende Halme
## als einzelne Knoten würden die Bildrate ruinieren, als MultiMesh kosten sie
## einen einzigen Zeichenaufruf.
##

const Gelaende = preload("res://scripts/gelaende.gd")


## Erzeugt ein Material mit leicht verschobenem Farbton.
## Selbst geringe Streuung nimmt einer Fläche das Fabrikmäßige.
static func _blatt_material(grund: Color, rnd: RandomNumberGenerator) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var h := grund.h + rnd.randf_range(-0.035, 0.035)
	var s := clampf(grund.s + rnd.randf_range(-0.12, 0.12), 0.0, 1.0)
	var v := clampf(grund.v + rnd.randf_range(-0.14, 0.14), 0.0, 1.0)
	m.albedo_color = Color.from_hsv(h, s, v)
	m.roughness = rnd.randf_range(0.80, 0.98)
	# Etwas Lichtdurchlass: Laub ist nicht undurchsichtig, sondern glimmt
	# an den Rändern, wenn die Sonne dahintersteht.
	m.rim_enabled = true
	m.rim = rnd.randf_range(0.25, 0.55)
	m.rim_tint = 0.6
	return m


static func _holz_material(rnd: RandomNumberGenerator) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.from_hsv(
		rnd.randf_range(0.06, 0.10),
		rnd.randf_range(0.35, 0.55),
		rnd.randf_range(0.16, 0.30))
	m.roughness = 1.0
	return m


## Nadelbaum: mehrere Kranzlagen, nach oben schmaler, mit leichtem Versatz je
## Lage — dadurch steht er nie perfekt gerade übereinander.
static func nadelbaum(rnd: RandomNumberGenerator, hoehe: float) -> Node3D:
	var baum := Node3D.new()
	var holz := _holz_material(rnd)
	var laub := _blatt_material(Color(0.19, 0.40, 0.24), rnd)

	var stamm := MeshInstance3D.new()
	var zyl := CylinderMesh.new()
	zyl.top_radius = 0.05 * hoehe / 2.4
	zyl.bottom_radius = 0.11 * hoehe / 2.4
	zyl.height = hoehe * 0.40
	zyl.radial_segments = 6
	stamm.mesh = zyl
	stamm.material_override = holz
	stamm.position.y = hoehe * 0.20
	baum.add_child(stamm)

	var lagen := rnd.randi_range(3, 5)
	for i in range(lagen):
		var k := float(i) / float(lagen - 1)
		var kegel := MeshInstance3D.new()
		var km := CylinderMesh.new()
		km.top_radius = 0.0
		km.bottom_radius = (0.92 - k * 0.55) * (hoehe / 2.6) * rnd.randf_range(0.9, 1.1)
		km.height = (1.15 - k * 0.35) * (hoehe / 2.6)
		km.radial_segments = rnd.randi_range(6, 9)
		kegel.mesh = km
		kegel.material_override = laub
		kegel.position = Vector3(
			rnd.randf_range(-0.06, 0.06) * hoehe,
			hoehe * (0.36 + k * 0.52),
			rnd.randf_range(-0.06, 0.06) * hoehe)
		kegel.rotation.y = rnd.randf() * TAU
		baum.add_child(kegel)
	return baum


## Laubbaum: Krone aus mehreren überlappenden Ballen, von dunkel-hinten nach
## hell-vorne. Ein einzelner Kugelkopf sähe nach Lutscher aus.
static func laubbaum(rnd: RandomNumberGenerator, hoehe: float) -> Node3D:
	var baum := Node3D.new()
	var holz := _holz_material(rnd)
	var grund := Color(0.24, 0.46, 0.22)

	var stamm := MeshInstance3D.new()
	var zyl := CylinderMesh.new()
	zyl.top_radius = 0.07 * hoehe / 2.4
	zyl.bottom_radius = 0.15 * hoehe / 2.4
	zyl.height = hoehe * 0.55
	zyl.radial_segments = 6
	stamm.mesh = zyl
	stamm.material_override = holz
	stamm.position.y = hoehe * 0.275
	# leichte Neigung des Stamms
	stamm.rotation = Vector3(rnd.randf_range(-0.06, 0.06), 0, rnd.randf_range(-0.06, 0.06))
	baum.add_child(stamm)

	var ballen := rnd.randi_range(4, 7)
	for i in range(ballen):
		var kugel := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := (0.42 + rnd.randf() * 0.34) * hoehe / 2.2
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 10
		sm.rings = 6
		kugel.mesh = sm
		# vordere Ballen heller — das erzeugt Tiefe in der Krone
		var vorn := rnd.randf()
		var c := grund.lightened(vorn * 0.22).darkened((1.0 - vorn) * 0.18)
		kugel.material_override = _blatt_material(c, rnd)
		var winkel := rnd.randf() * TAU
		var weite := rnd.randf() * 0.42 * hoehe / 2.2
		kugel.position = Vector3(
			cos(winkel) * weite,
			hoehe * rnd.randf_range(0.62, 0.92),
			sin(winkel) * weite)
		baum.add_child(kugel)
	return baum


## Busch: gedrungen, mehrere kleine Ballen dicht über dem Boden.
static func busch(rnd: RandomNumberGenerator, hoehe: float) -> Node3D:
	var b := Node3D.new()
	var n := rnd.randi_range(3, 5)
	for i in range(n):
		var kugel := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := hoehe * rnd.randf_range(0.28, 0.46)
		sm.radius = r
		sm.height = r * 1.7
		sm.radial_segments = 8
		sm.rings = 5
		kugel.mesh = sm
		kugel.material_override = _blatt_material(Color(0.26, 0.42, 0.20), rnd)
		var winkel := rnd.randf() * TAU
		kugel.position = Vector3(
			cos(winkel) * hoehe * 0.28,
			r * 0.75,
			sin(winkel) * hoehe * 0.28)
		b.add_child(kugel)
	return b


## Toter Baum: kahler Stamm mit wenigen Ästen. Bringt Abwechslung in eine
## Fläche, die sonst nur aus Grün besteht.
static func totholz(rnd: RandomNumberGenerator, hoehe: float) -> Node3D:
	var b := Node3D.new()
	var holz := _holz_material(rnd)
	holz.albedo_color = holz.albedo_color.darkened(0.25)

	var stamm := MeshInstance3D.new()
	var zyl := CylinderMesh.new()
	zyl.top_radius = 0.04
	zyl.bottom_radius = 0.13
	zyl.height = hoehe
	zyl.radial_segments = 6
	stamm.mesh = zyl
	stamm.material_override = holz
	stamm.position.y = hoehe * 0.5
	b.add_child(stamm)

	for i in range(rnd.randi_range(2, 4)):
		var ast := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 0.02
		am.bottom_radius = 0.05
		am.height = hoehe * rnd.randf_range(0.25, 0.45)
		am.radial_segments = 5
		ast.mesh = am
		ast.material_override = holz
		var h := hoehe * rnd.randf_range(0.45, 0.85)
		ast.position.y = h
		ast.rotation = Vector3(
			rnd.randf_range(0.5, 1.1),
			rnd.randf() * TAU,
			0.0)
		b.add_child(ast)
	return b


## Bodenschicht aus Grasbüscheln als MultiMesh.
## Jeder Büschel besteht aus drei gekreuzten Flächen — von schräg oben liest
## sich das als Halm, kostet aber fast nichts.
static func grasfeld(rnd: RandomNumberGenerator, plaetze: Array) -> MultiMeshInstance3D:
	var halm := _kreuzflaeche(0.075, 0.38)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = halm
	mm.instance_count = plaetze.size()

	for i in range(plaetze.size()):
		var p: Vector3 = plaetze[i]
		var t := Transform3D()
		var hoch := rnd.randf_range(0.7, 1.5)
		t = t.scaled(Vector3(rnd.randf_range(0.8, 1.3), hoch, rnd.randf_range(0.8, 1.3)))
		t = t.rotated(Vector3.UP, rnd.randf() * TAU)
		t.origin = p
		mm.set_instance_transform(i, t)
		# Farbstreuung: gleichmäßig grüner Teppich wirkt gemalt
		# eng um den Ton des Bodens; große Streuung ließ das Feld gesprenkelt wirken
		mm.set_instance_color(i, Color.from_hsv(
			rnd.randf_range(0.25, 0.29),
			rnd.randf_range(0.34, 0.52),
			rnd.randf_range(0.24, 0.40)).srgb_to_linear())

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	# Beidseitig, weil Kreuzflächen sonst von hinten verschwinden
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


## Steine als MultiMesh: unregelmäßig skalierte Kugeln mit wenigen Segmenten,
## dadurch kantig statt perfekt rund.
static func steinfeld(rnd: RandomNumberGenerator, plaetze: Array) -> MultiMeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = 0.15
	sm.height = 0.20
	sm.radial_segments = 6
	sm.rings = 3

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sm
	mm.instance_count = plaetze.size()
	for i in range(plaetze.size()):
		var p: Vector3 = plaetze[i]
		var t := Transform3D()
		t = t.scaled(Vector3(
			rnd.randf_range(0.5, 1.2),
			rnd.randf_range(0.3, 0.7),
			rnd.randf_range(0.5, 1.2)))
		t = t.rotated(Vector3.UP, rnd.randf() * TAU)
		# etwas eingesunken — ein Stein liegt im Boden, nicht darauf
		t.origin = p - Vector3(0, 0.05, 0)
		mm.set_instance_transform(i, t)
		# gedämpft: bei 0,28–0,52 leuchteten sie in der Sonne fast weiß aus
		var grau := rnd.randf_range(0.16, 0.31)
		mm.set_instance_color(i, Color(grau, grau * 0.97, grau * 0.90).srgb_to_linear())

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mmi.material_override = mat
	return mmi


## Blumen: kleine farbige Tupfen. Wenige genügen — sie setzen Akzente in einer
## sonst durchgehend grünen Fläche.
static func blumenfeld(rnd: RandomNumberGenerator, plaetze: Array) -> MultiMeshInstance3D:
	var mesh := _kreuzflaeche(0.1, 0.14)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = plaetze.size()
	var toene := [
		Color(0.90, 0.76, 0.34), Color(0.84, 0.48, 0.60),
		Color(0.62, 0.58, 0.86), Color(0.88, 0.82, 0.56),
	]
	for i in range(plaetze.size()):
		var p: Vector3 = plaetze[i]
		var t := Transform3D()
		t = t.rotated(Vector3.UP, rnd.randf() * TAU)
		t.origin = p + Vector3(0, 0.12, 0)
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, toene[rnd.randi() % toene.size()].srgb_to_linear())

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


## Drei senkrecht gekreuzte Flächen — die übliche Art, Gras darzustellen,
## ohne für jeden Halm Geometrie zu bauen.
static func _kreuzflaeche(breite: float, hoehe: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Zwei gekreuzte Dreiecke statt Rechtecke: unten breit, oben spitz. Als
	# Rechteck lasen sich die Flächen als hingestreute Papierschnipsel, weil
	# ihnen ohne Textur jede Halmform fehlte.
	for n in range(2):
		var winkel := float(n) * PI / 2.0
		var dx := cos(winkel) * breite
		var dz := sin(winkel) * breite
		var a := Vector3(-dx, 0.0, -dz)
		var b := Vector3(dx, 0.0, dz)
		var spitze := Vector3(dx * 0.15, hoehe, dz * 0.15)
		for p in [a, b, spitze]:
			st.set_uv(Vector2(p.x, p.y))
			st.add_vertex(p)
	st.generate_normals()
	return st.commit()
