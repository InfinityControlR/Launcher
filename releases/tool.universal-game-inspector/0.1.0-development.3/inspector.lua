-- Infinity Universal Game Inspector
-- artifact-schema: game-discovery-inspector-artifact/1
-- artifact-version: 0.1.0-development.3
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
Constants.INITIAL_SCAN_BATCH = 32

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

function BoundedBuffer:markTruncated(surface, tUs)
	self:_recordDrop({
		surface = type(surface) == "string" and surface or "errors",
		t_us = type(tUs) == "number" and math.max(0, math.floor(tUs)) or 0,
	})
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

function BoundedBuffer:size()
	return #self.records
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

local function isDeniedIdentity(value, identities)
	local candidate = lower(value or "")
	if identities[candidate] == true then return true end
	for identity in pairs(identities) do
		if #identity >= 3 and string.find(candidate, identity, 1, true) ~= nil then return true end
	end
	return false
end

local function isSensitiveString(value, patterns, identities)
	local candidate = lower(value)
	if isDeniedIdentity(value, identities)
		or string.find(candidate, "bearer ", 1, true)
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

local function isSensitiveDynamicIdentifier(value, patterns, identities)
	local candidate = lower(value or "")
	local canonical = string.gsub(candidate, "[^%w]", "")
	if isSensitiveField(candidate) or isSensitiveString(value, patterns, identities) then
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
		identities = {},
		identityCount = 0,
		identityLimit = math.min(16384, limits.connections * 4),
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
	if isSensitiveField(field) or isSensitiveString(value, self.patterns, self.identities) then
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

function Sanitizer:addEphemeralIdentity(identity)
	if type(identity) == "string" and #identity > 0 and #identity <= self.limits.string_bytes then
		local candidate = lower(identity)
		if self.identities[candidate] then return true end
		if self.identityCount >= self.identityLimit then return false end
		self.identities[candidate] = true
		self.identityCount += 1
	end
	return true
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
		if isSensitiveDynamicIdentifier(segment, self.patterns, self.identities) then
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
	if not inspector:_transitionCanStart() then return false end
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
	local owned = inspector:_ownConnection(connection, surface)
	inspector:_transitionCompleted()
	return owned
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
			if not inspector:_transitionCanStart() then break end
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
		if not inspector:_transitionCanStart() then break end
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
	local function visit(instance, operation)
		observeInstance(inspector, instance, collectionService, dependencies, operation == "appeared")
	end
	local job = inspector:_newScanJob("hierarchy", root, visit)
	-- Subscribe before draining the first batch. A signal racing the queued scan
	-- marks the same instance in the job's weak seen-set.
	attachSignal(inspector, "hierarchy", root.DescendantAdded, function(instance)
		inspector:_visitScanSignal(job, instance, "appeared")
	end)
	attachSignal(inspector, "hierarchy", root.DescendantRemoving, function(instance)
		if not inspector:_isBlockedInstance(instance) then
			inspector:_emit("hierarchy", "disappeared", subjectFor(inspector, instance, "instance", "instance-ref"), nil, {})
		end
	end)
end

local function observeUiTree(inspector, playerGui)
	local function visit(instance, _operation)
		observeUi(inspector, instance)
	end
	local job = inspector:_newScanJob("ui", playerGui, visit)
	attachSignal(inspector, "ui", playerGui.DescendantAdded, function(instance)
		inspector:_visitScanSignal(job, instance, "appeared")
	end)
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
	local job = inspector:_newScanJob(surface, container, visit)
	attachSignal(inspector, connectionSurface, container.DescendantAdded, function(instance)
		inspector:_visitScanSignal(job, instance, "appeared")
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
		-- Roblox marks interaction consumed by UI controls as processed. Inspector
		-- controls must never become evidence about the observed game.
		if processed == true then
			return
		end
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
	if not inspector:_transitionCanStart() then return end
	local gameObject = dependencies.gameObject or game
	local players = dependencies.players or safeGetService(gameObject, "Players")
	local collectionService = dependencies.collectionService or safeGetService(gameObject, "CollectionService")
	local replicatedStorage = dependencies.replicatedStorage or safeGetService(gameObject, "ReplicatedStorage")
	local workspaceService = dependencies.workspace or safeGetService(gameObject, "Workspace")
	local runService = dependencies.runService or safeGetService(gameObject, "RunService")
	local userInputService = dependencies.userInputService or safeGetService(gameObject, "UserInputService")

	-- Build the ephemeral identity denyset before any root scan. Roster names are
	-- read only for local redaction and are never emitted, buffered or diagnosed.
	local protectedPlayers = setmetatable({}, { __mode = "k" })
	local function protectPlayerIdentity(player)
		if player == nil then return end
		if not inspector:_transitionCanStart() then return end
		local isPlayerOk, isPlayer = pcall(function() return player:IsA("Player") end)
		if not isPlayerOk then inspector:_privacyFailClosed() return end
		if not isPlayer then return end
		if protectedPlayers[player] then return end
		protectedPlayers[player] = true
		for _, field in ipairs({ "Name", "DisplayName" }) do
			if not inspector:_transitionCanStart() then break end
			local function protectField()
				local ok, value = pcall(function() return player[field] end)
				if ok then inspector:_addPrivateName(value) else inspector:_privacyFailClosed() end
			end
			protectField()
			local signalOk, signal = pcall(function() return player:GetPropertyChangedSignal(field) end)
			if not signalOk or not attachSignal(inspector, "errors", signal, protectField) then inspector:_privacyFailClosed() end
		end
		local function protectCharacter(character)
			if character == nil then return end
			local function protectCharacterName()
				local nameOk, name = pcall(function() return character.Name end)
				if nameOk then inspector:_addPrivateName(name) else inspector:_privacyFailClosed() end
			end
			protectCharacterName()
			local signalOk, signal = pcall(function() return character:GetPropertyChangedSignal("Name") end)
			if not signalOk or not attachSignal(inspector, "errors", signal, protectCharacterName) then inspector:_privacyFailClosed() end
		end
		local characterOk, character = pcall(function() return player.Character end)
		if characterOk then protectCharacter(character) else inspector:_privacyFailClosed() end
		if not attachSignal(inspector, "errors", player.CharacterAdded, protectCharacter) then inspector:_privacyFailClosed() end
	end
	if players ~= nil then
		if not inspector:_transitionCanStart() then return end
		local rosterOk, roster = pcall(function() return players:GetPlayers() end)
		inspector:_transitionCompleted()
		if rosterOk then
			for index, rosterEntry in ipairs(roster) do
				if not inspector:_transitionCanStart() then break end
				if index > inspector:_scanLimit() then error("DISCOVERY_IDENTITY_ROSTER_LIMIT") end
				protectPlayerIdentity(rosterEntry)
			end
		else inspector:_privacyFailClosed() end
		protectPlayerIdentity(players.LocalPlayer)
		if not attachSignal(inspector, "errors", players.PlayerAdded, protectPlayerIdentity) then inspector:_privacyFailClosed() end
	end

	if inspector:_surfaceRequested("metadata") then
		inspector:_markSurfaceStarted("metadata")
		local source = { classification = "runtime" }
		local fields = {
			GameId = "game_id",
			PlaceId = "place_id",
		}
		for field, outputName in pairs(fields) do
			if not inspector:_transitionCanStart() then break end
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
	local rootScanRequested = inspector:_surfaceRequested("hierarchy") or inspector:_surfaceRequested("instances")
		or inspector:_surfaceRequested("attributes") or inspector:_surfaceRequested("value_bases")
		or inspector:_surfaceRequested("tags") or inspector:_surfaceRequested("tools")
		or inspector:_surfaceRequested("remote_inventory") or inspector:_surfaceRequested("remote_call_observation")
	if rootScanRequested then
		for _, root in ipairs(roots) do
			if not inspector:_transitionCanStart() then break end
			if root ~= nil then
				observeRoot(inspector, root, collectionService, dependencies)
			end
		end
	end
	if not inspector:_bindScanPump(runService) then error("DISCOVERY_SCAN_PUMP_UNAVAILABLE") end
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
		if not inspector:_transitionCanStart() then break end
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

local TRANSITION_DEADLINE_US = 5000000
local MAX_SAFE_INTEGER = 9007199254740991

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
	self._transitionClockUs = dependencies.transitionClockUs or self._clockUs
	self._transitionDeadlineUs = nil
	self._transitionTimedOut = false
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
	self._lastClockUs = nil
	self._lastUs = 0
	self._nextLocalRef = 1
	self._connections = {}
	self._scanJobs = {}
	self._scanPumpBound = false
	self._lastFault = nil
	self._timeoutTask = nil
	self._tagSignals = {}
	self._coverage = {}
	self._source = { classification = "runtime" }
	self._localPlayer = nil
	self._localCharacter = nil
	self._sealedSnapshot = nil
	self._retentionExpiresClockUs = nil
	self._retentionLastClockUs = nil
	self._retentionFailure = nil
	self._lastManualAction = nil
	self._cleanupComplete = false
	self._starting = false
	self._privacyInventoryFailed = false
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

function Inspector:_beginTransitionDeadline()
	local ok, now = pcall(self._transitionClockUs)
	if not ok or type(now) ~= "number" or now ~= now then
		self._transitionDeadlineUs = nil
		self._transitionTimedOut = true
		return nil
	end
	self._transitionDeadlineUs = math.floor(now) + TRANSITION_DEADLINE_US
	self._transitionTimedOut = false
	return self._transitionDeadlineUs
end

-- A controlled unit may only begin strictly before D. Runtime observer callbacks
-- execute after start has cleared the transition deadline and are unaffected.
function Inspector:_transitionCanStart(deadline)
	deadline = deadline or self._transitionDeadlineUs
	if deadline == nil then return self._transitionDeadlineUs == nil and not self._transitionTimedOut end
	local ok, now = pcall(self._transitionClockUs)
	if not ok or type(now) ~= "number" or now ~= now or math.floor(now) >= deadline then
		self._transitionTimedOut = true
		return false
	end
	return true
end

-- A unit that returns exactly at D completed within the contract. A host
-- primitive is not preempted; a return after D is detected and fails closed.
function Inspector:_transitionCompleted(deadline)
	deadline = deadline or self._transitionDeadlineUs
	if deadline == nil then return not self._transitionTimedOut end
	local ok, now = pcall(self._transitionClockUs)
	if not ok or type(now) ~= "number" or now ~= now or math.floor(now) > deadline then
		self._transitionTimedOut = true
		return false
	end
	return not self._transitionTimedOut
end

function Inspector:_endTransition()
	local timedOut = self._transitionTimedOut
	self._transitionDeadlineUs = nil
	self._transitionTimedOut = false
	return not timedOut
end

function Inspector:_invalidateExport()
	self._sealedSnapshot = nil
	self._retentionExpiresClockUs = nil
	self._retentionLastClockUs = nil
	self._retentionFailure = nil
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
	if not ok or type(current) ~= "number" or current ~= current
		or current % 1 ~= 0 or current < 0 or current > MAX_SAFE_INTEGER
	then
		return nil, "read"
	end
	if self._lastClockUs ~= nil and current < self._lastClockUs then
		return nil, "rollback"
	end
	self._lastClockUs = current
	if self._retentionLastClockUs == nil or current > self._retentionLastClockUs then self._retentionLastClockUs = current end
	local relative = current - self._startedClockUs
	self._lastUs = relative
	return relative, nil
end

function Inspector:_emit(surface, operation, subject, value, contextRefs)
	if self._state ~= "observing" then
		return false
	end
	if not self:_surfaceRequested(surface) and surface ~= "errors" then
		return false
	end
	local tUs, clockFailure = self:_nowUs()
	if tUs == nil then
		self:_fault("DISCOVERY_CLOCK_INVALID", "observer.clock." .. tostring(clockFailure or "read"))
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

function Inspector:_privacyFailClosed()
	self._privacyInventoryFailed = true
	if not self._starting and self._state == "observing" then
		return self:_fault("DISCOVERY_INTERNAL_ERROR", "privacy.inventory")
	end
	return false
end

function Inspector:_addPrivateName(name)
	if not self._sanitizer:addEphemeralIdentity(name) then return self:_privacyFailClosed() end
	return true
end

function Inspector:_setLocalPlayer(player)
	self._localPlayer = player
end

function Inspector:_setLocalCharacter(character)
	self._localCharacter = character
	if character ~= nil then
		local ok, name = pcall(function() return character.Name end)
		if ok then self:_addPrivateName(name) end
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
	self._buffer:markTruncated(surface, self._lastUs)
	self._sanitizer:dropField("initial_scan_limit_" .. string.lower(surface))
end

local function safePhase(field)
	if type(field) ~= "string" or #field < 1 or #field > 64
		or string.find(field, "[^a-z0-9%._%-]", 1) ~= nil
	then
		return "observer.scan"
	end
	return field
end

local function safeCode(code)
	if type(code) ~= "string" or #code < 1 or #code > 64
		or string.find(code, "[^A-Z0-9_]", 1) ~= nil
	then
		return "DISCOVERY_INTERNAL_ERROR"
	end
	return code
end

-- Scan jobs are owned by the Inspector lifecycle. Signal callbacks mark an
-- instance before observing it; the later initial scan therefore skips the
-- same instance instead of producing an appeared+observed race duplicate.
function Inspector:_newScanJob(surface, root, visit)
	local job = {
		surface = surface,
		root = root,
		visit = visit,
		queue = { root },
		head = 1,
		tail = 1,
		accepted = 1,
		seen = setmetatable({}, { __mode = "k" }),
		truncated = false,
	}
	table.insert(self._scanJobs, job)
	return job
end

function Inspector:_visitScanSignal(job, instance, operation)
	if self._state ~= "observing" or job == nil or job.seen[instance] then return false end
	job.seen[instance] = true
	local ok = pcall(job.visit, instance, operation or "appeared")
	if not ok then self:_fault("DISCOVERY_INTERNAL_ERROR", "observer.signal") return false end
	return true
end

function Inspector:_fault(code, field)
	if self._state == "failed" then return false end
	self._lastFault = { code = safeCode(code), field = safePhase(field) }
	self._state = "failed"
	self._scanJobs = {}
	self:_invalidateExport()
	self._buffer:clear()
	if self._starting then return false end
	local cleanupComplete, cleanupTimedOut = self:_cleanup()
	if not cleanupComplete then
		self._lastFault = {
			code = "DISCOVERY_CLEANUP_FAILED",
			field = cleanupTimedOut and "lifecycle.cleanup.timeout" or "lifecycle.cleanup.disconnect",
		}
	end
	return false
end

function Inspector:_drainScanBatch()
	if self._state ~= "observing" then return 0 end
	local processed = 0
	while processed < Constants.INITIAL_SCAN_BATCH and #self._scanJobs > 0 do
		local job = self._scanJobs[1]
		local instance = job.queue[job.head]
		job.queue[job.head] = nil
		job.head += 1
		if instance == nil then
			table.remove(self._scanJobs, 1)
		else
			processed += 1
			if not job.seen[instance] then
				job.seen[instance] = true
				local visitOk = pcall(job.visit, instance, "observed")
				if not visitOk then self:_fault("DISCOVERY_INTERNAL_ERROR", "observer.scan.visit") return processed end
			end
			local childrenOk, children = pcall(function() return instance:GetChildren() end)
			if not childrenOk or type(children) ~= "table" then
				self:_fault("DISCOVERY_INTERNAL_ERROR", "observer.scan.children") return processed
			end
			local remaining = math.max(0, self:_scanLimit() - job.accepted)
			local take = math.min(#children, remaining)
			for index = 1, take do
				job.tail += 1
				job.queue[job.tail] = children[index]
			end
			job.accepted += take
			if take < #children and not job.truncated then
				job.truncated = true
				self:_markScanTruncated(job.surface)
			end
			if job.head > job.tail and self._scanJobs[1] == job then table.remove(self._scanJobs, 1) end
		end
	end
	return processed
end

function Inspector:_bindScanPump(runService)
	if self._scanPumpBound or #self._scanJobs == 0 then return true end
	if runService == nil or runService.Heartbeat == nil then
		for _, job in ipairs(self._scanJobs) do
			if not job.truncated then job.truncated = true self:_markScanTruncated(job.surface) end
		end
		self._scanJobs = {}
		return true
	end
	self._scanPumpBound = true
	local ok, connection = pcall(function()
		return runService.Heartbeat:Connect(function()
			local drainOk = pcall(function() self:_drainScanBatch() end)
			if not drainOk then self:_fault("DISCOVERY_INTERNAL_ERROR", "observer.scan.tick") end
		end)
	end)
	if not ok or connection == nil then return self:_fault("DISCOVERY_INTERNAL_ERROR", "observer.scan.connect") end
	return self:_ownConnection(connection, "hierarchy")
end

function Inspector:_cancelPendingScans()
	for _, job in ipairs(self._scanJobs) do
		if not job.truncated then
			job.truncated = true
			self:_markScanTruncated(job.surface)
		end
	end
	self._scanJobs = {}
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
	if not ok or type(initial) ~= "number" or initial ~= initial
		or initial % 1 ~= 0 or initial < 0 or initial > MAX_SAFE_INTEGER
	then
		self._state = "failed"
		return resultFailure("DISCOVERY_CLOCK_INVALID", "lifecycle.start.clock")
	end
	local retentionDelta = self._config.retention_seconds * 1000000
	if retentionDelta > MAX_SAFE_INTEGER - initial then
		self._state = "failed"
		return resultFailure("DISCOVERY_RETENTION_INVALID", "export.retention.deadline")
	end
	self._startedClockUs = initial
	self._lastClockUs = initial
	self._lastUs = 0
	self._retentionExpiresClockUs = initial + retentionDelta
	self._retentionLastClockUs = initial
	self._retentionFailure = nil
	local deadline = self:_beginTransitionDeadline()
	if deadline == nil or not self:_transitionCanStart(deadline) then
		self._state = "failed"
		self:_endTransition()
		return resultFailure("DISCOVERY_INTERNAL_ERROR", "lifecycle.start.timeout")
	end
	self._state = "observing"
	self._starting = true
	if not self:_transitionCanStart(deadline) then
		self._state = "failed"
		self:_endTransition()
		return resultFailure("DISCOVERY_INTERNAL_ERROR", "lifecycle.start.timeout")
	end
	local utcOk, startedAt = pcall(self._utcNow)
	if not self:_transitionCompleted(deadline) then utcOk = false end
	self._startedAtUtc = type(startedAt) == "string" and startedAt or nil
	local attachOk = false
	if utcOk and self:_transitionCanStart(deadline) then
		attachOk = pcall(Observers.attach, self, self._dependencies)
	end
	local attachCompleted = self:_transitionCompleted(deadline)
	self._starting = false
	if self._privacyInventoryFailed or self._lastFault ~= nil then attachOk = false end
	if not attachOk then
		self._state = "failed"
		local timedOut = self._transitionTimedOut
		local fault = self._lastFault ~= nil and deepCopy(self._lastFault) or nil
		self:_endTransition()
		local cleanupComplete = self:_cleanup()
		self._buffer:clear()
		if not cleanupComplete then return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout") end
		if fault ~= nil then return resultFailure(fault.code, fault.field) end
		return resultFailure("DISCOVERY_INTERNAL_ERROR", timedOut and "lifecycle.start.timeout" or "observer_attach")
	end
	local scheduleFailed = false
	if self._scheduler ~= nil and type(self._scheduler.delay) == "function" then
		if self:_transitionCanStart(deadline) then
			local scheduleOk, timeoutTask = pcall(self._scheduler.delay, self._config.limits.duration_seconds, function()
				self._timeoutTask = nil
				self:stop()
			end)
			if scheduleOk then self._timeoutTask = timeoutTask else scheduleFailed = true end
			attachCompleted = self:_transitionCompleted(deadline)
		else
			attachCompleted = false
		end
	end
	if scheduleFailed or not attachCompleted or self._transitionTimedOut then
		self._state = "failed"
		local timedOut = self._transitionTimedOut or not attachCompleted
		self:_endTransition()
		local cleanupComplete = self:_cleanup()
		self._buffer:clear()
		if not cleanupComplete then return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout") end
		return resultFailure("DISCOVERY_INTERNAL_ERROR", timedOut and "lifecycle.start.timeout" or "observer_attach")
	end
	self:_endTransition()
	return { ok = true, value = { state = self._state } }
end

function Inspector:_cleanup(sharedDeadline)
	local deadline = sharedDeadline
	local ownsDeadline = deadline == nil
	if ownsDeadline then deadline = self:_beginTransitionDeadline() end
	local complete = true
	local timedOut = deadline == nil
	local remainingConnections = {}
	for index = #self._connections, 1, -1 do
		local connection = self._connections[index]
		if not self:_transitionCanStart(deadline) then
			timedOut = true
			for pending = 1, index do table.insert(remainingConnections, self._connections[pending]) end
			break
		end
		local ok = pcall(function()
			connection:Disconnect()
		end)
		complete = complete and ok
		if not ok then
			table.insert(remainingConnections, 1, connection)
		end
		if not self:_transitionCompleted(deadline) then
			timedOut = true
			for pending = 1, index - 1 do table.insert(remainingConnections, 1, self._connections[pending]) end
			break
		end
	end
	self._connections = remainingConnections
	if self._timeoutTask ~= nil and not timedOut then
		local timeoutTask = self._timeoutTask
		local current = coroutine.running()
		if timeoutTask ~= current and self._scheduler ~= nil and type(self._scheduler.cancel) == "function" then
			if self:_transitionCanStart(deadline) then
				local ok = pcall(self._scheduler.cancel, timeoutTask)
				complete = complete and ok
				if ok then self._timeoutTask = nil end
				if not self:_transitionCompleted(deadline) then timedOut = true end
			else
				timedOut = true
			end
		elseif timeoutTask == current then
			self._timeoutTask = nil
		else
			complete = false
		end
	end
	complete = complete and not timedOut and #self._connections == 0 and self._timeoutTask == nil
	if complete then
		table.clear(self._tagSignals)
		self._scanJobs = {}
		self._scanPumpBound = false
	end
	self._cleanupComplete = complete
	if ownsDeadline then self:_endTransition() end
	return complete, timedOut
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
	local deadline = self:_beginTransitionDeadline()
	if deadline == nil or not self:_transitionCanStart(deadline) then
		self._state = "failed"
		self:_invalidateExport()
		self._buffer:clear()
		self:_endTransition()
		local cleanupComplete = self:_cleanup()
		if not cleanupComplete then return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout") end
		return resultFailure("DISCOVERY_INTERNAL_ERROR", "lifecycle.stop.timeout")
	end
	local endedUs = self:_nowUs()
	local endedInTime = self:_transitionCompleted(deadline)
	if endedUs == nil then
		self._state = "failed"
		local timedOut = not endedInTime or self._transitionTimedOut
		self:_endTransition()
		local cleanupComplete = self:_cleanup()
		self._buffer:clear()
		self:_invalidateExport()
		if not cleanupComplete then return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout") end
		return resultFailure(timedOut and "DISCOVERY_INTERNAL_ERROR" or "DISCOVERY_CLOCK_INVALID", timedOut and "lifecycle.stop.timeout" or "lifecycle.stop.clock")
	end
	self._state = "stopping"
	self:_cancelPendingScans()
	if not self:_transitionCanStart(deadline) then
		self._state = "failed"
		self:_invalidateExport()
		self._buffer:clear()
		self:_endTransition()
		local cleanupComplete = self:_cleanup()
		if not cleanupComplete then return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout") end
		return resultFailure("DISCOVERY_INTERNAL_ERROR", "lifecycle.stop.timeout")
	end
	local records = self._buffer:snapshotAndClear()
	local truncation = self._buffer:stats()
	local candidate = deepFreeze({
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
			complete = true,
			connections = 0,
			hooks = 0,
			tasks = 0,
			buffers = 0,
		},
	})
	local cleanupComplete = self:_cleanup(deadline)
	local completed = self:_transitionCompleted(deadline)
	self:_endTransition()
	if not cleanupComplete then
		self._state = "failed"
		self:_invalidateExport()
		self._buffer:clear()
		return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout")
	end
	if not completed then
		self._state = "failed"
		self:_invalidateExport()
		self._buffer:clear()
		return resultFailure("DISCOVERY_INTERNAL_ERROR", "lifecycle.stop.timeout")
	end
	self._sealedSnapshot = candidate
	self._state = "stopped"
	return { ok = true, value = { state = "stopped", cleanup = deepCopy(self._sealedSnapshot.cleanup) } }
end

function Inspector:exportSnapshot()
	if self._retentionFailure ~= nil then return resultFailure(self._retentionFailure.code, self._retentionFailure.phase) end
	if self._state ~= "stopped" or self._sealedSnapshot == nil then
		return resultFailure("DISCOVERY_CONFIG_INVALID", "lifecycle.export")
	end
	local retained = self:expireRetention()
	if not retained.ok then return resultFailure(retained.code, retained.phase) end
	if self._sealedSnapshot.retention_seconds == 0 or self._sealedSnapshot.clock.started_at_utc == nil then
		return resultFailure("DISCOVERY_RETENTION_INVALID", "retention")
	end
	return {
		ok = true,
		value = deepCopy(self._sealedSnapshot),
		retention_expires_clock_us = self._retentionExpiresClockUs,
	}
end

function Inspector:_retentionFailureResult(code, phase)
	self._sealedSnapshot = nil
	self._retentionExpiresClockUs = nil
	self._retentionLastClockUs = nil
	self._retentionFailure = { code = code, phase = phase }
	return { ok = false, code = code, phase = phase, retryable = false }
end

function Inspector:expireRetention()
	if self._retentionFailure ~= nil then
		return { ok = false, code = self._retentionFailure.code, phase = self._retentionFailure.phase, retryable = false }
	end
	if self._sealedSnapshot == nil then return { ok = true } end
	if type(self._retentionExpiresClockUs) ~= "number"
		or self._retentionExpiresClockUs ~= self._retentionExpiresClockUs
		or self._retentionExpiresClockUs % 1 ~= 0
		or self._retentionExpiresClockUs < 0
		or self._retentionExpiresClockUs > MAX_SAFE_INTEGER
	then
		return self:_retentionFailureResult("DISCOVERY_RETENTION_INVALID", "export.retention.deadline")
	end
	local ok, now = pcall(self._clockUs)
	if not ok or type(now) ~= "number" or now ~= now or now % 1 ~= 0 or now < 0 or now > MAX_SAFE_INTEGER then
		return self:_retentionFailureResult("DISCOVERY_CLOCK_INVALID", "export.retention.clock.read")
	end
	if self._retentionLastClockUs ~= nil and now < self._retentionLastClockUs then
		return self:_retentionFailureResult("DISCOVERY_CLOCK_INVALID", "export.retention.clock.rollback")
	end
	self._retentionLastClockUs = now
	if now >= self._retentionExpiresClockUs then
		return self:_retentionFailureResult("DISCOVERY_RETENTION_EXPIRED", "export.retention")
	end
	return { ok = true }
end

function Inspector:progress()
	local elapsedUs = self._lastUs or 0
	if self._state == "observing" and self._startedClockUs ~= nil then
		local ok, current = pcall(self._clockUs)
		if ok and type(current) == "number" and current == current then
			elapsedUs = math.max(elapsedUs, math.floor(current - self._startedClockUs))
		end
	end
	local recordCount = self._buffer:size()
	if self._sealedSnapshot ~= nil then
		recordCount = #self._sealedSnapshot.records
		elapsedUs = self._sealedSnapshot.clock.ended_t_us
	end
	return {
		state = self._state,
		error = self._lastFault ~= nil and deepCopy(self._lastFault) or nil,
		record_count = recordCount,
		duration_seconds = math.max(0, math.floor(elapsedUs / 1000000)),
	}
end

function Inspector:unload()
	if self._state == "failed" then
		local cleanupComplete = self:_cleanup()
		if not cleanupComplete then
			self:_invalidateExport()
			return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout")
		end
		self._buffer:clear()
		self._sealedSnapshot = nil
		self._retentionExpiresClockUs = nil
		self._retentionLastClockUs = nil
		self._retentionFailure = nil
		self._state = "stopped"
		return { ok = true, value = { state = "stopped" } }
	end
	if self._state == "validated" then
		local cleanupComplete = self:_cleanup()
		if not cleanupComplete then
			self:_invalidateExport()
			return resultFailure("DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup.timeout")
		end
		self._buffer:clear()
		self._state = "stopped"
		return { ok = true, value = { state = "stopped" } }
	end
	local result = self:stop()
	if result.ok then
		self._sealedSnapshot = nil
		self._retentionExpiresClockUs = nil
		self._retentionLastClockUs = nil
		self._retentionFailure = nil
	end
	return result
end

return Inspector
end
__factories["init"] = function(__require)
-- Public entry point. This module performs no work until the caller explicitly starts it.
return __require("Inspector")
end
__factories["JsonCodec"] = function(__require)
local JsonCodec = {}

local ESCAPES = {
	["\b"] = "\\b",
	["\t"] = "\\t",
	["\n"] = "\\n",
	["\f"] = "\\f",
	["\r"] = "\\r",
	['"'] = '\\"',
	["\\"] = "\\\\",
}

local function escapeString(value)
	return '"' .. string.gsub(value, '[%z\1-\31\\"]', function(character)
		return ESCAPES[character] or string.format("\\u%04x", string.byte(character))
	end) .. '"'
end

local function arrayLength(value)
	local count = 0
	local maximum = 0
	for key in pairs(value) do
		count += 1
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 then
			return nil
		end
		maximum = math.max(maximum, key)
	end
	if maximum ~= count then
		return nil
	end
	return maximum
end

local function encodeValue(value, active)
	local kind = type(value)
	if kind == "nil" then
		return "null"
	elseif kind == "boolean" then
		return value and "true" or "false"
	elseif kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			error("DISCOVERY_ARTIFACT_JSON_VALUE_INVALID")
		end
		return tostring(value)
	elseif kind == "string" then
		return escapeString(value)
	elseif kind ~= "table" then
		error("DISCOVERY_ARTIFACT_JSON_VALUE_INVALID")
	end
	if active[value] then
		error("DISCOVERY_ARTIFACT_JSON_CYCLE")
	end
	active[value] = true
	local length = arrayLength(value)
	local parts = {}
	if length ~= nil then
		for index = 1, length do
			table.insert(parts, encodeValue(value[index], active))
		end
		active[value] = nil
		return "[" .. table.concat(parts, ",") .. "]"
	end
	local keys = {}
	for key, item in pairs(value) do
		if type(key) ~= "string" then
			error("DISCOVERY_ARTIFACT_JSON_KEY_INVALID")
		end
		if item ~= nil then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		table.insert(parts, escapeString(key) .. ":" .. encodeValue(value[key], active))
	end
	active[value] = nil
	return "{" .. table.concat(parts, ",") .. "}"
end

function JsonCodec.encode(value)
	return encodeValue(value, {})
end

return table.freeze(JsonCodec)
end
__factories["Sha256"] = function(__require)
local Sha256 = {}

local K = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local function add(...)
	local sum = 0
	for index = 1, select("#", ...) do
		sum = bit32.band(sum + select(index, ...), 0xffffffff)
	end
	return sum
end

local function word(bytes, offset)
	return bit32.bor(
		bit32.lshift(string.byte(bytes, offset), 24),
		bit32.lshift(string.byte(bytes, offset + 1), 16),
		bit32.lshift(string.byte(bytes, offset + 2), 8),
		string.byte(bytes, offset + 3)
	)
end

function Sha256.hex(message)
	assert(type(message) == "string", "DISCOVERY_ARTIFACT_HASH_INPUT_INVALID")
	local bitLength = #message * 8
	local high = math.floor(bitLength / 4294967296)
	local low = bitLength % 4294967296
	local padding = string.char(0x80)
	local zeros = (56 - ((#message + 1) % 64)) % 64
	local bytes = message .. padding .. string.rep("\0", zeros)
	bytes ..= string.char(
		bit32.extract(high, 24, 8), bit32.extract(high, 16, 8), bit32.extract(high, 8, 8), bit32.extract(high, 0, 8),
		bit32.extract(low, 24, 8), bit32.extract(low, 16, 8), bit32.extract(low, 8, 8), bit32.extract(low, 0, 8)
	)
	local hash = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 }
	for block = 1, #bytes, 64 do
		local schedule = {}
		for index = 1, 16 do
			schedule[index] = word(bytes, block + (index - 1) * 4)
		end
		for index = 17, 64 do
			local before15 = schedule[index - 15]
			local before2 = schedule[index - 2]
			local small0 = bit32.bxor(bit32.rrotate(before15, 7), bit32.rrotate(before15, 18), bit32.rshift(before15, 3))
			local small1 = bit32.bxor(bit32.rrotate(before2, 17), bit32.rrotate(before2, 19), bit32.rshift(before2, 10))
			schedule[index] = add(schedule[index - 16], small0, schedule[index - 7], small1)
		end
		local a, b, c, d, e, f, g, h = table.unpack(hash)
		for index = 1, 64 do
			local big1 = bit32.bxor(bit32.rrotate(e, 6), bit32.rrotate(e, 11), bit32.rrotate(e, 25))
			local choose = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
			local first = add(h, big1, choose, K[index], schedule[index])
			local big0 = bit32.bxor(bit32.rrotate(a, 2), bit32.rrotate(a, 13), bit32.rrotate(a, 22))
			local majority = bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c))
			local second = add(big0, majority)
			h, g, f, e, d, c, b, a = g, f, e, add(d, first), c, b, a, add(first, second)
		end
		local nextHash = { a, b, c, d, e, f, g, h }
		for index = 1, 8 do
			hash[index] = add(hash[index], nextHash[index])
		end
	end
	local result = {}
	for index = 1, 8 do
		table.insert(result, string.format("%08x", hash[index]))
	end
	return table.concat(result)
end

return table.freeze(Sha256)
end
__factories["Layout"] = function(__require)
local Layout = {}

local MARGIN = 8
local MIN_TOUCH = 44
local MAX_FLOATING = 52

local function finite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function number(value, fallback)
	if finite(value) then
		return value
	end
	return fallback
end

function Layout.safeRect(viewportWidth, viewportHeight, insets)
	local width = math.max(1, math.floor(number(viewportWidth, 360)))
	local height = math.max(1, math.floor(number(viewportHeight, 640)))
	insets = type(insets) == "table" and insets or {}
	local left = math.max(0, math.floor(number(insets.left, MARGIN)))
	local top = math.max(0, math.floor(number(insets.top, MARGIN)))
	local right = math.max(0, math.floor(number(insets.right, MARGIN)))
	local bottom = math.max(0, math.floor(number(insets.bottom, MARGIN)))
	if left + right >= width or top + bottom >= height then
		left, top, right, bottom = MARGIN, MARGIN, MARGIN, MARGIN
	end
	return {
		x = left,
		y = top,
		width = math.max(1, width - left - right),
		height = math.max(1, height - top - bottom),
	}
end

function Layout.compact(rect)
	local availableWidth = math.max(1, rect.width - MARGIN * 2)
	local width = math.min(520, availableWidth, math.max(1, math.floor(rect.width * 0.72)))
	local landscape = rect.width >= rect.height
	local actionRows = not landscape and width < 420 and 2 or 1
	local minimumHeight = 44 + 44 * actionRows
	local height = minimumHeight
	return {
		width = width,
		height = height,
		action_rows = actionRows,
		game_visible_ratio = 1 - (width * height) / (rect.width * rect.height),
	}
end

function Layout.expanded(rect, compact)
	return {
		width = math.min(rect.width - MARGIN * 2, math.max(compact.width, 340)),
		height = math.min(rect.height - MARGIN * 2, math.max(compact.height, 360)),
	}
end

function Layout.clamp(rect, size, x, y)
	local minimumX = rect.x + MARGIN
	local minimumY = rect.y + MARGIN
	local maximumX = math.max(minimumX, rect.x + rect.width - size.width - MARGIN)
	local maximumY = math.max(minimumY, rect.y + rect.height - size.height - MARGIN)
	return math.max(minimumX, math.min(number(x, minimumX), maximumX)),
		math.max(minimumY, math.min(number(y, minimumY), maximumY))
end

function Layout.initialPosition(rect, size)
	return Layout.clamp(rect, size, rect.x + MARGIN, rect.y + MARGIN)
end

function Layout.constants()
	return { margin = MARGIN, min_touch = MIN_TOUCH, max_floating = MAX_FLOATING }
end

return table.freeze(Layout)
end
__factories["ExportPipeline"] = function(__require)
local JsonCodec = __require("JsonCodec")
local Sha256 = __require("Sha256")

local ExportPipeline = {}
ExportPipeline.__index = ExportPipeline

local MAX_EXPORT_BYTES = 1048576
local PAGE_BYTES = 4096
local OUTPUT_BYTES = 2048
local MAX_PAGES = 256
local MAX_SAFE_INTEGER = 9007199254740991
local NULL_MARKER = string.rep("UGC_JSON_NULL_SENTINEL_", 16)
local EMPTY_OBJECT_MARKER = string.rep("UGC_JSON_EMPTY_OBJECT_SENTINEL_", 10)

local function defaultClockUs()
	return math.floor(os.clock() * 1000000)
end

local function clone(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then error("DISCOVERY_ARTIFACT_JSON_CYCLE") end
	seen[value] = true
	local result = {}
	for key, item in pairs(value) do result[key] = clone(item, seen) end
	seen[value] = nil
	return result
end

local function deepFreeze(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return value end
	seen[value] = true
	for _, item in pairs(value) do deepFreeze(item, seen) end
	return table.freeze(value)
end

local function prepare(snapshot)
	local copy = clone(snapshot)
	local nulls, emptyObjects = 0, 0
	local function nullable(container, key)
		if container[key] == nil then container[key] = NULL_MARKER nulls += 1 end
	end
	local function emptyObject(container)
		if next(container) == nil then container[EMPTY_OBJECT_MARKER] = true emptyObjects += 1 end
	end
	nullable(copy.clock, "started_at_utc")
	nullable(copy.truncation, "first_dropped_t_us")
	emptyObject(copy.truncation.surfaces)
	emptyObject(copy.sanitization.dropped_fields)
	for _, coverage in pairs(copy.coverage) do
		nullable(coverage, "first_t_us") nullable(coverage, "last_t_us") nullable(coverage, "unavailable_reason")
	end
	return copy, nulls, emptyObjects
end

local function finalize(encoded, nulls, emptyObjects)
	local replaced
	encoded, replaced = string.gsub(encoded, '"' .. NULL_MARKER .. '"', "null")
	if replaced ~= nulls then error("DISCOVERY_ARTIFACT_JSON_NULL_MISMATCH") end
	encoded, replaced = string.gsub(encoded, '{"' .. EMPTY_OBJECT_MARKER .. '":true}', "{}")
	if replaced ~= emptyObjects then error("DISCOVERY_ARTIFACT_JSON_OBJECT_MISMATCH") end
	return encoded
end

local function validateSnapshot(snapshot)
	return type(snapshot) == "table"
		and snapshot.contract_id == "game-discovery-capture"
		and snapshot.contract_version == "v1-draft"
		and snapshot.schema_version == 1
		and snapshot.mode == "passive"
		and type(snapshot.records) == "table"
		and type(snapshot.coverage) == "table"
		and type(snapshot.clock) == "table"
		and type(snapshot.truncation) == "table"
		and type(snapshot.sanitization) == "table"
end

local function splitUtf8(text, maximum, maxParts)
	local parts = {}
	local first = 1
	while first <= #text do
		local last = math.min(first + maximum - 1, #text)
		while last < #text do
			local following = string.byte(text, last + 1)
			if following == nil or following < 128 or following >= 192 then break end
			last -= 1
		end
		if last < first then return nil, "DISCOVERY_ARTIFACT_UTF8_SPLIT_FAILED" end
		table.insert(parts, string.sub(text, first, last))
		if #parts > maxParts then return nil, "DISCOVERY_ARTIFACT_EXPORT_LIMIT_EXCEEDED" end
		first = last + 1
	end
	return parts, nil
end

function ExportPipeline.new(httpService, capabilities, clockUs)
	return setmetatable({
		_http = httpService,
		_capabilities = capabilities or {},
		state = "empty",
		snapshot = nil,
		json = nil,
		pages = {},
		chunks = {},
		bytes = 0,
		hash = nil,
		encoder = "none",
		attempt = 0,
		lastError = nil,
		backend = "none",
		clipboardStatus = type((capabilities or {}).setclipboard) == "function" and "setclipboard"
			or (type((capabilities or {}).clipboard) == "function" and "clipboard" or "unavailable"),
		writefileStatus = type((capabilities or {}).writefile) == "function" and "available" or "unavailable",
		_clockUs = clockUs or defaultClockUs,
		_retentionExpiresUs = nil,
		_lastRetentionClockUs = nil,
		_retentionFailure = nil,
	}, ExportPipeline)
end

function ExportPipeline:_clearRetentionFailure(code, phase, state)
	self.snapshot, self.json = nil, nil
	table.clear(self.pages) table.clear(self.chunks)
	self.bytes, self.hash, self.backend = 0, nil, "none"
	self._retentionExpiresUs, self._lastRetentionClockUs = nil, nil
	self.state = state
	self.lastError, self.phase = code, phase
	self._retentionFailure = { code = code, phase = phase }
	return { ok = false, code = code, phase = phase, retryable = false }
end

function ExportPipeline:_expireRetention()
	return self:_clearRetentionFailure("DISCOVERY_RETENTION_EXPIRED", "export.retention", "expired")
end

function ExportPipeline:_invalidRetentionDeadline()
	return self:_clearRetentionFailure("DISCOVERY_RETENTION_INVALID", "export.retention.deadline", "invalid")
end

function ExportPipeline:_invalidRetentionClock(phase)
	return self:_clearRetentionFailure("DISCOVERY_CLOCK_INVALID", phase, "invalid")
end

function ExportPipeline:validateRetention()
	if self._retentionFailure ~= nil then
		return { ok = false, code = self._retentionFailure.code, phase = self._retentionFailure.phase, retryable = false }
	end
	if self.snapshot == nil then return { ok = true } end
	if self._retentionExpiresUs == nil then return self:_invalidRetentionDeadline() end
	local ok, now = pcall(self._clockUs)
	if not ok or type(now) ~= "number" or now ~= now or now % 1 ~= 0 or now < 0 or now > MAX_SAFE_INTEGER then
		return self:_invalidRetentionClock("export.retention.clock.read")
	end
	if self._lastRetentionClockUs ~= nil and now < self._lastRetentionClockUs then
		return self:_invalidRetentionClock("export.retention.clock.rollback")
	end
	self._lastRetentionClockUs = now
	if now >= self._retentionExpiresUs then return self:_expireRetention() end
	return { ok = true }
end

function ExportPipeline:seal(snapshot, retentionExpiresClockUs)
	if self.snapshot == nil then
		if not validateSnapshot(snapshot) then return false, "DISCOVERY_ARTIFACT_SNAPSHOT_INVALID" end
		if type(retentionExpiresClockUs) ~= "number"
			or retentionExpiresClockUs ~= retentionExpiresClockUs
			or retentionExpiresClockUs % 1 ~= 0
			or retentionExpiresClockUs < 0
			or retentionExpiresClockUs > MAX_SAFE_INTEGER
		then
			local failure = self:_invalidRetentionDeadline()
			return false, failure.code
		end
		self.snapshot = deepFreeze(clone(snapshot))
		self._retentionExpiresUs = retentionExpiresClockUs
	elseif retentionExpiresClockUs ~= self._retentionExpiresUs then
		local failure = self:_invalidRetentionDeadline()
		return false, failure.code
	end
	self.state = "snapshot_ready"
	local retained = self:validateRetention()
	if not retained.ok then return false, retained.code end
	return true
end

function ExportPipeline:_fail(code, phase)
	self.state = "retryable_error"
	self.lastError = code
	self.phase = phase
	return { ok = false, code = code, phase = phase, retryable = self.snapshot ~= nil }
end

function ExportPipeline:encode()
	self.attempt += 1
	local retained = self:validateRetention()
	if not retained.ok then return retained end
	if self.snapshot == nil then return self:_fail("DISCOVERY_ARTIFACT_SNAPSHOT_INVALID", "snapshot") end
	if self.json ~= nil and self.hash ~= nil and #self.pages > 0 and #self.chunks > 0 then
		self.state = "encoded"
		return { ok = true, value = self.json, reused = true }
	end
	self.lastError = nil
	self.state = "encoding"
	local encoded = self.json
	if encoded == nil then
		local preparedOk, prepared, nulls, emptyObjects = pcall(prepare, self.snapshot)
		if not preparedOk then return self:_fail("DISCOVERY_ARTIFACT_JSON_PREPARE_FAILED", "prepare") end
		local primaryOk, primaryValue = pcall(function() return self._http:JSONEncode(prepared) end)
		if primaryOk and type(primaryValue) == "string" then
			local finalOk, finalValue = pcall(finalize, primaryValue, nulls, emptyObjects)
			if finalOk then encoded = finalValue self.encoder = "httpservice" end
		end
		if encoded == nil then
			self.lastError = "DISCOVERY_ARTIFACT_JSON_PRIMARY_FAILED"
			self.phase = "encode_primary"
			local fallbackOk, fallbackValue = pcall(function()
				return finalize(JsonCodec.encode(prepared), nulls, emptyObjects)
			end)
			if not fallbackOk or type(fallbackValue) ~= "string" then
				return self:_fail("DISCOVERY_ARTIFACT_JSON_ENCODE_FAILED", "encode")
			end
			encoded = fallbackValue
			self.encoder = "embedded"
		end
	end
	retained = self:validateRetention()
	if not retained.ok then return retained end
	if #encoded > MAX_EXPORT_BYTES or string.sub(encoded, 1, 1) ~= "{" or string.sub(encoded, -1) ~= "}" then
		return self:_fail(#encoded > MAX_EXPORT_BYTES and "DISCOVERY_ARTIFACT_EXPORT_LIMIT_EXCEEDED" or "DISCOVERY_ARTIFACT_JSON_VALIDATE_FAILED", "validate")
	end
	-- Once syntactically valid, retain the exact bytes independently of later
	-- hash, pagination, UI or backend failures so retry never recaptures.
	self.json, self.bytes = encoded, #encoded
	local hashOk, digest = pcall(Sha256.hex, encoded)
	if not hashOk or type(digest) ~= "string" or #digest ~= 64 then
		return self:_fail("DISCOVERY_ARTIFACT_CAPTURE_HASH_FAILED", "hash")
	end
	retained = self:validateRetention()
	if not retained.ok then return retained end
	self.hash = "sha256:" .. digest
	local pages, pageError = splitUtf8(encoded, PAGE_BYTES, MAX_PAGES)
	if pages == nil then return self:_fail(pageError, "textbox") end
	local chunks, chunkError = splitUtf8(encoded, OUTPUT_BYTES, math.ceil(MAX_EXPORT_BYTES / OUTPUT_BYTES))
	if chunks == nil then return self:_fail(chunkError, "chunks") end
	self.pages, self.chunks = pages, chunks
	self.state = "encoded"
	return { ok = true, value = encoded, reused = false }
end

function ExportPipeline:deliverClipboard()
	local encoded = self:encode()
	if not encoded.ok then return encoded end
	self.state = "delivering"
	for _, name in ipairs({ "setclipboard", "clipboard" }) do
		local backend = self._capabilities[name]
		if type(backend) == "function" then
			local retained = self:validateRetention()
			if not retained.ok then return retained end
			local ok, result = pcall(backend, self.json)
			retained = self:validateRetention()
			if not retained.ok then return retained end
			if ok and result ~= false then
				if self.lastError == "DISCOVERY_ARTIFACT_CLIPBOARD_UNAVAILABLE" or self.lastError == "DISCOVERY_ARTIFACT_CLIPBOARD_FAILED" then self.lastError = nil end
				self.backend, self.state, self.clipboardStatus = "clipboard", "exported", name
				return { ok = true, backend = "clipboard", capability = name }
			end
		end
	end
	local callable = type(self._capabilities.setclipboard) == "function" or type(self._capabilities.clipboard) == "function"
	self.clipboardStatus = callable and "failed" or "unavailable"
	self.lastError = callable and "DISCOVERY_ARTIFACT_CLIPBOARD_FAILED" or "DISCOVERY_ARTIFACT_CLIPBOARD_UNAVAILABLE"
	self.phase = callable and "export.clipboard.write" or "export.clipboard.discovery"
	self.backend, self.state = "textbox", "exported"
	return { ok = true, backend = "textbox", capability = "unavailable_or_failed" }
end

function ExportPipeline:writeFile()
	local encoded = self:encode()
	if not encoded.ok then return encoded end
	local backend = self._capabilities.writefile
	if type(backend) ~= "function" then return self:_fail("DISCOVERY_ARTIFACT_FILE_UNAVAILABLE", "export.file.discovery") end
	local retained = self:validateRetention()
	if not retained.ok then return retained end
	self.state = "delivering"
	local filename = "ugc-capture-" .. string.sub(self.hash, 8, 23) .. ".json"
	local ok, result = pcall(backend, filename, self.json)
	retained = self:validateRetention()
	if not retained.ok then return retained end
	if not ok or result == false then self.writefileStatus = "failed" return self:_fail("DISCOVERY_ARTIFACT_FILE_FAILED", "writefile") end
	self.backend, self.state, self.writefileStatus = "writefile", "exported", "available"
	return { ok = true, backend = "writefile" }
end

function ExportPipeline:printChunks(writer)
	local encoded = self:encode()
	if not encoded.ok then return encoded end
	if type(writer) ~= "function" then return self:_fail("DISCOVERY_ARTIFACT_CHUNK_OUTPUT_FAILED", "chunk_writer") end
	local retained = self:validateRetention()
	if not retained.ok then return retained end
	self.state = "delivering"
	local total = #self.chunks
	local beginOk = pcall(writer, string.format("UGC_CAPTURE_BEGIN v=1 total=%d bytes=%d hash=%s", total, self.bytes, self.hash))
	retained = self:validateRetention()
	if not retained.ok then return retained end
	if not beginOk then return self:_fail("DISCOVERY_ARTIFACT_CHUNK_OUTPUT_FAILED", "chunk_begin") end
	local offset = 0
	for index, chunk in ipairs(self.chunks) do
		retained = self:validateRetention()
		if not retained.ok then return retained end
		local ok = pcall(writer, string.format("UGC_CAPTURE_CHUNK index=%d total=%d offset=%d length=%d bytes=%d hash=%s data=%s", index, total, offset, #chunk, self.bytes, self.hash, chunk))
		retained = self:validateRetention()
		if not retained.ok then return retained end
		if not ok then return self:_fail("DISCOVERY_ARTIFACT_CHUNK_OUTPUT_FAILED", "chunk_" .. tostring(index)) end
		offset += #chunk
	end
	local endOk = pcall(writer, string.format("UGC_CAPTURE_END total=%d bytes=%d hash=%s", total, self.bytes, self.hash))
	retained = self:validateRetention()
	if not retained.ok then return retained end
	if not endOk then return self:_fail("DISCOVERY_ARTIFACT_CHUNK_OUTPUT_FAILED", "chunk_end") end
	self.backend, self.state = "chunks", "exported"
	return { ok = true, backend = "chunks", chunks = total }
end

function ExportPipeline:clear()
	self.state, self.snapshot, self.json = "empty", nil, nil
	table.clear(self.pages) table.clear(self.chunks)
	self.bytes, self.hash, self.lastError, self.backend = 0, nil, nil, "none"
	self.phase, self.encoder, self.attempt = nil, "none", 0
	self._retentionExpiresUs, self._lastRetentionClockUs = nil, nil
	self._retentionFailure = nil
	self.clipboardStatus = type(self._capabilities.setclipboard) == "function" and "setclipboard"
		or (type(self._capabilities.clipboard) == "function" and "clipboard" or "unavailable")
	self.writefileStatus = type(self._capabilities.writefile) == "function" and "available" or "unavailable"
end

function ExportPipeline:diagnostic(captureState, records, duration, safeInsets)
	return {
		capture_state = captureState,
		export_state = self.state,
		last_error_code = self.lastError or "none",
		phase = self.phase or "none",
		backend = self.backend,
		retryable = self.snapshot ~= nil,
		snapshot_retained = self.snapshot ~= nil,
		attempt = self.attempt,
		record_count = records or 0,
		duration_seconds = duration or 0,
		json_bytes = self.bytes,
		json_sha256 = self.hash or "none",
		safe_insets = safeInsets,
		json_encoder = self.encoder,
		clipboard = self.clipboardStatus,
		writefile = self.writefileStatus,
	}
end

ExportPipeline.splitUtf8 = splitUtf8

return ExportPipeline
end
__factories["MobileApp"] = function(__require)
local Inspector = __require("Inspector")
local ExportPipeline = __require("ExportPipeline")
local Layout = __require("Layout")

local MobileApp = {}

local SENTINEL_NAME = "InfinityUniversalInspector_v1"
local SENTINEL_IDENTITY = "game-discovery-inspector-artifact|0.1.0-development.3"
local pendingUiInstances = nil
local DISPLAY = {
	ready = "Preparado", capturing = "Capturando", stopped = "Detenido",
	exported = "Exportado", error = "Error", unloaded = "Cerrado",
}

local function defaultConfig()
	return {
		contract_version = "v1-draft", schema_version = 1, mode = "passive",
		retention_class = "local-ephemeral", retention_seconds = 86400, duration_seconds = 1800,
		capabilities = { remote_call_observation = false, active_diagnostics = false },
		surfaces = {
			"metadata", "hierarchy", "instances", "attributes", "value_bases", "tags", "character",
			"zones", "inventory", "stats", "tools", "ui", "manual_interactions", "cycles", "errors",
			"remote_inventory",
		},
	}
end

local function newInstance(className, properties, parent)
	local object = Instance.new(className)
	if pendingUiInstances ~= nil then table.insert(pendingUiInstances, object) end
	for key, value in pairs(properties) do object[key] = value end
	object.Parent = parent
	return object
end

local function findPlayerGui(players)
	local player = players.LocalPlayer
	if player == nil then return nil, "DISCOVERY_ARTIFACT_UI_UNAVAILABLE" end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui == nil then
		local ok, value = pcall(function() return player:WaitForChild("PlayerGui", 10) end)
		if ok then playerGui = value end
	end
	if playerGui == nil then return nil, "DISCOVERY_ARTIFACT_UI_UNAVAILABLE" end
	return playerGui, nil
end

local function errorApp(code)
	warn(code)
	return { state = function() return "error" end, unload = function() return true end }
end

local function launchInternal()
	local servicesOk, players, httpService, guiService, inputService, runService = pcall(function()
		return game:GetService("Players"), game:GetService("HttpService"), game:GetService("GuiService"),
			game:GetService("UserInputService"), game:GetService("RunService")
	end)
	if not servicesOk or players == nil or httpService == nil then return errorApp("DISCOVERY_ARTIFACT_UI_UNAVAILABLE") end
	local playerGui, guiError = findPlayerGui(players)
	if playerGui == nil then return errorApp(guiError) end

	local old = playerGui:FindFirstChild(SENTINEL_NAME)
	if old ~= nil then
		if not old:IsA("BindableFunction") then return errorApp("DISCOVERY_ARTIFACT_INSTANCE_CONFLICT") end
		local identityOk, identity = pcall(function() return old:Invoke("identity") end)
		if not identityOk or identity ~= SENTINEL_IDENTITY then return errorApp("DISCOVERY_ARTIFACT_INSTANCE_CONFLICT") end
		local cleanupOk, cleanupResult = pcall(function() return old:Invoke("replace") end)
		if not cleanupOk or cleanupResult ~= true then return errorApp("DISCOVERY_ARTIFACT_INSTANCE_CONFLICT") end
	end

	local owned = setmetatable({}, { __mode = "k" })
	local connections, dragConnections = {}, {}
	local inspector = nil
	local active, unloading, cleanupSucceeded = true, false, false
	local captureState, appState = "ready", "ready"
	local records, duration = 0, 0
	local safeInsetsMode = "fallback"
	local panelX, panelY = 8, 8
	local compactSize, expandedSize, safeRect
	local detailsOpen = false

	local capabilities = {
		setclipboard = type(setclipboard) == "function" and setclipboard or nil,
		clipboard = type(clipboard) == "function" and clipboard or nil,
		writefile = type(writefile) == "function" and writefile or nil,
	}
	local function clockUs()
		return math.floor(os.clock() * 1000000)
	end
	local pipeline = ExportPipeline.new(httpService, capabilities, clockUs)

	local sentinel = newInstance("BindableFunction", { Name = SENTINEL_NAME }, playerGui)
	owned[sentinel] = true
	local screen = newInstance("ScreenGui", {
		Name = "InfinityUniversalInspector", ResetOnSpawn = false, DisplayOrder = 2147483000,
		IgnoreGuiInset = false,
	}, playerGui)
	owned[screen] = true
	local coreInsetsOk = pcall(function()
		local coreInsets = Enum.ScreenInsets.CoreUISafeInsets
		if coreInsets == nil then error("unsupported") end
		screen.ScreenInsets = coreInsets
		screen.ClipToDeviceSafeArea = true
	end)
	local deviceInsetsOk = false
	if not coreInsetsOk then
		deviceInsetsOk = pcall(function()
			local deviceInsets = Enum.ScreenInsets.DeviceSafeInsets
			if deviceInsets == nil then error("unsupported") end
			screen.ScreenInsets = deviceInsets
			screen.ClipToDeviceSafeArea = true
		end)
	end
	if coreInsetsOk or deviceInsetsOk then safeInsetsMode = "native" end
	local frame = newInstance("Frame", {
		Name = "Panel", BackgroundColor3 = Color3.fromRGB(20, 24, 32), BorderSizePixel = 0,
		Active = false, ClipsDescendants = true,
	}, screen)
	owned[frame] = true
	local dragHandle = newInstance("TextButton", {
		Name = "DragHandle", Size = UDim2.new(1, -96, 0, 44), Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(30, 40, 54), Text = "Preparado · 0 · 0s",
		TextColor3 = Color3.fromRGB(245, 248, 255), TextSize = 12, TextWrapped = false, Font = Enum.Font.GothamBold,
		Active = true, AutoButtonColor = false,
	}, frame)
	owned[dragHandle] = true
	local minimizeButton = newInstance("TextButton", {
		Name = "Minimize", Size = UDim2.new(0, 48, 0, 44), Position = UDim2.new(1, -96, 0, 0),
		BackgroundColor3 = Color3.fromRGB(50, 68, 88), Text = "—", TextColor3 = Color3.fromRGB(255,255,255),
		TextSize = 22, Font = Enum.Font.GothamBold, Active = true,
	}, frame)
	owned[minimizeButton] = true
	local closeButton = newInstance("TextButton", {
		Name = "Close", Size = UDim2.new(0, 48, 0, 44), Position = UDim2.new(1, -48, 0, 0),
		BackgroundColor3 = Color3.fromRGB(110, 48, 54), Text = "×", TextColor3 = Color3.fromRGB(255,255,255),
		TextSize = 22, Font = Enum.Font.GothamBold, Active = true,
	}, frame)
	owned[closeButton] = true

	local function actionButton(name, text, index)
		local value = newInstance("TextButton", {
			Name = name, Size = UDim2.new(0.25, -4, 0, 44), Position = UDim2.new(index * 0.25, 2, 0, 44),
			BackgroundColor3 = Color3.fromRGB(45, 88, 125), Text = text,
			TextColor3 = Color3.fromRGB(255,255,255), TextSize = 12, TextWrapped = true, Font = Enum.Font.GothamBold, Active = true,
		}, frame)
		owned[value] = true
		return value
	end
	local startButton = actionButton("Start", "Iniciar", 0)
	local stopButton = actionButton("Stop", "Detener", 1)
	local exportButton = actionButton("Export", "Exportar/Copiar", 2)
	local detailsButton = actionButton("Details", "Detalles", 3)
	local actionButtons = { startButton, stopButton, exportButton, detailsButton }

	local details = newInstance("Frame", {
		Name = "DetailsPanel", Size = UDim2.new(1, 0, 1, -88), Position = UDim2.new(0, 0, 0, 88),
		BackgroundColor3 = Color3.fromRGB(15, 19, 26), Active = false, Visible = false,
	}, frame)
	owned[details] = true
	local diagnosticLabel = newInstance("TextLabel", {
		Name = "Diagnostic", Size = UDim2.new(1, -8, 0, 68), Position = UDim2.new(0, 4, 0, 2),
		BackgroundTransparency = 1, Active = false, Text = "", TextColor3 = Color3.fromRGB(170, 210, 245),
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Code, TextSize = 12,
	}, details)
	owned[diagnosticLabel] = true
	local pageHelp = newInstance("TextLabel", {
		Name = "PageHelp", Size = UDim2.new(1, -8, 0, 24), Position = UDim2.new(0, 4, 0, 70),
		BackgroundTransparency = 1, Active = false, Text = "Mantén pulsado, selecciona todo y copia esta página.",
		TextColor3 = Color3.fromRGB(245, 220, 150), TextSize = 13, TextWrapped = true, Font = Enum.Font.Gotham,
	}, details)
	owned[pageHelp] = true
	local pageText = nil
	pageHelp.Text = "Pulsa Exportar/Copiar para preparar páginas seleccionables."
	local function detailButton(name, text, index)
		local value = newInstance("TextButton", {
			Name = name, Size = UDim2.new(0.2, -3, 0, 44), Position = UDim2.new(index * 0.2, 2, 1, -46),
			BackgroundColor3 = Color3.fromRGB(50, 68, 88), Text = text, TextColor3 = Color3.fromRGB(255,255,255),
			TextSize = 13, TextWrapped = false, Font = Enum.Font.GothamBold, Active = true,
		}, details)
		owned[value] = true
		return value
	end
	local previousButton = detailButton("PreviousPage", "◀", 0)
	local nextButton = detailButton("NextPage", "▶", 1)
	local selectButton = detailButton("SelectPage", "Seleccionar", 2)
	local chunksButton = detailButton("PrintChunks", "Fragmentos", 3)
	local fileButton = detailButton("WriteFile", "Archivo", 4)
	fileButton.Visible = capabilities.writefile ~= nil
	fileButton.Active = capabilities.writefile ~= nil
	local floatingButton = newInstance("TextButton", {
		Name = "Restore", Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0, 8, 0, 8),
		BackgroundColor3 = Color3.fromRGB(45, 88, 125), Text = "IG", TextColor3 = Color3.fromRGB(255,255,255),
		TextSize = 16, Font = Enum.Font.GothamBold, Active = true, Visible = false,
	}, screen)
	owned[floatingButton] = true

	local pageIndex = 1
	local function disconnectList(list)
		local remaining = {}
		for index = #list, 1, -1 do
			local connection = list[index]
			local ok = pcall(function() connection:Disconnect() end)
			if not ok then table.insert(remaining, 1, connection) end
		end
		return remaining
	end
	local function connect(signal, callback, list)
		if signal == nil then return nil end
		local ok, connection = pcall(function() return signal:Connect(callback) end)
		if ok then table.insert(list or connections, connection) return connection end
		return nil
	end

	local function viewportSize()
		local cameraOk, camera = pcall(function() return workspace.CurrentCamera end)
		if cameraOk and camera ~= nil then
			local sizeOk, size = pcall(function() return camera.ViewportSize end)
			if sizeOk and size ~= nil and type(size.X) == "number" and size.X > 0 and type(size.Y) == "number" and size.Y > 0 then
				return size.X, size.Y
			end
		end
		local ok, value = pcall(function() return screen.AbsoluteSize end)
		if ok and value ~= nil and type(value.X) == "number" and value.X > 0 then return value.X, value.Y end
		return 360, 640
	end
	local function nativeInsets()
		if safeInsetsMode == "native" and guiService ~= nil and type(guiService.GetGuiInset) == "function" then
			local ok, topLeft, bottomRight = pcall(function() return guiService:GetGuiInset() end)
			if ok and topLeft ~= nil and bottomRight ~= nil then
				safeInsetsMode = "native"
				return { left = topLeft.X, top = topLeft.Y, right = bottomRight.X, bottom = bottomRight.Y }
			end
		end
		safeInsetsMode = "fallback"
		return { left = 8, top = 8, right = 8, bottom = 8 }
	end
	local function applyLayout()
		local width, height = viewportSize()
		safeRect = Layout.safeRect(width, height, nativeInsets())
		compactSize = Layout.compact(safeRect)
		expandedSize = Layout.expanded(safeRect, compactSize)
		local size = detailsOpen and expandedSize or compactSize
		local actionRows = compactSize.action_rows
		local columns = actionRows == 2 and 2 or 4
		for index, button in ipairs(actionButtons) do
			local slot = index - 1
			local column = slot % columns
			local row = math.floor(slot / columns)
			button.Size = UDim2.new(1 / columns, -4, 0, 44)
			button.Position = UDim2.new(column / columns, 2, 0, 44 + row * 44)
		end
		local detailsTop = 44 + actionRows * 44
		details.Position = UDim2.new(0, 0, 0, detailsTop)
		details.Size = UDim2.new(1, 0, 1, -detailsTop)
		panelX, panelY = Layout.clamp(safeRect, size, panelX, panelY)
		frame.Size = UDim2.new(0, size.width, 0, size.height)
		frame.Position = UDim2.new(0, panelX, 0, panelY)
		local floatX, floatY = Layout.clamp(safeRect, { width = 52, height = 52 }, panelX, panelY)
		floatingButton.Position = UDim2.new(0, floatX, 0, floatY)
		if safeInsetsMode == "fallback" and pipeline.lastError == nil then
			pipeline.lastError = "DISCOVERY_ARTIFACT_SAFE_INSET_FALLBACK"
		end
	end

	local function sanitizedPhase(value)
		if type(value) ~= "string" or #value < 1 or #value > 64 or string.find(value, "[^a-z0-9%._%-]", 1) ~= nil then
			return "ui.error"
		end
		return value
	end
	local function sanitizedCode(value)
		if type(value) ~= "string" or #value < 1 or #value > 64 or string.find(value, "[^A-Z0-9_]", 1) ~= nil then
			return "DISCOVERY_INTERNAL_ERROR"
		end
		return value
	end
	local function setDisplay(nextState, code, phase)
		appState = nextState
		dragHandle.Text = string.format("%s · %d · %ds", DISPLAY[nextState] or DISPLAY.error, records, duration)
		dragHandle.TextColor3 = nextState == "error" and Color3.fromRGB(255, 125, 125) or Color3.fromRGB(245, 248, 255)
		if code ~= nil then
			pipeline.lastError = sanitizedCode(code)
			if phase ~= nil then pipeline.phase = sanitizedPhase(phase) end
		end
		if nextState == "error" and pipeline.phase == nil then
			pipeline.phase = "ui.error"
		end
	end
	local function refreshProgress()
		if inspector ~= nil then
			local ok, value = pcall(function() return inspector:progress() end)
			if ok and type(value) == "table" then
				records, duration = value.record_count or records, value.duration_seconds or duration
				if value.state == "failed" then
					captureState = "fault"
					local failure = type(value.error) == "table" and value.error or {}
					setDisplay("error", failure.code or "DISCOVERY_INTERNAL_ERROR", failure.field or "observer.runtime")
					return
				end
			end
		end
		setDisplay(appState)
	end
	local function refreshDiagnostic()
		if safeInsetsMode == "fallback" and pipeline.lastError == nil then
			pipeline.lastError = "DISCOVERY_ARTIFACT_SAFE_INSET_FALLBACK"
		end
		local diagnostic = pipeline:diagnostic(captureState, records, duration, safeInsetsMode)
		diagnosticLabel.Text = string.format(
			"capture=%s export=%s code=%s phase=%s backend=%s retryable=%s snapshot=%s attempt=%d records=%d duration=%ds bytes=%d hash=%s\ninsets=%s encoder=%s clipboard=%s writefile=%s",
			diagnostic.capture_state, diagnostic.export_state, diagnostic.last_error_code, diagnostic.phase,
			diagnostic.backend, tostring(diagnostic.retryable), tostring(diagnostic.snapshot_retained), diagnostic.attempt,
			diagnostic.record_count, diagnostic.duration_seconds, diagnostic.json_bytes, diagnostic.json_sha256,
			diagnostic.safe_insets, diagnostic.json_encoder, diagnostic.clipboard, diagnostic.writefile
		)
	end
	local function ensurePageText()
		if pageText ~= nil then return pageText end
		pageText = newInstance("TextBox", {
			Name = "ExportText", Size = UDim2.new(1, -8, 1, -144), Position = UDim2.new(0, 4, 0, 96),
			BackgroundColor3 = Color3.fromRGB(8, 11, 16), TextColor3 = Color3.fromRGB(230, 235, 245),
			Text = "", ClearTextOnFocus = false, MultiLine = true, TextEditable = true, TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			Font = Enum.Font.Code, TextSize = 12, Active = true,
		}, details)
		owned[pageText] = true
		return pageText
	end
	local function clearPageText()
		if pageText ~= nil then pcall(function() pageText.Text = "" end) end
	end
	local function showPage(index)
		local retained = pipeline:validateRetention()
		if not retained.ok then
			clearPageText()
			return false, retained.code
		end
		if #pipeline.pages == 0 then return false, "DISCOVERY_ARTIFACT_TEXTBOX_EMPTY" end
		local createOk, textBox = pcall(ensurePageText)
		if not createOk or textBox == nil then return false, "DISCOVERY_ARTIFACT_TEXTBOX_ASSIGN_FAILED" end
		pageIndex = math.max(1, math.min(index, #pipeline.pages))
		local ok = pcall(function()
			textBox.Text = pipeline.pages[pageIndex]
			pageHelp.Text = string.format("Página %d/%d · mantén pulsado, selecciona todo y copia.", pageIndex, #pipeline.pages)
		end)
		if not ok then return false, "DISCOVERY_ARTIFACT_TEXTBOX_ASSIGN_FAILED" end
		retained = pipeline:validateRetention()
		if not retained.ok then
			clearPageText()
			return false, retained.code
		end
		return true
	end
	local function expireInspectorIfNeeded(code)
		if (code == "DISCOVERY_RETENTION_EXPIRED" or code == "DISCOVERY_RETENTION_INVALID" or code == "DISCOVERY_CLOCK_INVALID") and inspector ~= nil then
			pcall(function() inspector:unload() end)
			clearPageText()
		end
	end

	local function isOwnedInstance(instance)
		local current = instance
		while current ~= nil do if owned[current] then return true end current = current.Parent end
		return false
	end
	local function cleanup()
		if cleanupSucceeded then return true end
		if unloading then return false end
		unloading, active, appState = true, false, "unloaded"
		if inspector ~= nil then
			local ok, result = pcall(function() return inspector:unload() end)
			if not ok or type(result) ~= "table" or result.ok ~= true then
				unloading = false setDisplay("error", "DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup") warn("DISCOVERY_CLEANUP_FAILED") return false
			end
			inspector = nil
		end
		pipeline:clear()
		pageIndex, records, duration = 1, 0, 0
		dragConnections = disconnectList(dragConnections)
		connections = disconnectList(connections)
		if #dragConnections > 0 or #connections > 0 then
			unloading = false setDisplay("error", "DISCOVERY_CLEANUP_FAILED", "lifecycle.cleanup") warn("DISCOVERY_CLEANUP_FAILED") return false
		end
		local screenOk = pcall(function() screen:Destroy() end)
		if not screenOk or screen.Parent ~= nil then unloading = false warn("DISCOVERY_CLEANUP_FAILED") return false end
		local sentinelOk = pcall(function() sentinel:Destroy() end)
		cleanupSucceeded = sentinelOk and sentinel.Parent == nil
		unloading = false
		if not cleanupSucceeded then warn("DISCOVERY_CLEANUP_FAILED") end
		return cleanupSucceeded
	end

	sentinel.OnInvoke = function(command)
		if command == "identity" then return SENTINEL_IDENTITY end
		if command == "unload" or command == "replace" then return cleanup() end
		return false
	end

	connect(startButton.Activated, function()
		if captureState ~= "ready" then captureState = "fault" setDisplay("error", "DISCOVERY_CONFIG_INVALID", "lifecycle.start.state") refreshDiagnostic() return end
		pipeline:clear()
		local created = Inspector.new(defaultConfig(), {
			clockUs = clockUs,
			isOwnedInstance = isOwnedInstance,
			scheduler = {
				delay = function(seconds, callback)
					return task.delay(seconds, function()
						callback()
						if active and inspector ~= nil and inspector:state() == "stopped" then
							captureState = "stopped" refreshProgress()
							local exported = inspector:exportSnapshot()
							if exported.ok then
								local sealed, sealError = pipeline:seal(exported.value, exported.retention_expires_clock_us)
								if sealed then setDisplay("stopped") else expireInspectorIfNeeded(sealError) setDisplay("error", sealError, pipeline.phase) end
							else setDisplay("error", exported.error.code, exported.error.field) end
							refreshDiagnostic()
						end
					end)
				end,
				cancel = function(thread) task.cancel(thread) end,
			},
		})
		if not created.ok then captureState = "fault" setDisplay("error", created.error.code, created.error.field) refreshDiagnostic() return end
		inspector = created.value
		local started = inspector:start()
		if not started.ok then captureState = "fault" setDisplay("error", started.error.code, started.error.field) refreshDiagnostic() return end
		captureState, records, duration = "capturing", 0, 0
		setDisplay("capturing") refreshDiagnostic()
	end)
	connect(stopButton.Activated, function()
		if captureState == "stopped" then setDisplay(pipeline.state == "exported" and "exported" or "stopped") refreshDiagnostic() return end
		if captureState ~= "capturing" or inspector == nil then setDisplay("error", "DISCOVERY_CONFIG_INVALID", "lifecycle.stop.state") refreshDiagnostic() return end
		local stopped = inspector:stop()
		refreshProgress()
		if not stopped.ok then setDisplay("error", stopped.error.code, stopped.error.field) refreshDiagnostic() return end
		captureState = "stopped"
		local exported = inspector:exportSnapshot()
		if not exported.ok then setDisplay("error", exported.error.code, exported.error.field) refreshDiagnostic() return end
		local sealed, sealError = pipeline:seal(exported.value, exported.retention_expires_clock_us)
		if not sealed then expireInspectorIfNeeded(sealError) setDisplay("error", sealError, pipeline.phase) refreshDiagnostic() return end
		setDisplay("stopped") refreshDiagnostic()
	end)
	connect(exportButton.Activated, function()
		if captureState == "stopped" then
			local retained = pipeline:validateRetention()
			if not retained.ok then expireInspectorIfNeeded(retained.code) setDisplay("error", retained.code, retained.phase) refreshDiagnostic() return end
		end
		if captureState ~= "stopped" or pipeline.snapshot == nil then setDisplay("error", "DISCOVERY_CONFIG_INVALID", "lifecycle.export.state") refreshDiagnostic() return end
		local encoded = pipeline:encode()
		if not encoded.ok then expireInspectorIfNeeded(encoded.code) setDisplay("error", encoded.code, encoded.phase) refreshDiagnostic() return end
		local textReady, textError = showPage(1)
		local delivered = pipeline:deliverClipboard()
		if not delivered.ok then expireInspectorIfNeeded(delivered.code) setDisplay("error", delivered.code, delivered.phase) refreshDiagnostic() return end
		if delivered.ok and delivered.backend == "clipboard" then
			setDisplay("exported")
		elseif textReady then
			detailsOpen, details.Visible = true, true applyLayout() setDisplay("exported")
		else
			expireInspectorIfNeeded(textError)
			pipeline:_fail(textError, "textbox") setDisplay("error", textError, "textbox")
		end
		refreshDiagnostic()
	end)
	connect(detailsButton.Activated, function()
		detailsOpen = not detailsOpen details.Visible = detailsOpen applyLayout() refreshDiagnostic()
	end)
	connect(previousButton.Activated, function()
		local ok, code = showPage(pageIndex - 1) if not ok then
			if code ~= "DISCOVERY_RETENTION_EXPIRED" then pipeline:_fail(code, "textbox") end
			expireInspectorIfNeeded(code) setDisplay("error", code, pipeline.phase or "textbox")
		end refreshDiagnostic()
	end)
	connect(nextButton.Activated, function()
		local ok, code = showPage(pageIndex + 1) if not ok then
			if code ~= "DISCOVERY_RETENTION_EXPIRED" then pipeline:_fail(code, "textbox") end
			expireInspectorIfNeeded(code) setDisplay("error", code, pipeline.phase or "textbox")
		end refreshDiagnostic()
	end)
	connect(selectButton.Activated, function()
		local retained = pipeline:validateRetention()
		if not retained.ok then expireInspectorIfNeeded(retained.code) setDisplay("error", retained.code, retained.phase) refreshDiagnostic() return end
		local ok = pageText ~= nil and pcall(function() pageText:CaptureFocus() pageText.SelectionStart = 1 pageText.CursorPosition = #pageText.Text + 1 end)
		if not ok then pipeline:_fail("DISCOVERY_ARTIFACT_TEXTBOX_FOCUS_FAILED", "textbox") setDisplay("error", "DISCOVERY_ARTIFACT_TEXTBOX_FOCUS_FAILED", "textbox") end
		retained = pipeline:validateRetention()
		if not retained.ok then expireInspectorIfNeeded(retained.code) setDisplay("error", retained.code, retained.phase) end
		refreshDiagnostic()
	end)
	connect(chunksButton.Activated, function()
		local result = pipeline:printChunks(print)
		if result.ok then setDisplay("exported") else expireInspectorIfNeeded(result.code) setDisplay("error", result.code, result.phase) end refreshDiagnostic()
	end)
	if capabilities.writefile ~= nil then
		connect(fileButton.Activated, function()
			local result = pipeline:writeFile()
			if result.ok then setDisplay("exported") else expireInspectorIfNeeded(result.code) setDisplay("error", result.code, result.phase) end refreshDiagnostic()
		end)
	end
	connect(minimizeButton.Activated, function() frame.Visible, floatingButton.Visible = false, true end)
	connect(floatingButton.Activated, function() frame.Visible, floatingButton.Visible = true, false applyLayout() end)
	connect(closeButton.Activated, cleanup)

	local function endDrag() dragConnections = disconnectList(dragConnections) end
	connect(dragHandle.InputBegan, function(input)
		local inputType = input and input.UserInputType
		if inputType ~= Enum.UserInputType.Touch and inputType ~= Enum.UserInputType.MouseButton1 then return end
		endDrag()
		local startX, startY = input.Position.X, input.Position.Y
		local originX, originY = panelX, panelY
		if inputService ~= nil then
			connect(inputService.InputChanged, function(changed)
				if changed == input or changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch then
					local size = detailsOpen and expandedSize or compactSize
					panelX, panelY = Layout.clamp(safeRect, size, originX + changed.Position.X - startX, originY + changed.Position.Y - startY)
					frame.Position = UDim2.new(0, panelX, 0, panelY)
				end
			end, dragConnections)
			connect(inputService.InputEnded, function(ended)
				if ended == input or ended.UserInputType == inputType then endDrag() end
			end, dragConnections)
		end
	end)

	if runService ~= nil then connect(runService.Heartbeat, function()
		if captureState == "capturing" then
			refreshProgress()
			if appState == "error" then refreshDiagnostic() end
		elseif captureState == "stopped" then
			local retained = pipeline:validateRetention()
			if not retained.ok then expireInspectorIfNeeded(retained.code) setDisplay("error", retained.code, retained.phase) refreshDiagnostic() end
		end
	end) end
	local sizeSignalOk, sizeSignal = pcall(function() return screen:GetPropertyChangedSignal("AbsoluteSize") end)
	if sizeSignalOk then connect(sizeSignal, applyLayout) end
	applyLayout() setDisplay("ready") refreshDiagnostic()
	return { state = function() return appState end, unload = cleanup }
end

function MobileApp.launch()
	pendingUiInstances = {}
	local ok, app = pcall(launchInternal)
	if not ok then
		for index = #pendingUiInstances, 1, -1 do pcall(function() pendingUiInstances[index]:Destroy() end) end
		pendingUiInstances = nil
		return errorApp("DISCOVERY_ARTIFACT_UI_UNAVAILABLE")
	end
	pendingUiInstances = nil
	return app
end

return MobileApp
end
return __require("MobileApp").launch()
