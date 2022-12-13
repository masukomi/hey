#!/bin/sh

# makes sure all the required chicken scheme eggs
# are installed
echo "Will run chicken-install for required eggs (libraries)"

eggs=(
condition-utils \
error-utils \
fmt \
http-client \
json \
json-abnf \
simple-loops \
numbers \
pathname-expand \
shell \
sql-de-lite \
srfi-1 \
srfi-13 \
srfi-19 \
srfi-69 \
uri-common
)

for egg in ${eggs[@]}; do
	echo "  * $egg"
done

echo "------------------"
for egg in ${eggs[@]}; do
	chicken-install $egg
done




echo "DONE"
