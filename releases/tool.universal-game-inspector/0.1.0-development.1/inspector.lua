-- Infinity Universal Game Inspector
-- artifact-schema: game-discovery-inspector-artifact/1
-- generated deterministically; edit game-creator/inspector/*.luau, not this file
local __factories = {}
local __cache = {}
local __loading = {}
local function __require(name)
	if __cache[name] ~= nil then return __cache[name] end
	if __loading[name] then error("INSPECTOR_ARTIFACT_IMPORT_CYCLE:" .. tostring(name)) end
	local factory = __factories[name]
	if factory == nil then error("INSPECTOR_ARTIFACT_IMPORT_UNKNOWN:" .. tostring(name)) end
	__loading[name] = true
	local value = factory(__require)
	__loading[name] = nil
	__cache[name] = value
	return value
end
__factories["Constants"] = function(__require)
local Constants = {}

Constants.CONTRACT_ID = "game-discovery-capture"
Constants.CONTRACT_VERSION = "v1-draft"
Constants.SCHEMA_VERSION = 1
Constants.INSPECTOR_VERSION = "0.1.0"
Constants.SANITIZATION_POLICY_VERSION = "sanitize-v1.1"
Constants.COUNTER_MAX = 8192

Constants.MAX_LIMITS = table.freeze({
	duration_seconds = 7200,
	raw_queue_records = 4096,
	path_segments = 64,
	string_bytes = 256,
	remote_arguments = 16,
	table_depth = 4,
	table_entries = 32,
	snapshot_bytes = 65536,
	connections = 4096,
})

Constants.DEFAULT_LIMITS = table.freeze({
	duration_seconds = 1800,
	raw_queue_records = 4096,
	path_segments = 64,
	string_bytes = 256,
	remote_arguments = 16,
	table_depth = 4,
	table_entries = 32,
	snapshot_bytes = 65536,
	connections = 4096,
})

Constants.CAPABILITIES = table.freeze({
	hierarchy_observation = true,
	ui_observation = true,
	manual_input_correlation = true,
	remote_inventory = true,
	remote_call_observation = false,
	active_diagnostics = false,
})

Constants.SURFACES = table.freeze({
	metadata = true,
	hierarchy = true,
	instances = true,
	attributes = true,
	value_bases = true,
	tags = true,
	character = true,
	zones = true,
	inventory = true,
	stats = true,
	tools = true,
	ui = true,
	manual_interactions = true,
	cycles = true,
	errors = true,
	remote_inventory = true,
	remote_call_observation = true,
})

return table.freeze(Constants)
end
__factories["BoundedBuffer"] = function(__require)
local Constants = __require("Constants")

local BoundedBuffer = {}
BoundedBuffer.__index = BoundedBuffer

function BoundedBuffer.new(capacity)
	return setmetatable({
		capacity = capacity,
		records = {},
		surfaceCounts = {},
		droppedCount = 0,
		firstDroppedUs = nil,
		truncatedSurfaces = {},
	}, BoundedBuffer)
end

local function equalValue(left, right, seen)
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	seen = seen or {}
	if seen[left] == right then
		return true
	end
	seen[left] = right
	for key, value in pairs(left) do
		if not equalValue(value, right[key], seen) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function sameObservation(left, right)
	if left.surface ~= right.surface or left.operation ~= right.operation then
		return false
	end
	local leftSubject = left.subject
	local rightSubject = right.subject
	if leftSubject.class_name ~= rightSubject.class_name or leftSubject.value_type ~= rightSubject.value_type then
		return false
	end
	if #leftSubject.path_segments ~= #rightSubject.path_segments then
		return false
	end
	for index, segment in ipairs(leftSubject.path_segments) do
		if rightSubject.path_segments[index] ~= segment then
			return false
		end
	end
	return equalValue(left.value, right.value)
		and equalValue(left.context_refs, right.context_refs)
end

function BoundedBuffer:_recordDrop(record)
	self.droppedCount = math.min(Constants.COUNTER_MAX, self.droppedCount + 1)
	self.firstDroppedUs = self.firstDroppedUs or record.t_us
	self.truncatedSurfaces[record.surface] = math.min(
		Constants.COUNTER_MAX,
		(self.truncatedSurfaces[record.surface] or 0) + 1
	)
end

function BoundedBuffer:push(record)
	local last = self.records[#self.records]
	if #self.records < self.capacity then
		table.insert(self.records, record)
		self.surfaceCounts[record.surface] = (self.surfaceCounts[record.surface] or 0) + 1
		return "kept"
	end
	if last ~= nil and sameObservation(last, record) then
		last.occurrences = (last.occurrences or 1) + 1
		last.last_t_us = record.t_us
		return "aggregated"
	end
	-- Never evict an older record: doing so would break local_ref/context_refs.
	-- The incoming record is the newest member of its surface and is dropped.
	self:_recordDrop(record)
	return "dropped"
end

function BoundedBuffer:snapshotAndClear()
	local snapshot = self.records
	self.records = {}
	self.surfaceCounts = {}
	return snapshot
end

function BoundedBuffer:clear()
	table.clear(self.records)
	table.clear(self.surfaceCounts)
end

function BoundedBuffer:stats()
	local surfaces = {}
	for surface, count in pairs(self.truncatedSurfaces) do
		surfaces[surface] = count
	end
	return {
		occurred = self.droppedCount > 0,
		dropped_count = self.droppedCount,
		first_dropped_t_us = self.firstDroppedUs,
		surfaces = surfaces,
	}
end

return BoundedBuffer
end
__factories["Config"] = function(__require)
local Constants = __require("Constants")

local Config = {}

local function failure(code, field)
	return {
		ok = false,
		error = {
			code = code,
			field = field,
			count = 1,
		},
	}
end

local function copyMap(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

function Config.validate(input)
	if type(input) ~= "table" then
		return failure("DISCOVERY_CONFIG_INVALID", "config")
	end
	if input.contract_version ~= Constants.CONTRACT_VERSION then
		return failure("DISCOVERY_CONTRACT_UNSUPPORTED", "contract_version")
	end
	if input.schema_version ~= Constants.SCHEMA_VERSION then
		return failure("DISCOVERY_SCHEMA_UNSUPPORTED", "schema_version")
	end
	if input.mode ~= "passive" then
		return failure("DISCOVERY_PASSIVITY_VIOLATION", "mode")
	end
	if input.retention_class ~= "local-ephemeral" then
		return failure("DISCOVERY_RETENTION_INVALID", "retention_class")
	end

	local capabilities = copyMap(Constants.CAPABILITIES)
	if input.capabilities ~= nil then
		if type(input.capabilities) ~= "table" then
			return failure("DISCOVERY_CONFIG_INVALID", "capabilities")
		end
		for name, enabled in pairs(input.capabilities) do
			if Constants.CAPABILITIES[name] == nil or type(enabled) ~= "boolean" then
				return failure("DISCOVERY_CAPABILITY_UNSUPPORTED", "capabilities")
			end
			capabilities[name] = enabled
		end
	end
	if capabilities.active_diagnostics then
		return failure("DISCOVERY_PASSIVITY_VIOLATION", "capabilities.active_diagnostics")
	end
	local requested = {}
	local requestedList = {}
	local surfaces = input.surfaces or {
		"metadata", "hierarchy", "instances", "attributes", "value_bases",
		"tags", "character", "ui", "remote_inventory",
	}
	if type(surfaces) ~= "table" then
		return failure("DISCOVERY_CONFIG_INVALID", "surfaces")
	end
	for _, surface in ipairs(surfaces) do
		if type(surface) ~= "string" or not Constants.SURFACES[surface] then
			return failure("DISCOVERY_CONFIG_INVALID", "surfaces")
		end
		if surface == "remote_call_observation" and not capabilities.remote_call_observation then
			return failure("DISCOVERY_CAPABILITY_UNSUPPORTED", "surfaces.remote_call_observation")
		end
		if requested[surface] then
			return failure("DISCOVERY_CONFIG_INVALID", "surfaces")
		end
		requested[surface] = true
		table.insert(requestedList, surface)
	end
	table.sort(requestedList)
	if (requested.hierarchy or requested.instances or requested.attributes or requested.value_bases or requested.tags)
		and not capabilities.hierarchy_observation
	then
		return failure("DISCOVERY_CAPABILITY_UNSUPPORTED", "capabilities.hierarchy_observation")
	end
	if requested.ui and not capabilities.ui_observation then
		return failure("DISCOVERY_CAPABILITY_UNSUPPORTED", "capabilities.ui_observation")
	end
	if requested.manual_interactions and not capabilities.manual_input_correlation then
		return failure("DISCOVERY_CAPABILITY_UNSUPPORTED", "capabilities.manual_input_correlation")
	end
	if requested.remote_inventory and not capabilities.remote_inventory then
		return failure("DISCOVERY_CAPABILITY_UNSUPPORTED", "capabilities.remote_inventory")
	end

	local limits = copyMap(Constants.DEFAULT_LIMITS)
	if input.limits ~= nil then
		if type(input.limits) ~= "table" then
			return failure("DISCOVERY_CONFIG_INVALID", "limits")
		end
		for name, value in pairs(input.limits) do
			local maximum = Constants.MAX_LIMITS[name]
			if maximum == nil or type(value) ~= "number" or value % 1 ~= 0 or value < 1 or value > maximum then
				return failure("DISCOVERY_CONFIG_INVALID", "limits")
			end
			limits[name] = value
		end
	end

	local duration = input.duration_seconds or limits.duration_seconds
	if type(duration) ~= "number" or duration % 1 ~= 0 or duration < 1 or duration > Constants.MAX_LIMITS.duration_seconds then
		return failure("DISCOVERY_CONFIG_INVALID", "duration_seconds")
	end
	limits.duration_seconds = math.min(duration, limits.duration_seconds)

	local retention = input.retention_seconds
	if retention == nil then
		retention = 86400
	end
	if type(retention) ~= "number" or retention % 1 ~= 0 or retention < 0 or retention > 604800 then
		return failure("DISCOVERY_CONFIG_INVALID", "retention_seconds")
	end

	local patterns = input.redaction_patterns or {}
	if type(patterns) ~= "table" or #patterns > 32 then
		return failure("DISCOVERY_CONFIG_INVALID", "redaction_patterns")
	end
	local copiedPatterns = {}
	for index, pattern in ipairs(patterns) do
		if type(pattern) ~= "string" or #pattern > Constants.MAX_LIMITS.string_bytes then
			return failure("DISCOVERY_CONFIG_INVALID", "redaction_patterns")
		end
		copiedPatterns[index] = pattern
	end

	return {
		ok = true,
		value = {
			contract_version = Constants.CONTRACT_VERSION,
			schema_version = Constants.SCHEMA_VERSION,
			mode = "passive",
			retention_class = "local-ephemeral",
			capabilities = capabilities,
			surfaces = requested,
			surface_list = requestedList,
			limits = limits,
			retention_seconds = retention,
			redaction_patterns = copiedPatterns,
		},
	}
end

return Config
end
__factories["Sanitizer"] = function(__require)
local Constants = __require("Constants")

local Sanitizer = {}
Sanitizer.__index = Sanitizer

local REDACTED = "<redacted>"
local DROP_FIELD_NAMES = table.freeze({
	userid = true,
	user_id = true,
	username = true,
	player_name = true,
	device_id = true,
	hardware_id = true,
	ip = true,
	latitude = true,
	longitude = true,
	jobid = true,
	job_id = true,
})

local RECORD_VALUE_FIELDS = table.freeze({
	game_id = true,
	place_id = true,
	creator_id = true,
	attribute_name = true,
	value = true,
	visible = true,
	ui_text = true,
	direction = true,
	method = true,
	arguments = true,
	value_type = true,
	class_name = true,
	name = true,
	kind = true,
	entry_count = true,
	value_types = true,
	truncated = true,
	state = true,
	x = true,
	y = true,
	z = true,
	quantum = true,
	health = true,
	processed = true,
	input_category = true,
})

local TECHNICAL_FIELDS = table.freeze({
	path_segment = true,
	category = true,
	class_name = true,
	value_type = true,
	instance_name = true,
	name = true,
	attribute_name = true,
	direction = true,
	method = true,
	kind = true,
	state = true,
	input_category = true,
})

local TECHNICAL_ENUMS = table.freeze({
	closed = true,
	open = true,
	start = true,
	["end"] = true,
	["end-reset"] = true,
})

local TECHNICAL_UI = table.freeze({
	dragon = true,
})

local function lower(value)
	return string.lower(value)
end

local function isSensitiveField(field)
	local key = lower(field or "")
	if DROP_FIELD_NAMES[key] then
		return true
	end
	return string.find(key, "cookie", 1, true) ~= nil
		or string.find(key, "token", 1, true) ~= nil
		or string.find(key, "secret", 1, true) ~= nil
		or string.find(key, "password", 1, true) ~= nil
		or string.find(key, "license", 1, true) ~= nil
end

local function isSensitiveString(value, patterns)
	local candidate = lower(value)
	if string.find(candidate, "bearer ", 1, true)
		or string.find(candidate, "cookie:", 1, true)
		or string.find(candidate, "authorization:", 1, true)
		or string.find(candidate, "token", 1, true)
		or string.match(candidate, "[%w%._%%+%-]+@[%w%.%-]+%.[%a]+")
		or string.match(candidate, "^https?://[^%s]+%?")
		or string.find(candidate, "discord.gg/", 1, true)
		or string.match(candidate, "^[%w_%-]+%.[%w_%-]+%.[%w_%-]+$")
		or string.match(candidate, "^gh[%a]_[-%w_]+$")
		or string.match(candidate, "^xox[%a]%-[-%w]+$")
		or string.match(candidate, "^akia[%w]+$")
		or (#value >= 24 and string.find(value, "%s") == nil)
	then
		return true
	end
	for _, pattern in ipairs(patterns) do
		local ok, found = pcall(string.find, candidate, lower(pattern))
		if ok and found ~= nil then
			return true
		end
	end
	return false
end

local function isSensitiveDynamicIdentifier(value, patterns)
	local candidate = lower(value or "")
	local canonical = string.gsub(candidate, "[^%w]", "")
	if isSensitiveField(candidate) or isSensitiveString(value, patterns) then
		return true
	end
	local technicalIdentityPaths = {
		players = true,
		playergui = true,
		playerscripts = true,
		starterplayer = true,
		userinputservice = true,
	}
	if candidate == "$local_player" or technicalIdentityPaths[canonical] then
		return false
	end
	for _, identityMarker in ipairs({ "player", "user", "account", "profile", "owner", "member", "customer" }) do
		if string.find(canonical, identityMarker, 1, true) ~= nil then
			return true
		end
	end
	for _, marker in ipairs({
		"displayname", "deviceid", "hardwareid", "jobid", "apikey", "accesskey",
		"sessionid", "credential", "authorization", "auth",
	}) do
		if string.find(canonical, marker, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function truncateUtf8(value, maximum)
	if #value <= maximum then
		return value
	end
	local candidate = string.sub(value, 1, maximum)
	while #candidate > 0 and utf8.len(candidate) == nil do
		candidate = string.sub(candidate, 1, #candidate - 1)
	end
	return candidate
end

local function valueType(value)
	local kind = typeof(value)
	if kind == "nil" then
		return "nil"
	elseif kind == "boolean" then
		return "boolean"
	elseif kind == "number" then
		if value % 1 == 0 then
			return "integer"
		end
		return "number"
	elseif kind == "string" then
		return "string"
	elseif kind == "Instance" then
		return "instance-ref"
	elseif kind == "table" then
		return "map-summary"
	end
	return "redacted"
end

function Sanitizer.new(limits, patterns)
	return setmetatable({
		limits = limits,
		patterns = patterns,
		redactionCount = 0,
		dropped = {},
	}, Sanitizer)
end

function Sanitizer:_drop(reason)
	self.dropped[reason] = (self.dropped[reason] or 0) + 1
end

function Sanitizer:_redact()
	self.redactionCount += 1
	return REDACTED
end

local function technicalEnumAllowed(value, context)
	if context == nil or (context.value_type ~= "enum" and context.value_type ~= "string") then
		return false
	end
	local surface = context.surface
	if surface ~= "attributes" and surface ~= "value_bases" and surface ~= "cycles" then
		return false
	end
	return TECHNICAL_ENUMS[lower(value)] == true
end

function Sanitizer:string(value, field, context)
	if value == REDACTED then
		return REDACTED
	end
	if isSensitiveField(field) or isSensitiveString(value, self.patterns) then
		return self:_redact()
	end
	if field == "remote_argument" then
		return self:_redact()
	end
	if field == "ui_text" then
		if context ~= nil
			and context.surface == "ui"
			and #value <= 64
			and string.match(value, "^[%a][%w_%-]*$") ~= nil
			and TECHNICAL_UI[lower(value)]
		then
			return truncateUtf8(value, 64)
		end
		return self:_redact()
	end
	if TECHNICAL_FIELDS[field] then
		return truncateUtf8(value, self.limits.string_bytes)
	end
	if field == "value" and technicalEnumAllowed(value, context) then
		return value
	end
	return self:_redact()
end

function Sanitizer:addEphemeralPattern(pattern)
	if type(pattern) == "string" and #pattern > 0 and #pattern <= self.limits.string_bytes then
		table.insert(self.patterns, pattern)
	end
end

function Sanitizer:dropField(reason)
	self:_drop(reason)
end

function Sanitizer:path(pathSegments)
	local result = {}
	for index, segment in ipairs(pathSegments) do
		if index > self.limits.path_segments then
			self:_drop("path_segments_limit")
			break
		end
		if type(segment) ~= "string" then
			self:_drop("invalid_path_segment")
			return nil
		end
		if isSensitiveDynamicIdentifier(segment, self.patterns) then
			self:_drop("sensitive_dynamic_identifier")
			return nil
		end
		result[index] = self:string(segment, "path_segment")
	end
	return result
end

function Sanitizer:value(value, field, depth, context)
	depth = depth or 0
	if isSensitiveField(field) then
		self:_drop("sensitive_field")
		return nil
	end
	local kind = typeof(value)
	if kind == "nil" or kind == "boolean" then
		return value
	elseif kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			self:_drop("non_finite_number")
			return nil
		end
		if value == 0 then
			return 0
		end
		return value
	elseif kind == "string" then
		return self:string(value, field, context)
	elseif kind == "Instance" then
		return {
			class_name = self:string(value.ClassName, "class_name", context),
			name = self:string(value.Name, "instance_name", context),
		}
	elseif kind == "table" then
		if depth >= self.limits.table_depth then
			self:_drop("table_depth_limit")
			return { kind = "table", truncated = true }
		end
		local counts = {}
		local total = 0
		for key, item in pairs(value) do
			total += 1
			if total > self.limits.table_entries then
				break
			end
			local itemKind = valueType(item)
			counts[itemKind] = (counts[itemKind] or 0) + 1
			-- Traverse nested values only to account for adversarial depth/shape.
			if type(item) == "table" then
				self:value(item, tostring(key), depth + 1, context)
			end
		end
		if total > self.limits.table_entries then
			self:_drop("table_entries_limit")
		end
		return {
			kind = "table",
			entry_count = math.min(total, self.limits.table_entries),
			value_types = counts,
			truncated = total > self.limits.table_entries,
		}
	end
	self:_drop("unsupported_value_type")
	return nil
end

function Sanitizer:remoteArguments(arguments)
	local result = {}
	local count = math.min(arguments.n or #arguments, self.limits.remote_arguments)
	for index = 1, count do
		local item = arguments[index]
		result[index] = {
			value_type = valueType(item),
			value = self:value(item, "remote_argument", 0),
		}
	end
	if (arguments.n or #arguments) > self.limits.remote_arguments then
		self:_drop("remote_arguments_limit")
	end
	return result
end

function Sanitizer:recordValue(value, depth, context)
	depth = depth or 0
	if type(value) ~= "table" then
		return self:value(value, "value", depth, context)
	end
	if depth >= self.limits.table_depth then
		self:_drop("table_depth_limit")
		return { kind = "table", truncated = true }
	end
	local result = {}
	local count = 0
	for key, item in pairs(value) do
		count += 1
		if count > self.limits.table_entries then
			self:_drop("table_entries_limit")
			break
		end
		if type(key) == "number" then
			result[key] = self:recordValue(item, depth + 1, context)
		elseif type(key) == "string" and RECORD_VALUE_FIELDS[key] then
			if type(item) == "table" then
				result[key] = self:recordValue(item, depth + 1, context)
			else
				result[key] = self:value(item, key, depth + 1, context)
			end
		else
			self:_drop("non_allowlisted_value_field")
		end
	end
	return result
end

function Sanitizer:subject(subject)
	if type(subject) ~= "table" then
		self:_drop("invalid_subject")
		return nil
	end
	local path = self:path(subject.path_segments or {})
	if path == nil then
		return nil
	end
	return {
		category = self:string(tostring(subject.category or "unknown"), "category", nil),
		path_segments = path,
		class_name = self:string(tostring(subject.class_name or "unknown"), "class_name", nil),
		value_type = self:string(tostring(subject.value_type or "nil"), "value_type", nil),
	}
end

function Sanitizer:stats()
	local dropped = {}
	for reason, count in pairs(self.dropped) do
		dropped[reason] = count
	end
	return {
		policy_version = Constants.SANITIZATION_POLICY_VERSION,
		redaction_count = self.redactionCount,
		dropped_fields = dropped,
	}
end

return Sanitizer
end
__factories["Observers"] = function(__require)
local Observers = {}

local VALUE_BASE_CLASSES = table.freeze({
	BoolValue = "boolean",
	IntValue = "integer",
	NumberValue = "number",
	StringValue = "string",
	ObjectValue = "instance-ref",
	CFrameValue = "cframe-summary",
	Vector3Value = "vector3",
	Color3Value = "unknown",
	BrickColorValue = "unknown",
})

local function safeGetService(gameObject, name)
	local ok, service = pcall(function()
		return gameObject:GetService(name)
	end)
	if ok then
		return service
	end
	return nil
end

local function pathContainsBlockedUi(path)
	for _, segment in ipairs(path) do
		local candidate = string.lower(segment)
		if string.find(candidate, "chat", 1, true)
			or string.find(candidate, "playerlist", 1, true)
			or string.find(candidate, "leaderboard", 1, true)
		then
			return true
		end
	end
	return false
end

local function subjectFor(inspector, instance, category, explicitType)
	return {
		category = category,
		path_segments = inspector:_pathFor(instance),
		class_name = instance.ClassName,
		value_type = explicitType or "instance-ref",
	}
end

local function attributeSubject(inspector, instance, name, explicitType)
	local path = inspector:_pathFor(instance)
	table.insert(path, "@attribute:" .. name)
	return {
		category = "attribute",
		path_segments = path,
		class_name = instance.ClassName,
		value_type = explicitType,
	}
end

local function attachSignal(inspector, surface, signal, callback)
	if signal == nil then
		return false
	end
	local ok, connection = pcall(function()
		return signal:Connect(function(...)
			local callbackOk = pcall(callback, ...)
			if not callbackOk then
				inspector:_observerError(surface, "callback")
			end
		end)
	end)
	if not ok or connection == nil then
		inspector:_observerError(surface, "connect")
		return false
	end
	return inspector:_ownConnection(connection, surface)
end

local function observeAttributes(inspector, instance)
	if not inspector:_surfaceRequested("attributes") then
		return
	end
	local ok, attributes = pcall(function()
		return instance:GetAttributes()
	end)
	if ok then
		for name, value in pairs(attributes) do
			inspector:_emit("attributes", "observed", attributeSubject(inspector, instance, name, typeof(value)), {
				attribute_name = name,
				value = value,
			}, {})
		end
	end
	attachSignal(inspector, "attributes", instance.AttributeChanged, function(name)
		local readOk, value = pcall(function()
			return instance:GetAttribute(name)
		end)
		if readOk then
			inspector:_emit("attributes", "changed", attributeSubject(inspector, instance, name, typeof(value)), {
				attribute_name = name,
				value = value,
			}, {})
		end
	end)
end

local function observeValueBase(inspector, instance, outputSurface)
	outputSurface = outputSurface or "value_bases"
	if not inspector:_surfaceRequested(outputSurface) then
		return
	end
	local expectedType = VALUE_BASE_CLASSES[instance.ClassName]
	if expectedType == nil then
		return
	end
	local ok, value = pcall(function()
		return instance.Value
	end)
	if not ok then
		return
	end
	local subject = subjectFor(inspector, instance, "value-base", expectedType)
	inspector:_emit(outputSurface, "observed", subject, value, {})
	attachSignal(inspector, outputSurface, instance.Changed, function(newValue)
		inspector:_emit(outputSurface, "changed", subject, newValue, {})
	end)
end

local function observeTags(inspector, instance, collectionService)
	if not inspector:_surfaceRequested("tags") or collectionService == nil then
		return
	end
	local ok, tags = pcall(function()
		return collectionService:GetTags(instance)
	end)
	if not ok then
		return
	end
	for _, tag in ipairs(tags) do
		inspector:_emit("tags", "observed", subjectFor(inspector, instance, "configuration", "string"), tag, {})
		inspector:_observeTagSignals(collectionService, tag)
	end
end

local function observeUi(inspector, instance)
	if not inspector:_surfaceRequested("ui") or inspector:_isBlockedInstance(instance) then
		return
	end
	local path = inspector:_pathFor(instance)
	if pathContainsBlockedUi(path) then
		return
	end
	if instance:IsA("GuiObject") then
		local subject = subjectFor(inspector, instance, "ui", "boolean")
		inspector:_emit("ui", "observed", subject, { visible = instance.Visible }, {})
		attachSignal(inspector, "ui", instance:GetPropertyChangedSignal("Visible"), function()
			inspector:_emit("ui", "changed", subject, { visible = instance.Visible }, {})
		end)
	end
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		local textSubject = subjectFor(inspector, instance, "ui", "string")
		inspector:_emit("ui", "observed", textSubject, { ui_text = instance.Text }, {})
		attachSignal(inspector, "ui", instance:GetPropertyChangedSignal("Text"), function()
			inspector:_emit("ui", "changed", textSubject, { ui_text = instance.Text }, {})
		end)
	end
end

local function observeRemote(inspector, instance, dependencies)
	local inventoryRequested = inspector:_surfaceRequested("remote_inventory")
		and inspector:_capabilityEnabled("remote_inventory")
	local callsRequested = inspector:_surfaceRequested("remote_call_observation")
		and inspector:_capabilityEnabled("remote_call_observation")
	if not inventoryRequested and not callsRequested then
		return
	end
	if not instance:IsA("RemoteEvent") and not instance:IsA("RemoteFunction") then
		return
	end
	local subject = subjectFor(inspector, instance, "remote", "instance-ref")
	if inventoryRequested then
		inspector:_emit("remote_inventory", "appeared", subject, { direction = "unknown" }, {})
	end
	-- This observes only the standard inbound signal and never replaces handlers.
	if callsRequested and dependencies.allowRemoteCallObservation == true and instance:IsA("RemoteEvent") then
		attachSignal(inspector, "remote_call_observation", instance.OnClientEvent, function(...)
			inspector:_emit("remote_call_observation", "observed", subject, {
				direction = "server-to-client-observed",
				method = "OnClientEvent",
				arguments = inspector:_sanitizeRemoteArguments(table.pack(...)),
			}, {})
		end)
	end
end

local function observeTool(inspector, instance)
	if inspector:_surfaceRequested("tools") and instance:IsA("Tool") then
		inspector:_emit("tools", "observed", subjectFor(inspector, instance, "instance", "instance-ref"), nil, {})
	end
end

local function observeInstance(inspector, instance, collectionService, dependencies, appeared)
	if inspector:_isBlockedInstance(instance) then
		return
	end
	if inspector:_surfaceRequested("hierarchy") or inspector:_surfaceRequested("instances") then
		local surface = inspector:_surfaceRequested("hierarchy") and "hierarchy" or "instances"
		inspector:_emit(surface, appeared and "appeared" or "observed", subjectFor(inspector, instance, "instance", "instance-ref"), nil, {})
	end
	observeAttributes(inspector, instance)
	observeValueBase(inspector, instance)
	observeTags(inspector, instance, collectionService)
	observeUi(inspector, instance)
	observeRemote(inspector, instance, dependencies)
	observeTool(inspector, instance)
end

local function observeRoot(inspector, root, collectionService, dependencies)
	observeInstance(inspector, root, collectionService, dependencies, false)
	local ok, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if ok then
		for index, instance in ipairs(descendants) do
			if index > inspector:_scanLimit() then
				inspector:_markScanTruncated(root.ClassName)
				break
			end
			observeInstance(inspector, instance, collectionService, dependencies, false)
		end
	else
		inspector:_observerError("hierarchy", "initial_scan")
	end
	attachSignal(inspector, "hierarchy", root.DescendantAdded, function(instance)
		observeInstance(inspector, instance, collectionService, dependencies, true)
	end)
	attachSignal(inspector, "hierarchy", root.DescendantRemoving, function(instance)
		if not inspector:_isBlockedInstance(instance) then
			inspector:_emit("hierarchy", "disappeared", subjectFor(inspector, instance, "instance", "instance-ref"), nil, {})
		end
	end)
end

local function observeUiTree(inspector, playerGui)
	local function visit(instance)
		observeUi(inspector, instance)
	end
	visit(playerGui)
	local ok, descendants = pcall(function()
		return playerGui:GetDescendants()
	end)
	if ok then
		for index, instance in ipairs(descendants) do
			if index > inspector:_scanLimit() then
				inspector:_markScanTruncated("ui")
				break
			end
			visit(instance)
		end
	end
	attachSignal(inspector, "ui", playerGui.DescendantAdded, visit)
end

local function observeLocalContainer(inspector, container, surface)
	local connectionSurface = inspector:_surfaceRequested(surface) and surface or "value_bases"
	local function visit(instance, operation)
		if instance:IsA("Tool") or VALUE_BASE_CLASSES[instance.ClassName] ~= nil then
			inspector:_emit(surface, operation, subjectFor(inspector, instance, "instance", "instance-ref"), nil, {})
		end
		if inspector:_surfaceRequested("value_bases") then
			observeValueBase(inspector, instance, "value_bases")
		end
		if inspector:_surfaceRequested(surface) and VALUE_BASE_CLASSES[instance.ClassName] ~= nil then
			observeValueBase(inspector, instance, surface)
		end
	end
	visit(container, "observed")
	local ok, descendants = pcall(function()
		return container:GetDescendants()
	end)
	if ok then
		for index, instance in ipairs(descendants) do
			if index > inspector:_scanLimit() then
				inspector:_markScanTruncated(surface)
				break
			end
			visit(instance, "observed")
		end
	end
	attachSignal(inspector, connectionSurface, container.DescendantAdded, function(instance)
		visit(instance, "appeared")
	end)
	attachSignal(inspector, connectionSurface, container.DescendantRemoving, function(instance)
		if instance:IsA("Tool") or VALUE_BASE_CLASSES[instance.ClassName] ~= nil then
			inspector:_emit(surface, "disappeared", subjectFor(inspector, instance, "instance", "instance-ref"), nil, {})
		end
	end)
end

local function quantize(value, quantum)
	return math.floor(value / quantum + 0.5) * quantum
end

local function observeCharacter(inspector, character, runService)
	inspector:_setLocalCharacter(character)
	inspector:_emit("character", "appeared", subjectFor(inspector, character, "state", "instance-ref"), { state = "present" }, {})
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		local healthSubject = {
			category = "state",
			path_segments = { "$local_character", "$health" },
			class_name = "Humanoid",
			value_type = "number",
		}
		inspector:_emit("character", "observed", healthSubject, { health = math.floor(humanoid.Health * 10 + 0.5) / 10 }, {})
		attachSignal(inspector, "character", humanoid.HealthChanged, function(health)
			inspector:_emit("character", "changed", healthSubject, { health = math.floor(health * 10 + 0.5) / 10 }, {})
		end)
		attachSignal(inspector, "character", humanoid.Died, function()
			inspector:_emit("character", "changed", healthSubject, { health = 0, state = "died" }, {})
		end)
	end
	if runService ~= nil then
		local elapsed = 0
		local previous = nil
		attachSignal(inspector, "character", runService.Heartbeat, function(deltaSeconds)
			elapsed += deltaSeconds
			if elapsed < 1 then
				return
			end
			elapsed = 0
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart == nil or not rootPart:IsA("BasePart") then
				return
			end
			local position = rootPart.Position
			local current = {
				kind = "quantized-position",
				x = quantize(position.X, 16),
				y = quantize(position.Y, 16),
				z = quantize(position.Z, 16),
				quantum = 16,
			}
			local state = "sample"
			if previous ~= nil then
				local dx = current.x - previous.x
				local dy = current.y - previous.y
				local dz = current.z - previous.z
				if dx * dx + dy * dy + dz * dz >= 128 * 128 then
					state = "teleport-candidate"
				end
			end
			current.state = state
			inspector:_emit("character", previous == nil and "observed" or "changed", {
				category = "state",
				path_segments = { "$local_character", "$quantized_position" },
				class_name = "BasePart",
				value_type = "vector3",
			}, current, {})
			previous = current
		end)
	end
end

local function inputCategory(input)
	local inputType = tostring(input.UserInputType)
	if string.find(inputType, "Mouse", 1, true) then
		return "mouse"
	elseif string.find(inputType, "Touch", 1, true) then
		return "touch"
	elseif string.find(inputType, "Keyboard", 1, true) then
		return "keyboard"
	elseif string.find(inputType, "Gamepad", 1, true) then
		return "gamepad"
	end
	return nil
end

local function observeManualInteractions(inspector, userInputService)
	if not inspector:_surfaceRequested("manual_interactions")
		or not inspector:_capabilityEnabled("manual_input_correlation")
		or userInputService == nil
	then
		return
	end
	inspector:_markSurfaceStarted("manual_interactions")
	attachSignal(inspector, "manual_interactions", userInputService.InputBegan, function(input, processed)
		local category = inputCategory(input)
		if category == nil then
			return
		end
		local localRef = inspector:_emit("manual_interactions", "observed", {
			category = "unknown",
			path_segments = { "$operator_input", category },
			class_name = "InputObject",
			value_type = "enum",
		}, { input_category = category, processed = processed == true }, {})
		inspector:_setManualAction(localRef)
	end)
end

function Observers.attach(inspector, dependencies)
	local gameObject = dependencies.gameObject or game
	local players = dependencies.players or safeGetService(gameObject, "Players")
	local collectionService = dependencies.collectionService or safeGetService(gameObject, "CollectionService")
	local replicatedStorage = dependencies.replicatedStorage or safeGetService(gameObject, "ReplicatedStorage")
	local workspaceService = dependencies.workspace or safeGetService(gameObject, "Workspace")
	local runService = dependencies.runService or safeGetService(gameObject, "RunService")
	local userInputService = dependencies.userInputService or safeGetService(gameObject, "UserInputService")

	if inspector:_surfaceRequested("metadata") then
		inspector:_markSurfaceStarted("metadata")
		local source = { classification = "runtime" }
		local fields = {
			GameId = "game_id",
			PlaceId = "place_id",
		}
		for field, outputName in pairs(fields) do
			local ok, value = pcall(function()
				return gameObject[field]
			end)
			if ok and type(value) == "number" then
				source[outputName] = value
			end
		end
		inspector:_dropSensitiveField("job_id_without_hmac")
		inspector:_setSource(source)
		inspector:_emit("metadata", "observed", {
			category = "identifier",
			path_segments = { "game" },
			class_name = "DataModel",
			value_type = "map-summary",
		}, source, {})
	end

	local localPlayer = nil
	if players ~= nil then
		localPlayer = players.LocalPlayer
		if localPlayer ~= nil then
			inspector:_setLocalPlayer(localPlayer)
			inspector:_addPrivateName(localPlayer.Name)
			inspector:_setLocalCharacter(localPlayer.Character)
			if inspector:_surfaceRequested("character") then
				inspector:_markSurfaceStarted("character")
				if localPlayer.Character ~= nil then
					observeCharacter(inspector, localPlayer.Character, runService)
				end
				attachSignal(inspector, "character", localPlayer.CharacterAdded, function(character)
					observeCharacter(inspector, character, runService)
				end)
				attachSignal(inspector, "character", localPlayer.CharacterRemoving, function(character)
					inspector:_emit("character", "disappeared", subjectFor(inspector, character, "state", "instance-ref"), { state = "absent" }, {})
					inspector:_setLocalCharacter(nil)
				end)
			end
			local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
			if playerGui ~= nil and inspector:_surfaceRequested("ui") then
				inspector:_markSurfaceStarted("ui")
				observeUiTree(inspector, playerGui)
			elseif inspector:_surfaceRequested("ui") then
				inspector:_markSurfaceUnavailable("ui", "local_player_gui_unavailable")
			end
			local backpack = localPlayer:FindFirstChildOfClass("Backpack")
			if backpack ~= nil and (inspector:_surfaceRequested("inventory") or inspector:_surfaceRequested("value_bases")) then
				inspector:_markSurfaceStarted("inventory")
				observeLocalContainer(inspector, backpack, "inventory")
			elseif inspector:_surfaceRequested("inventory") then
				inspector:_markSurfaceUnavailable("inventory", "local_backpack_unavailable")
			end
			local leaderstats = localPlayer:FindFirstChild("leaderstats")
			if leaderstats ~= nil and (inspector:_surfaceRequested("stats") or inspector:_surfaceRequested("value_bases")) then
				inspector:_markSurfaceStarted("stats")
				observeLocalContainer(inspector, leaderstats, "stats")
			elseif inspector:_surfaceRequested("stats") then
				inspector:_markSurfaceUnavailable("stats", "local_leaderstats_unavailable")
			end
		end
	end
	observeManualInteractions(inspector, userInputService)
	if localPlayer == nil then
		for _, surface in ipairs({ "character", "ui", "inventory", "stats" }) do
			if inspector:_surfaceRequested(surface) then
				inspector:_markSurfaceUnavailable(surface, "local_player_unavailable")
			end
		end
	end
	if inspector:_surfaceRequested("manual_interactions") and userInputService == nil then
		inspector:_markSurfaceUnavailable("manual_interactions", "user_input_service_unavailable")
	end

	local roots = { replicatedStorage, workspaceService }
	for _, root in ipairs(roots) do
		if root ~= nil then
			observeRoot(inspector, root, collectionService, dependencies)
		end
	end
	local supported = {
		metadata = true, hierarchy = true, instances = true, attributes = true,
		value_bases = true, tags = true, tools = true,
		remote_inventory = true, remote_call_observation = true, errors = true,
	}
	local locallyHandled = {
		character = true, ui = true, inventory = true, stats = true,
		manual_interactions = true,
	}
	for surface, requested in pairs(inspector:_requestedSurfaces()) do
		if requested and supported[surface] then
			local hasRoot = replicatedStorage ~= nil or workspaceService ~= nil
			if hasRoot or surface == "metadata" or surface == "character" or surface == "ui" then
				inspector:_markSurfaceStarted(surface)
			else
				inspector:_markSurfaceUnavailable(surface, "runtime_surface_unavailable")
			end
		elseif requested and not locallyHandled[surface] then
			inspector:_markSurfaceUnavailable(surface, "observer_not_implemented")
		end
	end
end

return Observers
end
__factories["Inspector"] = function(__require)
local BoundedBuffer = __require("BoundedBuffer")
local Config = __require("Config")
local Constants = __require("Constants")
local Observers = __require("Observers")
local Sanitizer = __require("Sanitizer")

local Inspector = {}
Inspector.__index = Inspector

local function resultFailure(code, field)
	return {
		ok = false,
		error = {
			code = code,
			field = field,
			count = 1,
		},
	}
end

local function deepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] ~= nil then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for key, item in pairs(value) do
		copy[deepCopy(key, seen)] = deepCopy(item, seen)
	end
	return copy
end

local function deepFreeze(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return value
	end
	seen[value] = true
	for key, item in pairs(value) do
		deepFreeze(key, seen)
		deepFreeze(item, seen)
	end
	return table.freeze(value)
end

local function defaultClockUs()
	return math.floor(os.clock() * 1000000)
end

local function defaultUtcNow()
	local ok, value = pcall(function()
		return DateTime.now():ToIsoDate()
	end)
	if ok then
		return value
	end
	return nil
end

function Inspector.new(inputConfig, dependencies)
	local validated = Config.validate(inputConfig)
	if not validated.ok then
		return validated
	end
	dependencies = dependencies or {}
	if validated.value.capabilities.remote_call_observation
		and dependencies.allowRemoteCallObservation ~= true
	then
		return resultFailure("DISCOVERY_CAPABILITY_UNSUPPORTED", "capabilities.remote_call_observation")
	end
	local self = setmetatable({}, Inspector)
	self._config = validated.value
	self._dependencies = dependencies
	self._clockUs = dependencies.clockUs or defaultClockUs
	self._utcNow = dependencies.utcNow or defaultUtcNow
	self._scheduler = dependencies.scheduler
	if self._scheduler == nil and task ~= nil then
		self._scheduler = {
			delay = task.delay,
			cancel = task.cancel,
		}
	end
	self._state = "validated"
	self._startedClockUs = nil
	self._lastUs = 0
	self._nextLocalRef = 1
	self._connections = {}
	self._timeoutTask = nil
	self._tagSignals = {}
	self._coverage = {}
	self._source = { classification = "runtime" }
	self._localPlayer = nil
	self._localCharacter = nil
	self._sealedSnapshot = nil
	self._lastManualAction = nil
	self._cleanupComplete = false
	self._sanitizer = Sanitizer.new(self._config.limits, self._config.redaction_patterns)
	self._buffer = BoundedBuffer.new(self._config.limits.raw_queue_records)
	for surface, requested in pairs(self._config.surfaces) do
		self._coverage[surface] = {
			requested = requested,
			capability_available = true,
			observer_started = false,
			observed_count = 0,
			first_t_us = nil,
			last_t_us = nil,
			truncated = false,
			dropped_count = 0,
			unavailable_reason = nil,
		}
	end
	return { ok = true, value = self }
end

function Inspector:state()
	return self._state
end

function Inspector:_requestedSurfaces()
	return self._config.surfaces
end

function Inspector:_surfaceRequested(surface)
	return self._config.surfaces[surface] == true
end

function Inspector:_capabilityEnabled(capability)
	return self._config.capabilities[capability] == true
end

function Inspector:_markSurfaceStarted(surface)
	local coverage = self._coverage[surface]
	if coverage ~= nil then
		coverage.observer_started = true
	end
end

function Inspector:_markSurfaceUnavailable(surface, reason)
	local coverage = self._coverage[surface]
	if coverage ~= nil then
		coverage.capability_available = false
		coverage.unavailable_reason = reason
	end
end

function Inspector:_nowUs()
	local ok, current = pcall(self._clockUs)
	if not ok or type(current) ~= "number" or current ~= current then
		return nil
	end
	local relative = math.floor(current - self._startedClockUs)
	if relative < self._lastUs then
		return nil
	end
	self._lastUs = relative
	return relative
end

function Inspector:_emit(surface, operation, subject, value, contextRefs)
	if self._state ~= "observing" then
		return false
	end
	if not self:_surfaceRequested(surface) and surface ~= "errors" then
		return false
	end
	local tUs = self:_nowUs()
	if tUs == nil then
		self._state = "failed"
		self:_cleanup()
		self._buffer:clear()
		return false
	end
	local sanitizedSubject = self._sanitizer:subject(subject)
	if sanitizedSubject == nil then
		return false
	end
	local refs = {}
	for _, reference in ipairs(contextRefs or {}) do
		if type(reference) == "number" and reference % 1 == 0 and reference > 0 and reference < self._nextLocalRef then
			table.insert(refs, reference)
		end
	end
	if surface ~= "manual_interactions" and self._lastManualAction ~= nil then
		local manual = self._lastManualAction
		if tUs - manual.t_us <= 2000000 and manual.local_ref < self._nextLocalRef then
			local alreadyPresent = false
			for _, reference in ipairs(refs) do
				alreadyPresent = alreadyPresent or reference == manual.local_ref
			end
			if not alreadyPresent then
				table.insert(refs, manual.local_ref)
			end
		else
			self._lastManualAction = nil
		end
	end
	local record = {
		local_ref = self._nextLocalRef,
		t_us = tUs,
		surface = surface,
		operation = operation,
		subject = sanitizedSubject,
		value = self._sanitizer:recordValue(value, 0, {
			surface = surface,
			value_type = sanitizedSubject.value_type,
		}),
		context_refs = refs,
	}
	local disposition = self._buffer:push(record)
	if disposition == "kept" then
		self._nextLocalRef += 1
	end
	local coverage = self._coverage[surface]
	if coverage ~= nil then
		coverage.observed_count = math.min(Constants.COUNTER_MAX, coverage.observed_count + 1)
		coverage.first_t_us = coverage.first_t_us or tUs
		coverage.last_t_us = tUs
		if disposition == "dropped" then
			coverage.truncated = true
			coverage.dropped_count = math.min(Constants.COUNTER_MAX, coverage.dropped_count + 1)
		end
	end
	if disposition == "kept" then
		return record.local_ref
	end
	return nil
end

function Inspector:_observerError(surface, operation)
	self:_emit("errors", "error", {
		category = "unknown",
		path_segments = { surface, operation },
		class_name = "ObserverError",
		value_type = "nil",
	}, nil, {})
end

function Inspector:_dropSensitiveField(reason)
	self._sanitizer:dropField(reason)
end

function Inspector:_setSource(source)
	self._source = deepCopy(source)
end

function Inspector:_setManualAction(localRef)
	if type(localRef) == "number" then
		self._lastManualAction = { local_ref = localRef, t_us = self._lastUs }
	end
end

function Inspector:_sanitizeRemoteArguments(arguments)
	return self._sanitizer:remoteArguments(arguments)
end

function Inspector:_addPrivateName(name)
	self._sanitizer:addEphemeralPattern(name)
end

function Inspector:_setLocalPlayer(player)
	self._localPlayer = player
end

function Inspector:_setLocalCharacter(character)
	self._localCharacter = character
	if character ~= nil then
		self:_addPrivateName(character.Name)
	end
end

function Inspector:_pathFor(instance)
	if self._localCharacter ~= nil then
		local ok, isCharacter = pcall(function()
			return instance == self._localCharacter or instance:IsDescendantOf(self._localCharacter)
		end)
		if ok and isCharacter then
			local suffix = {}
			local current = instance
			while current ~= nil and current ~= self._localCharacter and #suffix < self._config.limits.path_segments - 1 do
				table.insert(suffix, 1, current.Name)
				current = current.Parent
			end
			table.insert(suffix, 1, "$local_character")
			return suffix
		end
	end
	local reversed = {}
	local current = instance
	while current ~= nil and #reversed < self._config.limits.path_segments do
		if current == self._localPlayer then
			table.insert(reversed, "$local_player")
		else
			table.insert(reversed, current.Name)
		end
		current = current.Parent
	end
	local path = {}
	for index = #reversed, 1, -1 do
		table.insert(path, reversed[index])
	end
	return path
end

function Inspector:_isBlockedInstance(instance)
	if type(self._dependencies.isOwnedInstance) == "function" then
		local ok, owned = pcall(self._dependencies.isOwnedInstance, instance)
		if ok and owned == true then
			return true
		end
	end
	if instance:IsA("TextBox") or instance:IsA("Player") then
		return true
	end
	local current = instance
	while current ~= nil do
		if current:IsA("Model") and current ~= self._localCharacter then
			local ok, humanoid = pcall(function()
				return current:FindFirstChildOfClass("Humanoid")
			end)
			if ok and humanoid ~= nil then
				return true
			end
		end
		current = current.Parent
	end
	return false
end

function Inspector:_scanLimit()
	return math.min(10000, self._config.limits.raw_queue_records * 2)
end

function Inspector:_markScanTruncated(surface)
	local coverage = self._coverage[surface] or self._coverage.hierarchy
	if coverage ~= nil then
		coverage.truncated = true
		coverage.dropped_count = math.min(Constants.COUNTER_MAX, coverage.dropped_count + 1)
	end
	self._sanitizer:dropField("initial_scan_limit_" .. string.lower(surface))
end

function Inspector:_ownConnection(connection, surface)
	if #self._connections >= self._config.limits.connections then
		pcall(function()
			connection:Disconnect()
		end)
		self:_markScanTruncated(surface)
		return false
	end
	table.insert(self._connections, connection)
	return true
end

function Inspector:_observeTagSignals(collectionService, tag)
	if self._tagSignals[tag] then
		return
	end
	self._tagSignals[tag] = true
	local added = collectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		if not self:_isBlockedInstance(instance) then
			self:_emit("tags", "appeared", {
				category = "configuration",
				path_segments = self:_pathFor(instance),
				class_name = instance.ClassName,
				value_type = "string",
			}, tag, {})
		end
	end)
	self:_ownConnection(added, "tags")
	local removed = collectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		if not self:_isBlockedInstance(instance) then
			self:_emit("tags", "disappeared", {
				category = "configuration",
				path_segments = self:_pathFor(instance),
				class_name = instance.ClassName,
				value_type = "string",
			}, tag, {})
		end
	end)
	self:_ownConnection(removed, "tags")
end

function Inspector:start()
	if self._state ~= "validated" then
		return resultFailure("DISCOVERY_CONFIG_INVALID", "lifecycle.start")
	end
	local ok, initial = pcall(self._clockUs)
	if not ok or type(initial) ~= "number" or initial ~= initial then
		self._state = "failed"
		return resultFailure("DISCOVERY_CLOCK_INVALID", "clock")
	end
	self._startedClockUs = math.floor(initial)
	self._lastUs = 0
	self._state = "observing"
	local startedAt = self._utcNow()
	self._startedAtUtc = type(startedAt) == "string" and startedAt or nil
	local attachOk = pcall(Observers.attach, self, self._dependencies)
	if not attachOk then
		self._state = "failed"
		self:_cleanup()
		self._buffer:clear()
		return resultFailure("DISCOVERY_INTERNAL_ERROR", "observer_attach")
	end
	if self._scheduler ~= nil and type(self._scheduler.delay) == "function" then
		self._timeoutTask = self._scheduler.delay(self._config.limits.duration_seconds, function()
			self._timeoutTask = nil
			self:stop()
		end)
	end
	return { ok = true, value = { state = self._state } }
end

function Inspector:_cleanup()
	local complete = true
	local remainingConnections = {}
	for index = #self._connections, 1, -1 do
		local connection = self._connections[index]
		local ok = pcall(function()
			connection:Disconnect()
		end)
		complete = complete and ok
		if not ok then
			table.insert(remainingConnections, 1, connection)
		end
	end
	self._connections = remainingConnections
	if self._timeoutTask ~= nil then
		local timeoutTask = self._timeoutTask
		local current = coroutine.running()
		if timeoutTask ~= current and self._scheduler ~= nil and type(self._scheduler.cancel) == "function" then
			local ok = pcall(self._scheduler.cancel, timeoutTask)
			complete = complete and ok
			if ok then
				self._timeoutTask = nil
			end
		elseif timeoutTask == current then
			self._timeoutTask = nil
		end
	end
	complete = complete and #self._connections == 0 and self._timeoutTask == nil
	if complete then
		table.clear(self._tagSignals)
	end
	self._cleanupComplete = complete
	return complete
end

function Inspector:stop()
	if self._state == "stopped" then
		local cleanup = self._sealedSnapshot ~= nil and deepCopy(self._sealedSnapshot.cleanup) or {
			complete = true,
			connections = 0,
			hooks = 0,
			tasks = 0,
			buffers = 0,
		}
		return { ok = true, value = { state = "stopped", cleanup = cleanup } }
	end
	if self._state ~= "observing" then
		return resultFailure("DISCOVERY_CONFIG_INVALID", "lifecycle.stop")
	end
	self._state = "stopping"
	local cleanupComplete = self:_cleanup()
	local endedUs = self._lastUs
	local records = self._buffer:snapshotAndClear()
	local truncation = self._buffer:stats()
	self._sealedSnapshot = deepFreeze({
		contract_id = Constants.CONTRACT_ID,
		contract_version = Constants.CONTRACT_VERSION,
		schema_version = Constants.SCHEMA_VERSION,
		inspector_version = Constants.INSPECTOR_VERSION,
		mode = "passive",
		capabilities = deepCopy(self._config.capabilities),
		source = deepCopy(self._source),
		clock = {
			started_at_utc = self._startedAtUtc,
			quality = self._startedAtUtc ~= nil and "client-untrusted" or "unavailable",
			resolution_us = 1,
			ended_t_us = endedUs,
		},
		limits = deepCopy(self._config.limits),
		duration_seconds = self._config.limits.duration_seconds,
		retention_class = "local-ephemeral",
		retention_seconds = self._config.retention_seconds,
		surfaces = deepCopy(self._config.surface_list),
		records = records,
		coverage = deepCopy(self._coverage),
		sanitization = self._sanitizer:stats(),
		truncation = truncation,
		cleanup = {
			complete = cleanupComplete,
			connections = 0,
			hooks = 0,
			tasks = 0,
			buffers = 0,
		},
	})
	if not cleanupComplete then
		self._state = "failed"
		return resultFailure("DISCOVERY_CLEANUP_FAILED", "cleanup")
	end
	self._state = "stopped"
	return { ok = true, value = { state = "stopped", cleanup = deepCopy(self._sealedSnapshot.cleanup) } }
end

function Inspector:exportSnapshot()
	if self._state ~= "stopped" or self._sealedSnapshot == nil then
		return resultFailure("DISCOVERY_CONFIG_INVALID", "lifecycle.export")
	end
	if self._sealedSnapshot.retention_seconds == 0 or self._sealedSnapshot.clock.started_at_utc == nil then
		return resultFailure("DISCOVERY_RETENTION_INVALID", "retention")
	end
	return { ok = true, value = deepCopy(self._sealedSnapshot) }
end

function Inspector:unload()
	if self._state == "failed" then
		local cleanupComplete = self:_cleanup()
		if not cleanupComplete then
			return resultFailure("DISCOVERY_CLEANUP_FAILED", "cleanup")
		end
		self._buffer:clear()
		self._sealedSnapshot = nil
		self._state = "stopped"
		return { ok = true, value = { state = "stopped" } }
	end
	if self._state == "validated" then
		self:_cleanup()
		self._buffer:clear()
		self._state = "stopped"
		return { ok = true, value = { state = "stopped" } }
	end
	local result = self:stop()
	if result.ok then
		self._sealedSnapshot = nil
	end
	return result
end

return Inspector
end
__factories["init"] = function(__require)
-- Public entry point. This module performs no work until the caller explicitly starts it.
return __require("Inspector")
end
__factories["MobileApp"] = function(__require)
local Inspector = __require("Inspector")

local MobileApp = {}

local SENTINEL_NAME = "InfinityUniversalInspector_v1"
local SENTINEL_IDENTITY = "game-discovery-inspector-artifact|0.1.0-development.1"
local MAX_EXPORT_BYTES = 1048576
local CHUNK_BYTES = 16384
local MAX_CHUNKS = 64
local JSON_NULL_MARKER = string.rep("UGC_JSON_NULL_SENTINEL_", 16)
local JSON_EMPTY_OBJECT_MARKER = string.rep("UGC_JSON_EMPTY_OBJECT_SENTINEL_", 10)
local pendingUiInstances = nil

local function copyForJson(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] ~= nil then
		error("DISCOVERY_ARTIFACT_JSON_ENCODE_FAILED")
	end
	local copy = {}
	seen[value] = copy
	for key, item in pairs(value) do
		copy[key] = copyForJson(item, seen)
	end
	seen[value] = nil
	return copy
end

local function prepareJsonSnapshot(snapshot)
	local copy = copyForJson(snapshot)
	local nullCount = 0
	local emptyObjectCount = 0
	local function nullable(container, key)
		if container[key] == nil then
			container[key] = JSON_NULL_MARKER
			nullCount += 1
		end
	end
	nullable(copy.clock, "started_at_utc")
	nullable(copy.truncation, "first_dropped_t_us")
	local function preserveEmptyObject(container)
		if next(container) == nil then
			container[JSON_EMPTY_OBJECT_MARKER] = true
			emptyObjectCount += 1
		end
	end
	preserveEmptyObject(copy.truncation.surfaces)
	preserveEmptyObject(copy.sanitization.dropped_fields)
	for _, coverage in pairs(copy.coverage) do
		nullable(coverage, "first_t_us")
		nullable(coverage, "last_t_us")
		nullable(coverage, "unavailable_reason")
	end
	return copy, nullCount, emptyObjectCount
end

local function defaultConfig()
	return {
		contract_version = "v1-draft",
		schema_version = 1,
		mode = "passive",
		retention_class = "local-ephemeral",
		retention_seconds = 86400,
		duration_seconds = 1800,
		capabilities = {
			remote_call_observation = false,
			active_diagnostics = false,
		},
		surfaces = {
			"metadata", "hierarchy", "instances", "attributes", "value_bases",
			"tags", "character", "zones", "inventory", "stats", "tools", "ui",
			"manual_interactions", "cycles", "errors", "remote_inventory",
		},
	}
end

local function newInstance(className, properties, parent)
	local object = Instance.new(className)
	if pendingUiInstances ~= nil then
		table.insert(pendingUiInstances, object)
	end
	for key, value in pairs(properties) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function findPlayerGui(players)
	local player = players.LocalPlayer
	if player == nil then
		return nil, "DISCOVERY_ARTIFACT_UI_UNAVAILABLE"
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui == nil then
		local ok, value = pcall(function()
			return player:WaitForChild("PlayerGui", 10)
		end)
		if ok then
			playerGui = value
		end
	end
	if playerGui == nil then
		return nil, "DISCOVERY_ARTIFACT_UI_UNAVAILABLE"
	end
	return playerGui, nil
end

local function errorApp(code)
	warn(code)
	return { state = function() return "error" end, unload = function() return true end }
end

local function launchInternal()
	local servicesOk, players, httpService = pcall(function()
		return game:GetService("Players"), game:GetService("HttpService")
	end)
	if not servicesOk or players == nil or httpService == nil then
		return errorApp("DISCOVERY_ARTIFACT_UI_UNAVAILABLE")
	end
	local playerGui, guiError = findPlayerGui(players)
	if playerGui == nil then
		return errorApp(guiError)
	end

	local old = playerGui:FindFirstChild(SENTINEL_NAME)
	if old ~= nil then
		if old:IsA("BindableFunction") then
			local identityOk, identity = pcall(function()
				return old:Invoke("identity")
			end)
			if not identityOk or identity ~= SENTINEL_IDENTITY then
				return errorApp("DISCOVERY_ARTIFACT_INSTANCE_CONFLICT")
			end
			local cleanupOk, cleanupResult = pcall(function()
				return old:Invoke("replace")
			end)
			if not cleanupOk or cleanupResult ~= true then
				return errorApp("DISCOVERY_ARTIFACT_INSTANCE_CONFLICT")
			end
		else
			return errorApp("DISCOVERY_ARTIFACT_INSTANCE_CONFLICT")
		end
	end

	local owned = setmetatable({}, { __mode = "k" })
	local connections = {}
	local active = true
	local unloading = false
	local cleanupSucceeded = false
	local inspector = nil
	local exportText = nil
	local exportChunks = {}
	local chunkIndex = 1
	local state = "ready"

	local sentinel = newInstance("BindableFunction", { Name = SENTINEL_NAME }, playerGui)
	owned[sentinel] = true

	local screen = newInstance("ScreenGui", {
		Name = "InfinityUniversalInspector",
		ResetOnSpawn = false,
		DisplayOrder = 2147483000,
		IgnoreGuiInset = false,
	}, playerGui)
	owned[screen] = true
	local frame = newInstance("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(0.94, 0.72),
		Position = UDim2.fromScale(0.03, 0.14),
		BackgroundColor3 = Color3.fromRGB(20, 24, 32),
		BorderSizePixel = 0,
	}, screen)
	owned[frame] = true
	local title = newInstance("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1,
		Text = "Universal Game Inspector",
		TextColor3 = Color3.fromRGB(245, 248, 255),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, frame)
	owned[title] = true
	local status = newInstance("TextLabel", {
		Name = "Status",
		Size = UDim2.new(1, -20, 0, 50),
		Position = UDim2.new(0, 10, 0, 48),
		BackgroundTransparency = 1,
		Text = "READY — passive; limits 4096 records / 1048576 bytes / timeout 1800s",
		TextColor3 = Color3.fromRGB(145, 205, 255),
		TextWrapped = true,
		TextScaled = true,
		Font = Enum.Font.Gotham,
	}, frame)
	owned[status] = true

	local function button(name, text, x)
		local value = newInstance("TextButton", {
			Name = name,
			Size = UDim2.new(0.19, -5, 0, 48),
			Position = UDim2.new(x, 10, 0, 102),
			BackgroundColor3 = Color3.fromRGB(45, 88, 125),
			Text = text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, frame)
		owned[value] = true
		return value
	end

	local startButton = button("Start", "Start", 0)
	local stopButton = button("Stop", "Stop", 0.2)
	local exportButton = button("Export", "Export", 0.4)
	local copyButton = button("Copy", "Copy", 0.6)
	local chunksButton = button("Chunks", "Chunks", 0.8)
	local output = newInstance("TextBox", {
		Name = "ExportText",
		Size = UDim2.new(1, -20, 1, -270),
		Position = UDim2.new(0, 10, 0, 160),
		BackgroundColor3 = Color3.fromRGB(10, 13, 18),
		TextColor3 = Color3.fromRGB(230, 235, 245),
		Text = "Exported JSON appears here. Long-press and Select All to copy manually.",
		ClearTextOnFocus = false,
		MultiLine = true,
		TextEditable = true,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Code,
		TextSize = 14,
	}, frame)
	owned[output] = true
	local chunkOutput = newInstance("TextBox", {
		Name = "ChunkText",
		Size = UDim2.new(1, -20, 1, -270),
		Position = UDim2.new(0, 10, 0, 160),
		BackgroundColor3 = Color3.fromRGB(10, 13, 18),
		TextColor3 = Color3.fromRGB(230, 235, 245),
		Text = "",
		Visible = false,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextEditable = true,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Code,
		TextSize = 14,
	}, frame)
	owned[chunkOutput] = true
	local function navButton(name, text, x)
		local value = newInstance("TextButton", {
			Name = name,
			Size = UDim2.new(0.24, -5, 0, 44),
			Position = UDim2.new(x, 10, 1, -100),
			BackgroundColor3 = Color3.fromRGB(50, 68, 88),
			Text = text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, frame)
		owned[value] = true
		return value
	end
	local previousButton = navButton("PreviousChunk", "Previous", 0)
	local nextButton = navButton("NextChunk", "Next", 0.25)
	local selectButton = navButton("SelectChunk", "Select", 0.5)
	local printButton = navButton("PrintChunks", "Print", 0.75)
	local unloadButton = newInstance("TextButton", {
		Name = "Unload",
		Size = UDim2.new(1, -20, 0, 42),
		Position = UDim2.new(0, 10, 1, -50),
		BackgroundColor3 = Color3.fromRGB(110, 48, 54),
		Text = "Unload / Cleanup",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Font = Enum.Font.GothamBold,
	}, frame)
	owned[unloadButton] = true

	local function setState(nextState, message, isError)
		state = nextState
		status.Text = string.upper(nextState) .. " — " .. message
		status.TextColor3 = isError and Color3.fromRGB(255, 125, 125) or Color3.fromRGB(145, 205, 255)
	end

	local function isOwnedInstance(instance)
		local current = instance
		while current ~= nil do
			if owned[current] then
				return true
			end
			current = current.Parent
		end
		return false
	end

	local function cleanup()
		if cleanupSucceeded then
			return true
		end
		if unloading then
			return false
		end
		unloading = true
		active = false
		state = "unloading"
		if inspector ~= nil then
			local ok, result = pcall(function()
				return inspector:unload()
			end)
			if not ok or type(result) ~= "table" or result.ok ~= true then
				state = "error"
				status.Text = "ERROR — DISCOVERY_CLEANUP_FAILED"
				status.TextColor3 = Color3.fromRGB(255, 125, 125)
				warn("DISCOVERY_CLEANUP_FAILED")
				unloading = false
				return false
			end
			inspector = nil
		end
		exportText = nil
		table.clear(exportChunks)
		output.Text = ""
		chunkOutput.Text = ""
		local complete = true
		local remainingConnections = {}
		for index = #connections, 1, -1 do
			local connection = connections[index]
			local ok = pcall(function()
				connection:Disconnect()
			end)
			complete = complete and ok
			if not ok then
				table.insert(remainingConnections, 1, connection)
			end
		end
		connections = remainingConnections
		if not complete then
			state = "error"
			status.Text = "ERROR — DISCOVERY_CLEANUP_FAILED"
			status.TextColor3 = Color3.fromRGB(255, 125, 125)
			warn("DISCOVERY_CLEANUP_FAILED")
			unloading = false
			return false
		end
		local screenOk = pcall(function()
			screen:Destroy()
		end)
		local screenGone = screenOk and screen.Parent == nil
		if not screenGone then
			state = "error"
			warn("DISCOVERY_CLEANUP_FAILED")
			unloading = false
			return false
		end
		local sentinelOk = pcall(function()
			sentinel:Destroy()
		end)
		local sentinelGone = sentinelOk and sentinel.Parent == nil
		cleanupSucceeded = screenGone and sentinelGone
		state = cleanupSucceeded and "unloaded" or "error"
		if not cleanupSucceeded then
			warn("DISCOVERY_CLEANUP_FAILED")
		end
		unloading = false
		return cleanupSucceeded
	end

	sentinel.OnInvoke = function(command)
		if command == "identity" then
			return SENTINEL_IDENTITY
		end
		if command == "unload" then
			return cleanup()
		end
		if command == "replace" then
			return cleanup()
		end
		return false
	end

	local function connect(buttonInstance, callback)
		table.insert(connections, buttonInstance.Activated:Connect(callback))
	end

	local function rebuildChunks(text)
		local chunks = {}
		local first = 1
		while first <= #text do
			local last = math.min(first + CHUNK_BYTES - 1, #text)
			while last < #text do
				local nextByte = string.byte(text, last + 1)
				if nextByte == nil or nextByte < 128 or nextByte >= 192 then
					break
				end
				last -= 1
			end
			if last < first then
				return nil, "DISCOVERY_ARTIFACT_JSON_ENCODE_FAILED"
			end
			table.insert(chunks, string.sub(text, first, last))
			if #chunks > MAX_CHUNKS then
				return nil, "DISCOVERY_ARTIFACT_EXPORT_LIMIT_EXCEEDED"
			end
			first = last + 1
		end
		return chunks, nil
	end

	local function showChunk(index)
		if exportText == nil or #exportChunks == 0 then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		chunkIndex = math.max(1, math.min(index, #exportChunks))
		local offset = 0
		for prior = 1, chunkIndex - 1 do
			offset += #exportChunks[prior]
		end
		output.Visible = false
		chunkOutput.Visible = true
		chunkOutput.Text = exportChunks[chunkIndex]
		setState("export_ready", string.format(
			"CHUNK %d/%d OFFSET %d LENGTH %d",
			chunkIndex, #exportChunks, offset, #exportChunks[chunkIndex]
		), false)
	end

	connect(startButton, function()
		if state ~= "ready" then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		local created = Inspector.new(defaultConfig(), {
			isOwnedInstance = isOwnedInstance,
			scheduler = {
				delay = function(seconds, callback)
					return task.delay(seconds, function()
						callback()
						if active and inspector ~= nil and inspector:state() == "stopped" then
							setState("stopped", "CAPTURE_TIMEOUT_REACHED", false)
						end
					end)
				end,
				cancel = function(thread)
					task.cancel(thread)
				end,
			},
		})
		if not created.ok then
			setState("error", created.error.code, true)
			return
		end
		inspector = created.value
		local started = inspector:start()
		if not started.ok then
			setState("error", started.error.code, true)
			return
		end
		exportText = nil
		output.Text = "Capture is active. Interact normally; the inspector remains passive."
		setState("capturing", "passive capture active; automatic timeout is 1800 seconds", false)
	end)

	connect(stopButton, function()
		if inspector == nil then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		if state == "stopped" or state == "export_ready" then
			setState(state, "STOP_IDEMPOTENT", false)
			return
		end
		if state ~= "capturing" then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		setState("stopping", "disconnecting observers", false)
		local stopped = inspector:stop()
		if not stopped.ok then
			setState("error", stopped.error.code, true)
			return
		end
		setState("stopped", "DURATION_LIMIT 1800 CLEANUP COMPLETE; press Export", false)
	end)

	connect(exportButton, function()
		if inspector == nil then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		if state ~= "stopped" then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		local exported = inspector:exportSnapshot()
		if not exported.ok then
			setState("error", exported.error.code, true)
			return
		end
		local ok, encoded, expectedNulls, expectedEmptyObjects = pcall(function()
			local jsonSnapshot, nullCount, emptyObjectCount = prepareJsonSnapshot(exported.value)
			return httpService:JSONEncode(jsonSnapshot), nullCount, emptyObjectCount
		end)
		if not ok or type(encoded) ~= "string" then
			setState("error", "DISCOVERY_ARTIFACT_JSON_ENCODE_FAILED", true)
			return
		end
		local marker = '"' .. JSON_NULL_MARKER .. '"'
		local replaced
		encoded, replaced = string.gsub(encoded, marker, "null")
		if replaced ~= expectedNulls then
			setState("error", "DISCOVERY_ARTIFACT_JSON_ENCODE_FAILED", true)
			return
		end
		local emptyObjectMarker = '{"' .. JSON_EMPTY_OBJECT_MARKER .. '":true}'
		encoded, replaced = string.gsub(encoded, emptyObjectMarker, "{}")
		if replaced ~= expectedEmptyObjects then
			setState("error", "DISCOVERY_ARTIFACT_JSON_ENCODE_FAILED", true)
			return
		end
		if #encoded > MAX_EXPORT_BYTES then
			setState("error", "DISCOVERY_ARTIFACT_EXPORT_LIMIT_EXCEEDED", true)
			return
		end
		exportText = encoded
		local chunks, chunkError = rebuildChunks(encoded)
		if chunks == nil then
			setState("error", chunkError, true)
			return
		end
		exportChunks = chunks
		chunkIndex = 1
		output.Text = encoded
		output.Visible = true
		chunkOutput.Visible = false
		output.CursorPosition = 1
		output.SelectionStart = 1
		setState("export_ready", string.format(
			"BYTES %d RECORDS %d TRUNCATED %s; Copy or select manually",
			#encoded, #exported.value.records, exported.value.truncation.occurred and "YES" or "NO"
		), false)
	end)

	connect(copyButton, function()
		if state ~= "export_ready" or exportText == nil then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		local clipboard = nil
		if type(setclipboard) == "function" then
			clipboard = setclipboard
		elseif type(toclipboard) == "function" then
			clipboard = toclipboard
		end
		if type(clipboard) ~= "function" then
			output:CaptureFocus()
			setState("export_ready", "DISCOVERY_ARTIFACT_CLIPBOARD_UNAVAILABLE", false)
			return
		end
		local ok = pcall(clipboard, exportText)
		if not ok then
			output:CaptureFocus()
			setState("export_ready", "DISCOVERY_ARTIFACT_CLIPBOARD_FAILED", false)
			return
		end
		setState("export_ready", "JSON copied to clipboard", false)
	end)

	connect(chunksButton, function()
		if state ~= "export_ready" or exportText == nil then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		showChunk(1)
	end)

	connect(previousButton, function()
		showChunk(chunkIndex - 1)
	end)
	connect(nextButton, function()
		showChunk(chunkIndex + 1)
	end)
	connect(selectButton, function()
		if chunkOutput.Visible and chunkOutput.Text ~= "" then
			chunkOutput:CaptureFocus()
			chunkOutput.SelectionStart = 1
			chunkOutput.CursorPosition = #chunkOutput.Text + 1
		end
	end)
	connect(printButton, function()
		if state ~= "export_ready" or exportText == nil then
			setState("error", "DISCOVERY_CONFIG_INVALID", true)
			return
		end
		for index, chunk in ipairs(exportChunks) do
			print(string.format("UGC_CAPTURE_CHUNK %03d/%03d %s", index, #exportChunks, chunk))
		end
		setState("export_ready", tostring(#exportChunks) .. " CHUNKS_PRINTED", false)
	end)

	connect(unloadButton, cleanup)
	setState("ready", "passive; LIMITS 4096 RECORDS / 1048576 BYTES / TIMEOUT 1800s", false)
	return {
		state = function()
			return state
		end,
		unload = cleanup,
	}
end

function MobileApp.launch()
	pendingUiInstances = {}
	local ok, app = pcall(launchInternal)
	if not ok then
		for index = #pendingUiInstances, 1, -1 do
			pcall(function()
				pendingUiInstances[index]:Destroy()
			end)
		end
		pendingUiInstances = nil
		return errorApp("DISCOVERY_ARTIFACT_UI_UNAVAILABLE")
	end
	pendingUiInstances = nil
	return app
end

return MobileApp
end
return __require("MobileApp").launch()
