# .just/ci.just

# Run the CI tests like in `.github/workflows/ci-rust.yaml`
[group('CI')]
ci:
	echo {{ CYAN }}Run all {{ GREEN }}CI{{ CYAN }} checks{{ NORMAL }}

	# Preparation.
	just lint_just
	just check_actions
	just audit_actions

	echo {{ done('') }}
