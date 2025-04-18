HOSTNAME	:= $(shell hostname -s)
UNAME_S		:= $(shell uname -s)
UNAME_M		:= $(shell uname -m)


# Temporary, work around issue with nixos-unstable
TOOL	:= sudo nixos-rebuild

# Using the "replace" mode with tpwrules/nixos-apple-silicon doesn't work
# in "pure" mode. The "overlay" option works as well, but rebuilds the world.
ARGS		:= --impure -v

all:
	@echo "Cowardly refusing to run. Try again with 'switch' or 'test'"

install: switch

build:
	$(TOOL) build --flake ./#$(HOSTNAME) $(ARGS)
	nvd diff /run/current-system result

switch:
	$(TOOL) switch --flake ./#$(HOSTNAME) $(ARGS) --show-trace

boot:
	$(TOOL) boot --flake ./#$(HOSTNAME) $(ARGS) --show-trace

testdwl:
	$(TOOL) switch --flake ./#$(HOSTNAME) $(ARGS) --override-input dwl-minego-customized ../dwl/

switch-debug: check
	$(TOOL) switch --flake ./#$(HOSTNAME) --option eval-cache false --show-trace $(ARGS)

switch-offline:
	$(TOOL) switch --flake ./#$(HOSTNAME) --option substitute false $(ARGS)

update:
	@nix flake update
	$(TOOL) switch --flake ./#$(HOSTNAME) --upgrade $(ARGS)

check:
	@nix flake check --show-trace $(ARGS)

test: check
	$(TOOL) dry-build --flake ./#$(HOSTNAME)

rollback:
	$(TOOL) switch --flake ./#$(HOSTNAME) --rollback

repl:
	nixos-repl

