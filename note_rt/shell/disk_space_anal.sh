#!/bin/sh

du -a ./ | sort -n -r | head -n 20
