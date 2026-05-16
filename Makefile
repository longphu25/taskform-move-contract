.PHONY: build test summary codegen publish clean

build:
	sui move build

test:
	sui move test

summary:
	sui move summary

publish:
	@set -e; \
	output="$$(mktemp -t taskform-publish.XXXXXX.json)"; \
	echo "Publishing TaskForm contract..."; \
	echo "Network: $$(sui client active-env 2>/dev/null || echo unknown)"; \
	echo "Address: $$(sui client active-address 2>/dev/null || echo unknown)"; \
	if sui client publish --gas-budget $${GAS_BUDGET:-200000000} --json > "$$output"; then \
		node scripts/publish-summary.mjs "$$output"; \
		if [ "$${PRINT_PUBLISH_JSON:-0}" = "1" ]; then \
			printf '\nRaw publish JSON:\n'; \
			cat "$$output"; \
		fi; \
		rm -f "$$output"; \
	else \
		status=$$?; \
		printf '\nPublish failed. Raw output:\n'; \
		cat "$$output"; \
		rm -f "$$output"; \
		exit $$status; \
	fi

clean:
	rm -rf build package_summaries
