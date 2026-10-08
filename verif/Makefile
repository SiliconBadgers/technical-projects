# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Course-level help and clean. Each project builds from its own directory: cd projects/<project> && make help.

PROJECTS := $(notdir $(wildcard projects/*))

.PHONY: help clean

help:
	@echo "projects: $(PROJECTS)"
	@echo "cd projects/<project> && make help"

clean:
	rm -rf build
