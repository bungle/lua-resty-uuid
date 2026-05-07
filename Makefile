.PHONY: luarocks-install lint unit coverage test docs clean install-rock install

luarocks-install:
	@luarocks --lua-version 5.1 make

lint:
	@luacheck ./lib

unit:
	@busted

coverage: unit
	@luacov
	@echo
	@awk '/File/,0' luacov.report.out
	@echo

test: luarocks-install coverage lint

docs:
	@ldoc .

install-rock:
	@luarocks --lua-version 5.1 make

install: install-rock

clean:
	@rm luacov.stats.out luacov.report.out
