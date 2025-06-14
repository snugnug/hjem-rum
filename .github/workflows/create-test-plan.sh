#!/usr/bin/env bash

# Set default output values:
echo "run-all-checks=true" >>"$GITHUB_OUTPUT"

allChangedFiles="$(git diff "$GITHUB_SHA" origin/"$GITHUB_BASE_REF" --name-only)"

# Changes to these files can affect modules.
# Run all checks out of precaution.
criticalPaths=("modules/lib/" "flake.nix" "flake.lock" ".github/workflows/create-test-plan.sh" ".github/workflows/integration-tests.yml")
for criticalPath in "${criticalPaths[@]}"; do
  if echo "$allChangedFiles" | grep "$criticalPath"; then
    echo "Changes to '$criticalPath' detected, running all tests..."
    echo "run-all-checks=true" >>"$GITHUB_OUTPUT"
    exit 0
  fi
done

changedFiles=$(
  # Get all changed files in /modules/tests and /modules/collection
  # and sluggify the remaining path:
  # /modules/collection/programs/foot.nix -> programs-foot
  # /modules/tests/programs/ncmpcpp/ncmpcpp.nix -> programs-ncmpcpp
  echo "$allChangedFiles" |
    grep \
      -P "^modules/(tests|collection)/\K(.+?/.+?)(?=\.nix|/)" \
      --only-matching |
    sed 's/\//-/g' | sort | uniq |
    jq -s -R 'split("\n") | .[:-1]'
)

echo "Detected $(echo "$changedFiles" | jq '. | length') changed files:"
echo "$changedFiles" | jq '.[]'

checksToRun=$(
  # Retrieve the names of all checks and filter on those that contain
  # one of the generated slugs as substrings.
  nix eval .#checks.x86_64-linux --apply builtins.attrNames --json |
    jq \
      --compact-output \
      --argjson selection "$changedFiles" \
      '. as $checks | $selection | map(. as $sel | $checks[] | select(. | contains($sel)))'
)

echo Running the following tests:
echo "$checksToRun" | jq '.[]'

echo "checks=$checksToRun" >>"$GITHUB_OUTPUT"
echo "run-all-checks=false" >>"$GITHUB_OUTPUT"
