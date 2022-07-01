#!/bin/bash


# get current commit message
commit_msg=`cat $1`

# get user email
email=`git config user.email`
msg_re="^(feat|fix|docs|style|refactor|perf|test|workflow|build|ci|chore|release|workflow)(\(.+\))?: .{1,100}"

if [[ ! $commit_msg =~ $msg_re ]]; then
	echo "\nInvalid commit format:\
	\nfeat: add comments\
	\nfix: handle events on blur (close #28)\
	\nref commit rule: './docs/git_commit_rule.md'"

	exit 1
fi

email_re="@zbitsemi\.com"
if [[ ! $email =~ $email_re ]]; then
	echo "deny committing, only: xxx@zbitsemi.com"
	exit 1
fi
