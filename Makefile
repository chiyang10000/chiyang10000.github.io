SITE_DIR := /tmp/_site

all:
	bundle exec jekyll build --destination $(SITE_DIR)
	
	git -C $(SITE_DIR) init
	git -C $(SITE_DIR) add -A
	git -C $(SITE_DIR) commit -m 'publish'
	git -C $(SITE_DIR) remote remove github || true
	git -C $(SITE_DIR) remote add github https://github.com/chiyang10000/chiyang10000.github.io
	git -C $(SITE_DIR) push github -f

