#!/bin/bash
# Run all screenshot and logic tests. Linked from the slide deck: clicking the link opens this in a new Terminal window.
cd "$(dirname "$0")/../.." || exit 1
clear
printf '\033[1mRun all screenshot and logic tests\033[0m\n\n'
printf '\033[2m$ make ios-test\033[0m\n'
make ios-test
