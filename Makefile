SHELL := /bin/bash
SITE_DIR := /tmp/_site
PUBLISH_REPO := https://github.com/chiyang10000/chiyang10000.github.io

ifeq ($(PUBLISH_REPO), $(shell git remote get-url origin))
$(info PUBLISH_REPO: $(PUBLISH_REPO))
$(info CURRENT_REPO: $(shell git remote get-url origin))
$(error Dangerous! PUBLISH_REPO and CURRENT_REPO is identical!)
endif

all:
	pkill jekyll || true
	bundle exec jekyll server --destination $(SITE_DIR)
	@echo Open http://127.0.0.1:4000 to view.

publish:
	bundle exec jekyll build --destination $(SITE_DIR)
	
	git -C $(SITE_DIR) init
	git -C $(SITE_DIR) remote add github $(PUBLISH_REPO) || true
	git -C $(SITE_DIR) remote set-url github $(PUBLISH_REPO)
	git -C $(SITE_DIR) fetch github
	git -C $(SITE_DIR) reset github/master
	git -C $(SITE_DIR) add -A
	git -C $(SITE_DIR) commit -m 'publish'
	git -C $(SITE_DIR) push github

