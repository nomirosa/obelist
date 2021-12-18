#!/bin/sh -e

lint_out="${LINT_OUT:=}"
silent="${SILENT:=}"

if test -z "${lint_out}"; then
    echo "Error: \`LINT_OUT\` not set"
    exit 1
fi

if test "${silent}" != "true"; then
    make --no-print-directory lint-clean
fi

# Find elibible files in the current directory, skipping the largest
# directories that would be ignored by Git
find_files() {
    # Preemptively ignore the largest directories that would be ignored by Git
    find . -type "f" \
        ! -path "./.git/*" \
        ! -path "./.venv/*" \
        ! -path "poetry.lock" |
        sed 's,./,,' | sort | while read -r file; do
        # Skip any files ignored by Git
        if git check-ignore "${file}" >/dev/null; then
            continue 2
        fi
        echo "${file}" | sed -E 's/^\.\///'
    done
}

run_cspell() {
    # This program is relatively slow, so we run it in parallel
    find_files |
        xargs cspell \
            --config ".cspell.json" --no-color --no-progress --no-summary |
        sed "s,^${PWD}/,,"
}

# Using a pipe means the exit value of the first command will be ignored,
# allowing `obelist` to determine which severity level should result in an
# error
run_cspell |
    obelist parse --quiet --console --write "${lint_out}" \
        --error-on="notice" --parser="cspell" --format="txt" -

if test "${silent}" != "true"; then
    make --no-print-directory lint-process
fi