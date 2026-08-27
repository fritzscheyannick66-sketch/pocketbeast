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
## Stand: 2026-08-27
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
	"fire": { "grass": 2, "ice": 2, "steel": 2, "water": 0.5, "rock": 0.5, "fire": 0.5, "psychic": 1 },
	"water": { "fire": 2, "rock": 2, "water": 0.5, "grass": 0.5, "electric": 0.5, "ice": 0.5 },
	"grass": { "water": 2, "rock": 2, "grass": 0.5, "fire": 0.5, "psychic": 1, "ice": 0.5, "steel": 0.5 },
	"electric": { "water": 2, "steel": 2, "electric": 0.5, "grass": 0.5, "rock": 0.5 },
	"rock": { "fire": 2, "electric": 2, "ice": 2, "rock": 0.5, "water": 0.5, "grass": 0.5, "steel": 0.5 },
	"psychic": { "psychic": 0.5, "steel": 0.5, "fire": 1.25, "water": 1.25, "grass": 1.25, "electric": 1.25, "rock": 1.25, "ice": 1.25 },
	"ice": { "grass": 2, "rock": 2, "ice": 0.5, "fire": 0.5, "water": 0.5, "steel": 0.5 },
	"steel": { "ice": 2, "rock": 2, "fairy": 2, "steel": 0.5, "fire": 0.5, "water": 0.5, "electric": 0.5 },
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
		"luft": true,
		"beschreibung": "Schnelle Einzelziele, entzündet Gegner.",
		"stufen": [
			{ "name": "Zündling", "kosten": 90, "schaden": 12, "rate": 1.6, "reichweite": 86 },
			{ "name": "Glutkatze", "kosten": 130, "schaden": 26, "rate": 1.9, "reichweite": 102, "brand": { "dps": 9, "dur": 2 } },
			{ "name": "Flammenkralle", "kosten": 240, "schaden": 48, "rate": 2.2, "reichweite": 120, "brand": { "dps": 22, "dur": 3 } },
		],
	},
	{
		"id": "water", "typ": "water", "gestalt": "drop",
		"luft": true,
		"beschreibung": "Flächenschaden, verlangsamt alles im Umkreis.",
		"stufen": [
			{ "name": "Tröpfling", "kosten": 110, "schaden": 14, "rate": 1, "reichweite": 140, "flaeche": 36, "bremse": { "amt": 0.2, "dur": 1.2 } },
			{ "name": "Flutwelpe", "kosten": 165, "schaden": 30, "rate": 1.15, "reichweite": 166, "flaeche": 48, "bremse": { "amt": 0.3, "dur": 1.5 } },
			{ "name": "Wogenfürst", "kosten": 300, "schaden": 58, "rate": 1.3, "reichweite": 195, "flaeche": 64, "bremse": { "amt": 0.42, "dur": 2 } },
		],
	},
	{
		"id": "grass", "typ": "grass", "gestalt": "sprout",
		"luft": true,
		"beschreibung": "Günstig und verlässlich, fesselt mit Ranken.",
		"stufen": [
			{ "name": "Keimling", "kosten": 65, "schaden": 10, "rate": 1.3, "reichweite": 104 },
			{ "name": "Dornbock", "kosten": 105, "schaden": 22, "rate": 1.5, "reichweite": 123, "fessel": { "p": 0.12, "dur": 0.6 } },
			{ "name": "Rankenschlund", "kosten": 210, "schaden": 40, "rate": 1.7, "reichweite": 145, "brand": { "dps": 8, "dur": 3 }, "fessel": { "p": 0.2, "dur": 1 } },
		],
	},
	{
		"id": "electric", "typ": "electric", "gestalt": "fox",
		"luft": true,
		"beschreibung": "Feuert sehr schnell, Blitze springen weiter.",
		"stufen": [
			{ "name": "Blitzmilbe", "kosten": 100, "schaden": 7, "rate": 3.2, "reichweite": 121 },
			{ "name": "Wetterfuchs", "kosten": 150, "schaden": 13, "rate": 3.6, "reichweite": 143, "kette": 2 },
			{ "name": "Donnerrachen", "kosten": 275, "schaden": 24, "rate": 4, "reichweite": 168, "kette": 3 },
		],
	},
	{
		"id": "rock", "typ": "rock", "gestalt": "ox",
		"luft": false,
		"beschreibung": "Wuchtige Erschütterung — trifft keine Flieger.",
		"stufen": [
			{ "name": "Kiesling", "kosten": 130, "schaden": 34, "rate": 0.55, "reichweite": 169, "flaeche": 52 },
			{ "name": "Felsochse", "kosten": 195, "schaden": 76, "rate": 0.62, "reichweite": 200, "flaeche": 68 },
			{ "name": "Bergwucht", "kosten": 350, "schaden": 148, "rate": 0.7, "reichweite": 235, "flaeche": 88, "fessel": { "p": 0.1, "dur": 0.5 } },
		],
	},
	{
		"id": "psychic", "typ": "psychic", "gestalt": "owl",
		"luft": true,
		"beschreibung": "Stärkt benachbarte Wächter und markiert Ziele.",
		"stufen": [
			{ "name": "Traumflaum", "kosten": 150, "schaden": 9, "rate": 0.9, "reichweite": 180, "feld": { "dmg": 0.1, "rng": 0.08 } },
			{ "name": "Traumeule", "kosten": 210, "schaden": 20, "rate": 1, "reichweite": 213, "marke": 0.14, "feld": { "dmg": 0.18, "rng": 0.12 } },
			{ "name": "Weitseher", "kosten": 380, "schaden": 38, "rate": 1.1, "reichweite": 250, "marke": 0.26, "feld": { "dmg": 0.28, "rng": 0.18 } },
		],
	},
	{
		"id": "ice", "typ": "ice", "gestalt": "zottel",
		"luft": true,
		"beschreibung": "Friert Gegner ein — die stärkste Verlangsamung.",
		"stufen": [
			{ "name": "Frostfell", "kosten": 105, "schaden": 9, "rate": 1.1, "reichweite": 147, "flaeche": 30, "bremse": { "amt": 0.3, "dur": 1.6 } },
			{ "name": "Raureifer", "kosten": 160, "schaden": 19, "rate": 1.2, "reichweite": 175, "flaeche": 42, "bremse": { "amt": 0.45, "dur": 2 } },
			{ "name": "Eisklamm", "kosten": 290, "schaden": 36, "rate": 1.3, "reichweite": 205, "flaeche": 58, "bremse": { "amt": 0.6, "dur": 2.6 }, "fessel": { "p": 0.16, "dur": 0.8 } },
		],
	},
	{
		"id": "steel", "typ": "steel", "gestalt": "bolzen",
		"luft": false,
		"beschreibung": "Schwere Treffer, durchschlägt Panzerung — bodengebunden.",
		"stufen": [
			{ "name": "Nietling", "kosten": 140, "schaden": 40, "rate": 0.7, "reichweite": 92, "durchschlag": 6 },
			{ "name": "Schmiedstier", "kosten": 205, "schaden": 84, "rate": 0.78, "reichweite": 109, "durchschlag": 14 },
			{ "name": "Ambosswacht", "kosten": 360, "schaden": 158, "rate": 0.86, "reichweite": 128, "flaeche": 40, "durchschlag": 26 },
		],
	},
	{
		"id": "fairy", "typ": "fairy", "gestalt": "wisp",
		"luft": true, "nur_bei": "tag",
		"beschreibung": "Markiert Ziele und bricht Unlicht — entwickelt sich nur am Tag.",
		"stufen": [
			{ "name": "Schimmerchen", "kosten": 120, "schaden": 11, "rate": 1.5, "reichweite": 129, "marke": 0.1 },
			{ "name": "Glanzfee", "kosten": 175, "schaden": 24, "rate": 1.7, "reichweite": 153, "flaeche": 32, "marke": 0.18 },
			{ "name": "Morgenwacht", "kosten": 315, "schaden": 46, "rate": 1.9, "reichweite": 180, "flaeche": 46, "marke": 0.3 },
		],
	},
	{
		"id": "dark", "typ": "dark", "gestalt": "eye",
		"luft": true, "nur_bei": "nacht",
		"beschreibung": "Schlägt hart aus dem Dunkel — entwickelt sich nur nachts.",
		"stufen": [
			{ "name": "Schattling", "kosten": 125, "schaden": 26, "rate": 0.95, "reichweite": 111 },
			{ "name": "Nachtzehrer", "kosten": 185, "schaden": 54, "rate": 1.05, "reichweite": 132, "brand": { "dps": 14, "dur": 2.5 } },
			{ "name": "Finsterwacht", "kosten": 330, "schaden": 104, "rate": 1.15, "reichweite": 155, "kette": 2, "brand": { "dps": 30, "dur": 3 } },
		],
	},
	{
		"id": "wind", "typ": "wind", "gestalt": "falke",
		"luft": true,
		"beschreibung": "Feuert unaufhörlich über große Weite — prallt aber an Panzerung ab.",
		"stufen": [
			{ "name": "Windling", "kosten": 105, "schaden": 4, "rate": 4.2, "reichweite": 250 },
			{ "name": "Sturmfalke", "kosten": 160, "schaden": 8, "rate": 5, "reichweite": 285 },
			{ "name": "Wirbelwacht", "kosten": 300, "schaden": 15, "rate": 6, "reichweite": 325 },
		],
	},
	{
		"id": "legend", "typ": "legend", "gestalt": "hueter",
		"luft": true, "legendaer": true,
		"beschreibung": "Kennt weder Schwäche noch Vorteil — trifft alles gleich hart.",
		"stufen": [
			{ "name": "Dämmerhüter", "kosten": 420, "schaden": 70, "rate": 1.2, "reichweite": 194, "flaeche": 40, "durchschlag": 12 },
			{ "name": "Firnwächter", "kosten": 620, "schaden": 140, "rate": 1.35, "reichweite": 230, "flaeche": 56, "durchschlag": 24, "brand": { "dps": 26, "dur": 3 } },
			{ "name": "Ewigwacht", "kosten": 980, "schaden": 265, "rate": 1.5, "reichweite": 270, "flaeche": 74, "durchschlag": 42, "kette": 3, "brand": { "dps": 52, "dur": 3.5 } },
		],
	},
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
]

## Anführer. Deutlich größer und zäher als gewöhnliche Arten.
const ANFUEHRER := [
	{ "name": "Glutochse", "typ": "fire", "gestalt": "ox", "leben": 24, "tempo": 0.5, "beute": 16, "groesse": 34, "panzer": 8 },
	{ "name": "Tiefenschlund", "typ": "water", "gestalt": "fish", "leben": 26, "tempo": 0.55, "beute": 18, "groesse": 34, "heilt": 0.008 },
	{ "name": "Wurzelriese", "typ": "grass", "gestalt": "sprout", "leben": 30, "tempo": 0.45, "beute": 20, "groesse": 36, "panzer": 11 },
	{ "name": "Gewitteraar", "typ": "electric", "gestalt": "bird", "leben": 25, "tempo": 0.8, "beute": 20, "groesse": 32, "fliegt": true },
	{ "name": "Felsenherz", "typ": "rock", "gestalt": "crystal", "leben": 34, "tempo": 0.38, "beute": 24, "groesse": 38, "panzer": 17, "zaeh": true },
	{ "name": "Nimmerauge", "typ": "psychic", "gestalt": "eye", "leben": 32, "tempo": 0.6, "beute": 30, "groesse": 36 },
	{ "name": "Frostmähne", "typ": "ice", "gestalt": "zottel", "leben": 31, "tempo": 0.48, "beute": 26, "groesse": 36, "panzer": 12, "schild": 0.5 },
	{ "name": "Erzhammer", "typ": "steel", "gestalt": "bolzen", "leben": 33, "tempo": 0.42, "beute": 28, "groesse": 37, "panzer": 24, "zaeh": true },
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
	{ "name": "Grünpfad", "grad": "Ruhig", "faktor": 1.25, "beeren": 280, "leben": 20 },
	{ "name": "Glutschlucht", "grad": "Fordernd", "faktor": 1.44, "beeren": 300, "leben": 18 },
	{ "name": "Flutruine", "grad": "Brutal", "faktor": 1.95, "beeren": 500, "leben": 15 },
]

