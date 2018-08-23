#!/bin/bash

# source this file
git config --global diff.tool vimdiff
git config --global difftool.prompt false
git config --global alias.d difftool
git config --global merge.tool vimdiff