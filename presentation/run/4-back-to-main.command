#!/bin/bash
# Back to the correct code. Linked from the slide deck: clicking the link opens this in a new Terminal window.
cd "$(dirname "$0")/../.." || exit 1
clear
printf '\033[1mBack to the correct code\033[0m\n\n'
printf '\033[2m$ git checkout main\033[0m\n'
git checkout main
printf '\n\033[2m$ git branch --show-current\033[0m\n'
git branch --show-current
