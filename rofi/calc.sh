#!/bin/bash

if [ -z "$1" ]; then
    echo "Digite expressão..."
else
    qalc -t "$1"
fi
