class_name CSVParser
extends RefCounted

static func load_csv(path: String) -> Array[Dictionary]:
	"""
	Load CSV file and return array of dictionaries.
	Each dictionary uses header row as keys.
	Returns empty array if file doesn't exist.
	"""
	if not FileAccess.file_exists(path):
		return []
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return []
	
	var result: Array[Dictionary] = []
	var headers: PackedStringArray = []
	var is_first_line = true
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() == 0 or (line.size() == 1 and line[0] == ""):
			continue
		
		if is_first_line:
			headers = line
			is_first_line = false
			continue
		
		var row: Dictionary = {}
		for i in range(min(headers.size(), line.size())):
			row[headers[i]] = line[i]
		result.append(row)
	
	file.close()
	return result

static func save_csv(path: String, data: Array[Dictionary]) -> bool:
	"""Save array of dictionaries to CSV file."""
	if data.is_empty():
		return false
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	
	# Write headers from first dictionary
	var headers = data[0].keys()
	file.store_csv_line(PackedStringArray(headers))
	
	# Write data rows
	for row in data:
		var values: PackedStringArray = []
		for header in headers:
			values.append(str(row.get(header, "")))
		file.store_csv_line(values)
	
	file.close()
	return true

static func file_exists(path: String) -> bool:
	"""Check if CSV file exists."""
	return FileAccess.file_exists(path)
