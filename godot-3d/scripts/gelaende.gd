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
	var h := sin(x * 0.231) * cos(z * 0.187) * 0.50
	h += sin(x * 0.073 + z * 0.109) * 0.62
	h += sin(x * 0.041 - z * 0.137 + 2.3) * 0.55
	h += cos(x * 0.409 + 1.7) * sin(z * 0.371) * 0.16
	h += sin(x * 0.617 + z * 0.443 - 0.8) * 0.07
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
	for p in [a, b, c]:
		st.set_color(farbe_bei(p).srgb_to_linear())
		st.set_uv(Vector2(p.x * 0.25, p.z * 0.25))
		st.add_vertex(p)


## Bodenfarbe an einer Stelle.
##
## Erste Fassung mischte nur nach Höhe — und weil das Gelände flach ist, kam
## überall fast derselbe Ton heraus: eine einheitlich blassgrüne Fläche, die
## wie Plastikfolie aussah. Jetzt überlagern sich drei Dinge:
## Wiesenton, trockene Stellen und nackte Erde, jedes mit eigener Wellenlänge.
## Die Palette der Karte. welt.gd setzt sie, bevor das Gelände gebaut wird —
## vorher standen die Werte fest, und damit sah die Glutschlucht aus wie eine
## Wiese. Die Vorgabe ist der Grünpfad, damit das Gelände auch ohne gesetzte
## Palette etwas Sinnvolles zeigt.
static var P_WIESE := Color(0.22, 0.36, 0.19)
static var P_SATT := Color(0.15, 0.30, 0.14)
static var P_TROCKEN := Color(0.42, 0.44, 0.24)
static var P_ERDE := Color(0.29, 0.25, 0.19)

static func farbe_bei(p: Vector3) -> Color:
	var wiese := P_WIESE
	var satt := P_SATT
	var trocken := P_TROCKEN
	var erde := P_ERDE

	# grobe Flecken: wo die Wiese satt steht und wo sie ausdünnt.
	# Drei Frequenzen ohne einfaches Verhältnis — eine einzelne Welle malte
	# regelmäßige Diagonalstreifen quer über die Wiese.
	var g := sin(p.x * 0.131 + 2.1) * cos(p.z * 0.107 - 0.7)
	g += sin(p.x * 0.313 - p.z * 0.271 + 1.4) * 0.55
	g += cos(p.x * 0.077 + p.z * 0.223 - 2.6) * 0.40
	g /= 1.95
	var c := wiese.lerp(satt, clampf(g * 0.5 + 0.5, 0.0, 1.0))

	# trockene Kuppen: höhere Stellen bekommen Sonne ab
	var h: float = clampf(p.y * 0.42 + 0.5, 0.0, 1.0)
	c = c.lerp(trocken, h * 0.35)

	# vereinzelt durchscheinende Erde, kleinteiliger als die Flecken
	var e := sin(p.x * 0.471 - 1.3) * sin(p.z * 0.533 + 0.9) * cos(p.x * 0.191 + p.z * 0.227)
	c = c.lerp(erde, clampf(e * 1.6 - 0.60, 0.0, 1.0) * 0.60)

	# Ein feines Rauschen stand hier einmal, um große Farbfelder aufzubrechen.
	# Bei rund zwei Einheiten Wellenlänge fiel es in der Ferne unter die
	# Pixelauflösung und erzeugte Moiré — Streifenbänder bis zum Horizont.
	# Die Kleinteiligkeit übernimmt jetzt das Gras, das ohnehin darüber steht.
	var f := sin(p.x * 0.83 + p.z * 0.61) * 0.018
	return Color(clampf(c.r + f, 0, 1), clampf(c.g + f, 0, 1), clampf(c.b + f, 0, 1))


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
