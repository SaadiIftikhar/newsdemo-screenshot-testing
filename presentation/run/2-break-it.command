#!/bin/bash
# Switch to the branch with the bug and run the same tests (they fail on purpose: 29 of 89).
# Linked from the slide deck: clicking the link opens this in a new Terminal window.
cd "$(dirname "$0")/../.." || exit 1
clear
printf '\033[1mSwitch to the branch with the bug and run the same tests\033[0m\n\n'
printf '\033[2m$ git checkout demo/regression\033[0m\n'
git checkout demo/regression || exit 1
printf '\n\033[2m$ make ios-test\033[0m\n'
make ios-test
