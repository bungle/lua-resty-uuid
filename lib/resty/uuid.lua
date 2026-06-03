---
-- LuaJIT FFI bindings to UUID library
--
-- @module resty.uuid


local ffi          = require "ffi"
local ffi_new      = ffi.new
local ffi_str      = ffi.string
local ffi_load     = ffi.load
local ffi_cdef     = ffi.cdef
local pcall        = pcall
local tonumber     = tonumber
local setmetatable = setmetatable


ffi_cdef[[
typedef unsigned char uuid_t[16];
typedef struct timeval {
  int64_t tv_sec;
  int64_t tv_usec;
} timeval;
   void uuid_generate(uuid_t out);
   void uuid_generate_random(uuid_t out);
   void uuid_generate_time(uuid_t out);
    int uuid_generate_time_safe(uuid_t out);
   void uuid_generate_time_v6(uuid_t out);
   void uuid_generate_time_v7(uuid_t out);
    int uuid_parse(const char *in, uuid_t uu);
   void uuid_unparse(const uuid_t uu, char *out);
    int uuid_type(const uuid_t uu);
    int uuid_variant(const uuid_t uu);
int64_t uuid_time(const uuid_t uu, struct timeval *ret_tv);
]]


local function load_lib(name)
  local pok, lib = pcall(ffi_load, name)
  if pok then
    return lib
  end
end


local load_lib_from_cpath do
  local gmatch = string.gmatch
  local match = string.match
  local open = io.open
  local close = io.close
  local cpath = package.cpath
  function load_lib_from_cpath(name)
    for path, _ in gmatch(cpath, "[^;]+") do
      if path == "?.so" or path == "?.dylib" then
        path = "./"
      end
      local file_path = match(path, "(.*/)")
      file_path = file_path .. name
      local file = open(file_path)
      if file ~= nil then
        close(file)
        local lib = load_lib(file_path)
        return lib
      end
    end
  end
end


local function load_uuid()
  local ipairs = ipairs

  local library_names = {
    "libuuid",
    "uuid",
  }

  local library_versions = {
    "",
    ".1",
  }

  local library_extensions = ffi.os == "OSX" and { ".dylib", ".so" }
    or { ".so", ".dylib" }

  -- try to load ada library from package.cpath
  for _, library_name in ipairs(library_names) do
    for _, library_version in ipairs(library_versions) do
      for _, library_extension in ipairs(library_extensions) do
        local lib = load_lib_from_cpath(library_name .. library_extension .. library_version)
        if lib then
          return lib
        end
        lib = load_lib_from_cpath(library_name .. library_version .. library_extension)
        if lib then
          return lib
        end
      end
    end
  end

  -- try to load ada library from normal system path
  for _, library_name in ipairs(library_names) do
    for _, library_version in ipairs(library_versions) do
      for _, library_extension in ipairs(library_extensions) do
        local lib = load_lib(library_name .. library_extension .. library_version)
        if lib then
          return lib
        end
        lib = load_lib(library_name .. library_version .. library_extension)
        if lib then
          return lib
        end
        lib = load_lib(library_name .. library_version)
        if lib then
          return lib
        end
      end
    end
  end

  -- a final check before we give up
  local pok, lib = pcall(function()
    if ffi.C.uuid_generate then
      return ffi.C
    end
  end)
  if pok then
    return lib
  end

  error("unable to load uuid library - please make sure that it can be found in package.cpath or system library path")
end


local lib = load_uuid()
local uid = ffi_new "uuid_t"
local tvl = ffi_new "timeval"
local buf = ffi_new("char[?]", 36)


local uuid = {}
local mt   = {}


local function unparse(id)
  lib.uuid_unparse(id, buf)
  return ffi_str(buf, 36)
end


local function parse(id)
  return lib.uuid_parse(id, uid) == 0 and uid or nil
end


---
-- Generate Functions
-- @section generate-functions


--- Generates a new UUID.
--
-- Picks the best available generator on the host: prefers a high-quality
-- randomness source (v4) when available, otherwise falls back to a
-- time-based UUID (v1).
--
-- @function generate
-- @treturn string a 36-character canonical UUID (e.g. `"f81d4fae-7dec-11d0-a765-00a0c91e6bf6"`).
-- @usage
-- local uuid = require("resty.uuid")
-- local id = uuid.generate()
function uuid.generate()
  lib.uuid_generate(uid)
  return unparse(uid)
end


--- Generates a random (version 4) UUID.
--
-- Uses the system's cryptographic random source. If high-quality randomness
-- is unavailable, libuuid falls back to a pseudo-random generator.
--
-- @function generate_random
-- @treturn string a 36-character canonical v4 UUID.
-- @usage
-- local uuid = require("resty.uuid")
-- local id = uuid.generate_random()
function uuid.generate_random()
  lib.uuid_generate_random(uid)
  return unparse(uid)
end


--- Generates a time-based (version 1) UUID.
--
-- Encodes the current timestamp and the host's MAC address (or a random
-- node id when no MAC is available).
--
-- @function generate_time
-- @treturn string a 36-character canonical v1 UUID.
-- @usage
-- local uuid = require("resty.uuid")
-- local id = uuid.generate_time()
function uuid.generate_time()
  lib.uuid_generate_time(uid)
  return unparse(uid)
end


--- Generates a time-based (version 1) UUID and reports whether generation
--  was uniqueness-safe.
--
-- The `safe` flag indicates whether libuuid was able to use synchronization
-- (typically via `uuidd`) to guarantee uniqueness across concurrent callers.
-- A value of `false` means the UUID is still well-formed but may collide if
-- the same node generates many UUIDs in the same clock tick from multiple
-- processes.
--
-- @function generate_time_safe
-- @treturn string a 36-character canonical v1 UUID.
-- @treturn boolean `true` if generation was synchronized/safe, `false` otherwise.
-- @usage
-- local uuid = require("resty.uuid")
-- local id, safe = uuid.generate_time_safe()
function uuid.generate_time_safe()
  local safe = lib.uuid_generate_time_safe(uid) == 0
  return unparse(uid), safe
end


--- Generates a reordered time-based (version 6) UUID.
--
-- Version 6 reorders the v1 timestamp fields so the UUID sorts naturally
-- in lexical order, while remaining compatible with v1 node/clock semantics.
--
-- @function generate_time_v6
-- @treturn string a 36-character canonical v6 UUID.
-- @usage
-- local uuid = require("resty.uuid")
-- local id = uuid.generate_time_v6()
function uuid.generate_time_v6()
  lib.uuid_generate_time_v6(uid)
  return unparse(uid)
end


--- Generates a Unix-epoch time-based (version 7) UUID.
--
-- Version 7 encodes a millisecond-resolution Unix timestamp followed by
-- random bits, and sorts naturally in lexical order.
--
-- @function generate_time_v7
-- @treturn string a 36-character canonical v7 UUID.
-- @usage
-- local uuid = require("resty.uuid")
-- local id = uuid.generate_time_v7()
function uuid.generate_time_v7()
  lib.uuid_generate_time_v7(uid)
  return unparse(uid)
end


---
-- Time Extraction
-- @section time-functions


--- Extracts the timestamp embedded in a time-based UUID.
--
-- Only meaningful for v1, v6 and v7 UUIDs. For other versions the result
-- is the value libuuid synthesizes from the bits and is not a real time.
--
-- @function time
-- @tparam string id a UUID string to inspect.
-- @treturn ?number seconds since the Unix epoch, or `nil` if `id` is not a valid UUID.
-- @treturn ?number microseconds within that second.
-- @usage
-- local uuid = require("resty.uuid")
-- local secs, usecs = uuid.time(id)
function uuid.time(id)
  local parsed = parse(id)
  if parsed then
    local secs = lib.uuid_time(parsed, tvl)
    return tonumber(secs, 10), tonumber(tvl.tv_usec, 10)
  end
end


---
-- Type / Variant Functions
-- @section type-functions


--- Returns the UUID type (version) of a UUID string.
--
-- The returned integer corresponds to libuuid's `UUID_TYPE_*` constants
-- (`1` = DCE time/v1, `4` = DCE random/v4, `6` = v6, `7` = v7, etc.).
--
-- @function type
-- @tparam string id a UUID string to inspect.
-- @treturn ?int the UUID type, or `nil` if `id` is not a valid UUID.
-- @usage
-- local uuid = require("resty.uuid")
-- local t = uuid.type("f81d4fae-7dec-11d0-a765-00a0c91e6bf6") --> 1
function uuid.type(id)
  local parsed = parse(id)
  return parsed and lib.uuid_type(parsed)
end


--- Returns the UUID variant of a UUID string.
--
-- The returned integer corresponds to libuuid's `UUID_VARIANT_*` constants
-- (`0` = NCS, `1` = DCE, `2` = Microsoft, `3` = other/reserved).
--
-- @function variant
-- @tparam string id a UUID string to inspect.
-- @treturn ?int the UUID variant, or `nil` if `id` is not a valid UUID.
-- @usage
-- local uuid = require("resty.uuid")
-- local v = uuid.variant("f81d4fae-7dec-11d0-a765-00a0c91e6bf6") --> 1
function uuid.variant(id)
  local parsed = parse(id)
  return parsed and lib.uuid_variant(parsed)
end


---
-- Validation Functions
-- @section validation-functions


--- Tests whether a string is a syntactically valid UUID.
--
-- Accepts the canonical 36-character `8-4-4-4-12` hex form in either case.
-- Does not check the version or variant fields beyond what libuuid's parser
-- requires.
--
-- @function is_valid
-- @tparam string id the candidate UUID string.
-- @treturn boolean `true` if `id` parses as a UUID, `false` otherwise.
-- @usage
-- local uuid = require("resty.uuid")
-- if uuid.is_valid(s) then
--   ...
-- end
function uuid.is_valid(id)
  return not not parse(id)
end


---
-- Metamethods
-- @section metamethods


--- Calls the module as a shortcut for `uuid.generate`.
--
-- Lets you write `uuid()` instead of `uuid.generate()`.
--
-- @function __call
-- @treturn string a 36-character canonical UUID.
-- @usage
-- local uuid = require("resty.uuid")'
-- local id = uuid()
mt.__call = uuid.generate


return setmetatable(uuid, mt)