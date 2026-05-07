# lua-resty-uuid

LuaJIT FFI bindings for [libuuid] — a DCE-compatible Universally Unique
Identifier (UUID/GUID) library. Generates v1 (time), v4 (random), v6
(reordered time) and v7 (Unix-epoch) UUIDs, plus parses and inspects
existing UUID strings.

[libuuid]: https://man7.org/linux/man-pages/man3/libuuid.3.html

## Status

Production-ready. Used in OpenResty / LuaJIT environments. Pure FFI
bindings — no C build step required, just `libuuid` on the system.

## Requirements

- LuaJIT (or Lua 5.1+ with the `luaffi` shim)
- `libuuid` available on the dynamic loader path
  - Debian / Ubuntu: `apt install uuid-dev` (provides `libuuid.so`)
  - Alpine: `apk add util-linux-dev`
  - RHEL / Fedora: `dnf install libuuid-devel`
  - macOS: bundled with the system (loaded from `libSystem`)

## Installation

### Via LuaRocks

```sh
luarocks install lua-resty-uuid
```

### From source

```sh
git clone https://github.com/bungle/lua-resty-uuid
cd lua-resty-uuid
luarocks make
```

The library will look for `libuuid` first in `package.cpath`, then on the
system loader path, falling back to symbols already present in the host
process.

## Quick start

```lua
local uuid = require "resty.uuid"

uuid.generate()         --> "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
uuid.generate_random()  --> "550e8400-e29b-41d4-a716-446655440000"  (v4)
uuid.generate_time()    --> "..."                                   (v1)
uuid.generate_time_v6() --> "..."                                   (v6)
uuid.generate_time_v7() --> "..."                                   (v7)

uuid()                  --> shortcut for uuid.generate()

uuid.is_valid("not-a-uuid")  --> false
uuid.type(some_v4_id)        --> 4
uuid.variant(some_id)        --> 1   (DCE)
uuid.time(some_v1_id)        --> 1714867200, 123456
```

## API

The module is a table that is also callable. Calling `uuid()` is a
shortcut for `uuid.generate()`.

### Generators

| Function | Returns | Description |
| --- | --- | --- |
| `uuid.generate()` | `string` | Best generator available on the host (random when possible, otherwise time-based). |
| `uuid.generate_random()` | `string` | Version 4 (random) UUID. |
| `uuid.generate_time()` | `string` | Version 1 (timestamp + node id) UUID. |
| `uuid.generate_time_safe()` | `string, boolean` | Version 1 UUID and a flag indicating whether generation was synchronized for uniqueness. |
| `uuid.generate_time_v6()` | `string` | Version 6 UUID — v1 fields reordered for lexical sortability. |
| `uuid.generate_time_v7()` | `string` | Version 7 UUID — millisecond Unix timestamp + random tail. |

All generators return the canonical 36-character `8-4-4-4-12` lower-case
hex form, e.g. `"f81d4fae-7dec-11d0-a765-00a0c91e6bf6"`.

### Inspection

| Function | Returns | Description |
| --- | --- | --- |
| `uuid.is_valid(id)` | `boolean` | Whether `id` parses as a UUID. |
| `uuid.type(id)` | `int` or `nil` | UUID version (`UUID_TYPE_*` constant), or `nil` if invalid. |
| `uuid.variant(id)` | `int` or `nil` | UUID variant (`UUID_VARIANT_*` constant), or `nil` if invalid. |
| `uuid.time(id)` | `number, number` or `nil` | Seconds since the Unix epoch and microseconds within that second; `nil` if `id` is not a valid UUID. Meaningful only for v1, v6 and v7. |

### Constant reference

`uuid.type` returns one of:

| Value | Constant | Meaning |
| --- | --- | --- |
| `1` | `UUID_TYPE_DCE_TIME` | Time-based (v1) |
| `2` | `UUID_TYPE_DCE_SECURITY` | DCE Security (v2) |
| `3` | `UUID_TYPE_DCE_MD5` | Name-based MD5 (v3) |
| `4` | `UUID_TYPE_DCE_RANDOM` | Random (v4) |
| `5` | `UUID_TYPE_DCE_SHA1` | Name-based SHA-1 (v5) |
| `6` | `UUID_TYPE_DCE_TIME_V6` | Reordered time (v6) |
| `7` | `UUID_TYPE_DCE_TIME_V7` | Unix-epoch time (v7) |

`uuid.variant` returns one of:

| Value | Constant | Meaning |
| --- | --- | --- |
| `0` | `UUID_VARIANT_NCS` | NCS / Apollo legacy |
| `1` | `UUID_VARIANT_DCE` | DCE 1.1 / RFC 4122 |
| `2` | `UUID_VARIANT_MICROSOFT` | Microsoft GUID |
| `3` | `UUID_VARIANT_OTHER` | Reserved |

## Testing

```sh
make test          # full pipeline: install rock, run busted, coverage, lint
make unit          # busted only
make coverage      # busted + luacov report
make lint          # luacheck
```

Tests live in `spec/` and exercise every public function plus the
`__call` metamethod.

## Documentation

API reference is built with [LDoc] and lives under `docs/`:

```sh
make docs
```

[LDoc]: https://github.com/lunarmodules/LDoc

## License

BSD 2-Clause. See [LICENSE](LICENSE).

Copyright (c) 2014 — 2026 Aapo Talvensaari.
