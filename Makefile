.PHONY: install uninstall

CLAUDE_USER ?= $(HOME)/.claude
SKILL_DIRS := $(notdir $(wildcard skills/*))
AGENT_FILES := $(notdir $(wildcard agents/*.md))
REPO_DIR := $(shell readlink -f $(CURDIR))

# Symlink each skill dir into ~/.claude/skills/ with ndimiduk: prefix.
# Idempotent: replaces existing symlinks pointing at this repo, warns on
# anything else in the way. Edits in this repo are immediately live.
install:
	@mkdir -p "$(CLAUDE_USER)/skills" "$(HOME)/.local/bin"
	@for s in $(SKILL_DIRS); do \
	  target="$(CLAUDE_USER)/skills/ndimiduk:$$s"; \
	  src="$(REPO_DIR)/skills/$$s"; \
	  if [ -L "$$target" ]; then \
	    existing="$$(readlink -f "$$target")"; \
	    if [ "$$existing" = "$$src" ]; then \
	      echo "ok       skills/ndimiduk:$$s -> $$src"; \
	    else \
	      echo "replace  skills/ndimiduk:$$s -> $$src (was $$(readlink "$$target"))"; \
	      rm "$$target" && ln -s "$$src" "$$target"; \
	    fi; \
	  elif [ -e "$$target" ]; then \
	    echo "WARN     skills/ndimiduk:$$s exists and is not a symlink — skipped"; \
	  else \
	    echo "link     skills/ndimiduk:$$s -> $$src"; \
	    ln -s "$$src" "$$target"; \
	  fi; \
	done
	@mkdir -p "$(CLAUDE_USER)/agents"
	@for a in $(AGENT_FILES); do \
	  target="$(CLAUDE_USER)/agents/$$a"; \
	  src="$(REPO_DIR)/agents/$$a"; \
	  if [ -L "$$target" ]; then \
	    existing="$$(readlink -f "$$target")"; \
	    if [ "$$existing" = "$$src" ]; then \
	      echo "ok       agents/$$a -> $$src"; \
	    else \
	      echo "replace  agents/$$a -> $$src (was $$(readlink "$$target"))"; \
	      rm "$$target" && ln -s "$$src" "$$target"; \
	    fi; \
	  elif [ -e "$$target" ]; then \
	    echo "WARN     agents/$$a exists and is not a symlink — skipped"; \
	  else \
	    echo "link     agents/$$a -> $$src"; \
	    ln -s "$$src" "$$target"; \
	  fi; \
	done
	@for bin in session-transcripts/session-tx research-lint/rklint; do \
	  name="$$(basename "$$bin")"; \
	  target="$(HOME)/.local/bin/$$name"; \
	  src="$(REPO_DIR)/skills/$$bin"; \
	  if [ -L "$$target" ]; then \
	    existing="$$(readlink -f "$$target")"; \
	    if [ "$$existing" = "$$src" ]; then \
	      echo "ok       bin/$$name -> $$src"; \
	    else \
	      echo "replace  bin/$$name -> $$src (was $$(readlink "$$target"))"; \
	      rm "$$target" && ln -s "$$src" "$$target"; \
	    fi; \
	  elif [ -e "$$target" ]; then \
	    echo "WARN     bin/$$name exists and is not a symlink — skipped"; \
	  else \
	    echo "link     bin/$$name -> $$src"; \
	    ln -s "$$src" "$$target"; \
	  fi; \
	done
	@echo "Done. Restart sessions or /reload-plugins to pick up changes."

# Remove only the symlinks that point at this repo. Leave anything else alone.
uninstall:
	@for a in $(AGENT_FILES); do \
	  target="$(CLAUDE_USER)/agents/$$a"; \
	  src="$(REPO_DIR)/agents/$$a"; \
	  if [ -L "$$target" ] && [ "$$(readlink -f "$$target")" = "$$src" ]; then \
	    echo "unlink   agents/$$a"; \
	    rm "$$target"; \
	  fi; \
	done
	@for s in $(SKILL_DIRS); do \
	  target="$(CLAUDE_USER)/skills/ndimiduk:$$s"; \
	  src="$(REPO_DIR)/skills/$$s"; \
	  if [ -L "$$target" ] && [ "$$(readlink -f "$$target")" = "$$src" ]; then \
	    echo "unlink   skills/ndimiduk:$$s"; \
	    rm "$$target"; \
	  fi; \
	done
	@for bin in session-transcripts/session-tx research-lint/rklint; do \
	  name="$$(basename "$$bin")"; \
	  target="$(HOME)/.local/bin/$$name"; \
	  src="$(REPO_DIR)/skills/$$bin"; \
	  if [ -L "$$target" ] && [ "$$(readlink -f "$$target")" = "$$src" ]; then \
	    echo "unlink   bin/$$name"; \
	    rm "$$target"; \
	  fi; \
	done
