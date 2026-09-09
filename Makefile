.PHONY: install uninstall install-claude uninstall-claude install-pi uninstall-pi install-bins uninstall-bins

# Install target (the agent's config dir). Add a new destination by setting a
# <NAME>_USER variable and adding a $(eval $(call LINK_RULES,<name>,...)) line.
CLAUDE_USER ?= $(HOME)/.claude
PI_USER ?= $(HOME)/.pi/agent

SKILL_DIRS := $(notdir $(wildcard skills/*))
AGENT_FILES := $(notdir $(wildcard agents/*.md))
REPO_DIR := $(shell readlink -f $(CURDIR))
# Skill prefix: skills install as <prefix><name> under each target's skills/ dir.
SKILL_PREFIX := ndimiduk:
# CLI tools shared by skills, linked into ~/.local/bin regardless of target.
BINS := session-transcripts/session-tx research-lint/rklint

# ---------------------------------------------------------------------------
# Meta-targets: install/uninstall every supported destination.
install: install-claude install-pi
uninstall: uninstall-claude uninstall-pi uninstall-bins

# ---------------------------------------------------------------------------
# LINK_RULES <target> <dest> <context>: define install-<target>/uninstall-<target>
# that symlink this repo's skills and agents into <dest>/skills and <dest>/agents,
# and pull in the shared ~/.local/bin tools. <context> is an optional path
# (relative to REPO_DIR) to symlink as <dest>/AGENTS.md; pass empty for targets
# that don't use an AGENTS.md context file.
# Idempotent: replaces existing symlinks pointing at this repo, warns on
# anything else in the way. Edits in this repo are immediately live.
#
# NOTE: this body is expanded twice ($(call) then $(eval)), so shell variables
# and $(...) command substitutions must be escaped as $$$$ / $$$$(...).
define LINK_RULES
install-$(1): install-bins
	@mkdir -p "$(2)/skills" "$(2)/agents"
	@for s in $(SKILL_DIRS); do \
	  target="$(2)/skills/$(SKILL_PREFIX)$$$$s"; \
	  src="$(REPO_DIR)/skills/$$$$s"; \
	  if [ -L "$$$$target" ]; then \
	    existing="$$$$(readlink -f "$$$$target")"; \
	    if [ "$$$$existing" = "$$$$src" ]; then \
	      echo "ok       skills/$(SKILL_PREFIX)$$$$s -> $$$$src"; \
	    else \
	      echo "replace  skills/$(SKILL_PREFIX)$$$$s -> $$$$src (was $$$$(readlink "$$$$target"))"; \
	      rm "$$$$target" && ln -s "$$$$src" "$$$$target"; \
	    fi; \
	  elif [ -e "$$$$target" ]; then \
	    echo "WARN     skills/$(SKILL_PREFIX)$$$$s exists and is not a symlink — skipped"; \
	  else \
	    echo "link     skills/$(SKILL_PREFIX)$$$$s -> $$$$src"; \
	    ln -s "$$$$src" "$$$$target"; \
	  fi; \
	done
	@for a in $(AGENT_FILES); do \
	  target="$(2)/agents/$$$$a"; \
	  src="$(REPO_DIR)/agents/$$$$a"; \
	  if [ -L "$$$$target" ]; then \
	    existing="$$$$(readlink -f "$$$$target")"; \
	    if [ "$$$$existing" = "$$$$src" ]; then \
	      echo "ok       agents/$$$$a -> $$$$src"; \
	    else \
	      echo "replace  agents/$$$$a -> $$$$src (was $$$$(readlink "$$$$target"))"; \
	      rm "$$$$target" && ln -s "$$$$src" "$$$$target"; \
	    fi; \
	  elif [ -e "$$$$target" ]; then \
	    echo "WARN     agents/$$$$a exists and is not a symlink — skipped"; \
	  else \
	    echo "link     agents/$$$$a -> $$$$src"; \
	    ln -s "$$$$src" "$$$$target"; \
	  fi; \
	done
	@if [ -n "$(3)" ]; then \
	  target="$(2)/AGENTS.md"; \
	  src="$(REPO_DIR)/$(3)"; \
	  if [ -L "$$$$target" ]; then \
	    existing="$$$$(readlink -f "$$$$target")"; \
	    if [ "$$$$existing" = "$$$$src" ]; then \
	      echo "ok       AGENTS.md -> $$$$src"; \
	    else \
	      echo "replace  AGENTS.md -> $$$$src (was $$$$(readlink "$$$$target"))"; \
	      rm "$$$$target" && ln -s "$$$$src" "$$$$target"; \
	    fi; \
	  elif [ -e "$$$$target" ]; then \
	    echo "WARN     AGENTS.md exists and is not a symlink — skipped"; \
	  else \
	    echo "link     AGENTS.md -> $$$$src"; \
	    ln -s "$$$$src" "$$$$target"; \
	  fi; \
	fi

uninstall-$(1):
	@if [ -n "$(3)" ]; then \
	  target="$(2)/AGENTS.md"; \
	  src="$(REPO_DIR)/$(3)"; \
	  if [ -L "$$$$target" ] && [ "$$$$(readlink -f "$$$$target")" = "$$$$src" ]; then \
	    echo "unlink   AGENTS.md"; \
	    rm "$$$$target"; \
	  fi; \
	fi
	@for a in $(AGENT_FILES); do \
	  target="$(2)/agents/$$$$a"; \
	  src="$(REPO_DIR)/agents/$$$$a"; \
	  if [ -L "$$$$target" ] && [ "$$$$(readlink -f "$$$$target")" = "$$$$src" ]; then \
	    echo "unlink   agents/$$$$a"; \
	    rm "$$$$target"; \
	  fi; \
	done
	@for s in $(SKILL_DIRS); do \
	  target="$(2)/skills/$(SKILL_PREFIX)$$$$s"; \
	  src="$(REPO_DIR)/skills/$$$$s"; \
	  if [ -L "$$$$target" ] && [ "$$$$(readlink -f "$$$$target")" = "$$$$src" ]; then \
	    echo "unlink   skills/$(SKILL_PREFIX)$$$$s"; \
	    rm "$$$$target"; \
	  fi; \
	done
endef

$(eval $(call LINK_RULES,claude,$(CLAUDE_USER),))
$(eval $(call LINK_RULES,pi,$(PI_USER),agents-md/AGENTS.md))

# CLI tools shared by skills, linked into ~/.local/bin (target-independent).
install-bins:
	@mkdir -p "$(HOME)/.local/bin"
	@for bin in $(BINS); do \
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

uninstall-bins:
	@for bin in $(BINS); do \
	  name="$$(basename "$$bin")"; \
	  target="$(HOME)/.local/bin/$$name"; \
	  src="$(REPO_DIR)/skills/$$bin"; \
	  if [ -L "$$target" ] && [ "$$(readlink -f "$$target")" = "$$src" ]; then \
	    echo "unlink   bin/$$name"; \
	    rm "$$target"; \
	  fi; \
	done
