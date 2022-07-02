#!/bin/bash

# Configure commitlint to use conventional config
echo -e "module.exports = {                  \n\
  extends: [                                 \n\
    '@commitlint/config-conventional'        \n\
  ],                                         \n\
  rules: {                                   \n\
    'type-enum': [2, 'always', [             \n\
        'feat',                              \n\
        'fix',                               \n\
        'perf',                              \n\
        'refactor',                          \n\
        'docs',                              \n\
        'style',                             \n\
        'test',                              \n\
        'build',                             \n\
        'revert',                            \n\
        'ci',                                \n\
        'chore',                             \n\
        'release',                           \n\
     ]],                                     \n\
    'type-case': [0],                        \n\
    'type-empty': [0],                       \n\
    'scope-empty': [0],                      \n\
    'scope-case': [0],                       \n\
    'subject-full-stop': [0],                \n\
    'subject-empty': [0],                    \n\
    'subject-case': [0],                     \n\
    'body-empty': [0],                       \n\
    'header-max-length': [1, 'always', 50],  \n\
  }
};" > commitlint.config.js


# # Activate hooks
# npx husky install

# Add hook
npx husky add .husky/commit-msg "npx --no -- commitlint --edit $1"