#!/usr/bin/env lua

-- Custom text captcha example

package.path = package.path .. ";../lib/?.lua"

local captcha = require("resty.captcha")
local cap = captcha.new()

cap:font("./Vera.ttf")
cap:string("hello")
cap:bgcolor(61, 174, 233)
cap:fgcolor(49, 54, 59)
cap:line(true)
cap:write("captcha_text.jpg", 70)

print("Captcha text: " .. cap:getStr())
print("Captcha written to captcha_text.jpg")
