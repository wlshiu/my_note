#!/bin/bash

#
# Dependencies
#

# npm install -g @commitlint/cli @commitlint/config-conventional
# npm install -g husky
# npm install -g conventional-changelog-cli


#
# generate packet.josn
#   use default setting (press ok until end)
#   ps. It should check url in packet.json
#
npm init

npx husky-init

cat > .husky/pre-commit << EOF
#!/usr/bin/env bash
. "$(dirname -- "\$0")/_/husky.sh"

email=\$(git config user.email)
if printf '%s\n' "\$email" | grep -qP '^[a-zA-Z0-9_.+-]+@(zbitsemi)\.com\$'; then
    git config --global user.email "\$email"
else
    echo -e "E-mail MUST be xxx@zbitsemi.com"
    exit -1;
fi
EOF

cat > .husky/commit-msg << EOF
#!/usr/bin/env bash
. "$(dirname "\$0")/_/husky.sh"

npx --no-install commitlint --edit "\$1"
EOF

# generate '.commitlintrc.json'
echo -e '{"extends":["@commitlint/config-conventional"],"rules":{"type-enum":[2,"always",["feat","fix","docs","style","refactor","perf","test","build","ci","chore","revert","release"]],"type-case":[2,"always",["lower-case"]],"type-empty":[2,"never"],"scope-empty":[0],"scope-case":[0],"subject-case":[0],"subject-empty":[2,"never"],"subject-full-stop":[2,"never"],"body-empty":[0],"header-max-length":[2,"always",50]}}' > .commitlintrc.json


