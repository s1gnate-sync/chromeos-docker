#!/usr/bin/env bash

cat << EOF
devices:
  loop-control:
    major: "10"
    minor: "237"
    path: /dev/loop-control
    type: unix-char
EOF

for i in $(seq 0 64); do
cat << EOF
  loop${i}:
    major: "7"
    minor: "${i}"
    path: /dev/loop${i}
    type: unix-block
EOF
done
