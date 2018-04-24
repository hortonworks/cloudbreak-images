#!/bin/bash

cat>amazon2017.json<<EOF
{"aliases": {"amazon2017": "amazon6"}}
EOF

for file in $(find / -name "os_family.json"); do
	jq -s '.[0] * .[1]' amazon2017.json $file > merge.json
	mv -f merge.json $file
done

rm -f amazon2017.json

cat>amazon2018.json<<EOF
{"aliases": {"amazon2018": "amazon6"}}
EOF

for file in $(find / -name "os_family.json"); do
	jq -s '.[0] * .[1]' amazon2018.json $file > merge.json
	mv -f merge.json $file
done

rm -f amazon2018.json
