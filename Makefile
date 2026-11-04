.PHONY: check build test lint app

check: lint test build

build:
	swift build

test:
	swift test

lint:
	swiftlint lint --strict

app:
	./scripts/build-app.sh
