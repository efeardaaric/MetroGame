class_name Dilemmas
extends RefCounted
## Decision events: a card with 2–3 choices. Text keys: dlg_<id>_t (title), dlg_<id>_b (body),
## dlg_<id>_o<n> (option label), dlg_<id>_r<n> (result text).
##
## Option effect keys (money is expressed as a fraction "g" of the city's annual grant so it
## scales per city):
##   cash_g: float            add cash (negative = cost)
##   approval: float          public approval bump (decays over months)
##   wage: float              permanent opex multiplier increase
##   strike: [chance, lines]  chance to close N random lines for 1 month
##   incident: {cap, months}  apply to the event's target line
##   repair_target: true      clear the target line's incident
##   rename_sponsor: true     rename the target station with a sponsor name
##   fare_cap: [mult, months] cap fare policy for N months
##   flag: String             set a permanent flag (e.g. "retrofit", "elevators")
##   mission: String          start a mission of that type
##   sat_bonus: float         permanent satisfaction bonus
##   rival: int               a rival service makes cars/taxis more attractive for N months

const LIST := {
	"union_wage": {"weight": 1.0, "min_lines": 2, "icon": "people", "options": [
		{"wage": 0.07, "approval": 2.0},
		{"wage": 0.035, "strike": [0.45, 1]},
		{"approval": -4.0, "strike": [0.85, 2]},
	]},
	"signal_failure": {"weight": 1.2, "min_lines": 1, "target": "busy_line", "icon": "warning", "options": [
		{"cash_g": -0.07, "approval": 1.0},
		{"incident": {"cap": 0.4, "months": 2}, "approval": -3.0},
	]},
	"sponsor_station": {"weight": 0.8, "min_lines": 1, "target": "busy_station", "icon": "coin", "options": [
		{"cash_g": 0.22, "rename_sponsor": true, "approval": -2.0},
		{"approval": 1.5},
	]},
	"fare_cut": {"weight": 0.7, "min_lines": 2, "icon": "coin", "options": [
		{"fare_cap": [0.8, 12], "approval": 7.0},
		{"approval": -4.0},
	]},
	"eu_grant": {"weight": 0.6, "min_lines": 1, "icon": "star", "options": [
		{"mission": "riders_growth"},
		{},
	]},
	"seismic": {"weight": 0.5, "min_lines": 2, "requires_city": ["istanbul", "izmir"], "not_flag": "retrofit", "icon": "warning", "options": [
		{"cash_g": -0.3, "flag": "retrofit", "approval": 3.0},
		{"approval": -1.0},
	]},
	"flood": {"weight": 0.7, "min_lines": 1, "target": "underground_line", "icon": "warning", "options": [
		{"cash_g": -0.09},
		{"incident": {"cap": 0.0, "months": 1}, "approval": -3.0},
	]},
	"accessibility": {"weight": 0.6, "min_lines": 2, "not_flag": "elevators", "icon": "people", "options": [
		{"cash_g": -0.18, "flag": "elevators", "sat_bonus": 3.0, "approval": 5.0},
		{"approval": -2.5},
	]},
	"night_event": {"weight": 0.9, "min_lines": 1, "icon": "star", "options": [
		{"cash_g": -0.025, "approval": 3.5},
		{"approval": -2.0},
	]},
	"vandalism": {"weight": 0.8, "min_lines": 1, "target": "busy_station", "icon": "warning", "options": [
		{"cash_g": -0.02, "approval": 1.0},
		{"approval": -2.5},
	]},
	"developer": {"weight": 0.8, "min_lines": 1, "icon": "build", "options": [
		{"mission": "connect_zone"},
		{},
	]},
	"press": {"weight": 0.8, "min_lines": 1, "needs_crowding": true, "icon": "megaphone", "options": [
		{"cash_g": -0.05, "approval": 3.0},
		{"approval": -4.5},
	]},
	"mayor_challenge": {"weight": 0.7, "min_lines": 2, "icon": "target", "options": [
		{"mission": "no_crowding"},
		{"approval": -1.5},
	]},
	"new_mode": {"weight": 0.5, "min_lines": 2, "icon": "lines", "options": [
		{"mission": "build_mode"},
		{},
	]},
	"rival_app": {"weight": 0.7, "min_lines": 2, "icon": "warning", "options": [
		{"cash_g": -0.08, "rival": 2, "approval": 1.0},
		{"fare_cap": [0.85, 6], "rival": 3},
		{"rival": 9, "approval": -1.0},
	]},
	"satisfaction_drive": {"weight": 0.6, "min_lines": 2, "icon": "smile", "options": [
		{"mission": "satisfaction"},
		{},
	]},
}

const SPONSORS := ["Martı Market", "Boğaz Bank", "Simitçi Plaza", "Lale Sigorta", "Kordon Kafe", "Anadolu Telekom",
	"Yıldız Eczane", "Defne Kitabevi", "Çınar Spor", "Pera Sinema"]

const MISSIONS := {
	"riders_growth": {"months": 12, "reward_g": 0.55, "fail_approval": -3.0},
	"connect_zone": {"months": 14, "reward_g": 0.35, "fail_approval": -3.0},
	"no_crowding": {"months": 12, "reward_g": 0.3, "fail_approval": -4.0, "need": 4},
	"build_mode": {"months": 12, "reward_g": 0.3, "fail_approval": -2.0},
	"satisfaction": {"months": 12, "reward_g": 0.35, "fail_approval": -3.0, "need": 5, "level": 70.0},
}
