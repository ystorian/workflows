# .just/_main.just

# Common recipes.
import 'git.just'
import 'github.just'
import 'utils.just'

# Language recipes.

# Project recipes.
import 'ci.just'

# Template only: import all.

# Project variables.

# Additional Cargo tools required by this project (see `.just/cargo.just`).
additional_cargo_tools := ['zizmor']

# Setup this project (tooling, hooks)
[group('_')]
setup:
	just no_index

# Bump all dependencies
[group('_')]
bump:
	just update_actions
	just audit_actions
	just lint_just
	just check_markdown
