clean:
	rm -rf www/css
	rm -rf www/img
	rm -rf www/js
	rm -f www/index.html

www/css:
	@mkdir -p www/css

www/img:
	@mkdir -p www/img

www/js:
	@mkdir -p www/js

www/index.html:
	cp indexes/web.html www/index.html

www/css/index.css: www/css
	cp stylesheets/index.css www/css/index.css

www/img/%.png: www/img
	cp images/$*.png www/img/$*.png

www/js/disk1.js: www/js
	cp carts/disk1.js www/js/disk1.js

www/js/disk2.js: www/js
	cp carts/disk2.js www/js/disk2.js

www/js/pico8.js: www/js
	cp scripts/pico8.js www/js/pico8.js

www/js/tailbone.js: www/js
	cp launchers/web.js www/js/tailbone.js

www: \
	www/index.html \
	www/css/index.css \
	www/img/icon-512.png \
	www/img/loading.png \
	www/js/disk1.js \
	www/js/disk2.js \
	www/js/pico8.js \
	www/js/tailbone.js

res/icon/ios/icon-%.png:
	convert res/icon/ios/icon-1024.png -resize $*x$* res/icon/ios/icon-$*.png

icons: \
	res/icon/ios/icon-20.png \
	res/icon/ios/icon-29.png \
	res/icon/ios/icon-40.png \
	res/icon/ios/icon-48.png \
	res/icon/ios/icon-50.png \
	res/icon/ios/icon-55.png \
	res/icon/ios/icon-56.png \
	res/icon/ios/icon-57.png \
	res/icon/ios/icon-58.png \
	res/icon/ios/icon-60.png \
	res/icon/ios/icon-72.png \
	res/icon/ios/icon-76.png \
	res/icon/ios/icon-80.png \
	res/icon/ios/icon-87.png \
	res/icon/ios/icon-88.png \
	res/icon/ios/icon-100.png \
	res/icon/ios/icon-114.png \
	res/icon/ios/icon-120.png \
	res/icon/ios/icon-144.png \
	res/icon/ios/icon-152.png \
	res/icon/ios/icon-167.png \
	res/icon/ios/icon-172.png \
	res/icon/ios/icon-180.png \
	res/icon/ios/icon-196.png \
	res/icon/ios/icon-512.png


.PHONY: clean www
