#!/bin/sh

# cat any relevant logs

echo "=========================================="
echo "Here is the line count for each log file:"
wc -l tmp/log/*
echo "=========================================="
tail -n +1 tmp/log/*
