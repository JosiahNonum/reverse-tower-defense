extends SceneTree


const UNIT_COUNT: int = 300
const TOWER_COUNT: int = 100
const WARMUP_FRAME_COUNT: int = 30
const SAMPLE_FRAME_COUNT: int = 180
const MAX_P95_FRAME_MS: float = 16.67
const MAX_P95_RECONCILE_MS: float = 4.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var battlefield := BattlefieldView.new()
	root.add_child(battlefield)
	var view := MatchView.new(&"resolution", 0, UNIT_COUNT + TOWER_COUNT, _entities())
	var empty_events: Array[DomainEvent] = []
	battlefield.reconcile(view, empty_events)

	for frame_index: int in WARMUP_FRAME_COUNT:
		await process_frame

	var frame_microseconds: Array[int] = []
	var reconcile_microseconds: Array[int] = []
	var previous_frame_time: int = Time.get_ticks_usec()
	for frame_index: int in SAMPLE_FRAME_COUNT:
		var reconcile_started: int = Time.get_ticks_usec()
		battlefield.reconcile(view, empty_events)
		reconcile_microseconds.append(Time.get_ticks_usec() - reconcile_started)
		await process_frame
		var current_frame_time: int = Time.get_ticks_usec()
		frame_microseconds.append(current_frame_time - previous_frame_time)
		previous_frame_time = current_frame_time

	frame_microseconds.sort()
	reconcile_microseconds.sort()
	var frame_p95_ms: float = _percentile_ms(frame_microseconds, 95)
	var reconcile_p95_ms: float = _percentile_ms(reconcile_microseconds, 95)
	var passed: bool = (
		battlefield.get_visual_count() == UNIT_COUNT + TOWER_COUNT
		and frame_p95_ms <= MAX_P95_FRAME_MS
		and reconcile_p95_ms <= MAX_P95_RECONCILE_MS
	)
	var report: Dictionary = {
		"benchmark_id": "m2.presentation_proxy",
		"resolution": "1280x720",
		"unit_count": UNIT_COUNT,
		"tower_count": TOWER_COUNT,
		"visual_count": battlefield.get_visual_count(),
		"sample_frame_count": SAMPLE_FRAME_COUNT,
		"median_frame_ms": _percentile_ms(frame_microseconds, 50),
		"p95_frame_ms": frame_p95_ms,
		"maximum_frame_ms": snappedf(float(frame_microseconds[-1]) / 1000.0, 0.001),
		"median_reconcile_ms": _percentile_ms(reconcile_microseconds, 50),
		"p95_reconcile_ms": reconcile_p95_ms,
		"thresholds_ms": {
			"p95_frame": MAX_P95_FRAME_MS,
			"p95_reconcile": MAX_P95_RECONCILE_MS,
		},
		"scope": "current one-Node2D-per-entity snapshot reconciliation proxy",
		"passed": passed,
	}
	print("RENDER BENCHMARK: %s" % JSON.stringify(report))
	if not passed:
		push_error("RENDER BENCHMARK FAIL: frame or reconciliation threshold failed")
		quit(1)
		return
	print("RENDER BENCHMARK PASS")
	quit(0)


func _entities() -> Array[EntityView]:
	var entities: Array[EntityView] = []
	for tower_index: int in TOWER_COUNT:
		entities.append(EntityView.new(
			tower_index + 1,
			&"tower",
			1000 + (tower_index % 20) * 250,
			500 + (tower_index / 20) * 500,
		))
	for unit_index: int in UNIT_COUNT:
		entities.append(EntityView.new(
			TOWER_COUNT + unit_index + 1,
			&"unit",
			(unit_index % 60) * 100,
			1200 + (unit_index / 60) * 200,
		))
	return entities


func _percentile_ms(sorted_values: Array[int], percentile: int) -> float:
	var index: int = int(ceil(
		(float(percentile) / 100.0) * sorted_values.size(),
	)) - 1
	index = clampi(index, 0, sorted_values.size() - 1)
	return snappedf(float(sorted_values[index]) / 1000.0, 0.001)
