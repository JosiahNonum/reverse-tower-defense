class_name DefenseInspectionPanel
extends PanelContainer


var _model: DefenseInspectionModel
var _selected_tower_id: StringName


func configure(model: DefenseInspectionModel) -> void:
	_model = model
	_update_threat_summary()
	var towers: Array[DefenseTowerInspection] = _model.get_towers()
	if not towers.is_empty():
		show_tower(towers[0].get_slot_id())


func show_tower(slot_id: StringName) -> void:
	if _model == null:
		return
	var tower: DefenseTowerInspection = _model.get_tower(slot_id)
	if tower == null:
		return
	_selected_tower_id = tower.get_tower_id()
	%TowerName.text = tower.get_tower_name().to_upper()
	%TowerMeta.text = "%s  ·  %s" % [
		_humanize_id(tower.get_slot_id()),
		_humanize_id(tower.get_targeting_kind()),
	]
	%RangeValue.text = "%.2f map units" % (float(tower.get_range()) / 1000.0)
	%PolicyValue.text = tower.get_targeting_summary()
	%UpgradeValue.text = tower.get_upgrade_summary()
	%RoutesValue.text = _humanize_ids(tower.get_route_ids())
	%SegmentsValue.text = _segment_names(tower.get_covered_edge_ids())


func get_selected_tower_id() -> StringName:
	return _selected_tower_id


func get_policy_text() -> String:
	return %PolicyValue.text


func get_routes_text() -> String:
	return %RoutesValue.text


func get_threat_summary_text() -> String:
	return %ThreatSummary.text


func _update_threat_summary() -> void:
	var lines: PackedStringArray = []
	var priority_segments: Array[RouteThreatInspection] = (
		_model.get_most_defended_segments(2)
	)
	for index: int in priority_segments.size():
		var segment: RouteThreatInspection = priority_segments[index]
		lines.append("%d. %s — %s (%d ranges)" % [
			index + 1,
			segment.get_display_name(),
			_humanize_id(segment.get_threat_level()),
			segment.get_coverage_count(),
		])
	%ThreatSummary.text = "\n".join(lines)


func _segment_names(edge_ids: Array[StringName]) -> String:
	var names: PackedStringArray = []
	for edge_id: StringName in edge_ids:
		var segment: RouteThreatInspection = _model.get_segment(edge_id)
		if segment != null:
			names.append(segment.get_display_name())
	return ", ".join(names) if not names.is_empty() else "No route segment"


func _humanize_ids(values: Array[StringName]) -> String:
	var names: PackedStringArray = []
	for value: StringName in values:
		names.append(_humanize_id(value))
	return ", ".join(names) if not names.is_empty() else "None"


func _humanize_id(content_id: StringName) -> String:
	var pieces: PackedStringArray = String(content_id).split(".")
	var meaningful: PackedStringArray = pieces.slice(1) if pieces.size() > 1 else pieces
	var words: PackedStringArray = "_".join(meaningful).split("_")
	for index: int in words.size():
		words[index] = words[index].capitalize()
	return " ".join(words)
