.PHONY: install uninstall install-claude uninstall-claude install-pi uninstall-pi install-shared uninstall-shared install-codex uninstall-codex install-bins uninstall-bins check-plugins bump check-release

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

# ---------------------------------------------------------------------------
# Plugin manifests. Claude Code and Codex each read their own plugin.json; both
# must carry the same name and version, and every skill's name: must equal its
# directory name, because both harnesses publish skills as <plugin>:<name>.
PLUGIN_MANIFESTS := .claude-plugin/plugin.json .codex-plugin/plugin.json

check-plugins:
	@status=0; \
	ids="$$(for m in $(PLUGIN_MANIFESTS); do jq -r '.name + "@" + .version' "$$m"; done | sort -u)"; \
	if [ "$$(printf '%s\n' "$$ids" | wc -l | tr -d ' ')" != 1 ]; then \
	  echo "FAIL     plugin manifests disagree on name or version:"; printf '         %s\n' $$ids; status=1; \
	else \
	  echo "ok       plugin $$ids in $(PLUGIN_MANIFESTS)"; \
	fi; \
	for s in $(SKILL_DIRS); do \
	  name="$$(sed -n 's/^name: *//p' "skills/$$s/SKILL.md" | head -1)"; \
	  if [ "$$name" != "$$s" ]; then \
	    echo "FAIL     skills/$$s/SKILL.md has name: '$$name', want '$$s'"; status=1; \
	  fi; \
	done; \
	for a in $(AGENT_FILES); do \
	  name="$$(sed -n 's/^name: *//p' "agents/$$a" | head -1)"; \
	  if [ "$$name" != "$${a%.md}" ]; then \
	    echo "FAIL     agents/$$a has name: '$$name', want '$${a%.md}'"; status=1; \
	  fi; \
	done; \
	if [ $$status = 0 ]; then echo "ok       $(words $(SKILL_DIRS)) skill and $(words $(AGENT_FILES)) agent names match their files"; fi; \
	exit $$status

# Usage: make bump [VERSION=x.y.z]. Without VERSION, scripts/next-version picks
# the bump level from the skill and agent names changed since the last v* tag.
# Marketplace installs receive a new release only when this version changes.
bump:
	@v="$(VERSION)"; [ -n "$$v" ] || v="$$(scripts/next-version)" || exit 1; \
	if ! printf '%s' "$$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
	  echo "usage: make bump [VERSION=x.y.z]" >&2; exit 2; \
	fi; \
	for m in $(PLUGIN_MANIFESTS); do \
	  jq --arg v "$$v" '.version = $$v' "$$m" > "$$m.tmp" && mv "$$m.tmp" "$$m"; \
	  echo "version  $$m -> $$v"; \
	done
	@$(MAKE) --no-print-directory check-plugins check-release

# Fails when the manifest version is below what the name changes since the
# previous v* tag require, or when TAG (if given) doesn't name that version.
# The previous tag is looked up from HEAD^ so a tag on HEAD itself is skipped.
check-release:
	@version="$$(jq -r .version .claude-plugin/plugin.json)"; \
	base="$$(git describe --tags --abbrev=0 --match 'v[0-9]*' HEAD^ 2>/dev/null || true)"; \
	required="$$(scripts/next-version "$$base" HEAD)" || exit 1; \
	lowest="$$(printf '%s\n' "$$required" "$$version" | sort -V | head -1)"; \
	if [ "$$lowest" != "$$required" ]; then \
	  echo "FAIL     version $$version is below $$required, required since $${base:-the first release}"; exit 1; \
	fi; \
	if [ -n "$(TAG)" ] && [ "$(TAG)" != "v$$version" ]; then \
	  echo "FAIL     tag $(TAG) does not name plugin version $$version"; exit 1; \
	fi; \
	echo "ok       version $$version meets $$required, required since $${base:-the first release}"
