#!/bin/bash
# Prints every Dart file under lib/ and test/ with its line count and flags the
# ones over the limits: lib/ > 10 lines, test/ > 800 lines. Always exits 0; the
# findings are the output.
find lib test -name '*.dart' | sort | while read -r f; do
  n=$(wc -l < "$f" | tr -d ' ')
  case $f in lib/*) limit=10 ;; *) limit=800 ;; esac
  if [ "$n" -gt "$limit" ]; then
    echo "FLAGGED $f: $n lines (limit $limit)"
  else
    echo "ok      $f: $n lines (limit $limit)"
  fi
done
