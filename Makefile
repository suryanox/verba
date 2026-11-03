.PHONY: check build test lint

check: lint test build

build:
	swift build

test:
	swift test

lint:
	swiftlint lint --strict
