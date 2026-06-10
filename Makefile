PREFIX ?= /usr/local/openresty/lualib
INSTALL ?= install

.PHONY: install clean

install:
	$(INSTALL) -D lib/resty/captcha.lua $(PREFIX)/resty/captcha.lua

clean:
	rm -f $(PREFIX)/resty/captcha.lua
