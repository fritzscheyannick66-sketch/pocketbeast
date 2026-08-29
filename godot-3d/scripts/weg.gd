extends RefCounted
##
## Erzeugt das Wegband und liefert Positionen darauf.
##
## Der Weg ist kein aufgemaltes Band, sondern eigene Geometrie knapp über dem
## Boden. Dadurch wirft er einen Rand, nimmt Licht anders an als die Wiese und
## verschwindet nicht, wenn die Kamera flach steht.
##

const Gelaende = preload("res://scripts/gelaende.gd")

const BREITE := 0.85         # halbe Wegbreite; 1,7 war fast zwei Kacheln
                             # breit und ließ die Schlinge zuwachsen
const UEBER_BODEN := 0.16    # Abhebung; bei 0,06 verschwand der Weg
                             # stellenweise im welligen Gelände


## Wandelt Kachelkoordinaten des Browserspiels in Weltpunkte.
## Dieselbe Route wie der Grünpfad, damit beide Fassungen vergleichbar bleiben.
static func punkte_aus_kacheln(kacheln: Array) -> PackedVector3Array:
	var aus := PackedVector3Array()
	var breite := Gelaende.SPALTEN * Gelaende.KACHEL
	var tiefe := Gelaende.ZEILEN * Gelaende.KACHEL
	for k in kacheln:
		var x: float = (k.x + 0.5) * Gelaende.KACHEL - breite * 0.5
		var z: float = (k.y + 0.5) * Gelaende.KACHEL - tiefe * 0.5
		aus.append(Vector3(x, 0.0, z))
	return aus


## Glättung nach Chaikin — dieselbe Idee wie im Browserspiel: aus einem
## Streckenzug wird ein geschwungener Weg, ohne den Verlauf zu verfälschen.
static func glaetten(punkte: PackedVector3Array, durchgaenge: int) -> PackedVector3Array:
	var p := punkte
	for _n in range(durchgaenge):
		var aus := PackedVector3Array()
		aus.append(p[0])
		for i in range(p.size() - 1):
			aus.append(p[i].lerp(p[i + 1], 0.25))
			aus.append(p[i].lerp(p[i + 1], 0.75))
		aus.append(p[p.size() - 1])
		p = aus
	return p


static func baue(punkte: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var links := PackedVector3Array()
	var rechts := PackedVector3Array()
	for i in range(punkte.size()):
		var vor: Vector3 = punkte[mini(i + 1, punkte.size() - 1)]
		var zurueck: Vector3 = punkte[maxi(i - 1, 0)]
		var richtung := (vor - zurueck)
		richtung.y = 0.0
		if richtung.length() < 0.0001:
			richtung = Vector3.FORWARD
		richtung = richtung.normalized()
		var quer := Vector3(-richtung.z, 0.0, richtung.x)
		var mitte := punkte[i]
		mitte.y = Gelaende.hoehe_bei(mitte.x, mitte.z, 0.0) + UEBER_BODEN
		links.append(mitte - quer * BREITE)
		rechts.append(mitte + quer * BREITE)

	var laenge := 0.0
	for i in range(punkte.size() - 1):
		var l0 := links[i]
		var l1 := links[i + 1]
		var r0 := rechts[i]
		var r1 := rechts[i + 1]
		var d := punkte[i].distance_to(punkte[i + 1])
		_quad(st, l0, r0, r1, l1, laenge, laenge + d)
		laenge += d

	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		u0: float, u1: float) -> void:
	# Zwei Dreiecke; die Längskoordinate läuft mit der Strecke mit, damit sich
	# eine Textur später nicht staucht.
	# Reihenfolge wie beim Gelände, damit die Fläche nach oben schaut
	var punkte := [a, c, b, a, d, c]
	var uvs := [
		Vector2(0.0, u0), Vector2(1.0, u1), Vector2(1.0, u0),
		Vector2(0.0, u0), Vector2(0.0, u1), Vector2(1.0, u1),
	]
	for i in range(6):
		st.set_uv(uvs[i])
		st.set_color(farbe_bei(punkte[i]).srgb_to_linear())
		st.add_vertex(punkte[i])


## Farbe eines Punktes auf dem Weg.
##
## Ein einfarbiges Band liest sich als aufgeklebter Streifen. Ein getretener
## Pfad ist stellenweise staubig ausgeblichen, in Senken feucht und dunkel.
## Palette des Weges, von welt.gd je Karte gesetzt.
static var P_ERDE := Color(0.46, 0.36, 0.25)
static var P_STAUB := Color(0.72, 0.62, 0.46)
static var P_FEUCHT := Color(0.36, 0.29, 0.22)

static func farbe_bei(p: Vector3) -> Color:
	var erde := P_ERDE
	var staub := P_STAUB
	var feucht := P_FEUCHT

	# Wechsel über die Länge: mal staubig, mal festgetreten
	var laengs := sin(p.x * 0.29 + p.z * 0.37) * 0.5 + 0.5
	var c := erde.lerp(staub, laengs * 0.7 + 0.15)

	# feuchte, dunklere Stellen in Senken
	var senke := sin(p.x * 0.13 - p.z * 0.21 + 1.9)
	c = c.lerp(feucht, clampf(senke * 1.3 - 0.45, 0.0, 1.0) * 0.55)

	# grobe Körnung, gerade so fein, dass sie nicht zu Moiré führt
	var korn := sin(p.x * 0.97 + p.z * 1.13) * 0.028
	return Color(clampf(c.r + korn, 0, 1), clampf(c.g + korn, 0, 1), clampf(c.b + korn, 0, 1))


## Gesamtlänge der Strecke, für die Bewegung der Gegner.
static func laenge_von(punkte: PackedVector3Array) -> float:
	var l := 0.0
	for i in range(punkte.size() - 1):
		l += punkte[i].distance_to(punkte[i + 1])
	return l


## Position nach zurückgelegter Strecke, auf Geländehöhe.
static func punkt_bei(punkte: PackedVector3Array, strecke: float) -> Vector3:
	if strecke <= 0.0:
		return _auf_boden(punkte[0])
	var rest := strecke
	for i in range(punkte.size() - 1):
		var d := punkte[i].distance_to(punkte[i + 1])
		if rest <= d:
			return _auf_boden(punkte[i].lerp(punkte[i + 1], rest / d))
		rest -= d
	return _auf_boden(punkte[punkte.size() - 1])


static func _auf_boden(p: Vector3) -> Vector3:
	return Vector3(p.x, Gelaende.hoehe_bei(p.x, p.z, 0.0) + UEBER_BODEN, p.z)
