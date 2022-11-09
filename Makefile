.PHONY: server

server:
	hugo server -D --disableFastRender

build:
	hugo --minify