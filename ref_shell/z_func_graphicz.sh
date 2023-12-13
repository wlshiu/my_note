#!/bin/bash

find . -name "*.[c|h]" > cscope.files
cscope -Rcbkq

tceetree -f -i cscope.files -o filename.dot

# Draw relathon figure
dot -Tpdf -O filename.dot -o filename.pdf
