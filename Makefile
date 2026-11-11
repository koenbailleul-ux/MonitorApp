.PHONY: all build run install clean

all: build

build:
	@./build.sh

run:
	@./build.sh run

install:
	@./build.sh install

clean:
	@./build.sh clean
