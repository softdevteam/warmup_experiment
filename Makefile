all: build bench

.PHONY: build bench

build:
	./build.sh

bench:
	if ! [ -d krun ]; then \
		git clone https://github.com/softdevteam/krun.git; \
	fi
	if ! [ -d libkalibera ]; then \
		git clone https://github.com/softdevteam/libkalibera.git; \
	fi
	# XXX command to run here

# XXX target to format results.
