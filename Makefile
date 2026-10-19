.PHONY: build install release icon clean

build:    ## Compila build/Mirro.app
	@scripts/build.sh

install:  ## Compila e instala en /Applications
	@scripts/build.sh --install

release:  ## Genera dist/Mirro-x.y.z.zip y su .sha256
	@scripts/release.sh

icon:     ## Regenera el icono desde scripts/icon.swift
	@scripts/make-icon.sh

clean:
	rm -rf build dist
