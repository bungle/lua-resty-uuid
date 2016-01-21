package = "lua-resty-uuid"
version = "dev-1"
source = {
    url = "git://github.com/bungle/lua-resty-uuid.git"
}
description = {
    summary = "DCE compatible Universally Unique Identifier (UUID/GUID) library",
    detailed = "lua-resty-uuid is a DCE compatible Universally Unique Identifier library for Lua and OpenResty.",
    homepage = "https://github.com/bungle/lua-resty-uuid",
    maintainer = "Aapo Talvensaari <aapo.talvensaari@gmail.com>",
    license = "BSD"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        ["resty.uuid"] = "lib/resty/uuid.lua"
    }
}
