#
# list-unsubscribe.py
#
# Some email clients may not support List-Unsubscribe header, so this is a
# small script to do it from command line instead. Copy-paste headers or pipe
# to the script.
#

import sys
import re
import urllib.request
import urllib.parse
from email.header import decode_header

do_request = True

if len(sys.argv) > 1 and (sys.argv[1] == '-d' or sys.argv[1] == '--dry-run'):
    do_request = False

raw = sys.stdin.read()

# Extract List-Unsubscribe header (including folded lines)
match = re.search(r'^List-Unsubscribe:\s*(.+(?:\n\s+.+)*)', raw, re.IGNORECASE | re.MULTILINE)

if not match:
    print("No List-Unsubscribe header found")
    sys.exit(1)

header_value = match.group(1)

# Decode MIME encoded parts
decoded = ""
for part, enc in decode_header(header_value):
    if isinstance(part, bytes):
        decoded += part.decode(enc or "utf-8", errors="replace")
    else:
        decoded += part

# Extract URL inside <>
url_match = re.search(r'<(https?://[^>]+)>', decoded)

if not url_match:
    print("No HTTPS unsubscribe URL found")
    sys.exit(1)

url = url_match.group(1)

print("Unsubscribe URL:", url)

if do_request:
    data = urllib.parse.urlencode({"List-Unsubscribe": "One-Click"}).encode()

    # Try POST first
    try:
        req = urllib.request.Request(url, data=data)
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        resp = urllib.request.urlopen(req)
        print("POST status:", resp.status)
    except Exception as e:
        print("POST failed:", e)
        print("Trying GET...")

        try:
            resp = urllib.request.urlopen(url)
            print("GET status:", resp.status)
        except Exception as e:
            print("GET failed:", e)
