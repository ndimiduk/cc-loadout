.PHONY: install uninstall install-claude uninstall-claude install-pi uninstall-pi install-shared uninstall-shared install-codex uninstall-codex install-bins uninstall-bins

# Install target (the agent's config dir). Add a new destination by setting a
# <NAME>_USER variable and adding a $(eval $(call LINK_RULES,<name>,...)) line.
CLAUDE_USER ?= $(HOME)/.claude
PI_USER ?= $(HOME)/.pi/agent
CODEX_USER ?= $(HOME)/.codex
# The open agent-skills user location. Codex and Pi both scan ~/.agents/skills,
# so skills for both install here once; Pi must not also get them in its own dir
# or every skill is listed twice.
SHARED_USER ?= $(HOME)/.agents

SKILL_DIRS := $(notdir $(wildcard skills/*))
AGENT_FILES := $(notdir $(wildcard agents/*.md))
REPO_DIR := $(shell readlink -f $(CURDIR))
# Skill prefix: skills install as <prefix><name> under each target's skills/ dir.
SKILL_PREFIX := ndimiduk:
# CLI tools shared by skills, linked into BIN_DIR regardless of target.
BIN_DIR ?= $(HOME)/.local/bin
BINS := session-transcripts/session-tx research-lint/rklint

# ---------------------------------------------------------------------------
# Meta-targets: install/uninstall every supported destination.
install: install-claude install-pi install-codex install-shared
uninstall: uninstall-claude uninstall-pi uninstall-codex uninstall-shared uninstall-bins

# ---------------------------------------------------------------------------
# LINK_RULES <target> <dest> <context> <skills> <agents>: define
# install-<target>/uninstall-<target> that symlink this repo's skills into
# <dest>/skills when <skills> is non-empty and its agents into <dest>/agents when
# <agents> is non-empty, and pull in the shared BIN_DIR tools. <context> is an
# optional path (relative to REPO_DIR) to symlink as <dest>/AGENTS.md; pass empty
# for targets that don't use an AGENTS.md context file. Uninstall always removes
# skill and agent links that point at this repo, whatever the flags.
# Idempotent: replaces existing symlinks pointing at this repo, warns on
# anything else in the way. Edits in this repo are immediately live.
#
# NOTE: this body is expanded twice ($(call) then $(eval)), so shell variables
# and $(...) command substitutions must be escaped as $$$$ / $$$$(...).
define LINK_RULES
install-$(1): install-bins
	@if [ -n "$(4)" ]; then mkdir -p "$(2)/skills"; for s in $(SKILL_DIRS); do \
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
	done; fi
	@if [ -n "$(5)" ]; then mkdir -p "$(2)/agents"; for a in $(AGENT_FILES); do \
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
	done; fi
	@if [ -n "$(3)" ]; then \
	  mkdir -p "$(2)"; \
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

$(eval $(call LINK_RULES,claude,$(CLAUDE_USER),,skills,agents))
$(eval $(call LINK_RULES,pi,$(PI_USER),agents-md/AGENTS.md,,agents))
$(eval $(call LINK_RULES,codex,$(CODEX_USER),agents-md/AGENTS.md,,))
$(eval $(call LINK_RULES,shared,$(SHARED_USER),,skills,))

# Pi and Codex read their skills from the shared location.
install-pi: install-shared
install-codex: install-shared

# CLI tools shared by skills, linked into BIN_DIR (target-independent).
install-bins:
	@mkdir -p "$(BIN_DIR)"
	@for bin in $(BINS); do \
	  name="$$(basename "$$bin")"; \
	  target="$(BIN_DIR)/$$name"; \
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
	  target="$(BIN_DIR)/$$name"; \
	  src="$(REPO_DIR)/skills/$$bin"; \
	  if [ -L "$$target" ] && [ "$$(readlink -f "$$target")" = "$$src" ]; then \
	    echo "unlink   bin/$$name"; \
	    rm "$$target"; \
	  fi; \
	done
