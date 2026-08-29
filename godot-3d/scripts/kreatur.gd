extends RefCounted
##
## Kreaturen aus Grundkörpern.
##
## Im Browserspiel ist jede Kreatur eine gezeichnete Figur — Bögen, Verläufe,
## Striche. Das lässt sich nicht übertragen: Dort sind es zweidimensionale
## Pfade, hier braucht es Körper im Raum. Bis eben waren Wächter und Gegner
## deshalb schlicht farbige Kugeln, und damit sah die 3D-Fassung aus wie ein
## Machbarkeitsnachweis statt wie dasselbe Spiel.
##
## Der Weg hier ist ein anderer als im Browser: kein Nachzeichnen, sondern ein
## Bauteilsatz. Jede Figur bekommt Rumpf, Kopf und Augen, und darüber legt die
## Form ihre eigenen Teile — Ohren, Hörner, Schwingen, Flossen, einen Kamm.
##
## Warum das reicht: Was eine Silhouette erkennbar macht, sind zwei oder drei
## Merkmale, nicht die Feinzeichnung. Eine Katze erkennt man an den spitzen
## Ohren, einen Ochsen an den Hörnern, einen Vogel an den Schwingen — bei der
## Größe, in der die Figuren hier auf dem Bildschirm stehen, trägt der Rest
## ohnehin nichts bei.
##
## ALLE FARBEN GEHEN DURCH srgb_to_linear(). Godot liest gesetzte Farbwerte
## als linear; ein direkt zugewiesener sRGB-Wert erscheint deutlich zu hell.
## Das hat mich in dieser Fassung schon einmal einen halben Tag gekostet — der
## milchige Schleier über allem war genau das.
##

const Gelaende = preload("res://scripts/gelaende.gd")

## Ein Bauteil: Netz, Ort, Drehung, Farbe.
static func _teil(eltern: Node3D, netz: Mesh, ort: Vector3, farbe: Color,
		drehung: Vector3 = Vector3.ZERO, leuchtet: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = netz
	m.position = ort
	m.rotation = drehung
	var mat := StandardMaterial3D.new()
	mat.albedo_color = farbe.srgb_to_linear()
	mat.roughness = 0.62
	if leuchtet > 0.0:
		mat.emission_enabled = true
		mat.emission = farbe.srgb_to_linear()
		mat.emission_energy_multiplier = leuchtet
	m.material_override = mat
	eltern.add_child(m)
	return m


static func _kugel(r: float, hoehe: float = -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = (r * 2.0) if hoehe < 0.0 else hoehe
	s.radial_segments = 12
	s.rings = 7
	return s


static func _kegel(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 7
	return c


static func _quader(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


## Baut eine Figur unter dem übergebenen Knoten auf.
##
##   form    Gestalt aus den Spieldaten (cat, ox, falke, drop, …)
##   farbe   Elementfarbe
##   groesse Maßstab in Metern; 1.0 entspricht etwa einer Kachelbreite Höhe
##   stufe   0–2, ab 1 kommt ein Kranz dazu
##
## Gibt den Rumpfknoten zurück, damit der Aufrufer ihn drehen kann.
static func baue(eltern: Node3D, form: String, farbe: Color, groesse: float,
		stufe: int = 0, anfuehrer: bool = false) -> Node3D:
	var g := groesse
	var dunkel := farbe.darkened(0.42)
	var hell := farbe.lightened(0.34)
	var koerper := Node3D.new()
	eltern.add_child(koerper)

	# ---- Rumpf ----------------------------------------------------------
	# Breit und niedrig. Der erste Anlauf machte ihn fast so groß wie den Kopf
	# und setzte beide dicht übereinander — auf dem Bild war das ein Klumpen
	# mit Augen, kein Wesen. Ein Körper liest sich erst als Körper, wenn der
	# Kopf sichtbar darauf sitzt.
	var rumpf := _kugel(0.44 * g, 0.56 * g)
	_teil(koerper, rumpf, Vector3(0, 0.30 * g, 0), farbe)

	# ---- Bauch ----------------------------------------------------------
	_teil(koerper, _kugel(0.28 * g, 0.34 * g), Vector3(0, 0.26 * g, 0.24 * g), hell)

	# ---- Hals -----------------------------------------------------------
	# Schmal, damit die Trennung zwischen Rumpf und Kopf sichtbar wird
	_teil(koerper, _kugel(0.17 * g, 0.16 * g), Vector3(0, 0.56 * g, 0.02 * g), dunkel)

	# ---- Kopf -----------------------------------------------------------
	var kopf_y := 0.80 * g
	_teil(koerper, _kugel(0.32 * g), Vector3(0, kopf_y, 0.03 * g), farbe)

	# ---- Augen ----------------------------------------------------------
	# Dunkel und leicht nach vorn gesetzt. Ohne Augen wirkt jede Form wie ein
	# Gegenstand, mit Augen wie ein Wesen — das ist der billigste und größte
	# Schritt in diesem ganzen Bauteilsatz.
	var auge := _kugel(0.075 * g)
	for s in [-1.0, 1.0]:
		_teil(koerper, auge, Vector3(s * 0.13 * g, kopf_y + 0.04 * g, 0.28 * g),
			Color(0.05, 0.08, 0.10))
		_teil(koerper, _kugel(0.028 * g),
			Vector3(s * 0.15 * g, kopf_y + 0.09 * g, 0.33 * g), Color(1, 1, 1))

	# ---- Formmerkmale ---------------------------------------------------
	match form:
		"cat", "fox":
			# Spitze Ohren, nach außen geneigt; beim Fuchs länger
			var lang := 0.34 if form == "fox" else 0.26
			for s in [-1.0, 1.0]:
				# Ansatz auf der Kopfkuppe, nicht darin: Der Kegel ist halb so
				# lang wie sein Abstand nach oben, sonst steckt er im Kopf.
				_teil(koerper, _kegel(0.10 * g, lang * g),
					Vector3(s * 0.17 * g, kopf_y + 0.24 * g + lang * 0.5 * g, 0.0),
					dunkel, Vector3(0, 0, s * -0.30))
			# Schweif
			_teil(koerper, _kugel(0.09 * g, 0.52 * g),
				Vector3(0, 0.42 * g, -0.42 * g), dunkel, Vector3(0.9, 0, 0))
		"ox":
			# Hörner: waagerecht abstehend, heller als der Körper
			for s in [-1.0, 1.0]:
				_teil(koerper, _kegel(0.085 * g, 0.44 * g),
					Vector3(s * 0.44 * g, kopf_y + 0.20 * g, 0.0),
					Color(0.91, 0.86, 0.75), Vector3(0, 0, s * -1.05))
			# Schnauze
			_teil(koerper, _kugel(0.17 * g, 0.20 * g),
				Vector3(0, kopf_y - 0.10 * g, 0.30 * g), hell)
		"falke", "bird":
			# Schwingen, angelegt und leicht abgespreizt
			for s in [-1.0, 1.0]:
				_teil(koerper, _quader(0.10 * g, 0.44 * g, 0.30 * g),
					Vector3(s * 0.44 * g, 0.46 * g, -0.04 * g),
					dunkel, Vector3(0, 0, s * -0.30))
			# Schnabel
			_teil(koerper, _kegel(0.09 * g, 0.22 * g),
				Vector3(0, kopf_y - 0.02 * g, 0.34 * g),
				Color(0.91, 0.70, 0.29), Vector3(1.57, 0, 0))
		"owl":
			for s in [-1.0, 1.0]:
				_teil(koerper, _kegel(0.085 * g, 0.24 * g),
					Vector3(s * 0.16 * g, kopf_y + 0.32 * g, 0.0), dunkel)
				_teil(koerper, _kugel(0.17 * g, 0.10 * g),
					Vector3(s * 0.15 * g, kopf_y + 0.03 * g, 0.26 * g), hell)
		"moth":
			# Große Flügel, weit gespreizt
			for s in [-1.0, 1.0]:
				_teil(koerper, _quader(0.52 * g, 0.06 * g, 0.42 * g),
					Vector3(s * 0.42 * g, 0.62 * g, -0.02 * g),
					hell, Vector3(0.22, 0, s * -0.42), 0.18)
			# Fühler
			for s in [-1.0, 1.0]:
				_teil(koerper, _kegel(0.03 * g, 0.30 * g),
					Vector3(s * 0.10 * g, kopf_y + 0.28 * g, 0.06 * g),
					dunkel, Vector3(-0.4, 0, s * -0.5))
		"fish", "drop":
			# Schwanzflosse hinten, Rückenflosse oben
			_teil(koerper, _quader(0.06 * g, 0.36 * g, 0.30 * g),
				Vector3(0, 0.42 * g, -0.46 * g), dunkel, Vector3(0.3, 0, 0))
			_teil(koerper, _quader(0.05 * g, 0.28 * g, 0.22 * g),
				Vector3(0, 0.78 * g, -0.10 * g), dunkel)
		"sprout":
			# Zwei Blätter, nach außen geneigt
			for s in [-1.0, 1.0]:
				_teil(koerper, _quader(0.09 * g, 0.40 * g, 0.20 * g),
					Vector3(s * 0.20 * g, kopf_y + 0.34 * g, 0.0),
					hell, Vector3(0, 0, s * -0.50))
		"crystal", "zottel":
			# Zacken rings um den Rumpf
			for i in range(6):
				var w := float(i) / 6.0 * TAU
				_teil(koerper, _kegel(0.08 * g, 0.28 * g),
					Vector3(cos(w) * 0.40 * g, 0.52 * g, sin(w) * 0.40 * g),
					hell, Vector3(sin(w) * 0.7, 0, -cos(w) * 0.7))
		"bolzen":
			# Kantig: Platten statt Rundungen, Visierschlitz
			_teil(koerper, _quader(0.62 * g, 0.20 * g, 0.52 * g),
				Vector3(0, 0.62 * g, 0), dunkel)
			_teil(koerper, _quader(0.44 * g, 0.07 * g, 0.06 * g),
				Vector3(0, kopf_y + 0.02 * g, 0.31 * g),
				Color(0.61, 0.91, 1.0), Vector3.ZERO, 0.9)
		"wisp", "eye":
			# Schwebender Kern mit Ring
			_teil(koerper, _kugel(0.20 * g),
				Vector3(0, kopf_y + 0.02 * g, 0), hell, Vector3.ZERO, 0.8)
			var ring := TorusMesh.new()
			ring.inner_radius = 0.34 * g
			ring.outer_radius = 0.40 * g
			_teil(koerper, ring, Vector3(0, 0.72 * g, 0), hell, Vector3(0.4, 0, 0.3), 0.5)
		"hueter", "thron":
			# Der legendäre Wächter: kein Gesicht, ein Visierschlitz, und über
			# dem Haupt eine Krone aus Splittern.
			_teil(koerper, _quader(0.40 * g, 0.06 * g, 0.06 * g),
				Vector3(0, kopf_y + 0.02 * g, 0.30 * g),
				Color(1, 0.93, 0.72), Vector3.ZERO, 1.2)
			for i in range(6):
				var w2 := float(i) / 6.0 * TAU
				_teil(koerper, _kegel(0.05 * g, 0.22 * g),
					Vector3(cos(w2) * 0.34 * g, kopf_y + 0.42 * g, sin(w2) * 0.34 * g),
					hell, Vector3.ZERO, 0.7)
		_:
			# Quabbe und alles ohne eigenes Merkmal: ein Kamm auf dem Rücken,
			# damit auch die schlichte Form eine Silhouette hat
			for i in range(3):
				_teil(koerper, _kegel(0.06 * g, 0.16 * g),
					Vector3(0, 0.70 * g - float(i) * 0.02 * g, -0.10 * g - float(i) * 0.14 * g),
					dunkel)

	# ---- Kranz der Entwicklungsstufe ------------------------------------
	# Ab Stufe 2 ein Ring aus Spitzen über dem Kopf, ab Stufe 3 höher und in
	# der Elementfarbe leuchtend. Dieselbe Sprache wie im Browserspiel.
	if stufe >= 1:
		var n := 7 if stufe >= 2 else 5
		var hoch := kopf_y + (0.40 if stufe >= 2 else 0.32) * g
		for i in range(n):
			var w3 := float(i) / float(n) * TAU
			_teil(koerper, _kegel(0.045 * g, 0.16 * g),
				Vector3(cos(w3) * 0.28 * g, hoch, sin(w3) * 0.28 * g),
				hell if stufe >= 2 else dunkel,
				Vector3.ZERO, 0.5 if stufe >= 2 else 0.0)

	# ---- Anführer -------------------------------------------------------
	# Ein Reif am Boden, damit man ihn im Gedränge sofort findet.
	if anfuehrer:
		var reif := TorusMesh.new()
		reif.inner_radius = 0.58 * g
		reif.outer_radius = 0.70 * g
		_teil(koerper, reif, Vector3(0, 0.06 * g, 0), Color(1, 0.77, 0.26),
			Vector3.ZERO, 0.6)

	return koerper
