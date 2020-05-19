#!/bin/bash

echo "{"
echo "\"name\": \"$(basename $PWD | sed -e "s/^keyboard-//")\""
echo "}"
