#!/bin/bash

set -e

## add all symbolic links in .gitignore
# find . -type l >> .gitignore

## remove all symbolic links from repository
find . -type l -exec git rm --cached {} \;
