extends SceneTree

const BalanceMatrixRunnerScript = preload("res://src/application/balance_matrix_runner.gd")


func _initialize() -> void:
	var catalog := ContentCatalog.load_from_directory("res://content")
	var report: Dictionary = BalanceMatrixRunnerScript.new().run(catalog, catalog.rules[0])
	var wins: int = 0
	for row: Dictionary in report["rows"]:
		wins += 1 if row["outcome"] == "player_win" else 0
	print("BALANCE SUMMARY: cases=%d player_wins=%d defender_wins=%d universal_attacker_shapes=%d unreachable_shapes=%d" % [
		report["case_count"], wins, report["case_count"] - wins, report["universal_attacker_shapes"].size(), report["unreachable_shapes"].size(),
	])
	print(JSON.stringify(report))
	quit(0)
