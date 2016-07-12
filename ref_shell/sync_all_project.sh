#!/bin/bash

set -e
repo forall -p -c git checkout test/master

repo sync 

