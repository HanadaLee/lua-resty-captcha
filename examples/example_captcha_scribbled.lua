#!/usr/bin/env lua

-- Scribbled captcha example

package.path = package.path .. ";../lib/?.lua"

local captcha = require("resty.captcha")
local cap = captcha.new()

cap:font("./Vera.ttf")
cap:scribble(30)
cap:write("captcha_scribbled.jpg", 70)

print("Captcha text: " .. cap:getStr())
print("Captcha written to captcha_scribbled.jpg")
