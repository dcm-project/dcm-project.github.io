.PHONY: build serve clean check-spell

# Use cspell when installed; otherwise npx. Set SPELLCHECK when invoking make to override.
ifeq ($(SPELLCHECK),)
  ifeq ($(shell command -v cspell 2>/dev/null),)
    SPELLCHECK := npx cspell
  else
    SPELLCHECK := cspell
  endif
endif
FILE ?= **/*.md

build:
	hugo --gc --minify

serve:
	hugo server

clean:
	rm -rf public/

check-spell:
	$(SPELLCHECK) "$(FILE)"
