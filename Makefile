.PHONY: build serve clean check-spell format check-format

# Use cspell when installed; otherwise npx. Set SPELLCHECK when invoking make to override.
ifeq ($(SPELLCHECK),)
  ifeq ($(shell command -v cspell 2>/dev/null),)
    SPELLCHECK := npx cspell
  else
    SPELLCHECK := cspell
  endif
endif
PRETTIER ?= npx prettier
FILE ?= **/*.md
# Prose docs only; see .prettierignore for paths under these trees to skip.
FORMAT_FILES ?= content/docs/**/*.md content/blog/**/*.md
PRETTIER_FLAGS ?= --prose-wrap always --print-width 80

build:
	hugo --gc --minify

serve:
	hugo server

clean:
	rm -rf public/

check-spell:
	$(SPELLCHECK) "$(FILE)"

format:
	$(PRETTIER) $(PRETTIER_FLAGS) --write $(FORMAT_FILES)

check-format:
	$(PRETTIER) $(PRETTIER_FLAGS) --check $(FORMAT_FILES)
