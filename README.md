lua-resty-captcha
=================

A simple captcha image generator for Lua, ported to [lua-resty-gd](https://github.com/HanadaLee/lua-resty-gd).

Based on the original [lua-captcha](http://projects.plentyfact.org/projects/lua-captcha/wiki) by startx, with fixes and enhancements by mrDoctorWho, and migration to lua-resty-gd by Hanada.

-----

## Dependencies

* [libgd](https://github.com/libgd/libgd) — GD Graphics library
* [lua-resty-gd](https://github.com/HanadaLee/lua-resty-gd) — Lua bindings to libgd

## Installation

```bash
make install
```

## Quick Start

```lua
local captcha = require("resty.captcha")
local cap = captcha.new()

cap:font("./Vera.ttf")       -- required
cap:write("out.jpg", 70)     -- write JPEG, quality 70
print(cap:getStr())          -- get the captcha text
```

More examples in the `examples/` directory.

---

## API Reference

### cap:font(path)

Set the TrueType font file path. **Required.**

### cap:length(n)

Set the number of characters. Default: `6`.

### cap:alphabet(s)

Set the character pool. Default: `a-z A-Z`.

### cap:string(s)

Set the captcha text explicitly. Overrides `length` and `alphabet`.

### cap:bgcolor(r, g, b)

Set the background color (RGB). Default: white.

### cap:fgcolor(r, g, b)

Set the foreground color (RGB). Default: black.

### cap:line(enable)

Draw a strike-through line across the captcha.

### cap:scribble(n)

Set the number of random scribble lines. Default: `20`. Not drawn unless called.

### cap:generate()

Generate the image. Called automatically by most output methods if needed.

### cap:write(outfile, quality)

Generate and write a JPEG file. Returns the captcha text. `quality` is 0–100.

### cap:jpeg(outfile, quality)

Write a JPEG file.

### cap:png(outfile)

Write a PNG file.

### cap:pngStr()

Return PNG image data as a string. Useful for HTTP responses.

### cap:jpegStr(quality)

Return JPEG image data as a string.

### cap:getStr()

Return the captcha text.

---

## Examples

### Basic

```lua
local captcha = require("resty.captcha")
local cap = captcha.new()
cap:font("./Vera.ttf")
cap:write("captcha.jpg", 70)
print("Captcha: " .. cap:getStr())
```

### Custom colors and strike-through

```lua
local captcha = require("resty.captcha")
local cap = captcha.new()
cap:font("./Vera.ttf")
cap:string("hello")
cap:bgcolor(61, 174, 233)
cap:fgcolor(49, 54, 59)
cap:line(true)
cap:write("captcha.jpg", 70)
```

### Image data for HTTP response

```lua
local captcha = require("resty.captcha")
local cap = captcha.new()
cap:font("./Vera.ttf")
cap:generate()
ngx.header["Content-Type"] = "image/png"
ngx.say(cap:pngStr())
```

### Scribble lines

```lua
local captcha = require("resty.captcha")
local cap = captcha.new()
cap:font("./Vera.ttf")
cap:scribble(30)
cap:write("captcha.jpg", 70)
```

---

## Copyright

© 2011 startx <startx@plentyfact.org>

© 2014-2015 mrDoctorWho <mrdoctorwho@gmail.com>

© Hanada <im@hanada.info>

## License

[MIT](https://github.com/mrDoctorWho/lua-captcha/blob/master/LICENSE)
