extends RefCounted
##
## Spieldaten — ERZEUGT, NICHT VON HAND ÄNDERN.
##
## Quelle: index.html. Neu erzeugen mit
##     node tools/daten-nach-godot.js
##
## Wer hier etwas ändert, verliert es beim nächsten Lauf. Die Werte
## gehören ins Browserspiel; diese Datei zieht nach.
##
## Stand: 2026-09-04
##

## Elementfarben. Dieselben Hexwerte wie im Browserspiel, damit ein
## Feuer-Wächter in beiden Fassungen gleich aussieht.
const TYPEN := {
	"fire": { "name": "Feuer", "farbe": Color("#FF6E45") },
	"water": { "name": "Wasser", "farbe": Color("#48A6FF") },
	"grass": { "name": "Pflanze", "farbe": Color("#57CE7C") },
	"electric": { "name": "Elektro", "farbe": Color("#FFD645") },
	"rock": { "name": "Gestein", "farbe": Color("#C08F67") },
	"psychic": { "name": "Psycho", "farbe": Color("#C382FF") },
	"ice": { "name": "Eis", "farbe": Color("#7FDBF0") },
	"steel": { "name": "Stahl", "farbe": Color("#A9BECD") },
	"fairy": { "name": "Fee", "farbe": Color("#FF9ED2") },
	"dark": { "name": "Unlicht", "farbe": Color("#8C7BB8") },
	"wind": { "name": "Wind", "farbe": Color("#9FE3D6") },
	"legend": { "name": "Legendär", "farbe": Color("#F5C542") },
}

## Angreifer -> Verteidiger. Fehlender Eintrag bedeutet 1.0 —
## genau wie eff() im Browserspiel.
const CHART := {
	"fire": { "grass": 2, "ice": 2, "steel": 2, "wind": 0.5, "water": 0.5, "rock": 0.5, "fire": 0.5, "psychic": 1 },
	"water": { "fire": 2, "rock": 2, "water": 0.5, "grass": 0.5, "electric": 0.5, "ice": 0.5 },
	"grass": { "water": 2, "rock": 2, "grass": 0.5, "fire": 0.5, "psychic": 1, "ice": 0.5, "steel": 0.5 },
	"electric": { "water": 2, "steel": 2, "electric": 0.5, "grass": 0.5, "rock": 0.5 },
	"rock": { "fire": 2, "electric": 2, "ice": 2, "wind": 2, "rock": 0.5, "water": 0.5, "grass": 0.5, "steel": 0.5 },
	"psychic": { "psychic": 0.5, "steel": 0.5, "fire": 1.25, "water": 1.25, "grass": 1.25, "electric": 1.25, "rock": 1.25, "ice": 1.25 },
	"ice": { "grass": 2, "rock": 2, "wind": 1.5, "ice": 0.5, "fire": 0.5, "water": 0.5, "steel": 0.5 },
	"steel": { "ice": 2, "rock": 2, "fairy": 2, "wind": 1.5, "steel": 0.5, "fire": 0.5, "water": 0.5, "electric": 0.5 },
	"fairy": { "dark": 2, "rock": 2, "psychic": 1.5, "fairy": 0.5, "fire": 0.5, "steel": 0.5 },
	"dark": { "psychic": 2, "dark": 2, "fairy": 0.5, "steel": 0.5 },
	"wind": { "grass": 2, "psychic": 1.5, "fairy": 1.25, "rock": 0.5, "steel": 0.5, "ice": 0.75 },
}

static func wirksamkeit(angriff: String, ziel: String) -> float:
	if not CHART.has(angriff):
		return 1.0
	var reihe: Dictionary = CHART[angriff]
	return float(reihe.get(ziel, 1.0))

## Wächterfamilien mit ihren drei Stufen.
const WAECHTER := [
	{
		"id": "fire", "typ": "fire", "gestalt": "cat",
		"luft": true, "stern": 0,
		"beschreibung": "Schnelle Einzelziele, entzündet Gegner.",
		"stufen": [
			{ "name": "Zündling", "kosten": 90, "schaden": 12, "rate": 1.6, "reichweite": 86 },
			{ "name": "Glutkatze", "kosten": 130, "schaden": 26, "rate": 1.9, "reichweite": 102, "brand": { "dps": 9, "dur": 2 } },
			{ "name": "Flammenkralle", "kosten": 240, "schaden": 48, "rate": 2.2, "reichweite": 120, "brand": { "dps": 22, "dur": 3 } },
		],
	},
	{
		"id": "water", "typ": "water", "gestalt": "drop",
		"luft": true, "stern": 0,
		"beschreibung": "Flächenschaden, verlangsamt alles im Umkreis.",
		"stufen": [
			{ "name": "Tröpfling", "kosten": 110, "schaden": 14, "rate": 1, "reichweite": 140, "flaeche": 36, "bremse": { "amt": 0.2, "dur": 1.2 } },
			{ "name": "Flutwelpe", "kosten": 165, "schaden": 30, "rate": 1.15, "reichweite": 166, "flaeche": 48, "bremse": { "amt": 0.3, "dur": 1.5 } },
			{ "name": "Wogenfürst", "kosten": 300, "schaden": 58, "rate": 1.3, "reichweite": 195, "flaeche": 64, "bremse": { "amt": 0.42, "dur": 2 } },
		],
	},
	{
		"id": "grass", "typ": "grass", "gestalt": "sprout",
		"luft": true, "stern": 0,
		"beschreibung": "Günstig und verlässlich, fesselt mit Ranken.",
		"stufen": [
			{ "name": "Keimling", "kosten": 65, "schaden": 10, "rate": 1.3, "reichweite": 104 },
			{ "name": "Dornbock", "kosten": 105, "schaden": 22, "rate": 1.5, "reichweite": 123, "fessel": { "p": 0.12, "dur": 0.6 } },
			{ "name": "Rankenschlund", "kosten": 210, "schaden": 40, "rate": 1.7, "reichweite": 145, "brand": { "dps": 8, "dur": 3 }, "fessel": { "p": 0.2, "dur": 1 } },
		],
	},
	{
		"id": "electric", "typ": "electric", "gestalt": "fox",
		"luft": true, "stern": 0,
		"beschreibung": "Feuert sehr schnell, Blitze springen weiter.",
		"stufen": [
			{ "name": "Blitzmilbe", "kosten": 100, "schaden": 7, "rate": 3.2, "reichweite": 121 },
			{ "name": "Wetterfuchs", "kosten": 150, "schaden": 13, "rate": 3.6, "reichweite": 143, "kette": 2 },
			{ "name": "Donnerrachen", "kosten": 275, "schaden": 24, "rate": 4, "reichweite": 168, "kette": 3 },
		],
	},
	{
		"id": "rock", "typ": "rock", "gestalt": "ox",
		"luft": false, "stern": 20,
		"beschreibung": "Wuchtige Erschütterung — trifft keine Flieger.",
		"stufen": [
			{ "name": "Kiesling", "kosten": 130, "schaden": 34, "rate": 0.55, "reichweite": 169, "flaeche": 52 },
			{ "name": "Felsochse", "kosten": 195, "schaden": 76, "rate": 0.62, "reichweite": 200, "flaeche": 68 },
			{ "name": "Bergwucht", "kosten": 350, "schaden": 148, "rate": 0.7, "reichweite": 235, "flaeche": 88, "fessel": { "p": 0.1, "dur": 0.5 } },
		],
	},
	{
		"id": "psychic", "typ": "psychic", "gestalt": "owl",
		"luft": true, "stern": 220,
		"beschreibung": "Stärkt benachbarte Wächter und markiert Ziele.",
		"stufen": [
			{ "name": "Traumflaum", "kosten": 150, "schaden": 9, "rate": 0.9, "reichweite": 180, "feld": { "dmg": 0.1, "rng": 0.08 } },
			{ "name": "Traumeule", "kosten": 210, "schaden": 20, "rate": 1, "reichweite": 213, "marke": 0.14, "feld": { "dmg": 0.18, "rng": 0.12 } },
			{ "name": "Weitseher", "kosten": 380, "schaden": 38, "rate": 1.1, "reichweite": 250, "marke": 0.26, "feld": { "dmg": 0.28, "rng": 0.18 } },
		],
	},
	{
		"id": "ice", "typ": "ice", "gestalt": "zottel",
		"luft": true, "stern": 35,
		"beschreibung": "Friert Gegner ein — die stärkste Verlangsamung.",
		"stufen": [
			{ "name": "Frostfell", "kosten": 105, "schaden": 9, "rate": 1.1, "reichweite": 147, "flaeche": 30, "bremse": { "amt": 0.3, "dur": 1.6 } },
			{ "name": "Raureifer", "kosten": 160, "schaden": 19, "rate": 1.2, "reichweite": 175, "flaeche": 42, "bremse": { "amt": 0.45, "dur": 2 } },
			{ "name": "Eisklamm", "kosten": 290, "schaden": 36, "rate": 1.3, "reichweite": 205, "flaeche": 58, "bremse": { "amt": 0.6, "dur": 2.6 }, "fessel": { "p": 0.16, "dur": 0.8 } },
		],
	},
	{
		"id": "steel", "typ": "steel", "gestalt": "bolzen",
		"luft": false, "stern": 80,
		"beschreibung": "Schwere Treffer, durchschlägt Panzerung — bodengebunden.",
		"stufen": [
			{ "name": "Nietling", "kosten": 140, "schaden": 40, "rate": 0.7, "reichweite": 92, "durchschlag": 6 },
			{ "name": "Schmiedstier", "kosten": 205, "schaden": 84, "rate": 0.78, "reichweite": 109, "durchschlag": 14 },
			{ "name": "Ambosswacht", "kosten": 360, "schaden": 158, "rate": 0.86, "reichweite": 128, "flaeche": 40, "durchschlag": 26 },
		],
	},
	{
		"id": "fairy", "typ": "fairy", "gestalt": "wisp",
		"luft": true, "stern": 160, "nur_bei": "tag",
		"beschreibung": "Markiert Ziele und bricht Unlicht — entwickelt sich nur am Tag.",
		"stufen": [
			{ "name": "Schimmerchen", "kosten": 120, "schaden": 11, "rate": 1.5, "reichweite": 129, "marke": 0.1 },
			{ "name": "Glanzfee", "kosten": 175, "schaden": 24, "rate": 1.7, "reichweite": 153, "flaeche": 32, "marke": 0.18 },
			{ "name": "Morgenwacht", "kosten": 315, "schaden": 46, "rate": 1.9, "reichweite": 180, "flaeche": 46, "marke": 0.3 },
		],
	},
	{
		"id": "dark", "typ": "dark", "gestalt": "eye",
		"luft": true, "stern": 110, "nur_bei": "nacht",
		"beschreibung": "Schlägt hart aus dem Dunkel — entwickelt sich nur nachts.",
		"stufen": [
			{ "name": "Schattling", "kosten": 125, "schaden": 26, "rate": 0.95, "reichweite": 111 },
			{ "name": "Nachtzehrer", "kosten": 185, "schaden": 54, "rate": 1.05, "reichweite": 132, "brand": { "dps": 14, "dur": 2.5 } },
			{ "name": "Finsterwacht", "kosten": 330, "schaden": 104, "rate": 1.15, "reichweite": 155, "kette": 2, "brand": { "dps": 30, "dur": 3 } },
		],
	},
	{
		"id": "wind", "typ": "wind", "gestalt": "falke",
		"luft": true, "stern": 55,
		"beschreibung": "Feuert unaufhörlich über große Weite und findet dabei jede Lücke im Panzer.",
		"stufen": [
			{ "name": "Windling", "kosten": 105, "schaden": 6, "rate": 4.2, "reichweite": 250, "durchschlag": 4 },
			{ "name": "Sturmfalke", "kosten": 160, "schaden": 11, "rate": 5, "reichweite": 285, "durchschlag": 8 },
			{ "name": "Wirbelwacht", "kosten": 300, "schaden": 21, "rate": 6, "reichweite": 325, "durchschlag": 14 },
		],
	},
	{
		"id": "marco", "typ": "grass", "gestalt": "marco",
		"luft": true, "stern": 300,
		"beschreibung": "Pustet Rauch: bremst und vergiftet. Kaum eigener Schaden.",
		"stufen": [
			{ "name": "Marco Bongkopf", "kosten": 135, "schaden": 4, "rate": 1, "reichweite": 132, "flaeche": 40, "gift": { "dps": 5, "dur": 4 }, "bremse": { "amt": 0.22, "dur": 1.8 } },
			{ "name": "Marco Blaudunst", "kosten": 200, "schaden": 8, "rate": 1.1, "reichweite": 158, "flaeche": 54, "gift": { "dps": 11, "dur": 5 }, "bremse": { "amt": 0.34, "dur": 2.2 } },
			{ "name": "Marco Nebelfürst", "kosten": 345, "schaden": 15, "rate": 1.2, "reichweite": 184, "flaeche": 70, "gift": { "dps": 23, "dur": 6 }, "bremse": { "amt": 0.46, "dur": 2.8 } },
		],
	},
	{
		"id": "legend", "typ": "legend", "gestalt": "thron",
		"luft": true, "stern": 0, "legendaer": true,
		"beschreibung": "Kennt weder Schwäche noch Vorteil — trifft alles gleich hart.",
		"stufen": [
			{ "name": "Dämmerhüter", "kosten": 420, "schaden": 70, "rate": 1.2, "reichweite": 194, "flaeche": 40, "durchschlag": 12 },
			{ "name": "Firnwächter", "kosten": 620, "schaden": 140, "rate": 1.35, "reichweite": 230, "flaeche": 56, "durchschlag": 24, "brand": { "dps": 26, "dur": 3 } },
			{ "name": "Ewigwacht", "kosten": 980, "schaden": 265, "rate": 1.5, "reichweite": 270, "flaeche": 74, "durchschlag": 42, "kette": 3, "brand": { "dps": 52, "dur": 3.5 } },
		],
	},
]

## Alle acht Wellen ein Anfuehrer, und die Schlusswelle immer.
static func ist_anfuehrerwelle(w: int) -> bool:
	return w > 0 and (w % 8 == 0 or w == 100)

## Grenzen des Trainerpfads und der Aufstellung.
const TALENT_RANG_MAX := 100
const AUFSTELLUNG_MAX := 8
const WAECHTER_JE_KARTE := 45

## Die zehn Zweige. "gerade" waechst je Rang um schritt, "satt"
## naehert sich grenze und erreicht sie nie: grenze * r / (r + halb).
const TALENTE := [
	{ "id": "vorrat", "name": "Proviantbeutel", "kurve": "satt", "grenze": 900.0, "halb": 20 },
	{ "id": "kraft", "name": "Schlagkraft", "kurve": "gerade", "schritt": 0.04 },
	{ "id": "weit", "name": "Weitblick", "kurve": "satt", "grenze": 0.6, "halb": 25 },
	{ "id": "zaeh", "name": "Zähigkeit", "kurve": "satt", "grenze": 40.0, "halb": 25.0 },
	{ "id": "durch", "name": "Panzerbrecher", "kurve": "gerade", "schritt": 3 },
	{ "id": "erst", "name": "Erstschlag", "kurve": "satt", "grenze": 4, "halb": 12 },
	{ "id": "lehre", "name": "Lehrmeister", "kurve": "satt", "grenze": 0.35, "halb": 8 },
	{ "id": "handel", "name": "Handelsgeschick", "kurve": "satt", "grenze": 0.35, "halb": 4 },
	{ "id": "zins", "name": "Zinseszins", "kurve": "satt", "grenze": 0.25, "halb": 10 },
	{ "id": "kopfgeld", "name": "Kopfgeld", "kurve": "satt", "grenze": 1.2, "halb": 14 },
]

## Gewöhnliche Gegnerarten.
const ARTEN := [
	{ "id": "mossnip", "name": "Moosnipp", "typ": "grass", "gestalt": "blob", "leben": 1, "tempo": 1, "beute": 1, "groesse": 15 },
	{ "id": "vinelet", "name": "Rankling", "typ": "grass", "gestalt": "sprout", "leben": 1.35, "tempo": 0.85, "beute": 1.2, "groesse": 17 },
	{ "id": "thornhog", "name": "Dornborst", "typ": "grass", "gestalt": "ox", "leben": 2.6, "tempo": 0.68, "beute": 1.8, "groesse": 20, "panzer": 4 },
	{ "id": "cinderpup", "name": "Glutwelp", "typ": "fire", "gestalt": "cat", "leben": 0.85, "tempo": 1.35, "beute": 1.1, "groesse": 15 },
	{ "id": "ashmoth", "name": "Aschfalter", "typ": "fire", "gestalt": "moth", "leben": 0.7, "tempo": 1.5, "beute": 1.3, "groesse": 14, "fliegt": true },
	{ "id": "magmaw", "name": "Magmaul", "typ": "fire", "gestalt": "ox", "leben": 3.1, "tempo": 0.6, "beute": 2, "groesse": 21, "panzer": 6 },
	{ "id": "puddlin", "name": "Pfützling", "typ": "water", "gestalt": "drop", "leben": 1.1, "tempo": 1.05, "beute": 1, "groesse": 15 },
	{ "id": "brinefin", "name": "Salzflosse", "typ": "water", "gestalt": "fish", "leben": 1.5, "tempo": 1.2, "beute": 1.3, "groesse": 17 },
	{ "id": "deluger", "name": "Sturzflut", "typ": "water", "gestalt": "blob", "leben": 3.4, "tempo": 0.72, "beute": 2.1, "groesse": 22, "heilt": 0.015 },
	{ "id": "zaplet", "name": "Zippel", "typ": "electric", "gestalt": "crystal", "leben": 0.8, "tempo": 1.55, "beute": 1.1, "groesse": 14 },
	{ "id": "voltbat", "name": "Voltschwinge", "typ": "electric", "gestalt": "bird", "leben": 1, "tempo": 1.7, "beute": 1.4, "groesse": 15, "fliegt": true },
	{ "id": "stormhorn", "name": "Sturmhorn", "typ": "electric", "gestalt": "fox", "leben": 2.2, "tempo": 1.1, "beute": 1.7, "groesse": 19 },
	{ "id": "pebblob", "name": "Kieselklotz", "typ": "rock", "gestalt": "crystal", "leben": 1.9, "tempo": 0.78, "beute": 1.2, "groesse": 17, "panzer": 7, "schild": 0.45 },
	{ "id": "cragger", "name": "Klippkralle", "typ": "rock", "gestalt": "ox", "leben": 3, "tempo": 0.66, "beute": 1.9, "groesse": 21, "panzer": 12 },
	{ "id": "monolith", "name": "Monolithor", "typ": "rock", "gestalt": "crystal", "leben": 5.2, "tempo": 0.5, "beute": 2.8, "groesse": 24, "panzer": 18, "zaeh": true },
	{ "id": "wispling", "name": "Irrlicht", "typ": "psychic", "gestalt": "wisp", "leben": 0.9, "tempo": 1.45, "beute": 1.3, "groesse": 14, "fliegt": true },
	{ "id": "mesmer", "name": "Mesmirr", "typ": "psychic", "gestalt": "owl", "leben": 1.8, "tempo": 1, "beute": 1.6, "groesse": 18 },
	{ "id": "enigmoth", "name": "Enigmotte", "typ": "psychic", "gestalt": "moth", "leben": 2.4, "tempo": 1.15, "beute": 2, "groesse": 19, "fliegt": true },
	{ "id": "budling", "name": "Knospling", "typ": "grass", "gestalt": "blob", "leben": 2.3, "tempo": 0.9, "beute": 1.6, "groesse": 20 },
	{ "id": "shellion", "name": "Schildling", "typ": "water", "gestalt": "crystal", "leben": 1.5, "tempo": 0.95, "beute": 1.5, "groesse": 17, "schild": 0.7 },
	{ "id": "grithog", "name": "Grimmborst", "typ": "rock", "gestalt": "ox", "leben": 3.6, "tempo": 0.7, "beute": 2.2, "groesse": 22, "panzer": 10 },
	{ "id": "flocke", "name": "Flöckling", "typ": "ice", "gestalt": "zottel", "leben": 1, "tempo": 1.15, "beute": 1.1, "groesse": 15 },
	{ "id": "raureif", "name": "Raureifer", "typ": "ice", "gestalt": "crystal", "leben": 1.7, "tempo": 0.92, "beute": 1.4, "groesse": 18, "rang": 1 },
	{ "id": "firnbaer", "name": "Firnbär", "typ": "ice", "gestalt": "zottel", "leben": 3.2, "tempo": 0.68, "beute": 2, "groesse": 22, "panzer": 5, "schild": 0.4, "rang": 2 },
	{ "id": "eisschwinge", "name": "Eisschwinge", "typ": "ice", "gestalt": "moth", "leben": 1.3, "tempo": 1.45, "beute": 1.4, "groesse": 16, "fliegt": true, "rang": 1 },
	{ "id": "nietling", "name": "Nietkäfer", "typ": "steel", "gestalt": "bolzen", "leben": 1.6, "tempo": 0.88, "beute": 1.3, "groesse": 17, "panzer": 7 },
	{ "id": "walzling", "name": "Walzling", "typ": "steel", "gestalt": "bolzen", "leben": 3.4, "tempo": 0.58, "beute": 2.1, "groesse": 22, "panzer": 13, "zaeh": true, "rang": 2 },
	{ "id": "spanling", "name": "Spanling", "typ": "steel", "gestalt": "crystal", "leben": 2.1, "tempo": 1, "beute": 1.6, "groesse": 19, "panzer": 5, "rang": 1 },
	{ "id": "graupel", "name": "Graupler", "typ": "ice", "gestalt": "blob", "leben": 1.3, "tempo": 1.25, "beute": 1.2, "groesse": 16 },
	{ "id": "eisnadel", "name": "Eisnadel", "typ": "ice", "gestalt": "crystal", "leben": 0.95, "tempo": 1.5, "beute": 1.1, "groesse": 14 },
	{ "id": "federstahl", "name": "Federstahl", "typ": "steel", "gestalt": "moth", "leben": 1.2, "tempo": 1.4, "beute": 1.3, "groesse": 16, "panzer": 3, "fliegt": true },
	{ "id": "schraubling", "name": "Schraubling", "typ": "steel", "gestalt": "wisp", "leben": 1, "tempo": 1.35, "beute": 1.2, "groesse": 15, "panzer": 2 },
	{ "id": "glimmling", "name": "Glimmling", "typ": "fairy", "gestalt": "wisp", "leben": 0.85, "tempo": 1.4, "beute": 1.1, "groesse": 14, "fliegt": true },
	{ "id": "tanzmotte", "name": "Tanzmotte", "typ": "fairy", "gestalt": "moth", "leben": 1.4, "tempo": 1.25, "beute": 1.4, "groesse": 17, "fliegt": true },
	{ "id": "feenbalg", "name": "Feenbalg", "typ": "fairy", "gestalt": "blob", "leben": 2.1, "tempo": 0.95, "beute": 1.6, "groesse": 19, "schild": 0.5 },
	{ "id": "prunkfalter", "name": "Prunkfalter", "typ": "fairy", "gestalt": "moth", "leben": 2.8, "tempo": 1.1, "beute": 2, "groesse": 20, "fliegt": true },
	{ "id": "nachtschlick", "name": "Nachtschlick", "typ": "dark", "gestalt": "blob", "leben": 1.2, "tempo": 1, "beute": 1.1, "groesse": 16 },
	{ "id": "duesterfalter", "name": "Düsterfalter", "typ": "dark", "gestalt": "moth", "leben": 1.5, "tempo": 1.35, "beute": 1.4, "groesse": 16, "fliegt": true },
	{ "id": "grufthund", "name": "Grufthund", "typ": "dark", "gestalt": "fox", "leben": 2.4, "tempo": 1.15, "beute": 1.8, "groesse": 19 },
	{ "id": "schlundaug", "name": "Schlundaug", "typ": "dark", "gestalt": "eye", "leben": 3.3, "tempo": 0.62, "beute": 2.2, "groesse": 22, "panzer": 8, "zaeh": true },
	{ "id": "boeling", "name": "Böling", "typ": "wind", "gestalt": "wisp", "leben": 0.8, "tempo": 1.6, "beute": 1.1, "groesse": 14, "fliegt": true },
	{ "id": "fetzenflug", "name": "Fetzenflug", "typ": "wind", "gestalt": "moth", "leben": 1.3, "tempo": 1.5, "beute": 1.3, "groesse": 15, "fliegt": true },
	{ "id": "sturmvogel", "name": "Sturmvogel", "typ": "wind", "gestalt": "bird", "leben": 2.2, "tempo": 1.45, "beute": 1.8, "groesse": 18, "fliegt": true },
	{ "id": "wirbelbock", "name": "Wirbelbock", "typ": "wind", "gestalt": "ox", "leben": 2.9, "tempo": 0.9, "beute": 2, "groesse": 21, "panzer": 4 },
]

## Anführer. Deutlich größer und zäher als gewöhnliche Arten.
const ANFUEHRER := [
	{ "name": "Vulkanox", "typ": "fire", "gestalt": "ox", "leben": 24, "tempo": 0.5, "beute": 16, "groesse": 34, "panzer": 8 },
	{ "name": "Abyssgrund", "typ": "water", "gestalt": "fish", "leben": 26, "tempo": 0.55, "beute": 18, "groesse": 34, "heilt": 0.008 },
	{ "name": "Titanwurz", "typ": "grass", "gestalt": "sprout", "leben": 30, "tempo": 0.45, "beute": 20, "groesse": 36, "panzer": 11 },
	{ "name": "Fulmax", "typ": "electric", "gestalt": "bird", "leben": 25, "tempo": 0.8, "beute": 20, "groesse": 32, "fliegt": true },
	{ "name": "Gorgolith", "typ": "rock", "gestalt": "crystal", "leben": 34, "tempo": 0.38, "beute": 24, "groesse": 38, "panzer": 17, "zaeh": true },
	{ "name": "Somnul", "typ": "psychic", "gestalt": "eye", "leben": 32, "tempo": 0.6, "beute": 30, "groesse": 36 },
	{ "name": "Glazior", "typ": "ice", "gestalt": "zottel", "leben": 31, "tempo": 0.48, "beute": 26, "groesse": 36, "panzer": 12, "schild": 0.5 },
	{ "name": "Amboloss", "typ": "steel", "gestalt": "bolzen", "leben": 33, "tempo": 0.42, "beute": 28, "groesse": 37, "panzer": 24, "zaeh": true },
	{ "name": "Sylphara", "typ": "fairy", "gestalt": "wisp", "leben": 28, "tempo": 0.7, "beute": 22, "groesse": 33, "fliegt": true, "schild": 0.45 },
	{ "name": "Umbraxis", "typ": "dark", "gestalt": "eye", "leben": 33, "tempo": 0.5, "beute": 26, "groesse": 36, "panzer": 14 },
	{ "name": "Zephyron", "typ": "wind", "gestalt": "bird", "leben": 27, "tempo": 0.95, "beute": 24, "groesse": 32, "fliegt": true },
]

## Wellenkurve, vorberechnet.
##
## Im Browserspiel entsteht sie aus drei Wachstumsraten, die in zwei
## Stufen abfallen. Hier steht das Ergebnis als Tabelle: Die Formel
## nachzubauen hieße, sie an zwei Orten pflegen zu müssen — und die eine
## Fassung driftet dann von der anderen weg, ohne dass es auffällt.
const WELLEN_JE_KARTE := 100
const WELLE_LEBEN := [30, 36, 44, 53, 64, 78, 94, 113, 137, 165, 199, 240, 289, 347, 416, 498, 594, 706, 836, 985, 1153, 1340, 1546, 1768, 2004, 2249, 2499, 2751, 3000, 3245, 3483, 3714, 3937, 4154, 4365, 4571, 4774, 4975, 5174, 5373, 5573, 5775, 5978, 6184, 6392, 6603, 6818, 7035, 7256, 7480, 7707, 7937, 8169, 8404, 8641, 8880, 9121, 9363, 9607, 9851, 10097, 10344, 10592, 10840, 11090, 11340, 11591, 11844, 12098, 12353, 12610, 12869, 13130, 13392, 13658, 13926, 14197, 14471, 14748, 15028, 15312, 15600, 15892, 16188, 16489, 16794, 17104, 17418, 17738, 18062, 18392, 18728, 19069, 19416, 19768, 20127, 20492, 20863, 21241, 21625]

## Karten mit ihrem Schwierigkeitsfaktor.
const KARTEN := [
	{
		"name": "Grünpfad", "grad": "Sanft",
		"faktor": 1, "beeren": 320, "leben": 24,
		"heim": "grass", "wetter": "pollen",
		"wilde": ["grass", "water", "fire"],
		"boden": [Color("#1E3324"), Color("#27422C")],
		"weg": Color("#9C7B54"), "wegkante": Color("#41301F"),
		"laub": Color("#4E9257"), "himmel": [Color("#3E5C6B"), Color("#7C9689")],
		"gras": Color("#5B9A5F"), "erde": Color("#6B5636"),
		"bewuchs": ["grass","bush","conifer","broadleaf","flower","mushroom","rock"],
		"route": [Vector2i(-1, 6), Vector2i(3, 6), Vector2i(3, 3), Vector2i(9, 3), Vector2i(9, 9), Vector2i(5, 9), Vector2i(5, 5), Vector2i(13, 5), Vector2i(13, 10), Vector2i(17, 10), Vector2i(17, 4), Vector2i(20, 5)],
		"route_b": [Vector2i(-1, 6), Vector2i(3, 6), Vector2i(3, 3), Vector2i(9, 3), Vector2i(9, 9), Vector2i(5, 9), Vector2i(5, 5), Vector2i(13, 5), Vector2i(13, 8), Vector2i(16, 8), Vector2i(17, 6), Vector2i(17, 4), Vector2i(20, 5)],
		"legendaer": { "typ": "grass", "gestalt": "thron", "namen": ["Hainhüter","Waldwächter","Wurzelthron"] },
	},
	{
		"name": "Glutschlucht", "grad": "Ruhig",
		"faktor": 1.35, "beeren": 300, "leben": 20,
		"heim": "fire", "wetter": "embers",
		"wilde": ["grass", "water", "fire", "electric"],
		"boden": [Color("#241310"), Color("#331914")],
		"weg": Color("#9E7359"), "wegkante": Color("#241509"),
		"laub": Color("#8E5730"), "himmel": [Color("#3B1F1E"), Color("#8F5238")],
		"gras": Color("#8A5A38"), "erde": Color("#8A6248"),
		"bewuchs": ["grass","rock","deadtree","crystalrock","vent"],
		"route": [Vector2i(-1, 5), Vector2i(3, 4), Vector2i(7, 8), Vector2i(3, 9), Vector2i(4, 6), Vector2i(11, 6), Vector2i(8, 3), Vector2i(13, 4), Vector2i(16, 8), Vector2i(11, 10), Vector2i(20, 8)],
		"legendaer": { "typ": "fire", "gestalt": "thron", "namen": ["Aschehüter","Glutwächter","Schlundthron"] },
	},
	{
		"name": "Flutruine", "grad": "Ruhig",
		"faktor": 1.65, "beeren": 340, "leben": 19,
		"heim": "water", "wetter": "rain",
		"wilde": ["grass", "water", "fire", "electric", "rock"],
		"boden": [Color("#1B2B3A"), Color("#223447")],
		"weg": Color("#6D7E8E"), "wegkante": Color("#28323F"),
		"laub": Color("#4E8878"), "himmel": [Color("#33505F"), Color("#7690A0")],
		"gras": Color("#4A7A6A"), "erde": Color("#5A6773"),
		"bewuchs": ["grass","rubble","rock","pillar","pool","broadleaf"],
		"route": [Vector2i(-1, 4), Vector2i(7, 4), Vector2i(7, 10), Vector2i(4, 10), Vector2i(4, 7), Vector2i(13, 7), Vector2i(13, 3), Vector2i(17, 3), Vector2i(17, 9), Vector2i(20, 9)],
		"legendaer": { "typ": "water", "gestalt": "thron", "namen": ["Tiefenhüter","Flutwächter","Strömungsthron"] },
	},
	{
		"name": "Gewitterkamm", "grad": "Fordernd",
		"faktor": 2.05, "beeren": 360, "leben": 19,
		"heim": "electric", "wetter": "storm",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice"],
		"boden": [Color("#2A2E3C"), Color("#353B4C")],
		"weg": Color("#8C8474"), "wegkante": Color("#3A362C"),
		"laub": Color("#6B7A96"), "himmel": [Color("#2F3A52"), Color("#6E7B96")],
		"gras": Color("#6E7C88"), "erde": Color("#5A5648"),
		"bewuchs": ["grass","rock","conifer","deadtree","bush","crystalrock","flower"],
		"route": [Vector2i(-1, 7), Vector2i(3, 7), Vector2i(3, 3), Vector2i(8, 3), Vector2i(8, 9), Vector2i(5, 9), Vector2i(5, 6), Vector2i(12, 6), Vector2i(12, 10), Vector2i(16, 10), Vector2i(16, 3), Vector2i(19, 3), Vector2i(19, 8), Vector2i(20, 8)],
		"legendaer": { "typ": "electric", "gestalt": "thron", "namen": ["Blitzhüter","Sturmwächter","Wetterthron"] },
	},
	{
		"name": "Steinkessel", "grad": "Fordernd",
		"faktor": 2.55, "beeren": 390, "leben": 18,
		"heim": "rock", "wetter": "dust",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice", "wind"],
		"boden": [Color("#3A342C"), Color("#463E34")],
		"weg": Color("#A89478"), "wegkante": Color("#4A4034"),
		"laub": Color("#7A6E5A"), "himmel": [Color("#4A4038"), Color("#8C7E6C")],
		"gras": Color("#7E7460"), "erde": Color("#6E6250"),
		"bewuchs": ["rock","crystalrock","grass","bush","deadtree","rubble","pillar"],
		"route": [Vector2i(-1, 5), Vector2i(4, 5), Vector2i(4, 10), Vector2i(8, 10), Vector2i(8, 4), Vector2i(12, 4), Vector2i(12, 9), Vector2i(6, 9), Vector2i(6, 7), Vector2i(16, 7), Vector2i(16, 3), Vector2i(19, 3), Vector2i(19, 6), Vector2i(20, 6)],
		"legendaer": { "typ": "rock", "gestalt": "thron", "namen": ["Steinhüter","Felswächter","Grundthron"] },
	},
	{
		"name": "Traumhain", "grad": "Fordernd",
		"faktor": 3.2, "beeren": 420, "leben": 18,
		"heim": "psychic", "wetter": "traum",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice", "wind", "psychic"],
		"boden": [Color("#2E2440"), Color("#3A2E50")],
		"weg": Color("#9C8AB4"), "wegkante": Color("#40325A"),
		"laub": Color("#8A6EB4"), "himmel": [Color("#4A3A62"), Color("#9A86B4")],
		"gras": Color("#7E68A4"), "erde": Color("#6A5A84"),
		"bewuchs": ["grass","mushroom","broadleaf","flower","bush","wisp"],
		"route": [Vector2i(-1, 6), Vector2i(4, 6), Vector2i(4, 3), Vector2i(10, 3), Vector2i(10, 9), Vector2i(6, 9), Vector2i(6, 6), Vector2i(14, 6), Vector2i(14, 10), Vector2i(18, 10), Vector2i(18, 4), Vector2i(20, 5)],
		"legendaer": { "typ": "psychic", "gestalt": "thron", "namen": ["Traumhüter","Seherwächter","Gedankenthron"] },
	},
	{
		"name": "Firnfeld", "grad": "Hart",
		"faktor": 4.05, "beeren": 450, "leben": 17,
		"heim": "ice", "wetter": "snow",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice", "wind", "psychic", "steel"],
		"boden": [Color("#3E4C5A"), Color("#4E5E6E")],
		"weg": Color("#B4BEC8"), "wegkante": Color("#4E5866"),
		"laub": Color("#96AABE"), "himmel": [Color("#54687E"), Color("#AEC2D4")],
		"gras": Color("#8EA2B2"), "erde": Color("#7A8492"),
		"bewuchs": ["conifer","rock","deadtree","crystalrock","grass","bush"],
		"route": [Vector2i(-1, 4), Vector2i(4, 4), Vector2i(4, 10), Vector2i(9, 10), Vector2i(9, 3), Vector2i(13, 3), Vector2i(13, 9), Vector2i(7, 9), Vector2i(7, 6), Vector2i(17, 6), Vector2i(17, 10), Vector2i(20, 10)],
		"legendaer": { "typ": "ice", "gestalt": "thron", "namen": ["Firnhüter","Frostwächter","Ewigthron"] },
	},
	{
		"name": "Erzwerk", "grad": "Hart",
		"faktor": 5.2, "beeren": 490, "leben": 17,
		"heim": "steel", "wetter": "russ",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice", "wind", "psychic", "steel", "fairy"],
		"boden": [Color("#32363C"), Color("#3E434A")],
		"weg": Color("#8E8E92"), "wegkante": Color("#3A3C40"),
		"laub": Color("#78828E"), "himmel": [Color("#3A4048"), Color("#7E868E")],
		"gras": Color("#6E767E"), "erde": Color("#5E6068"),
		"bewuchs": ["rubble","rock","pillar","deadtree","crystalrock","grass"],
		"route": [Vector2i(-1, 3), Vector2i(4, 3), Vector2i(4, 9), Vector2i(8, 9), Vector2i(8, 4), Vector2i(12, 4), Vector2i(12, 10), Vector2i(16, 10), Vector2i(16, 5), Vector2i(10, 5), Vector2i(10, 7), Vector2i(20, 7)],
		"legendaer": { "typ": "steel", "gestalt": "thron", "namen": ["Erzhüter","Schmiedwächter","Ambossthron"] },
	},
	{
		"name": "Glanzwiese", "grad": "Hart",
		"faktor": 6.9, "beeren": 530, "leben": 16,
		"heim": "fairy", "wetter": "sun",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice", "wind", "psychic", "steel", "fairy", "dark"],
		"boden": [Color("#3E3448"), Color("#4C4058")],
		"weg": Color("#C4A8B4"), "wegkante": Color("#584A5E"),
		"laub": Color("#B48ABE"), "himmel": [Color("#6E5A72"), Color("#C4A8BE")],
		"gras": Color("#9A7EA2"), "erde": Color("#8A7290"),
		"bewuchs": ["flower","grass","broadleaf","bush","mushroom","wisp"],
		"route": [Vector2i(-1, 8), Vector2i(4, 8), Vector2i(4, 3), Vector2i(9, 3), Vector2i(9, 10), Vector2i(13, 10), Vector2i(13, 4), Vector2i(7, 4), Vector2i(7, 7), Vector2i(17, 7), Vector2i(17, 10), Vector2i(20, 10)],
		"legendaer": { "typ": "fairy", "gestalt": "thron", "namen": ["Glanzhüter","Lichtwächter","Morgenthron"] },
	},
	{
		"name": "Nachtgrund", "grad": "Brutal",
		"faktor": 9.4, "beeren": 580, "leben": 16,
		"heim": "dark", "wetter": "fog",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice", "wind", "psychic", "steel", "fairy", "dark"],
		"boden": [Color("#1A1622"), Color("#221E2E")],
		"weg": Color("#6E6478"), "wegkante": Color("#2A2434"),
		"laub": Color("#5A4C72"), "himmel": [Color("#1E1A2A"), Color("#453C58")],
		"gras": Color("#4E4462"), "erde": Color("#463E52"),
		"bewuchs": ["deadtree","conifer","mushroom","rock","bush","wisp"],
		"route": [Vector2i(-1, 6), Vector2i(3, 6), Vector2i(3, 10), Vector2i(7, 10), Vector2i(7, 4), Vector2i(11, 4), Vector2i(11, 10), Vector2i(15, 10), Vector2i(15, 4), Vector2i(18, 4), Vector2i(18, 8), Vector2i(12, 8), Vector2i(12, 6), Vector2i(20, 6)],
		"legendaer": { "typ": "dark", "gestalt": "thron", "namen": ["Schattenhüter","Nachtwächter","Finsterthron"] },
	},
	{
		"name": "Böenkuppe", "grad": "Erbarmungslos",
		"faktor": 13, "beeren": 640, "leben": 15,
		"heim": "wind", "wetter": "boen",
		"wilde": ["grass", "water", "fire", "electric", "rock", "ice", "wind", "psychic", "steel", "fairy", "dark"],
		"boden": [Color("#3A4A44"), Color("#485A52")],
		"weg": Color("#AEA890"), "wegkante": Color("#4A4A3C"),
		"laub": Color("#8AA69A"), "himmel": [Color("#5A7280"), Color("#A6C0C6")],
		"gras": Color("#7E9A86"), "erde": Color("#6E6E58"),
		"bewuchs": ["grass","bush","conifer","rock","deadtree","flower"],
		"route": [Vector2i(-1, 5), Vector2i(4, 5), Vector2i(4, 10), Vector2i(9, 10), Vector2i(9, 4), Vector2i(14, 4), Vector2i(14, 10), Vector2i(18, 10), Vector2i(18, 5), Vector2i(11, 5), Vector2i(11, 8), Vector2i(20, 8)],
		"legendaer": { "typ": "wind", "gestalt": "thron", "namen": ["Böenhüter","Windwächter","Wirbelthron"] },
	},
]

