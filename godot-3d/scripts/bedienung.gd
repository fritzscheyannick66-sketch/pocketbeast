extends CanvasLayer
##
## Bedienoberfläche der 3D-Fassung.
##
## Bewusst schlicht: eine Kopfzeile mit Leben, Beeren, Welle und Punkten,
## darunter eine Reihe Wächterkarten zum Anwählen, unten der Ruf nach der
## nächsten Welle. Alles aus Godot-Bausteinen, keine Bilddateien — dieselbe
## Regel wie im Browserspiel.
##
## Die Farben stammen aus den Elementfarben der Karten, damit ein
## Feuer-Wächter hier so aussieht wie im Feld.
##

const Daten = preload("res://scripts/daten.gd")

signal waechter_gewaehlt(id: String)
signal welle_gerufen()
signal tempo_gewechselt()
signal ausbauen()
signal trainieren()
signal mega()
signal entlassen()

var _leben: Label
var _beeren: Label
var _welle: Label
var _punkte: Label
var _hinweis: Label
var _wellenknopf: Button
var _tempoknopf: Button
var _karten: Dictionary = {}      # id -> Button
var _gewaehlt := ""

## Das Feld, das erscheint, wenn ein gesetzter Wächter angewählt ist.
var _tafel: PanelContainer
var _tafel_titel: Label
var _tafel_werte: Label
var _tafel_fortschritt: Label
var _k_ausbau: Button
var _k_training: Button
var _k_mega: Button
var _k_entlassen: Button

const GRUND := Color(0.055, 0.078, 0.094, 0.92)
const RAND := Color(0.16, 0.21, 0.24)
const SCHRIFT := Color(0.90, 0.93, 0.95)
const MATT := Color(0.55, 0.62, 0.66)
const BERNSTEIN := Color(0.94, 0.66, 0.24)


func _ready() -> void:
	layer = 10
	_baue_kopf()
	_baue_laden()
	_baue_fuss()
	_baue_tafel()


func _stil(fuell: Color, rand: Color = RAND, radius: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fuell
	sb.border_color = rand
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb


## ------------------------------------------------------------
## Kopfzeile
## ------------------------------------------------------------
func _baue_kopf() -> void:
	var leiste := HBoxContainer.new()
	leiste.add_theme_constant_override("separation", 8)
	leiste.anchor_left = 0.0
	leiste.anchor_top = 0.0
	leiste.offset_left = 14
	leiste.offset_top = 12
	add_child(leiste)

	var titel := Label.new()
	titel.text = "PocketBeast 3D"
	titel.add_theme_font_size_override("font_size", 18)
	titel.add_theme_color_override("font_color", SCHRIFT)
	leiste.add_child(titel)

	var abstand := Control.new()
	abstand.custom_minimum_size = Vector2(16, 0)
	leiste.add_child(abstand)

	_leben = _kachel(leiste, "LEBEN", Color(1.0, 0.45, 0.35))
	_beeren = _kachel(leiste, "BEEREN", BERNSTEIN)
	_welle = _kachel(leiste, "WELLE", Color(0.35, 0.68, 1.0))
	_punkte = _kachel(leiste, "PUNKTE", Color(0.42, 0.85, 0.55))


## Eine Anzeigekachel: kleine Überschrift, darunter der Wert.
func _kachel(eltern: Node, beschriftung: String, farbe: Color) -> Label:
	var feld := PanelContainer.new()
	feld.add_theme_stylebox_override("panel", _stil(GRUND))
	eltern.add_child(feld)

	var spalte := VBoxContainer.new()
	spalte.add_theme_constant_override("separation", 1)
	feld.add_child(spalte)

	var kopf := Label.new()
	kopf.text = beschriftung
	kopf.add_theme_font_size_override("font_size", 9)
	kopf.add_theme_color_override("font_color", MATT)
	spalte.add_child(kopf)

	var wert := Label.new()
	wert.text = "0"
	wert.add_theme_font_size_override("font_size", 17)
	wert.add_theme_color_override("font_color", farbe)
	spalte.add_child(wert)
	return wert


## ------------------------------------------------------------
## Wächterladen
## ------------------------------------------------------------
## Der Laden hängt an Freischaltung und Aufstellung, also an einem
## Spielstand, den es beim Bau der Oberfläche noch nicht gibt. Er wird
## deshalb beim Rundenbeginn neu aufgebaut — vorher standen dort alle
## dreizehn Familien, auch die verschlossenen.
var _laden_aussen: PanelContainer

func baue_laden_neu(spiel: RefCounted) -> void:
	if _laden_aussen != null and is_instance_valid(_laden_aussen):
		_laden_aussen.queue_free()
	_karten.clear()
	_gewaehlt = ""
	_baue_laden(spiel)


func _baue_laden(spiel: RefCounted = null) -> void:
	var aussen := PanelContainer.new()
	_laden_aussen = aussen
	aussen.add_theme_stylebox_override("panel", _stil(GRUND))
	aussen.anchor_left = 0.0
	aussen.anchor_top = 1.0
	aussen.anchor_right = 1.0
	aussen.anchor_bottom = 1.0
	aussen.offset_left = 14
	aussen.offset_right = -14
	aussen.offset_top = -104
	aussen.offset_bottom = -48
	add_child(aussen)

	var reihe := HBoxContainer.new()
	reihe.add_theme_constant_override("separation", 5)
	reihe.alignment = BoxContainer.ALIGNMENT_CENTER
	aussen.add_child(reihe)

	var nr := 1
	for def in Daten.WAECHTER:
		# Der legendäre Wächter erscheint erst, wenn eine Karte gehalten wurde
		if def.get("legendaer", false):
			continue
		## Verschlossene und nicht aufgestellte Familien bleiben draußen. Wer
		## nichts freigeschaltet hat, sieht die vier Starter — und nicht eine
		## Reihe von dreizehn Knöpfen, von denen neun nichts tun.
		if spiel != null and not spiel.setzbar(String(def["id"])):
			continue
		var id: String = def["id"]
		var st: Dictionary = def["stufen"][0]
		var farbe: Color = Daten.TYPEN[def["typ"]]["farbe"]

		var knopf := Button.new()
		knopf.custom_minimum_size = Vector2(92, 44)
		knopf.tooltip_text = "%s — %s\n%s" % [st["name"], Daten.TYPEN[def["typ"]]["name"], def["beschreibung"]]
		knopf.text = "%d  %s\n%d" % [nr, st["name"], int(st["kosten"])]
		knopf.add_theme_font_size_override("font_size", 10)
		knopf.add_theme_color_override("font_color", farbe)
		knopf.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		knopf.add_theme_stylebox_override("normal", _stil(Color(farbe.r, farbe.g, farbe.b, 0.10), farbe * 0.6, 7))
		knopf.add_theme_stylebox_override("hover", _stil(Color(farbe.r, farbe.g, farbe.b, 0.22), farbe, 7))
		knopf.add_theme_stylebox_override("pressed", _stil(Color(farbe.r, farbe.g, farbe.b, 0.30), farbe, 7))
		knopf.pressed.connect(_auf_waechter.bind(id))
		reihe.add_child(knopf)
		_karten[id] = knopf
		nr += 1


func _auf_waechter(id: String) -> void:
	_gewaehlt = "" if _gewaehlt == id else id
	_zeichne_auswahl()
	waechter_gewaehlt.emit(_gewaehlt)


func _zeichne_auswahl() -> void:
	for id in _karten:
		var k: Button = _karten[id]
		k.modulate = Color(1, 1, 1) if id == _gewaehlt else Color(0.72, 0.72, 0.72)


## ------------------------------------------------------------
## Fußzeile
## ------------------------------------------------------------
func _baue_fuss() -> void:
	var reihe := HBoxContainer.new()
	reihe.add_theme_constant_override("separation", 8)
	reihe.anchor_left = 0.0
	reihe.anchor_top = 1.0
	reihe.anchor_bottom = 1.0
	reihe.offset_left = 14
	reihe.offset_top = -40
	reihe.offset_bottom = -12
	add_child(reihe)

	_wellenknopf = Button.new()
	_wellenknopf.text = "Welle rufen  (Leertaste)"
	_wellenknopf.add_theme_font_size_override("font_size", 12)
	_wellenknopf.add_theme_color_override("font_color", Color(0.1, 0.08, 0.03))
	_wellenknopf.add_theme_stylebox_override("normal", _stil(BERNSTEIN, BERNSTEIN, 7))
	_wellenknopf.add_theme_stylebox_override("hover", _stil(BERNSTEIN.lightened(0.15), BERNSTEIN, 7))
	_wellenknopf.pressed.connect(func(): welle_gerufen.emit())
	reihe.add_child(_wellenknopf)

	_tempoknopf = Button.new()
	_tempoknopf.text = "1×"
	_tempoknopf.add_theme_font_size_override("font_size", 12)
	_tempoknopf.add_theme_color_override("font_color", SCHRIFT)
	_tempoknopf.add_theme_stylebox_override("normal", _stil(GRUND))
	_tempoknopf.pressed.connect(func(): tempo_gewechselt.emit())
	reihe.add_child(_tempoknopf)

	_hinweis = Label.new()
	_hinweis.add_theme_font_size_override("font_size", 12)
	_hinweis.add_theme_color_override("font_color", MATT)
	_hinweis.text = "Wächter wählen, dann auf eine freie Fläche klicken"
	reihe.add_child(_hinweis)


## ------------------------------------------------------------
## Wächtertafel
## ------------------------------------------------------------
## Erscheint rechts, sobald ein gesetzter Wächter angewählt ist. Zeigt, was
## er kann und was der nächste Schritt kostet.
func _baue_tafel() -> void:
	_tafel = PanelContainer.new()
	_tafel.add_theme_stylebox_override("panel", _stil(GRUND))
	_tafel.anchor_left = 1.0
	_tafel.anchor_right = 1.0
	_tafel.anchor_top = 0.0
	_tafel.offset_left = -252
	_tafel.offset_right = -14
	_tafel.offset_top = 72
	_tafel.visible = false
	add_child(_tafel)

	var spalte := VBoxContainer.new()
	spalte.add_theme_constant_override("separation", 6)
	_tafel.add_child(spalte)

	_tafel_titel = Label.new()
	_tafel_titel.add_theme_font_size_override("font_size", 15)
	_tafel_titel.add_theme_color_override("font_color", SCHRIFT)
	spalte.add_child(_tafel_titel)

	_tafel_werte = Label.new()
	_tafel_werte.add_theme_font_size_override("font_size", 11)
	_tafel_werte.add_theme_color_override("font_color", MATT)
	spalte.add_child(_tafel_werte)

	_tafel_fortschritt = Label.new()
	_tafel_fortschritt.add_theme_font_size_override("font_size", 10)
	_tafel_fortschritt.add_theme_color_override("font_color", BERNSTEIN)
	spalte.add_child(_tafel_fortschritt)

	_k_ausbau = _tafelknopf(spalte, "Entwickeln", BERNSTEIN)
	_k_ausbau.pressed.connect(func(): ausbauen.emit())
	_k_training = _tafelknopf(spalte, "Training", Color(0.42, 0.85, 0.55))
	_k_training.pressed.connect(func(): trainieren.emit())
	_k_mega = _tafelknopf(spalte, "★ Megaentwicklung", Color(0.96, 0.77, 0.26))
	_k_mega.pressed.connect(func(): mega.emit())
	_k_entlassen = _tafelknopf(spalte, "Entlassen", Color(0.85, 0.45, 0.38))
	_k_entlassen.pressed.connect(func(): entlassen.emit())


func _tafelknopf(eltern: Node, beschriftung: String, farbe: Color) -> Button:
	var k := Button.new()
	k.text = beschriftung
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", farbe)
	k.add_theme_color_override("font_disabled_color", Color(0.38, 0.42, 0.44))
	k.add_theme_stylebox_override("normal", _stil(Color(farbe.r, farbe.g, farbe.b, 0.12), farbe * 0.6, 6))
	k.add_theme_stylebox_override("hover", _stil(Color(farbe.r, farbe.g, farbe.b, 0.24), farbe, 6))
	k.add_theme_stylebox_override("disabled", _stil(Color(1, 1, 1, 0.03), RAND, 6))
	eltern.add_child(k)
	return k


## Zeigt einen angewählten Wächter — oder verbirgt die Tafel bei null.
func zeige_turm(turm, spiel) -> void:
	if turm == null:
		_tafel.visible = false
		return
	_tafel.visible = true

	var def: Dictionary = spiel.waechter_def(String(turm.get("id", "")))
	var stufe: int = int(turm.get("stufe", 0))
	var st: Dictionary = def["stufen"][stufe]
	var name: String = String(st["name"])
	if turm.get("mega", false):
		name = "★ " + name
	_tafel_titel.text = "%s   Stufe %d" % [name, stufe + 1]

	var tf: float = spiel.trainingsfaktor(int(turm.get("training", 0)))
	_tafel_werte.text = "Schaden %d   Rate %.1f/s
Reichweite %d%s" % [
		int(round(float(turm["schaden"]))),
		float(turm["takt"]),
		int(round(float(turm["reichweite"]) * spiel.PIXEL_JE_METER)),
		"   Durchschlag %d" % int(turm.get("durchschlag", 0)) if float(turm.get("durchschlag", 0)) > 0 else "",
	]

	# Ausbauen
	var kosten: int = spiel.ausbaukosten(String(turm.get("id", "")), stufe)
	if turm.get("mega", false) or kosten < 0:
		_k_ausbau.text = "Endstufe erreicht"
		_k_ausbau.disabled = true
	else:
		_k_ausbau.text = "Entwickeln zu %s  ·  %d" % [def["stufen"][stufe + 1]["name"], kosten]
		_k_ausbau.disabled = spiel.beeren < kosten

	# Training — erst ab Endstufe, wie im Browserspiel
	var trn: int = int(turm.get("training", 0))
	var tkosten: int = spiel.trainingskosten(trn)
	if stufe < 2:
		_k_training.text = "Training ab Endstufe"
		_k_training.disabled = true
	elif trn >= spiel.TRAIN_MAX:
		_k_training.text = "Training voll (%d)" % trn
		_k_training.disabled = true
	else:
		_k_training.text = "Training %d/%d  ·  %d" % [trn + 1, spiel.TRAIN_MAX, tkosten]
		_k_training.disabled = spiel.beeren < tkosten

	# Megaentwicklung
	if turm.get("mega", false):
		_k_mega.text = "★ Megaentwickelt"
		_k_mega.disabled = true
		_tafel_fortschritt.text = ""
	elif spiel.mega_bereit(turm):
		_k_mega.text = "★ Megaentwicklung  ·  %d" % spiel.MEGA_KOSTEN
		_k_mega.disabled = spiel.beeren < spiel.MEGA_KOSTEN
		_tafel_fortschritt.text = "bereit"
	else:
		_k_mega.text = "★ Megaentwicklung"
		_k_mega.disabled = true
		_tafel_fortschritt.text = "Mega: %d/%d erledigt · Training %d/%d" % [
			mini(int(turm.get("erledigt", 0)), spiel.MEGA_ERLEDIGT), spiel.MEGA_ERLEDIGT,
			mini(trn, spiel.MEGA_TRAINING), spiel.MEGA_TRAINING]

	_k_entlassen.text = "Entlassen  ·  +%d" % spiel.entlassungswert(turm)
	_k_entlassen.disabled = false


## ------------------------------------------------------------
## Anzeige auffrischen
## ------------------------------------------------------------
func zeige(spiel) -> void:
	_leben.text = str(spiel.leben)
	_beeren.text = str(spiel.beeren)
	_welle.text = "%d / %d" % [spiel.welle, Daten.WELLEN_JE_KARTE]
	_punkte.text = str(spiel.punkte)
	_wellenknopf.disabled = spiel.welle_laeuft or spiel.verloren
	_wellenknopf.text = "Welle läuft" if spiel.welle_laeuft else "Welle rufen  (Leertaste)"

	# Was nicht bezahlbar ist, wird matt — ohne dass der Knopf verschwindet
	for id in _karten:
		var k: Button = _karten[id]
		var reicht: bool = spiel.beeren >= spiel.baukosten(id)
		var dunkel := 1.0 if reicht else 0.45
		k.modulate = Color(dunkel, dunkel, dunkel) * (1.0 if id == _gewaehlt else 0.78)


func setze_hinweis(text: String) -> void:
	_hinweis.text = text


func setze_tempo(t: int) -> void:
	_tempoknopf.text = "%d×" % t


func auswahl_loeschen() -> void:
	_gewaehlt = ""
	_zeichne_auswahl()
