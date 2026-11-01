#!/usr/bin/env python3
"""Cleans up an .ics file and imports it into khal's default calendar.

Some exporters (e.g. Outlook/Exchange-based university schedules) produce files khal can't handle:
- Trailing garbage after END:VCALENDAR (e.g. an HTML page appended by the server)
- Windows-style timezone names like "(UTC-03:00) Montevideo" with outdated DST rules in their
  VTIMEZONE, which shifts events by an hour

Those timezones are replaced with the matching IANA zone (falling back to the local zone) so the
current tz database rules are used instead.

Usage: import-ics.py FILE
Prints the number of imported events on success.
"""

import os
import re
import subprocess
import sys
import tempfile
from zoneinfo import available_timezones

ZONES = available_timezones()


def local_zone():
    try:
        target = os.path.realpath("/etc/localtime")
        return target.split("zoneinfo/", 1)[1]
    except (OSError, IndexError):
        return "UTC"


def to_iana(tzid):
    if tzid in ZONES:
        return tzid

    # "(UTC-03:00) Montevideo" / "(UTC-03:00) Buenos Aires, Georgetown" -> try each city name
    names = re.sub(r"^\(.*?\)\s*", "", tzid).split(",")
    for name in names:
        city = name.strip().replace(" ", "_")
        if not city:
            continue
        for zone in ZONES:
            if zone.endswith("/" + city):
                return zone

    return local_zone()


def clean(text):
    text = text.replace("\r\n", "\n").replace("\r", "\n")

    end = text.find("END:VCALENDAR")
    if end == -1:
        sys.exit("Not a calendar file (no END:VCALENDAR)")
    text = text[: end + len("END:VCALENDAR")] + "\n"

    # Unfold lines so TZID params split across lines are matched
    text = re.sub(r"\n[ \t]", "", text)

    tzids = set(re.findall(r"^TZID:(.+)$", text, re.M))
    tzids |= {m.strip('"') for m in re.findall(r";TZID=(\"[^\"]*\"|[^:;]*)", text)}

    for tzid in tzids:
        iana = to_iana(tzid)
        if iana == tzid:
            continue

        # Drop the custom VTIMEZONE so khal uses the tz database rules for the IANA zone
        text = re.sub(
            r"BEGIN:VTIMEZONE\nTZID:" + re.escape(tzid) + r"\n.*?END:VTIMEZONE\n",
            "",
            text,
            flags=re.S,
        )
        text = text.replace(f';TZID="{tzid}"', f";TZID={iana}").replace(f";TZID={tzid}:", f";TZID={iana}:")

    return text.replace("\n", "\r\n")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)

    with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
        cleaned = clean(f.read())

    count = cleaned.count("BEGIN:VEVENT")
    if not count:
        sys.exit("The file has no events")

    with tempfile.NamedTemporaryFile("w", suffix=".ics", encoding="utf-8", newline="", delete=False) as tmp:
        tmp.write(cleaned)

    try:
        proc = subprocess.run(["khal", "import", "--batch", tmp.name], capture_output=True, text=True)
    finally:
        os.unlink(tmp.name)

    # khal prints harmless warnings for zones it resolves itself, only surface real failures
    if proc.returncode != 0 or "critical:" in proc.stderr:
        sys.exit(proc.stderr.strip() or "khal import failed")

    remove_update_leftovers()
    print(count)


def remove_update_leftovers():
    # khal leaves behind a "<uid>.ics<random>" copy each time an existing event is updated
    try:
        from khal.settings import get_config

        calendars = get_config()["calendars"].values()
    except Exception:
        return

    for cal in calendars:
        path = os.path.expanduser(cal["path"])
        if not os.path.isdir(path):
            continue
        files = set(os.listdir(path))
        for f in files:
            m = re.fullmatch(r"(.+\.ics)[A-Za-z0-9_]{8}", f)
            if m and m.group(1) in files:
                os.remove(os.path.join(path, f))


if __name__ == "__main__":
    main()
