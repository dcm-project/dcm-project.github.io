.PHONY: build serve clean check-spell

SPELLCHECK ?= npx cspell
FILE ?= **/*.md

build:
	hugo --gc --minify

serve:
	hugo server

clean:
	rm -rf public/

check-spell:
	$(SPELLCHECK) "$(FILE)"

