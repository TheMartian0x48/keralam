ODIN      ?= odin
BUILD_DIR ?= build
KASHMIR   := vendor/kashmir
FLAGS     ?= -vet -strict-style -warnings-as-errors -collection:kashmir=$(KASHMIR)

.DEFAULT_GOAL := help
.PHONY: help deps icons build run clean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z_-]+:.*## / {printf "  %-6s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

deps: ## Fetch (or repair) kashmir into vendor/ and install npm dependencies
	python3 tools/deps.py
	npm install

icons: ## Generate the Phosphor icon table and CSS from node_modules
	$(ODIN) run tools/icons $(FLAGS)

build: ## Generate assets/ (css, js, fonts), then compile the library and the example
	@mkdir -p assets
	$(ODIN) run tools/css $(FLAGS)
	npm run build
	cp node_modules/@phosphor-icons/web/src/*/*.woff2 assets/
	$(ODIN) check component -no-entry-point $(FLAGS)
	@mkdir -p $(BUILD_DIR)
	$(ODIN) build example -out:$(BUILD_DIR)/example $(FLAGS)

run: build ## Build, then start the demo server on 127.0.0.1:8080 (make run PORT=3000)
	@./$(BUILD_DIR)/example

clean: ## Remove build output and generated assets (manual only)
	rm -rf $(BUILD_DIR) assets

