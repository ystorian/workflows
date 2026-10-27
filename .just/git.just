# @template/.just/git.just

# Variables.
githooks_dir := '.githooks'
precommit_file := githooks_dir + '/pre-commit'
precommit_script := f'''
	#!/usr/bin/env sh
	#
	# {{ precommit_file }}
	#
	# Enable this pre-commit script with `just enable_githooks`.

	# .just/git.just
	just precommit_just
'''

# Enable the git hooks in `.githooks`
[group('Git')]
[no-exit-message]
[script]
enable_githooks:
	echo {{ CYAN }}Enable the git hooks in {{ GREEN + githooks_dir + NORMAL }}

	not_found='';

	if [ ! -d "{{ githooks_dir }}" ]; then
		echo {{ error(['Directory not found:', BOLD + githooks_dir]) }};
		not_found='1';
	fi

	if [ ! -f "{{ precommit_file }}" ]; then
		echo {{ error('Script not found: ' + BOLD + precommit_file) }};
		not_found='1';
	fi

	if [ -n "$not_found" ]; then
		echo {{ info(['Create a pre-commit script with', MAGENTA + 'just create_precommit']) }};
		exit 1;
	fi

	if [ "$(git config get core.hooksPath)" != "{{ githooks_dir }}" ]; then
		git config set core.hooksPath {{ githooks_dir }};
		echo {{ info(['Git hooks path set to', GREEN + BOLD + githooks_dir]) }};
	fi

	echo {{ done('') }}

# Check if the git pre-commit hook script is installed
[group('Git')]
[no-exit-message]
[script]
check_precommit:
	echo {{ CYAN }}Check {{ GREEN }}pre-commit hook{{ NORMAL }}

	installed='';
	enabled='';

	if [ ! -d "{{ githooks_dir }}" ]; then
		echo {{ warning(['Directory not found:', RED + BOLD + githooks_dir]) }};
	elif [ ! -f "{{ precommit_file }}" ]; then
		echo {{ warning(['Pre-commit script not found:', RED + BOLD + precommit_file]) }};
	elif [ ! -x "{{ precommit_file }}" ]; then
		echo {{ warning(['Pre-commit script not executable:', BOLD + precommit_file]) }};
	else
		echo {{ dim(['Pre-commit script:', GREEN + precommit_file]) }};
		installed='1';
	fi

	hooks_path="$(git config get core.hooksPath || true)";
	if [ -z "$hooks_path" ]; then
		echo {{ warning(['Local git hooks config not set']) }};
	elif [ "$hooks_path" != "{{ githooks_dir }}" ]; then
		echo {{ warning(['Local git hook path not set to', BOLD + githooks_dir]) }};
		echo {{ info(['Configured git hooks path:', BOLD + '$hooks_path']) }};
	else
		echo {{ dim(['Git hooks:', GREEN + 'enabled']) }};
		enabled='1';
	fi

	if [ ! -n "$installed" ]; then
		echo {{ info(['Create a pre-commit script with:', MAGENTA + 'just create_precommit']) }};
		exit 1;
	fi

	if [ ! -n "$enabled" ]; then
		echo {{ info(['Enable git hooks with:', MAGENTA + 'just enable_githooks']) }};
		exit 1;
	fi

	echo {{ done('') }}

# Create a git hook pre-commit script.
[arg('enable', long='enable', flag, help='Enable the git hooks')]
[group('Git')]
[no-exit-message]
[script]
create_precommit enable:
	echo {{ CYAN }}Create a git hook pre-commit script {{ YELLOW + precommit_file + NORMAL }}

	just create_dir {{ githooks_dir }}

	if [ ! -f "{{ precommit_file }}" ]; then
		just create_file {{ precommit_file }};
		just write_file {{ precommit_file }} '{{ precommit_script }}';
	else
		echo {{ dim(YELLOW + 'Pre-commit script already exist') }};
	fi

	chmod +x {{ precommit_file }} &&
		echo {{ dim(['Set the', BOLD + 'execute', 'bit on', BOLD + precommit_file]) }}

	{{ if enable { 'just enable_githooks && echo ' + done('') } }}
	{{ if !enable { 'echo ' + info(['Enable with', MAGENTA + 'just enable_githooks']) } }}

# Git hook pre-commit script for Just
[group('Git')]
[no-exit-message]
[private]
[script]
precommit_just:
	if ! just --fmt --quiet --check --indentation '{{ "\t" }}'; then
		echo "justfile is not linted, run: just lint_just" >&2;
		exit 1;
	fi
	for justfile in `ls .just`; do
		if ! just --fmt --quiet --check --indentation '{{ "\t" }}' -f .just/$justfile; then
			echo ".just/$justfile is not linted, run: just lint_just" >&2;
			exit 1;
		fi;
	done
