extends RefCounted
##
## Spielzustand und Regeln der 3D-Fassung.
##
## Getrennt von welt.gd, weil dort das Zeichnen wohnt: Gelände, Bewuchs,
## Licht, Kamera. Was ein Wächter kostet, wie viele Leben bleiben und wann
## die nächste Welle kommt, hat damit nichts zu tun — und lässt sich so
## prüfen, ohne dass eine Szene laufen muss.
##
## Die Zahlen kommen aus daten.gd, also aus dem Browserspiel. Was hier steht,
## sind nur die Regeln, die beide Fassungen teilen.
##

const Daten = preload("res://scripts/daten.gd")
const Stand = preload("res://scripts/stand.gd")

## Der Spielstand. Er lebt länger als eine Runde und wird beim Erzeugen
## geladen — ohne ihn beginnt jeder Start bei null, und Sterne, Trainerpfad
## und Freischaltung wären Zierat.
var stand := Stand.new()

## Godot rechnet in Metern, das Browserspiel in Pixeln.
## Eine Kachel misst dort 56 Pixel und hier 2 Meter.
const PIXEL_JE_METER := 28.0

## Wie stark der Beerenzufluss gedrosselt ist. Dieselbe Zahl wie BEEREN_MULT
## im Browserspiel, und aus demselben Grund: Ohne Drosselung liefert eine
## gehaltene Runde mehr Beeren, als sich überhaupt ausgeben lässt — dann
## entwickelt man jeden Wächter und muss keinen mehr auswählen.
##
## Sie greift an jedem Zufluss, aber nicht an den Startbeeren: die sind die
## Aussaat und werden im Browserspiel über ein eigenes Talent gehoben.
const BEEREN_MULT := 0.55


## Jede Einnahme geht hier durch.
static func beeren_von(betrag: float) -> int:
	return int(round(betrag * BEEREN_MULT))

var karte_idx := 0
var beeren := 0
var leben := 0
var welle := 0
var punkte := 0
var durchgelassen := 0

## Läuft gerade eine Welle, oder wartet das Spiel auf den nächsten Ruf?
var welle_laeuft := false
var verloren := false
## Alle Wellen der Karte gehalten. Ohne das lief die Runde ins Leere: Bei
## Welle 100 kam einfach Welle 101, und die Kampagne hatte kein Ende.
var gewonnen := false
var endlos := false

## Was in dieser Welle noch zu schicken ist.
var warteschlange: Array[Dictionary] = []
var spawn_uhr := 0.0


func starte(idx: int) -> void:
	stand.lade()
	karte_idx = idx
	var k: Dictionary = Daten.KARTEN[idx]
	## Proviantbeutel und Zähigkeit heben die Aussaat. Gerundet, weil die
	## sättigenden Kurven Bruchzahlen liefern — halbe Leben darf es nicht geben.
	beeren = int(round(float(k["beeren"]) + talent("vorrat")))
	leben = int(round(float(k["leben"]) + talent("zaeh")))
	welle = 0
	punkte = 0
	durchgelassen = 0
	welle_laeuft = false
	verloren = false
	gewonnen = false
	warteschlange.clear()


func karte() -> Dictionary:
	return Daten.KARTEN[karte_idx]


func waechter_def(id: String) -> Dictionary:
	for w in Daten.WAECHTER:
		if w["id"] == id:
			return w
	return {}


## Was die erste Stufe eines Wächters kostet.
func baukosten(id: String) -> int:
	var def := waechter_def(id)
	if def.is_empty():
		return 999999
	return int(def["stufen"][0]["kosten"])


## Was die nächste Stufe kostet. -1, wenn schon auf Endstufe.
func ausbaukosten(id: String, stufe: int) -> int:
	if stufe >= 2:
		return -1
	var def := waechter_def(id)
	if def.is_empty():
		return -1
	return int(def["stufen"][stufe + 1]["kosten"])


## ============================================================
## Ausbau
## ============================================================

## Ab wann ein Wächter die Megaentwicklung erreichen kann.
## Dieselben Schwellen wie im Browserspiel.
const MEGA_ERLEDIGT := 40
const MEGA_TRAINING := 6
const MEGA_KOSTEN := 650
const TRAIN_MAX := 15


## Was die nächste Trainingsstufe kostet. Wächst um 24 Prozent je Stufe —
## dadurch bleibt Training früh günstig und wird spät zum Beerengrab.
func trainingskosten(stufe: int) -> int:
	return int(round(80.0 * pow(1.24, float(stufe))))


## Wieviel Schaden das Training zusätzlich bringt: neun Prozent je Stufe.
static func trainingsfaktor(stufe: int) -> float:
	return 1.0 + float(stufe) * 0.09


## Steht die Megaentwicklung bereit?
##
## Sie hängt nicht am Geld allein, sondern an einem Wächter, der lange genug
## gelebt und lange genug getroffen hat. Ein frisch gekaufter kommt nie
## dorthin — das belohnt Pflege statt Nachschub.
func mega_bereit(turm: Dictionary) -> bool:
	if turm.get("mega", false):
		return false
	if int(turm.get("stufe", 0)) < 2:
		return false
	if int(turm.get("erledigt", 0)) < MEGA_ERLEDIGT:
		return false
	if int(turm.get("training", 0)) < MEGA_TRAINING:
		return false
	## Auch die Megaentwicklung hängt an der Tageszeit — sonst käme die Fee
	## nachts über einen Umweg doch an ihre vierte Stufe.
	return darf_entwickeln(String(turm.get("id", "")))


## Die Werte der Megaentwicklung, abgeleitet aus der Endstufe.
## Schaden mal 1,75, Feuerrate mal 1,15, Reichweite mal 1,18 —
## dieselben Faktoren wie im Browserspiel.
static func mega_werte(endstufe: Dictionary) -> Dictionary:
	var m := endstufe.duplicate(true)
	m["schaden"] = float(endstufe["schaden"]) * 1.75
	m["rate"] = float(endstufe["rate"]) * 1.15
	m["reichweite"] = float(endstufe["reichweite"]) * 1.18
	if endstufe.has("durchschlag"):
		m["durchschlag"] = float(endstufe["durchschlag"]) * 1.5
	return m


## Was ein Wächter beim Entlassen zurückbringt: sechzig Prozent des
## Gezahlten. Wer umbaut, verliert etwas — sonst wäre jede Aufstellung
## beliebig, weil man sie jederzeit kostenlos umwerfen könnte.
func entlassungswert(turm: Dictionary) -> int:
	var def := waechter_def(String(turm.get("id", "")))
	if def.is_empty():
		return 0
	var summe := 0
	for i in range(int(turm.get("stufe", 0)) + 1):
		summe += int(def["stufen"][i]["kosten"])
	summe += int(turm.get("trainingsausgaben", 0))
	if turm.get("mega", false):
		summe += MEGA_KOSTEN
	return int(round(float(summe) * 0.6))


## ============================================================
## Wellen
## ============================================================

## Stellt die nächste Welle zusammen.
##
## Anders als im Browserspiel, wo eine Welle aus bis zu drei Arten besteht
## und die Lebenspunkte gegen deren durchschnittliche Zähigkeit normiert
## werden, sind es hier zwei Arten mit fester Aufteilung. Der Feinschliff
## gehört ins Browserspiel, solange dieses die spielbare Fassung ist —
## zwei Fassungen derselben Rechnung driften auseinander.
func rufe_welle() -> void:
	if welle_laeuft or verloren:
		return
	if gewonnen and not endlos:
		return
	welle += 1
	welle_laeuft = true
	warteschlange.clear()

	var faktor: float = float(karte()["faktor"])
	# Typ ausdrücklich angeben: Array-Werte haben in GDScript keinen
	# abgeleiteten Typ, := scheitert daran.
	var stufe: float = float(Daten.WELLE_LEBEN[clampi(welle - 1, 0, Daten.WELLE_LEBEN.size() - 1)])
	var budget: float = stufe * faktor

	# Welche Arten dürfen schon auftreten? Zähigkeit wächst mit der Welle.
	var grenze := 0.9 + float(welle) * 0.055
	## Nicht jede Art auf jeder Karte. Der Grünpfad kennt drei Elemente, die
	## letzten Routen alle elf — dieselbe Fauna wie im Browserspiel, und aus
	## demselben Grund: Ohne sie sieht jede Route gleich aus, nur in anderen
	## Farben.
	var fauna: Array = karte().get("wilde", [])
	var moeglich: Array = []
	for a in Daten.ARTEN:
		if not fauna.is_empty() and not (String(a["typ"]) in fauna):
			continue
		if float(a["leben"]) <= grenze:
			moeglich.append(a)
	if moeglich.size() < 2:
		moeglich = Daten.ARTEN.slice(0, 4)

	## Bodengarantie wie im Browserspiel: Eine Welle darf nie vollständig aus
	## Fliegern bestehen. Gegen eine solche fällt jeder bodengebundene
	## Wächter aus, und wer nicht zufällig Luftabwehr stehen hat, verliert
	## die Welle vollständig.
	var arten: Array = []
	arten.append(moeglich[randi() % moeglich.size()])
	var zweite: Dictionary = moeglich[randi() % moeglich.size()]
	if arten[0].get("fliegt", false) and zweite.get("fliegt", false):
		var boden: Array = []
		for a in moeglich:
			if not a.get("fliegt", false):
				boden.append(a)
		if not boden.is_empty():
			zweite = boden[randi() % boden.size()]
	arten.append(zweite)

	var stueck := 8 + welle
	for i in range(stueck):
		var art: Dictionary = arten[i % arten.size()]
		warteschlange.append({
			"art": art,
			"leben": budget * float(art["leben"]) / float(stueck),
		})

	## Anführer. Alle acht Wellen einer, und auf der Schlusswelle immer.
	##
	## Bis hierher hatte die 3D-Fassung keine — hundert Wellen ohne einen
	## einzigen Anführer sind kein Tower-Defense, sondern eine Zählschleife.
	## Er kommt zuletzt, hinter der ganzen Welle, damit er nicht im Gedränge
	## untergeht.
	if Daten.ist_anfuehrerwelle(welle):
		var chef := anfuehrer_fuer(welle)
		if not chef.is_empty():
			warteschlange.append({
				"art": chef,
				"leben": budget * float(chef["leben"]),
				"anfuehrer": true,
			})
	spawn_uhr = 0.0


## Welcher Anführer auf welche Welle.
##
## Aus der Fauna der Karte, nicht aus allen elf: Auf einer Route mit drei
## Elementen stünde sonst ein Anführer, gegen den es kein Gegenmittel gibt.
## Sortiert nach Panzerung, die weichen zuerst — Panzerung wird je Treffer
## abgezogen und trifft frühe, schwache Wächter deshalb ungleich härter.
func anfuehrer_fuer(w: int) -> Dictionary:
	var fauna: Array = karte().get("wilde", [])
	var vorrat: Array = []
	for b in Daten.ANFUEHRER:
		if fauna.is_empty() or String(b["typ"]) in fauna:
			vorrat.append(b)
	if vorrat.is_empty():
		vorrat = Daten.ANFUEHRER.duplicate()
	vorrat.sort_custom(func(x, y):
		var px := float(x.get("panzer", 0))
		var py := float(y.get("panzer", 0))
		if is_equal_approx(px, py):
			return float(x["leben"]) < float(y["leben"])
		return px < py)
	## Die Schlusswelle gehört dem Anführer des Heimatelements. Eine Route,
	## die mit einem beliebigen Gegner ausklingt, hat kein Ende, sondern hört
	## einfach auf.
	if w == Daten.WELLEN_JE_KARTE:
		var heim := String(karte().get("heim", ""))
		for b in vorrat:
			if String(b["typ"]) == heim:
				return b
	return vorrat[(int(w / 8.0) - 1 + vorrat.size()) % vorrat.size()]


## Ein Gegner ist durchgekommen.
func durchbruch() -> void:
	durchgelassen += 1
	leben -= 1
	if leben <= 0:
		leben = 0
		verloren = true


## Ein Gegner wurde erledigt.
func erledigt(art: Dictionary) -> void:
	beeren += beeren_von(float(art["beute"]) * (1.0 + float(welle) * 0.08)
		* (1.0 + talent("kopfgeld")))
	punkte += 10 + welle


## Welle vorbei — Belohnung.
func welle_geschafft() -> void:
	welle_laeuft = false
	if welle >= Daten.WELLEN_JE_KARTE and not endlos:
		gewonnen = true
		stand.geschafft[str(karte_idx)] = true
	var bonus := beeren_von(22.0 + float(welle) * 5.0)
	## Zinsen, gedeckelt am Wellenbonus. Ein Prozentsatz auf den ganzen Vorrat
	## wäre über hundert Wellen keine Belohnung, sondern eine Explosion.
	var zins := int(round(minf(float(beeren) * talent("zins"), float(bonus) * 2.5)))
	beeren += bonus + zins
	punkte += 120 + welle * 20

	## Sterne und Trainerpunkte. Beides überdauert die Runde, also wird der
	## Stand sofort geschrieben — im Endlosmodus gibt es keine Sterne, dort
	## zählt nur die Weite.
	if not endlos:
		stand.setze_sterne(karte_idx, welle)
	elif welle > stand.endlos:
		stand.endlos = welle
	stand.punkte += wellen_punkte(welle)
	stand.sichere()


## Was eine gehaltene Welle an Trainerpunkten einbringt: mit der Welle
## wachsend und mit der Schwierigkeit der Route. Eine flache Eins je Welle
## hätte für Rang 100 in allen zehn Zweigen 263 gewonnene Runden gekostet.
func wellen_punkte(w: int) -> int:
	var grund := int(ceil(float(w) / 4.0))
	var faktor := 1.0 + float(karte_idx) * 0.2
	var roh := grund * 6 if Daten.ist_anfuehrerwelle(w) else grund
	return int(round(float(roh) * faktor))


## ============================================================
## Tag und Nacht
## ============================================================
##
## Vier Wellen hell, vier dunkel, dann von vorn. Das ist keine Deko: Die Fee
## entwickelt sich nur bei Tag, der Unlicht-Wächter nur bei Nacht. Wer beide
## aufgestellt hat, muss den Ausbau über den Zyklus verteilen statt alles
## sofort zu kaufen.
##
## In der 3D-Fassung fehlte das — dort waren beide Familien jederzeit
## ausbaubar, und die Eigenheit, die sie von den anderen unterscheidet,
## existierte nicht.

func ist_nacht() -> bool:
	return Daten.ist_nacht(maxi(1, welle))


## Wie tief die Nacht gerade ist: 0 heller Tag, 1 tiefe Nacht.
## Die letzte Welle einer Hälfte blendet hinüber, damit der Wechsel nicht
## hart einsetzt.
func nacht_anteil() -> float:
	var w := maxi(1, welle)
	var in_haelfte := (w - 1) % Daten.ZYKLUS
	var nacht := Daten.ist_nacht(w)
	if in_haelfte == Daten.ZYKLUS - 1:
		return 0.5 if nacht else 0.5
	return 1.0 if nacht else 0.0


## Darf dieser Wächter gerade entwickelt werden?
func darf_entwickeln(id: String) -> bool:
	var def := waechter_def(id)
	var b := String(def.get("nur_bei", ""))
	if b.is_empty():
		return true
	return ist_nacht() if b == "nacht" else not ist_nacht()


## ============================================================
## Sonderfelder
## ============================================================
##
## Vier Arten, die einen Bauplatz von einem anderen unterscheiden:
##
##   wasser  Nur Wasser-Wächter dürfen darauf — und nirgends sonst hin.
##           Das macht die Familie zu einem Standortproblem statt zu einer
##           freien Wahl.
##   vulkan  Nur Feuer-Wächter, dafür +18 % Schaden UND Reichweite.
##   kraft   +30 % Reichweite für jeden.
##   hoehe   +32 % Reichweite für Gestein und Wind, ein Drittel davon für
##           alle anderen.
##
## Ohne sie war in der 3D-Fassung jeder Platz gleich viel wert und der
## Wasser-Wächter überall setzbar — die Karte hatte keine Topografie, nur
## eine Route.
##
## Die Felder hängen an der Kartennummer, nicht am Zufall: Eine Route soll
## wiedererkennbar sein und nicht bei jedem Start anders aussehen.

var felder: Dictionary = {}     ## Vector2i -> Art


func feld_art(k: Vector2i) -> String:
	return String(felder.get(k, ""))


## Darf diese Familie auf dieses Feld?
func darf_hier(id: String, k: Vector2i) -> bool:
	var def := waechter_def(id)
	if def.is_empty():
		return false
	var art := feld_art(k)
	if art == "vulkan":
		return String(def["typ"]) == "fire"
	if String(def["typ"]) == "water":
		return art == "wasser"
	return art != "wasser"


## Was das Feld unter einem Wächter an seiner Reichweite ändert.
func feld_reichweite(def: Dictionary, k: Vector2i) -> float:
	var art := feld_art(k)
	if art == "kraft":
		return 1.0 + Daten.FELD_KRAFT_BONUS
	if art == "vulkan":
		return 1.0 + Daten.FELD_VULKAN_BONUS
	if art == "hoehe":
		var voll: bool = String(def["typ"]) in Daten.FELD_HOEHE_TYPEN
		return 1.0 + Daten.FELD_HOEHE_BONUS * (1.0 if voll else 0.33)
	return 1.0


## Und an seinem Schaden. Nur der Vulkanschlot wirkt hier — und nur auf
## Feuer, weil sonst niemand darauf stehen darf.
func feld_schaden(k: Vector2i) -> float:
	return 1.0 + Daten.FELD_VULKAN_BONUS if feld_art(k) == "vulkan" else 1.0


## Die Felder einer Karte auslegen.
##
## `frei` sind die bebaubaren Kacheln, `naehe` sagt für jede, wie weit sie
## vom Weg liegt. Nur was nah genug am Weg liegt, kommt in Frage — ein
## Kraftfeld in der Ecke, auf der nie jemand baut, ist kein Sonderfeld,
## sondern Dekoration.
func lege_felder(frei: Array, naehe: Dictionary) -> void:
	felder = {}
	var karte: Dictionary = Daten.KARTEN[karte_idx]
	var liste: Array = karte.get("sonderfelder", [])
	if liste.is_empty():
		return

	## Fester Zufall aus der Kartennummer — dieselbe Karte, dieselben Felder.
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = karte_idx * 7717 + 13

	var tauglich: Array = []
	for k: Vector2i in frei:
		if float(naehe.get(k, 999.0)) < 6.0:
			tauglich.append(k)
	if tauglich.is_empty():
		return
	## Mischen, damit die Auswahl nicht dem Rasterlauf folgt und alle
	## Sonderfelder in derselben Ecke landen.
	for i in range(tauglich.size() - 1, 0, -1):
		var j := wuerfel.randi_range(0, i)
		var tmp = tauglich[i]
		tauglich[i] = tauglich[j]
		tauglich[j] = tmp

	for eintrag in liste:
		var art := String(eintrag["art"])
		var anzahl := int(eintrag["anzahl"])
		if String(eintrag.get("form", "")) == "see":
			_lege_see(art, anzahl, tauglich, eintrag.get("ort", Vector2i(-1, -1)))
		else:
			_lege_verstreut(art, anzahl, tauglich)


## Verstreute Einzelfelder, die einander nicht berühren — sonst entstehen
## Nester, und ein Nest aus sechs Kraftfeldern ist ein Bauplatz, kein
## Gelände.
func _lege_verstreut(art: String, anzahl: int, tauglich: Array) -> void:
	var gesetzt := 0
	for k: Vector2i in tauglich:
		if gesetzt >= anzahl:
			break
		if felder.has(k):
			continue
		var nachbar := false
		for dc: int in [-1, 0, 1]:
			for dr: int in [-1, 0, 1]:
				if felder.has(Vector2i(int(k.x) + dc, int(k.y) + dr)):
					nachbar = true
		if nachbar:
			continue
		felder[k] = art
		gesetzt += 1


## Ein zusammenhängender See statt verstreuter Tümpel. Für Wasser ist das
## Auseinanderhalten genau falsch — die Fläche wächst deshalb von einem
## Startfeld aus immer weiter an einen schon gesetzten Rand.
func _lege_see(art: String, anzahl: int, tauglich: Array, wunsch: Vector2i) -> void:
	var start := wunsch
	if not tauglich.has(start):
		start = tauglich[0]
	felder[start] = art
	var rand: Array = [start]
	var gesetzt := 1
	while gesetzt < anzahl and not rand.is_empty():
		var von: Vector2i = rand[0]
		var gewachsen := false
		## Ausdrücklich typisiert: Werte aus einem Array-Literal sind für
		## GDScript Variant, und := kann daraus keinen Typ ableiten.
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var k: Vector2i = von + d
			if felder.has(k) or not tauglich.has(k):
				continue
			felder[k] = art
			rand.append(k)
			gesetzt += 1
			gewachsen = true
			break
		if not gewachsen:
			rand.pop_front()


## ============================================================
## Trainerpfad und Freischaltung
## ============================================================

## Was ein Talentzweig beim aktuellen Rang bewirkt.
##
## Zwei Kurvenformen, dieselben wie im Browserspiel. Sie sind kein
## Balancedetail, sondern eine Notwendigkeit: Schaden und Durchschlag dürfen
## unbegrenzt wachsen, weil sie die Regeln nicht ändern. Reichweite, Leben,
## Startbeeren und alle Anteile müssen sättigen — bei dreifacher Reichweite
## deckt jeder Wächter die ganze Karte, und wo man ihn hinstellt, wäre
## gleichgültig.
func talent(id: String) -> float:
	var r := float(stand.rang(id))
	if r <= 0.0:
		return 0.0
	for t in Daten.TALENTE:
		if t["id"] != id:
			continue
		if t["kurve"] == "gerade":
			return r * float(t["schritt"])
		return float(t["grenze"]) * r / (r + float(t["halb"]))
	return 0.0


## Was der nächste Rang kostet: einen Punkt mehr als der vorige.
static func rangkosten(r: int) -> int:
	return r + 1


## Einen Rang kaufen. Gibt zurück, ob es geklappt hat.
func kaufe_rang(id: String) -> bool:
	var r := stand.rang(id)
	if r >= Daten.TALENT_RANG_MAX:
		return false
	var preis := rangkosten(r)
	if stand.offene_punkte() < preis:
		return false
	stand.raenge[id] = r + 1
	stand.ausgegeben += preis
	stand.sichere()
	return true


## Steht eine Wächterfamilie zur Verfügung?
##
## Vier von Anfang an, sieben über Sterne. Der legendäre Wächter hängt daran,
## ob seine Karte ganz gehalten wurde.
func waechter_frei(def: Dictionary) -> bool:
	if bool(def.get("legendaer", false)):
		return bool(stand.geschafft.get(str(karte_idx), false))
	return stand.sterne_gesamt() >= int(def.get("stern", 0))


## Ist die Familie auf dieser Karte auch aufgestellt?
##
## Aufstellung und Freischaltung sind zwei verschiedene Dinge: Freigeschaltet
## zu sein heißt, dass man sie besitzt; aufgestellt zu sein heißt, dass man
## sie für DIESE Route mitgenommen hat. Solange weniger als acht
## freigeschaltet sind, ziehen alle mit.
func in_aufstellung(def: Dictionary) -> bool:
	if bool(def.get("legendaer", false)):
		return true
	var liste: Array = stand.aufstellung.get(str(karte_idx), [])
	if liste.is_empty():
		return true
	return String(def["id"]) in liste


func setzbar(id: String) -> bool:
	var def := waechter_def(id)
	if def.is_empty():
		return false
	return waechter_frei(def) and in_aufstellung(def)


## Die acht, die das Spiel für eine Route vorschlägt: nach Typwirkung gegen
## deren Fauna, mit den Nebenwirkungen gewichtet. Ohne die Gewichtung wären
## zwei Familien desselben Elements ununterscheidbar — und Marco Bongkopf,
## Element Pflanze wie der Keimling, käme nie vor.
func schlage_aufstellung_vor(idx: int) -> Array:
	var k: Dictionary = Daten.KARTEN[idx]
	var wilde: Array = k.get("wilde", [])
	var bewertet: Array = []
	for d in Daten.WAECHTER:
		if bool(d.get("legendaer", false)) or not waechter_frei(d):
			continue
		var typ := 0.0
		if wilde.is_empty():
			typ = 1.0
		else:
			for w in wilde:
				typ += Daten.wirksamkeit(String(d["typ"]), String(w))
			typ /= float(wilde.size())
		var st: Dictionary = d["stufen"][1]
		var extra := 1.0
		if st.has("flaeche"):
			extra *= 1.0 + float(st["flaeche"]) / 140.0
		if st.has("bremse"):
			extra *= 1.0 + float(st["bremse"]["amt"]) * 0.5
		if st.has("fessel"):
			extra *= 1.0 + float(st["fessel"]["p"]) * 1.2
		if st.has("brand"):
			extra *= 1.0 + minf(0.35, float(st["brand"]["dps"]) / 80.0)
		if st.has("gift"):
			extra *= 1.0 + minf(0.55,
				float(st["gift"]["dps"]) * float(st["gift"]["dur"]) / 260.0)
		if st.has("kette"):
			extra *= 1.0 + float(st["kette"]) * 0.2
		if st.has("feld"):
			extra *= 1.0 + float(st["feld"].get("dmg", 0.0)) * 1.4
		if st.has("durchschlag"):
			extra *= 1.0 + minf(0.4, float(st["durchschlag"]) / 50.0)
		var luft := 1.12 if bool(d.get("luft", true)) else 1.0
		bewertet.append({ "id": d["id"], "wert": typ * extra * luft })
	bewertet.sort_custom(func(a, b): return float(a["wert"]) > float(b["wert"]))
	var raus: Array = []
	for e in bewertet:
		if raus.size() >= Daten.AUFSTELLUNG_MAX:
			break
		raus.append(e["id"])
	return raus


## ============================================================
## Schaden
## ============================================================

## Was ein Treffer wirklich anrichtet.
##
## Zwei Dinge stehen zwischen Angriff und Wirkung: der Typenvorteil
## vervielfacht, die Panzerung wird ABGEZOGEN. Deshalb ist Panzerung für
## einen schnellen Kleinschützen tödlich und für einen schweren Schläger nur
## lästig — der Wind-Wächter macht fünfzehn Schaden je Treffer und kommt
## gegen Panzerung achtzehn auf null, der Stahl-Wächter mit
## hundertachtundfünfzig kaum ins Stocken.
##
## Ein Rest bleibt immer: Ein Treffer, der gar nichts bewirkt, sieht wie ein
## Fehler aus, auch wenn er rechnerisch stimmt.
static func schaden(roh: float, angriffstyp: String, zieltyp: String,
		panzer: float, durchschlag: float) -> float:
	var d := roh * Daten.wirksamkeit(angriffstyp, zieltyp)
	var rest := maxf(0.0, panzer - durchschlag)
	return maxf(d * 0.06, d - rest)


## Panzerung eines Gegners in einer bestimmten Welle.
##
## Dieselbe Dämpfung wie im Browserspiel: 3,8 Prozent Wachstum je Welle, und
## der Schwierigkeitsfaktor der Karte geht nur zur Hälfte ein. Voll
## angewandt machte er die schwerste Karte undurchdringlich — Monolithor kam
## dort auf 216 Panzerung, während der stärkste gewöhnliche Wächter 158
## Schaden macht.
static func panzerung(grund: float, w: int, kartenfaktor: float) -> float:
	var wellenskala := 1.0 + float(w - 1) * 0.038
	var kartenskala := 1.0 + (kartenfaktor - 1.0) * 0.5
	return grund * wellenskala * kartenskala
