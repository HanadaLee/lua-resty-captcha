-- Copyright startx <startx@plentyfact.org>
-- Modifications copyright mrDoctorWho <mrdoctorwho@gmail.com>
-- Modifications copyright Hanada <im@hanada.info>
-- Published under the MIT license

local _M = {}

-- replaced with lua-resty-gd
local gd = require("resty.gd")
local math = math
local string = string
local table = table
local io = io
local os = os
local pcall = pcall
local tonumber = tonumber
local tostring = tostring
local type = type

local mt = { __index = {} }


local DEFAULT_LENGTH = 6
local DEFAULT_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local CHAR_WIDTH = 40
local IMAGE_HEIGHT = 45
local TEXT_SIZE = 25
local UINT32_RANGE = 4294967296
local RANDOMSEED_RANGE = 2147483647

local floor = math.floor
local random = math.random
local randomseed = math.randomseed
local rad = math.rad
local byte = string.byte
local len = string.len
local sub = string.sub
local concat = table.concat

local resty_random
do
    local ok, mod = pcall(require, "resty.random")
    if ok then
        resty_random = mod
    end
end


local function mark_dirty(self)
    self.dirty = true
end


local function is_integer(n)
    return n == floor(n)
end


local function validate_positive_integer(value, name)
    local n = tonumber(value)
    if not n or n < 1 or not is_integer(n) then
        return nil, name .. " must be a positive integer"
    end
    return n
end


local function validate_nonnegative_integer(value, name)
    local n = tonumber(value)
    if not n or n < 0 or not is_integer(n) then
        return nil, name .. " must be a non-negative integer"
    end
    return n
end


local function validate_color_value(value, name)
    local n = tonumber(value)
    if not n or n < 0 or n > 255 or not is_integer(n) then
        return nil, name .. " must be an integer between 0 and 255"
    end
    return n
end


local function validate_color(r, g, b, name)
    local red, err = validate_color_value(r, name .. ".r")
    if not red then
        return nil, err
    end

    local green
    green, err = validate_color_value(g, name .. ".g")
    if not green then
        return nil, err
    end

    local blue
    blue, err = validate_color_value(b, name .. ".b")
    if not blue then
        return nil, err
    end

    return { r = red, g = green, b = blue }
end


local function validate_optional_color(color, name)
    if color == nil then
        return nil
    end
    if type(color) ~= "table" then
        return nil, name .. " must be set with " .. name .. "(r, g, b)"
    end
    return validate_color(color.r, color.g, color.b, name)
end


local function validate_font(font)
    if type(font) ~= "string" or font == "" then
        return nil, "font must be a non-empty string"
    end
    return font
end


local function random_int(min, max)
    local range = max - min + 1
    if range <= 0 then
        return nil, "invalid random range"
    end

    if resty_random and resty_random.bytes then
        local limit = UINT32_RANGE - (UINT32_RANGE % range)
        for _ = 1, 16 do
            local bytes = resty_random.bytes(4, true)
            if not bytes or #bytes ~= 4 then
                break
            end

            local b1, b2, b3, b4 = byte(bytes, 1, 4)
            local n = (((b1 * 256) + b2) * 256 + b3) * 256 + b4
            if n < limit then
                return min + (n % range)
            end
        end
    end

    return random(min, max)
end


local function get_seed_from_urandom()
    local frandom, err = io.open("/dev/urandom", "rb")
    if not frandom then
        return nil, "failed to open /dev/urandom: " .. tostring(err)
    end

    local str = frandom:read(8)
    frandom:close()
    if not str or #str ~= 8 then
        return nil, "failed to read data from /dev/urandom"
    end

    local seed = 0
    for i = 1, 8 do
        seed = 256 * seed + byte(str, i)
    end

    seed = seed % RANDOMSEED_RANGE
    if seed == 0 then
        seed = 1
    end

    return seed
end


-- Seed random number generator
do
    local seed = get_seed_from_urandom()
    if not seed then
        seed = os.time()
    end
    randomseed(seed)
end


function _M.new()
    local cap = {}
    local f = setmetatable({ cap = cap, dirty = true }, mt)
    return f
end


local function random_char(length, alphabet)
    local captcha_t = {}
    local alphabet_len = len(alphabet)

    for i = 1, length do
        local j, err = random_int(1, alphabet_len)
        if not j then
            return nil, err
        end
        captcha_t[i] = sub(alphabet, j, j)
    end

    return captcha_t
end


local function random_angle()
    return random_int(-20, 40)
end


local function scribble(w)
    local x1, err = random_int(5, w - 5)
    if not x1 then
        return nil, nil, err
    end

    local x2
    x2, err = random_int(5, w - 5)
    if not x2 then
        return nil, nil, err
    end

    return x1, x2
end


local function ensure_generated(self)
    if self.im and not self.dirty then
        return true
    end
    return self:generate()
end


function mt.__index:string(s)
    if s == nil then
        self.cap.string = nil
        self.cap.explicit_string = false
        mark_dirty(self)
        return true
    end
    if type(s) ~= "string" or s == "" then
        return false, "string must be a non-empty string"
    end

    self.cap.string = s
    self.cap.explicit_string = true
    mark_dirty(self)
    return true
end


function mt.__index:scribble(n)
    if n == false then
        self.cap.scribble = nil
        mark_dirty(self)
        return true
    end

    local count, err = validate_nonnegative_integer(n or 20, "scribble")
    if not count then
        return false, err
    end

    self.cap.scribble = count
    mark_dirty(self)
    return true
end


function mt.__index:alphabet(s)
    if s == nil then
        self.cap.alphabet = nil
        mark_dirty(self)
        return true
    end
    if type(s) ~= "string" or s == "" then
        return false, "alphabet must be a non-empty string"
    end

    self.cap.alphabet = s
    mark_dirty(self)
    return true
end


function mt.__index:length(l)
    if l == nil then
        self.cap.length = nil
        mark_dirty(self)
        return true
    end

    local length, err = validate_positive_integer(l, "length")
    if not length then
        return false, err
    end

    self.cap.length = length
    mark_dirty(self)
    return true
end


function mt.__index:bgcolor(r, g, b)
    if r == nil and g == nil and b == nil then
        self.cap.bgcolor = nil
        mark_dirty(self)
        return true
    end

    local color, err = validate_color(r, g, b, "bgcolor")
    if not color then
        return false, err
    end

    self.cap.bgcolor = color
    mark_dirty(self)
    return true
end


function mt.__index:fgcolor(r, g, b)
    if r == nil and g == nil and b == nil then
        self.cap.fgcolor = nil
        mark_dirty(self)
        return true
    end

    local color, err = validate_color(r, g, b, "fgcolor")
    if not color then
        return false, err
    end

    self.cap.fgcolor = color
    mark_dirty(self)
    return true
end


function mt.__index:line(line)
    self.cap.line = not not line
    mark_dirty(self)
    return true
end


function mt.__index:font(font)
    if font == nil then
        self.cap.font = nil
        mark_dirty(self)
        return true
    end

    local valid_font, err = validate_font(font)
    if not valid_font then
        return false, err
    end

    self.cap.font = font
    mark_dirty(self)
    return true
end


function mt.__index:generate()
    local font, err = validate_font(self.cap.font)
    if not font then
        return nil, err
    end

    local captcha_t = {}
    local captcha_text

    if self.cap.explicit_string then
        if type(self.cap.string) ~= "string" or self.cap.string == "" then
            return nil, "string must be a non-empty string"
        end

        captcha_text = self.cap.string
        for i = 1, #captcha_text do
            captcha_t[i] = sub(captcha_text, i, i)
        end
    else
        local length
        length, err = validate_positive_integer(self.cap.length or DEFAULT_LENGTH, "length")
        if not length then
            return nil, err
        end

        local alphabet = self.cap.alphabet or DEFAULT_ALPHABET
        if type(alphabet) ~= "string" or alphabet == "" then
            return nil, "alphabet must be a non-empty string"
        end

        captcha_t, err = random_char(length, alphabet)
        if not captcha_t then
            return nil, err
        end
        captcha_text = concat(captcha_t)
    end

    local bgcolor_cfg
    bgcolor_cfg, err = validate_optional_color(self.cap.bgcolor, "bgcolor")
    if err then
        return nil, err
    end

    local fgcolor_cfg
    fgcolor_cfg, err = validate_optional_color(self.cap.fgcolor, "fgcolor")
    if err then
        return nil, err
    end

    local width = #captcha_t * CHAR_WIDTH
    local im
    im, err = gd.createTrueColor(width, IMAGE_HEIGHT)
    if not im then
        return nil, err
    end

    local black
    black, err = im:colorAllocate(0, 0, 0)
    if not black then
        gd.destroy(im)
        return nil, err or "failed to allocate black color"
    end

    local white
    white, err = im:colorAllocate(255, 255, 255)
    if not white then
        gd.destroy(im)
        return nil, err or "failed to allocate white color"
    end

    local bgcolor = white
    if bgcolor_cfg then
        bgcolor, err = im:colorAllocate(bgcolor_cfg.r, bgcolor_cfg.g, bgcolor_cfg.b)
        if not bgcolor then
            gd.destroy(im)
            return nil, err or "failed to allocate background color"
        end
    end

    local fgcolor = black
    if fgcolor_cfg then
        fgcolor, err = im:colorAllocate(fgcolor_cfg.r, fgcolor_cfg.g, fgcolor_cfg.b)
        if not fgcolor then
            gd.destroy(im)
            return nil, err or "failed to allocate foreground color"
        end
    end

    local ok
    ok, err = im:filledRectangle(0, 0, width, IMAGE_HEIGHT, bgcolor)
    if not ok then
        gd.destroy(im)
        return nil, err
    end

    local offset_left = 10

    for i = 1, #captcha_t do
        local angle
        angle, err = random_angle()
        if not angle then
            gd.destroy(im)
            return nil, err
        end

        local llx, lly, lrx, lry, urx, ury, ulx, uly =
            im:stringFT(fgcolor, font, TEXT_SIZE, rad(angle),
                        offset_left, 35, captcha_t[i])
        if not llx then
            gd.destroy(im)
            return nil, "failed to draw captcha text: " .. tostring(lly)
        end

        ok, err = im:polygon({ { llx, lly }, { lrx, lry }, { urx, ury }, { ulx, uly } }, bgcolor)
        if not ok then
            gd.destroy(im)
            return nil, err
        end

        offset_left = offset_left + CHAR_WIDTH
    end

    if self.cap.line then
        ok, err = im:line(10, 10, width - 10, 40, fgcolor)
        if not ok then
            gd.destroy(im)
            return nil, err
        end

        ok, err = im:line(11, 11, width - 11, 41, fgcolor)
        if not ok then
            gd.destroy(im)
            return nil, err
        end

        ok, err = im:line(12, 12, width - 12, 42, fgcolor)
        if not ok then
            gd.destroy(im)
            return nil, err
        end
    end

    if self.cap.scribble then
        for _ = 1, self.cap.scribble do
            local x1, x2
            x1, x2, err = scribble(width)
            if not x1 then
                gd.destroy(im)
                return nil, err
            end

            ok, err = im:line(x1, 5, x2, 40, fgcolor)
            if not ok then
                gd.destroy(im)
                return nil, err
            end
        end
    end

    local old_im = self.im
    self.im = im
    self.cap.string = captcha_text
    self.cap.explicit_string = not not self.cap.explicit_string
    self.dirty = false

    if old_im then
        gd.destroy(old_im)
    end

    return true
end


-- Perhaps it's not the best solution
-- Writes the generated image to a jpeg file
function mt.__index:jpeg(outfile, quality)
    local ok, err = ensure_generated(self)
    if not ok then
        return false, err
    end
    return self.im:jpeg(outfile, quality)
end


-- Writes the generated image to a png file
function mt.__index:png(outfile)
    local ok, err = ensure_generated(self)
    if not ok then
        return false, err
    end
    return self.im:png(outfile)
end


-- Allows to get the image data in PNG format
function mt.__index:pngStr()
    local ok, err = ensure_generated(self)
    if not ok then
        return nil, err
    end
    return self.im:pngStr()
end


-- Allows to get the image data in JPEG format
function mt.__index:jpegStr(quality)
    local ok, err = ensure_generated(self)
    if not ok then
        return nil, err
    end
    return self.im:jpegStr(quality)
end


-- Allows to get the image text
function mt.__index:getStr()
    return self.cap.string
end


-- Writes the image to a file
function mt.__index:write(outfile, quality)
    local ok, err = self:jpeg(outfile, quality)
    if not ok then
        return nil, err
    end
    return self:getStr()
end

return _M
