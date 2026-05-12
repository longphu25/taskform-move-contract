.PHONY: build test summary codegen publish clean

build:
	sui move build

test:
	sui move test

summary:
	sui move summary

publish:
	sui client publish --gas-budget 200000000

clean:
	rm -rf build package_summaries
