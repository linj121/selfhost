## Source: https://gist.github.com/jyio/22bfc530fda828652b4be6daa176f829
##
## Goals:
##
## - Manage multiple docker hosts, each with a different set of compose projects.
## - Use the same makefile on each host, and have `make up` *et al* apply to projects *on that host only* (keyed by hostname).
## - Be able to control each project individually, like `make keycloak.up`
## - Have projects that are shared among multiple hosts, but enable overriding using host-specific compose-files, keyed by hostname, e.g. `docker-compose.host-01.yml`.
####################

# anything that depends on this phony target would inherit phony behavior
.PHONY: docker-compose

PREFIX := ./src

# use hostname-specific override if available
dockercompose = docker compose$(if $(wildcard $(PREFIX)/$1/docker-compose.$(HOSTNAME).yml), -f docker-compose.yml -f docker-compose.$(HOSTNAME).yml,)

%.pull: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) pull
%.build: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) build
%.up: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) up -d
%.recreate: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) up -d --force-recreate
%.down: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) down
%.destroy: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) down --remove-orphans
%.start: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) start
%.stop: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) stop
%.kill: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) kill
%.restart: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) restart
%.log: docker-compose
	cd $(PREFIX)/$* && $(call dockercompose,$*) logs -ft

# example special target for Caddy
.PHONY: caddy.reload
caddy.reload:
	docker exec -w /etc/caddy caddy-main-1 caddy reload

# example special target for NSD
.PHONY: nsd.reload
nsd.reload:
	docker exec nsd-main-1 nsd-control reload

# node-specific targets
# PROJECTS_host_01 = caddy syncthing dokku
# PROJECTS_host_02 = caddy syncthing nsd gatus
# PROJECTS_host_03 = caddy syncthing sshwifty
# PROJECTS_host_04 = caddy syncthing seafile joplin gitea photoprism borgbackup smokeping samba
PROJECTS_josh_ashburn = caddy mailserver keycloak outline gitea vizonapi
PROJECTS_hwsrv_996597.hostwindsdns.com = caddy mailserver outline

# show project list
.PHONY: list-projects

HOSTNAME := $(shell hostname)

list-projects:
	@echo -e '\033[0;7m'$(HOSTNAME): $(PROJECTS_$(subst -,_,$(HOSTNAME)))'\033[0m'

# update projects
pull: list-projects $(patsubst %, %.pull, $(PROJECTS_$(subst -,_,$(HOSTNAME))))

# bring projects up
up: list-projects $(patsubst %, %.up, $(PROJECTS_$(subst -,_,$(HOSTNAME))))

# take projects down
down: list-projects $(patsubst %, %.down, $(PROJECTS_$(subst -,_,$(HOSTNAME))))

.DEFAULT_GOAL := up