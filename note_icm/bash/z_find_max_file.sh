#!/bin/bash

target_path=$1
du -a ${target_path} | sort -n -r | head -n 10
