#!/bin/bash

input_file=$1

sed -i 's/[[:space:]]*$//' ${input_file}