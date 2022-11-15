.PHONY: server

server:
	hugo server -D --disableFastRender -e production

build:
	hugo --minify