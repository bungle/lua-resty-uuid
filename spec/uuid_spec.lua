local uuid = require "resty.uuid"


local UUID_PATTERN =
  "^[0-9a-f][0-9a-f][0-9a-f][0-9a-f]"   ..
   "[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%-" ..
   "[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%-" ..
   "[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%-" ..
   "[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%-" ..
   "[0-9a-f][0-9a-f][0-9a-f][0-9a-f]"   ..
   "[0-9a-f][0-9a-f][0-9a-f][0-9a-f]"   ..
   "[0-9a-f][0-9a-f][0-9a-f][0-9a-f]$"

local UUID_TYPE_DCE_TIME    = 1
local UUID_TYPE_DCE_RANDOM  = 4
--local UUID_TYPE_DCE_TIME_V6 = 6
--local UUID_TYPE_DCE_TIME_V7 = 7

local UUID_VARIANT_DCE = 1


local function version_nibble(id)
  return tonumber(id:sub(15, 15), 16)
end


describe("resty.uuid", function()
  describe("generate()", function()
    it("returns a 36-character formatted UUID string", function()
      local id = uuid.generate()
      assert.is_string(id)
      assert.equal(36, #id)
      assert.matches(UUID_PATTERN, id)
    end)

    it("returns distinct UUIDs across calls", function()
      assert.are_not.equal(uuid.generate(), uuid.generate())
    end)
  end)

  describe("generate_random()", function()
    it("returns a v4 UUID", function()
      local id = uuid.generate_random()
      assert.matches(UUID_PATTERN, id)
      assert.equal(4, version_nibble(id))
    end)

    it("returns distinct UUIDs across calls", function()
      assert.are_not.equal(uuid.generate_random(), uuid.generate_random())
    end)
  end)

  describe("generate_time()", function()
    it("returns a v1 UUID", function()
      local id = uuid.generate_time()
      assert.matches(UUID_PATTERN, id)
      assert.equal(1, version_nibble(id))
    end)
  end)

  describe("generate_time_safe()", function()
    it("returns a v1 UUID and a boolean safety flag", function()
      local id, safe = uuid.generate_time_safe()
      assert.matches(UUID_PATTERN, id)
      assert.equal(1, version_nibble(id))
      assert.is_boolean(safe)
    end)
  end)

  -- skipping these because ubuntu noble still has too old util-linux
  --describe("generate_time_v6()", function()
  --  it("returns a v6 UUID", function()
  --    local id = uuid.generate_time_v6()
  --    assert.matches(UUID_PATTERN, id)
  --    assert.equal(6, version_nibble(id))
  --  end)
  --end)
  --
  --describe("generate_time_v7()", function()
  --  it("returns a v7 UUID", function()
  --    local id = uuid.generate_time_v7()
  --    assert.matches(UUID_PATTERN, id)
  --    assert.equal(7, version_nibble(id))
  --  end)
  --end)

  describe("is_valid()", function()
    it("accepts a freshly generated UUID", function()
      assert.is_true(uuid.is_valid(uuid.generate()))
      assert.is_true(uuid.is_valid(uuid.generate_random()))
      assert.is_true(uuid.is_valid(uuid.generate_time()))
    end)

    it("accepts a canonical lower-case UUID literal", function()
      assert.is_true(uuid.is_valid("550e8400-e29b-41d4-a716-446655440000"))
    end)

    it("accepts upper-case hex", function()
      assert.is_true(uuid.is_valid("550E8400-E29B-41D4-A716-446655440000"))
    end)

    it("accepts the nil UUID", function()
      assert.is_true(uuid.is_valid("00000000-0000-0000-0000-000000000000"))
    end)

    it("rejects malformed strings", function()
      assert.is_false(uuid.is_valid(""))
      assert.is_false(uuid.is_valid("not a uuid"))
      assert.is_false(uuid.is_valid("550e8400-e29b-41d4-a716-44665544000"))   -- short
      assert.is_false(uuid.is_valid("550e8400-e29b-41d4-a716-4466554400000")) -- long
      assert.is_false(uuid.is_valid("550e8400e29b41d4a716446655440000"))      -- no dashes
      assert.is_false(uuid.is_valid("550e8400-e29b-41d4-a716-44665544zzzz"))  -- non-hex
    end)
  end)

  describe("type()", function()
    it("identifies a random UUID as DCE_RANDOM", function()
      assert.equal(UUID_TYPE_DCE_RANDOM, uuid.type(uuid.generate_random()))
    end)

    it("identifies a time UUID as DCE_TIME", function()
      assert.equal(UUID_TYPE_DCE_TIME, uuid.type(uuid.generate_time()))
    end)

    -- skipping these because ubuntu noble still has too old util-linux
    --it("identifies a v6 UUID", function()
    --  assert.equal(UUID_TYPE_DCE_TIME_V6, uuid.type(uuid.generate_time_v6()))
    --end)
    --
    --it("identifies a v7 UUID", function()
    --  assert.equal(UUID_TYPE_DCE_TIME_V7, uuid.type(uuid.generate_time_v7()))
    --end)

    it("returns nil for an invalid UUID", function()
      assert.is_nil(uuid.type("not a uuid"))
    end)
  end)

  describe("variant()", function()
    it("returns DCE for generated UUIDs", function()
      assert.equal(UUID_VARIANT_DCE, uuid.variant(uuid.generate_random()))
      assert.equal(UUID_VARIANT_DCE, uuid.variant(uuid.generate_time()))
    end)

    it("returns nil for an invalid UUID", function()
      assert.is_nil(uuid.variant("not a uuid"))
    end)
  end)

  describe("time()", function()
    it("returns seconds and microseconds for a time UUID", function()
      local before = os.time() - 1
      local secs, usecs = uuid.time(uuid.generate_time())
      local after = os.time() + 1
      assert.is_number(secs)
      assert.is_number(usecs)
      assert.is_true(secs >= before)
      assert.is_true(secs <= after)
      assert.is_true(usecs >= 0 and usecs < 1000000)
    end)

    it("returns nil for an invalid UUID", function()
      assert.is_nil(uuid.time("not a uuid"))
    end)
  end)

  describe("__call metamethod", function()
    it("makes the module callable as a generator", function()
      local id = uuid()
      assert.is_string(id)
      assert.matches(UUID_PATTERN, id)
    end)
  end)
end)
