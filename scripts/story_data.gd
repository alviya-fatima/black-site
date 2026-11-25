class_name StoryData
extends RefCounted

const SECURITY_CODE := "314"
const ANCHOR_SEQUENCE: Array[String] = ["lights", "records", "lift"]
const FREQUENCY := "13.5"
const START_POSITION := Vector3(-12.5, 0.08, 15.5)

const ITEMS := {
	"staff_card": {
		"name": "STAFF KEYCARD 07",
		"short": "KEYCARD",
		"desc": "A scuffed staff card. It opens the west staff break room.",
		"glyph": "▣",
		"color": "#b9b49b"
	},
	"brass_key": {
		"name": "BRASS KEY",
		"short": "KEY",
		"desc": "A heavy brass key, warm from someone else's pocket.",
		"glyph": "⚿",
		"color": "#b5965b"
	},
	"fuse_power": {
		"name": "ANCHOR FUSE — POWER",
		"short": "POWER FUSE",
		"desc": "A ceramic fuse wound with copper. Stencilled: PWR.",
		"glyph": "▮",
		"color": "#c9a554"
	},
	"fuse_records": {
		"name": "ANCHOR FUSE — RECORDS",
		"short": "REC. FUSE",
		"desc": "A blue-grey fuse tagged with a filing number.",
		"glyph": "▮",
		"color": "#8299a5"
	},
	"fuse_lift": {
		"name": "ANCHOR FUSE — LIFT",
		"short": "LIFT FUSE",
		"desc": "A red fuse with a lift symbol scratched into the ceramic.",
		"glyph": "▮",
		"color": "#9e5b52"
	},
	"override_key": {
		"name": "SERVICE OVERRIDE",
		"short": "OVERRIDE",
		"desc": "A cracked magnetic key from the crawlspace. It bears the Black Site seal.",
		"glyph": "⌘",
		"color": "#d1c8a9"
	},
}

const FUSE_IDS: Array[String] = ["fuse_power", "fuse_records", "fuse_lift"]

const DOCS := {
	"intake_06": {
		"title": "INTAKE / SUBJECT 06",
		"code": "FORM BS-06  ·  NIGHT ADMISSION",
		"body": "Arrival: 03:17.\n\nSubject 06 was found in the east corridor. No record of entry. No record of discharge.\n\nDo not confirm the date. Do not use the word 'exit.' If the subject asks how they arrived, state: 'You have been here before.'\n\nReturn count: 41.\n\nThe bed frame has forty-one tallies carved into the paint. The intake officer's signature is wet.",
		"hint": "Forty-one returns."
	},
	"patient_13": {
		"title": "PATIENT RECORD / 13",
		"code": "WARD A  ·  DR. E. VOSS",
		"body": "Name: Eli Harrow.\nAdmitted: 1987.\nObservation: Chronic insomnia. No incidents. No restraint orders.\n\nPatient 13 requested a transfer nineteen times. Each request was returned unsigned.\n\nDr. Voss writes: 'Eli says the corridor moves at night. He says the exit sign keeps changing rooms. I checked. It does.'\n\nA second hand has added, in pencil: 'He is not dangerous. He is just tired of being returned.'",
		"hint": "The corridor is not reliable."
	},
	"maintenance_note": {
		"title": "MAINTENANCE / WEST WASHROOM",
		"code": "WORK ORDER 44-C  ·  DO NOT FILE",
		"body": "The mirror in the west washroom is not a mirror. It is a service panel. The hinge is on the left. Use the flat bar behind the sink if the latch sticks.\n\nDo not let the night staff see you open it. They file it as a bounce.\n\nThere is a crawlspace behind the wall. It exits into the return corridor. If you hear yourself breathing ahead of you, stop walking.\n\n— M.",
		"hint": "The west washroom mirror hides a service panel."
	},
	"staff_memo": {
		"title": "STAFF MEMO / 07",
		"code": "RECORDS  ·  SECURITY",
		"body": "Security door keypad was reset after the last cycle. New code: 3-1-4.\n\nKeep this out of patient files.\n\nThe ANCHOR array is drawing too much current. If the subject reaches the front entrance, route them through the west corridor and re-intake. Do not open the basement seal.\n\nThe Lift is scheduled for inspection. Do not let the subject ride it unattended.",
		"hint": "Security keypad: 3-1-4. Do not open the basement."
	},
	"medical_chart": {
		"title": "MEDICAL STORES / SHIFT NOTE",
		"code": "MEDICAL  ·  03:04",
		"body": "Staff keycard 07 was left in the medicine cabinet again. If you need the break room, use it and put it back.\n\nThe subject asks about the elevator every cycle. Same words every time: 'Does it go up?'\n\nTell them the truth. It goes back.\n\n— Nurse A.",
		"hint": "Staff keycard in the medicine cabinet. The lift goes back."
	},
	"security_log": {
		"title": "SECURITY LOG / ANCHOR ARRAY",
		"code": "RESTRICTED  ·  EYES ONLY",
		"body": "Anchor boot order: LIGHTS. RECORDS. LIFT.\n\nNever wake the RETURN anchor. It has no off switch.\n\nIf the sequence is entered incorrectly, the array grounds itself and resets the current cycle. The subject will wake in Intake. This is acceptable.\n\nThe lift is an anchor, not an exit. If the subject calls it, let them see the corridor. Let them believe they took it somewhere.\n\nBasement seal releases only when all three anchor fuses are seated and the sequence is correct.",
		"hint": "Boot order: Lights → Records → Lift. Never RETURN."
	},
	"boiler_note": {
		"title": "CARRIER CALIBRATION",
		"code": "BASEMENT  ·  DR. E. VOSS",
		"body": "I built the return corridor. It does not lead out. It leads back.\n\nThree fuses keep the anchors awake: POWER, RECORDS, LIFT. Remove them and the building cannot fold a route around you.\n\nTune the return carrier to 13.5. Any other frequency folds the corridor into itself. The needle will resist.\n\nWhen the loop lets go, use the service tunnel. Do not look at the sky for too long. It is not yours.\n\nI am sorry. I keep apologizing to the same room.",
		"hint": "Tune the return carrier to 13.5, then use the service tunnel."
	},
	"crawl_note": {
		"title": "UNSIGNED / CRAWLSPACE",
		"code": "FOUND BEHIND THE WEST MIRROR",
		"body": "You are not Subject 06.\n\nYou are the intake officer who signed the order. Every cycle you come back to check on them. Every cycle you forget.\n\nGo out through the west mirror. See for yourself. Then come back.\n\nYou always come back.\n\nThere is a service override hooked behind the pipe. Take it. You will need it when the basement lets you through.",
		"hint": "You signed the intake. Take the service override."
	},
	"tally_scrap": {
		"title": "SCRAP / STAFF CORRIDOR",
		"code": "NO FILE NUMBER",
		"body": "IT ALWAYS COMES BACK\nIT ALWAYS COMES BACK\nIT ALWAYS COMES BACK\n\n— same handwriting, four different pens.",
		"hint": "Same words. Different pens."
	},
}

const DOC_ORDER: Array[String] = [
	"intake_06", "patient_13", "maintenance_note", "staff_memo",
	"medical_chart", "security_log", "boiler_note", "crawl_note", "tally_scrap"
]

const ENDINGS := {
	1: {
		"number": "ENDING 01",
		"title": "WRONG EXIT",
		"tag": "LOOP 09",
		"summary": "The front door opened onto the corridor you had just left.",
		"body": "The night air touches your face for half a second.\n\nThen the door is a wall. The wall is a corridor. The corridor smells of bleach.\n\nYou have not moved. Somewhere behind you, a fluorescent light begins to hum.",
		"accent": "#8d3b31",
		"audio": "door_open",
	},
	2: {
		"number": "ENDING 02",
		"title": "THE STAFF ROOM",
		"tag": "LOOP 17",
		"summary": "The staff route closed before you could take it.",
		"body": "A service corridor. For one breath, the outer door is in sight.\n\nThen the shutter falls. The route becomes a wall. The lights go out in a line, one by one, like someone counting.\n\nWhen you blink, you are in Intake. The staff card is still in your pocket.",
		"accent": "#6c715f",
		"audio": "door_slam",
	},
	3: {
		"number": "ENDING 03",
		"title": "THE ELEVATOR",
		"tag": "LOOP 23",
		"summary": "The lift descended. It opened on the same corridor.",
		"body": "The doors close. The carriage descends. Or maybe it only pretends to.\n\nWhen the doors open, the same corridor waits. The floor indicator reads L.\n\nYou step out to prove you are somewhere else. The corridor light flickers. You are in Intake again.",
		"accent": "#758084",
		"audio": "elevator",
	},
	4: {
		"number": "ENDING 04",
		"title": "THE SECRET PASSAGE",
		"tag": "LOOP 31",
		"summary": "The crawlspace returned you to a familiar room.",
		"body": "You crawl until your knees ache. The vent opens into a corridor you know by heart.\n\nBehind you, the mirror is whole again. There is no seam, no hinge, no crawlspace.\n\nIt was never a passage. It was a way for the building to turn you around.",
		"accent": "#7d725a",
		"audio": "heartbeat",
	},
	5: {
		"number": "ENDING 05",
		"title": "THE FINAL DOOR",
		"tag": "LOOP 38",
		"summary": "You saw the night sky. Then the door shut itself.",
		"body": "You see the night sky. You hear wind in the grass. A moth turns against the outside light.\n\nYou lift your foot to step through.\n\nEvery light in the building goes out at once. The door closes without a sound.\n\nA voice from the intercom says: 'Rehearsal complete.'",
		"accent": "#6d3230",
		"audio": "signal_lost",
	},
	6: {
		"number": "ENDING 06",
		"title": "BOUNCE BACK",
		"tag": "TRUE ENDING  ·  LOOP 42",
		"summary": "The sun was warm. The grass was real. Then the world blinked.",
		"body": "The sun was warm. The grass was real. You were allowed to believe it.\n\nThen the world blinked.\n\nYou are in Intake. You were always in Intake. The tallies on the bed frame are yours.\n\nYou don't escape Black Site.\n\nYou bounce back.",
		"accent": "#8a2e28",
		"audio": "last_light",
	}
}

const ZONE_NAMES := {
	"intake": "INTAKE 03",
	"ward_a": "WARD A",
	"washroom": "WEST WASHROOM",
	"day_room": "DAY ROOM",
	"storage": "STORAGE",
	"records": "RECORDS",
	"medical": "MEDICAL",
	"security": "SECURITY",
	"staff_room": "STAFF BREAK ROOM",
	"corridor": "CENTRAL CORRIDOR",
	"lobby": "RECEPTION",
	"north_hall": "NORTH STAIRWELL",
	"crawlspace": "SERVICE CRAWL",
	"ward_b": "WARD B",
	"basement": "SUB-LEVEL C",
	"basement_tunnel": "SERVICE TUNNEL",
	"outside": "OUTSIDE",
}
