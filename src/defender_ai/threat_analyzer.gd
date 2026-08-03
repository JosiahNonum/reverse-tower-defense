class_name ThreatAnalyzer
extends RefCounted

static func analyze(observation) -> Dictionary[StringName, int]:
	var leaks: int = 0
	var survivors: int = 0
	for row: Dictionary in observation.history:
		leaks += int(row["leaks"])
		survivors += int(row["survivors"])
	return {&"leaks": leaks, &"survivors": survivors, &"pressure": leaks * 100 + survivors * 10}
