SITE_DIR := /tmp/_site
GITHUB_URL := https://github.com/chiyang10000/chiyang10000.github.io

all:
	pkill jekyll || true
	nohup bundle exec jekyll server --destination $(SITE_DIR) 2>&1 >$(SITE_DIR)/nohup &
	echo http://127.0.0.1:4000

publish:
	bundle exec jekyll build --destination $(SITE_DIR)
	
	git -C $(SITE_DIR) init
	git -C $(SITE_DIR) remote add github $(GITHUB_URL) || true
	git -C $(SITE_DIR) remote set-url github $(GITHUB_URL)
	git -C $(SITE_DIR) fetch github
	git -C $(SITE_DIR) reset github/master
	git -C $(SITE_DIR) add -A
	git -C $(SITE_DIR) commit -m 'publish'
	git -C $(SITE_DIR) push github

