extends RefCounted
##
## Der Spielstand — alles, was eine Runde überdauert.
##
## Bis hierher hatte die 3D-Fassung überhaupt keinen: Jeder Start begann bei
## null, und alles, was das Browserspiel an Fortschritt kennt — Sterne,
## Trainerpunkte, freigeschaltete Wächter, Aufstellungen — existierte hier
## nicht. Ein Spiel ohne Speicherstand ist kein Spiel, das man veröffentlicht.
##
## Abgelegt wird als JSON unter user://. Nicht als ConfigFile, weil
## verschachtelte Wörterbücher (Ränge, Aufstellungen je Karte) dort umständlich
## werden, und nicht als binäres var_to_bytes, weil sich eine Textdatei bei
## einem Fehlerbericht ansehen lässt.
##
## Die Schlüssel heißen wie im Browserspiel, damit sich ein Stand später
## zwischen beiden Fassungen übertragen ließe.
##

const DATEI := "user://stand.json"

## Höchste gehaltene Welle je Karte. Das sind zugleich die Sterne.
var sterne: Dictionary = {}
## Verdiente und ausgegebene Trainerpunkte.
var punkte := 0
var ausgegeben := 0
## Rang je Talentzweig.
var raenge: Dictionary = {}
## Welche Karten ganz durchgespielt sind.
var geschafft: Dictionary = {}
## Gewählte Aufstellung je Karte (Liste von Wächterkennungen).
var aufstellung: Dictionary = {}
## Bestwert und weiteste Endloswelle.
var bestwert := 0
var endlos := 0


func sterne_von(idx: int) -> int:
	return int(sterne.get(str(idx), 0))


## Sterne einer Karte auf die erreichte Welle heben. Sie sinken nie — ein
## schlechterer Lauf darf einen guten nicht entwerten.
func setze_sterne(idx: int, welle: int) -> bool:
	var vorher := sterne_von(idx)
	if welle <= vorher:
		return false
	sterne[str(idx)] = welle
	return true


func sterne_gesamt() -> int:
	var summe := 0
	for k in sterne:
		summe += int(sterne[k])
	return summe


func offene_punkte() -> int:
	return punkte - ausgegeben


func rang(id: String) -> int:
	return int(raenge.get(id, 0))


func lade() -> void:
	if not FileAccess.file_exists(DATEI):
		return
	var f := FileAccess.open(DATEI, FileAccess.READ)
	if f == null:
		return
	var roh := f.get_as_text()
	f.close()
	var daten: Variant = JSON.parse_string(roh)
	if typeof(daten) != TYPE_DICTIONARY:
		push_warning("Spielstand unlesbar — es wird neu begonnen")
		return
	var d: Dictionary = daten
	## Jedes Feld einzeln übernehmen statt den Stand zu ersetzen. Ein Stand aus
	## einer älteren Fassung kennt neue Felder nicht, und ein pauschales
	## Überschreiben ließe sie dann fehlen statt auf ihrem Standardwert stehen.
	## JSON kennt keine ganzen Zahlen — beim Zurücklesen wird aus 10 eine 10.0,
	## und beim nächsten Sichern steht das so in der Datei. Das ist nicht bloß
	## unschön: Über viele Runden sammeln sich Fließkommazahlen dort an, wo
	## Wellenzahlen und Ränge stehen sollen.
	sterne = {}
	for k in d.get("sterne", {}):
		sterne[String(k)] = int(d["sterne"][k])
	raenge = {}
	for k in d.get("raenge", {}):
		raenge[String(k)] = int(d["raenge"][k])
	punkte = int(d.get("punkte", 0))
	ausgegeben = int(d.get("ausgegeben", 0))
	geschafft = d.get("geschafft", {})
	aufstellung = d.get("aufstellung", {})
	bestwert = int(d.get("bestwert", 0))
	endlos = int(d.get("endlos", 0))


func sichere() -> void:
	var f := FileAccess.open(DATEI, FileAccess.WRITE)
	if f == null:
		push_error("Spielstand nicht schreibbar: " + DATEI)
		return
	f.store_string(JSON.stringify({
		"sterne": sterne,
		"punkte": punkte,
		"ausgegeben": ausgegeben,
		"raenge": raenge,
		"geschafft": geschafft,
		"aufstellung": aufstellung,
		"bestwert": bestwert,
		"endlos": endlos,
	}, "\t"))
	f.close()


## Alles zurücksetzen. Gehört ins Menü, nicht nur ins Werkzeug: Wer die
## Fassung wechselt, hat einen Stand nach alten Regeln.
func loesche() -> void:
	sterne = {}
	punkte = 0
	ausgegeben = 0
	raenge = {}
	geschafft = {}
	aufstellung = {}
	bestwert = 0
	endlos = 0
	if FileAccess.file_exists(DATEI):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DATEI))
