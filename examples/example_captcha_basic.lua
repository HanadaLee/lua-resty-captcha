#!/usr/bin/env lua

-- Basic captcha example

package.path = package.path .. ";../lib/?.lua"

local captcha = require("resty.captcha")
local cap = captcha.new()

cap:font("./Vera.ttf")
cap:write("captcha_basic.jpg", 70)

print("Captcha text: " .. cap:getStr())
print("Captcha written to captcha_basic.jpg")
