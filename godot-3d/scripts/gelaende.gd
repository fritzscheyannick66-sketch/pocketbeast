extends RefCounted
##
## Erzeugt das Geländemesh.
##
## Der Boden ist bewusst nicht flach: eine leichte Welligkeit lässt Licht und
## Schatten über die Fläche wandern und macht erst sichtbar, dass es sich um
## einen Körper im Raum handelt und nicht um eine bemalte Ebene. Entlang der
## Route wird die Welligkeit herausgerechnet, damit der Weg nicht durch Hügel
## schneidet.
##

const KACHEL := 2.0          # Weltmaß je Spielfeld-Kachel
const SPALTEN := 20
const ZEILEN := 12
# Überstand: das Gelände reicht über das Spielfeld hinaus, sonst sieht man
# im Bild die abgeschnittenen Ränder der Ebene schweben.
const UEBERSTAND := 22.0
const UNTERTEILUNG := 4      # Gittermaschen je Kachel — mehr = weichere Wellen


## Höhe des Bodens an einer Stelle. Zwei überlagerte Wellen unterschiedlicher
## Frequenz ergeben ein unregelmäßiges Relief, ohne dass Rauschdaten nötig sind.
static func hoehe_bei(x: float, z: float, weg_naehe: float) -> float:
	var h := sin(x * 0.23) * cos(z * 0.19) * 0.55
	h += sin(x * 0.07 + z * 0.11) * 0.9
	h += cos(x * 0.41 + 1.7) * sin(z * 0.37) * 0.18
	# In Wegnähe abflachen: sonst läge die Route mal im Hügel, mal in der Luft.
	var flach: float = clampf(weg_naehe / 3.0, 0.0, 1.0)
	return h * flach


static func baue(weg_punkte: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var breite := SPALTEN * KACHEL + UEBERSTAND * 2.0
	var tiefe := ZEILEN * KACHEL + UEBERSTAND * 2.0
	var schritt := KACHEL / float(UNTERTEILUNG)
	var nx := int(breite / schritt)
	var nz := int(tiefe / schritt)

	# Höhen vorab berechnen, damit jeder Gitterpunkt nur einmal ausgewertet wird
	var hoehen := []
	hoehen.resize(nx + 1)
	for i in range(nx + 1):
		var reihe := PackedFloat32Array()
		reihe.resize(nz + 1)
		for j in range(nz + 1):
			var x := i * schritt - breite * 0.5
			var z := j * schritt - tiefe * 0.5
			reihe[j] = hoehe_bei(x, z, _abstand_zum_weg(Vector3(x, 0, z), weg_punkte))
		hoehen[i] = reihe

	for i in range(nx):
		for j in range(nz):
			var x0 := i * schritt - breite * 0.5
			var z0 := j * schritt - tiefe * 0.5
			var x1 := x0 + schritt
			var z1 := z0 + schritt
			var a := Vector3(x0, hoehen[i][j], z0)
			var b := Vector3(x1, hoehen[i + 1][j], z0)
			var c := Vector3(x1, hoehen[i + 1][j + 1], z1)
			var d := Vector3(x0, hoehen[i][j + 1], z1)
			# Reihenfolge bestimmt, wohin die Fläche schaut. In der ersten
			# Fassung zeigten die Normalen nach unten — das Gelände war von der
			# Kamera aus unsichtbar, obwohl das Mesh mit 23.040 Ecken vorlag. 
			_dreieck(st, a, b, c)
			_dreieck(st, a, c, d)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func _dreieck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# Farbe je Scheitel: höhere Stellen heller, als läge dort mehr Licht.
	for p in [a, b, c]:
		var t: float = clampf(p.y * 0.35 + 0.5, 0.0, 1.0)
		st.set_color(Color(0.20, 0.34, 0.20).lerp(Color(0.36, 0.55, 0.31), t))
		st.set_uv(Vector2(p.x * 0.25, p.z * 0.25))
		st.add_vertex(p)


static func _abstand_zum_weg(p: Vector3, weg: PackedVector3Array) -> float:
	if weg.is_empty():
		return 999.0
	var best := 999.0
	for i in range(weg.size() - 1):
		best = minf(best, _abstand_zu_strecke(p, weg[i], weg[i + 1]))
	return best


static func _abstand_zu_strecke(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var laenge := ab.length_squared()
	if laenge < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / laenge, 0.0, 1.0)
	return p.distance_to(a + ab * t)
