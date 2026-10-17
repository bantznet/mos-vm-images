#!/usr/bin/env python3
"""Read swagger-ui-init.js on stdin, write the embedded OpenAPI JSON to stdout."""
import json
import sys

src = sys.stdin.read()
marker = src.index('"swaggerDoc"')
doc, _ = json.JSONDecoder().raw_decode(src[src.index('{', marker):])
if not doc.get('paths'):
    sys.exit('spec has no paths')
json.dump(doc, sys.stdout, indent=1, sort_keys=True)
sys.stdout.write('\n')
