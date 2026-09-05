extends CanvasLayer
##
## Das Menü: Kartenwahl, Trainerpfad, Aufstellung.
##
## Bis hierher lief die ganze Fortschrittslogik unter der Oberfläche und war
## nicht zu bedienen. Sterne wurden vergeben, Trainerpunkte gesammelt, Ränge
## konnten gekauft werden — nur gab es keinen Ort, an dem das sichtbar wurde.
## Ein Spielstand, den niemand ausgeben kann, ist eine Zahl in einer Datei.
##
## Aufgebaut wird bei jedem Öffnen neu. Das ist verschwenderisch und hier
## richtig: Das Menü steht still, während es offen ist, und ein
## Neuaufbau kann nicht veralten. Die Alternative wäre, dreißig Beschriftungen
## einzeln nachzuführen und bei jeder neuen Zeile daran zu denken.
##

const Daten = preload("res://scripts/daten.gd")

signal runde_gestartet(karte: int)
signal geschlossen()

const GRUND := Color(0.055, 0.078, 0.094, 0.97)
const FELD := Color(0.09, 0.12, 0.145)
const RAND := Color(0.16, 0.21, 0.24)
const SCHRIFT := Color(0.90, 0.93, 0.95)
const MATT := Color(0.55, 0.62, 0.66)
const BERNSTEIN := Color(0.94, 0.66, 0.24)
const GRUEN := Color(0.42, 0.85, 0.55)

var spiel: RefCounted
var gewaehlte_karte := 0
var _wurzel: Control


func _ready() -> void:
	layer = 20
	visible = false


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


func _text(eltern: Node, s: String, groesse: int, farbe: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", groesse)
	l.add_theme_color_override("font_color", farbe)
	eltern.add_child(l)
	return l


func oeffne(s: RefCounted, karte: int) -> void:
	spiel = s
	gewaehlte_karte = karte
	visible = true
	_baue()


func schliesse() -> void:
	visible = false
	if _wurzel != null and is_instance_valid(_wurzel):
		_wurzel.queue_free()
		_wurzel = null
	geschlossen.emit()


func _baue() -> void:
	if _wurzel != null and is_instance_valid(_wurzel):
		_wurzel.queue_free()
	_wurzel = Control.new()
	_wurzel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_wurzel)

	var hintergrund := ColorRect.new()
	hintergrund.color = GRUND
	hintergrund.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wurzel.add_child(hintergrund)

	var rollen := ScrollContainer.new()
	rollen.set_anchors_preset(Control.PRESET_FULL_RECT)
	rollen.offset_left = 40
	rollen.offset_right = -40
	rollen.offset_top = 30
	## Genug Luft, dass die letzte Talentreihe nicht hinter dem Startknopf
	## verschwindet. Der Knopf steht bei -66 bis -20, also braucht der
	## Rollbereich mehr als seine Höhe.
	rollen.offset_bottom = -86
	_wurzel.add_child(rollen)

	var spalte := VBoxContainer.new()
	spalte.add_theme_constant_override("separation", 14)
	spalte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rollen.add_child(spalte)

	_text(spalte, "PocketBeast", 30, SCHRIFT)
	_text(spalte, "★ %d Sterne gesamt · %s frei"
		% [spiel.stand.sterne_gesamt(), _punktwort(spiel.stand.offene_punkte())],
		14, BERNSTEIN)

	_baue_karten(spalte)
	_baue_aufstellung(spalte)
	_baue_pfad(spalte)

	# Fußzeile mit dem Startknopf, fest unten
	var fuss := HBoxContainer.new()
	fuss.add_theme_constant_override("separation", 10)
	fuss.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fuss.offset_left = 40
	fuss.offset_right = -40
	fuss.offset_top = -66
	fuss.offset_bottom = -20
	_wurzel.add_child(fuss)

	var start := Button.new()
	start.text = "Runde starten auf %s" % Daten.KARTEN[gewaehlte_karte]["name"]
	start.add_theme_font_size_override("font_size", 17)
	start.add_theme_stylebox_override("normal", _stil(BERNSTEIN.darkened(0.3), BERNSTEIN))
	start.add_theme_stylebox_override("hover", _stil(BERNSTEIN.darkened(0.15), BERNSTEIN))
	start.add_theme_color_override("font_color", SCHRIFT)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(func():
		schliesse()
		runde_gestartet.emit(gewaehlte_karte))
	fuss.add_child(start)

	var zu := Button.new()
	zu.text = "Zurück"
	zu.add_theme_stylebox_override("normal", _stil(FELD))
	zu.add_theme_color_override("font_color", MATT)
	zu.pressed.connect(schliesse)
	fuss.add_child(zu)


## ------------------------------------------------------------
## Kartenwahl
## ------------------------------------------------------------
func _baue_karten(eltern: Node) -> void:
	_text(eltern, "Route wählen", 19, SCHRIFT)
	var gitter := GridContainer.new()
	gitter.columns = 4
	gitter.add_theme_constant_override("h_separation", 8)
	gitter.add_theme_constant_override("v_separation", 8)
	eltern.add_child(gitter)

	for i in range(Daten.KARTEN.size()):
		var k: Dictionary = Daten.KARTEN[i]
		## Ausdrücklich typisiert: spiel ist als RefCounted deklariert, also
		## kennt GDScript den Rückgabetyp seiner Methoden nicht und := scheitert.
		var st: int = spiel.stand.sterne_von(i)
		var knopf := Button.new()
		knopf.custom_minimum_size = Vector2(210, 62)
		knopf.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var ausgewaehlt := i == gewaehlte_karte
		knopf.add_theme_stylebox_override("normal",
			_stil(FELD, BERNSTEIN if ausgewaehlt else RAND))
		knopf.add_theme_stylebox_override("hover", _stil(FELD.lightened(0.06), BERNSTEIN))
		knopf.add_theme_color_override("font_color", SCHRIFT if ausgewaehlt else MATT)
		knopf.text = "%d. %s\n%s · ★ %d / %d" % [
			i + 1, k["name"], k["grad"], st, Daten.WELLEN_JE_KARTE]
		knopf.add_theme_font_size_override("font_size", 12)
		var idx := i
		knopf.pressed.connect(func():
			gewaehlte_karte = idx
			_baue())
		gitter.add_child(knopf)


## ------------------------------------------------------------
## Aufstellung
## ------------------------------------------------------------
func _baue_aufstellung(eltern: Node) -> void:
	var frei: Array = []
	for d in Daten.WAECHTER:
		if not bool(d.get("legendaer", false)) and spiel.waechter_frei(d):
			frei.append(d)

	if frei.size() <= Daten.AUFSTELLUNG_MAX:
		_text(eltern, "Aufstellung", 19, SCHRIFT)
		_text(eltern, "Alle %d freigeschalteten Familien ziehen mit. Ab %d wählst du vor jeder Route %d davon aus."
			% [frei.size(), Daten.AUFSTELLUNG_MAX + 1, Daten.AUFSTELLUNG_MAX], 12, MATT)
		return

	var liste: Array = spiel.stand.aufstellung.get(str(gewaehlte_karte), [])
	if liste.is_empty():
		liste = spiel.schlage_aufstellung_vor(gewaehlte_karte)
		spiel.stand.aufstellung[str(gewaehlte_karte)] = liste
		spiel.stand.sichere()

	_text(eltern, "Aufstellung für %s — %d von %d"
		% [Daten.KARTEN[gewaehlte_karte]["name"], liste.size(), Daten.AUFSTELLUNG_MAX],
		19, SCHRIFT)
	_text(eltern, "Höchstens %d Wächter stehen gleichzeitig auf einer Route."
		% Daten.WAECHTER_JE_KARTE, 12, MATT)

	var gitter := GridContainer.new()
	gitter.columns = 4
	gitter.add_theme_constant_override("h_separation", 8)
	gitter.add_theme_constant_override("v_separation", 8)
	eltern.add_child(gitter)

	for d in frei:
		var drin: bool = String(d["id"]) in liste
		var farbe: Color = Daten.TYPEN[String(d["typ"])]["farbe"]
		var knopf := Button.new()
		knopf.custom_minimum_size = Vector2(210, 54)
		knopf.alignment = HORIZONTAL_ALIGNMENT_LEFT
		knopf.add_theme_stylebox_override("normal", _stil(FELD, farbe if drin else RAND))
		knopf.add_theme_stylebox_override("hover", _stil(FELD.lightened(0.06), farbe))
		knopf.add_theme_color_override("font_color", SCHRIFT if drin else MATT)
		knopf.add_theme_font_size_override("font_size", 12)
		var st0: Dictionary = d["stufen"][0]
		knopf.text = "%s%s\n%s · %s" % [
			"✓ " if drin else "", st0["name"],
			Daten.TYPEN[String(d["typ"])]["name"],
			"Luft ✓" if bool(d.get("luft", true)) else "nur Boden"]
		var id := String(d["id"])
		knopf.pressed.connect(func(): _wechsle_aufstellung(id))
		gitter.add_child(knopf)


func _wechsle_aufstellung(id: String) -> void:
	var liste: Array = spiel.stand.aufstellung.get(str(gewaehlte_karte), []).duplicate()
	if id in liste:
		liste.erase(id)
	elif liste.size() >= Daten.AUFSTELLUNG_MAX:
		return
	else:
		liste.append(id)
	spiel.stand.aufstellung[str(gewaehlte_karte)] = liste
	spiel.stand.sichere()
	_baue()


## ------------------------------------------------------------
## Trainerpfad
## ------------------------------------------------------------
func _baue_pfad(eltern: Node) -> void:
	_text(eltern, "Trainerpfad — %s frei" % _punktwort(spiel.stand.offene_punkte()),
		19, SCHRIFT)
	_text(eltern, "Jeder Rang kostet einen Punkt mehr als der vorige. Alle zehn Zweige bis Rang %d auszubauen kostet %d Punkte."
		% [Daten.TALENT_RANG_MAX,
		   Daten.TALENTE.size() * Daten.TALENT_RANG_MAX * (Daten.TALENT_RANG_MAX + 1) / 2],
		12, MATT)

	var gitter := GridContainer.new()
	gitter.columns = 3
	gitter.add_theme_constant_override("h_separation", 8)
	gitter.add_theme_constant_override("v_separation", 8)
	eltern.add_child(gitter)

	for t in Daten.TALENTE:
		var id := String(t["id"])
		var r: int = spiel.stand.rang(id)
		var voll: bool = r >= Daten.TALENT_RANG_MAX
		var preis: int = spiel.rangkosten(r)
		var bezahlbar: bool = not voll and spiel.stand.offene_punkte() >= preis
		var knopf := Button.new()
		knopf.custom_minimum_size = Vector2(280, 62)
		knopf.alignment = HORIZONTAL_ALIGNMENT_LEFT
		knopf.disabled = not bezahlbar
		knopf.add_theme_stylebox_override("normal", _stil(FELD, GRUEN if bezahlbar else RAND))
		knopf.add_theme_stylebox_override("hover", _stil(FELD.lightened(0.06), GRUEN))
		knopf.add_theme_stylebox_override("disabled", _stil(FELD.darkened(0.3), RAND))
		knopf.add_theme_color_override("font_color", SCHRIFT)
		knopf.add_theme_color_override("font_disabled_color", MATT)
		knopf.add_theme_font_size_override("font_size", 12)
		## Neben dem heutigen Wert steht der des nächsten Rangs. Ohne das kauft
		## man in die Sättigung hinein, ohne es zu merken: Beim Kopfgeld bringt
		## der erste Rang acht Prozent, der dreißigste noch ein halbes.
		var jetzt := _wirkungstext(t, r)
		var gleich := _wirkungstext(t, r + 1)
		knopf.text = "%s — Rang %d / %d\n%s%s" % [
			t["name"], r, Daten.TALENT_RANG_MAX, jetzt,
			"" if voll else "   →  %s  ·  %s" % [gleich, _punktwort(preis)]]
		var tid := id
		knopf.pressed.connect(func():
			if spiel.kaufe_rang(tid):
				_baue())
		gitter.add_child(knopf)


## Ein Punkt, zwei Punkte. Eine Zahl mit falschem Plural daneben liest sich
## wie ein Platzhalter, den jemand vergessen hat.
func _punktwort(n: int) -> String:
	return "1 Punkt" if n == 1 else "%d Punkte" % n


## Was ein Zweig bei einem bestimmten Rang bewirkt, als lesbarer Text.
## Anteile stehen in Prozent, Beträge als Zahl — sonst liest man „0,32
## Startbeeren“ statt „+289“.
func _wirkungstext(t: Dictionary, r: int) -> String:
	var wert := 0.0
	if r > 0:
		if t["kurve"] == "gerade":
			wert = float(r) * float(t["schritt"])
		else:
			wert = float(t["grenze"]) * float(r) / (float(r) + float(t["halb"]))
	var id := String(t["id"])
	match id:
		"vorrat": return "+%d Startbeeren" % int(round(wert))
		"zaeh": return "+%d Startleben" % int(round(wert))
		"durch": return "+%d Durchschlag" % int(round(wert))
		"kraft": return "+%d %% Schaden" % int(round(wert * 100.0))
		"weit": return "+%d %% Reichweite" % int(round(wert * 100.0))
		"erst": return "Frühstart +%d %%" % int(round(wert * 100.0))
		"lehre": return "Training −%d %%" % int(round(wert * 100.0))
		"handel": return "Entlassung %d %%" % int(round((0.6 + wert) * 100.0))
		"zins": return "+%.1f %% je Welle" % (wert * 100.0)
		"kopfgeld": return "+%d %% Beeren" % int(round(wert * 100.0))
	return "%.2f" % wert
