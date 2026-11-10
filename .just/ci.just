# .just/ci.just

# Run the CI tests like in `.github/workflows/ci-rust.yaml`
[group('CI')]
ci:
	echo {{ title(['Run all', BOLD + 'CI', 'checks']) }}

	# Preparation.
	just lint_just
	just check_typos
	just check_actions
	just audit_actions

	echo {{ done('') }}
