res/icon/ios/icon-57.png:
	convert res/icon/ios/icon-1024.png -resize 57x57 res/icon/ios/icon-57.png

res/icon/ios/icon-72.png:
	convert res/icon/ios/icon-1024.png -resize 72x72 res/icon/ios/icon-72.png

res/icon/ios/icon-114.png:
	convert res/icon/ios/icon-1024.png -resize 114x114 res/icon/ios/icon-114.png

res/icon/ios/icon-144.png:
	convert res/icon/ios/icon-1024.png -resize 144x144 res/icon/ios/icon-144.png

icons: \
	res/icon/ios/icon-57.png \
	res/icon/ios/icon-72.png \
	res/icon/ios/icon-114.png \
	res/icon/ios/icon-144.png

.PHONY: \
	res/icon/ios/icon-57.png \
	res/icon/ios/icon-72.png \
	res/icon/ios/icon-114.png \
	res/icon/ios/icon-144.png \
	icons
