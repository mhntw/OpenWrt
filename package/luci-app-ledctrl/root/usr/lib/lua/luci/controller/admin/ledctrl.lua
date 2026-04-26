-- LED Control Controller for LuCI
-- JDCloud AX1800 Pro / OpenWrt / iStoreOS 通用

module("luci.controller.admin.ledctrl", package.seeall)

local FS = require "nixio.fs"

local SYSFS = "/sys/class/leds/"

-- 跳过的 LED（SD 卡等系统 LED）
local SKIP_LEDS = {
    ["mmc0::"] = true,
    [":"]     = true,   -- 防止 . 和 .. 被误认
}

function index()
    entry({"admin", "system", "ledctrl"}, template("ledctrl"), _("LED Control"), 60).dependent = false
    entry({"admin", "system", "ledctrl", "api"}, call("led_api")).sysauth = false
end

function led_api()
    local http  = require "luci.http"
    local json  = require "luci.jsonc"
    local act   = http.formvalue("action") or "list"
    local res   = {}

    if     act == "list"      then res = list_leds()
    elseif act == "all_off"   then res = set_all_leds(0)
    elseif act == "default"   then res = set_default_leds()
    else
        http.status(400, "Bad Request")
        http.prepare_content("application/json")
        http.write(json.stringify({ success = false, error = "Unknown action: " .. act }))
        return
    end

    http.prepare_content("application/json")
    http.write(json.stringify(res))
end

-- 读取所有 LED 状态
function list_leds()
    local t = {}
    for name in FS.dir(SYSFS) do
        if not SKIP_LEDS[name] and name ~= "." and name ~= ".." then
            local bp = SYSFS .. name .. "/brightness"
            local f = io.open(bp, "r")
            if f then
                local br = tonumber(f:read("*a")) or 0
                f:close()
                t[#t + 1] = { name = name, brightness = br, on = br > 0 }
            end
        end
    end
    return { success = true, leds = t }
end

-- 设置所有 LED 亮度
function set_all_leds(value)
    local t = {}
    for name in FS.dir(SYSFS) do
        if not SKIP_LEDS[name] and name ~= "." and name ~= ".." then
            local bp = SYSFS .. name .. "/brightness"
            local f = io.open(bp, "w")
            if f then
                f:write(tostring(value))
                f:close()
                t[name] = true
            else
                t[name] = false
            end
        end
    end
    return { success = true, action = "all_off", results = t }
end

-- 恢复出厂：仅绿色 LED 常亮
function set_default_leds()
    local t = {}
    for name in FS.dir(SYSFS) do
        if not SKIP_LEDS[name] and name ~= "." and name ~= ".." then
            local bp = SYSFS .. name .. "/brightness"
            local v  = 0
            -- 支持各平台绿色 LED 命名
            if name == "green:status" or name == "green:power"
               or name == "led_g1"    or name == "green:usb"
               or name == "led_green" or name == "power:green" then
                v = 255
            end
            local f = io.open(bp, "w")
            if f then
                f:write(tostring(v))
                f:close()
                t[name] = v
            else
                t[name] = false
            end
        end
    end
    return { success = true, action = "default", results = t }
end
