.PHONY: check build test lint app icon

check: lint test build

build:
	swift build

test:
	swift test

lint:
	swiftlint lint --strict

app:
	zsh scripts/build-app.sh

icon:
	zsh scripts/make-icon.sh
