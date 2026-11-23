#!/usr/bin/env python3
"""Edit an event in khal's calendars in place, keeping everything the shell's form doesn't show
(BYDAY/COUNT, timezone, alarms, exceptions...). Edits apply to the whole series.

Usage: edit-event.py UID JSON
JSON: {title, date: "YYYY-MM-DD" | null (keep series start), allDay, start: "HH:MM", end: "HH:MM",
       repeat: bool, until: "YYYY-MM-DD" | "" , untilChanged: bool, location, description}
"""

import json
import os
import sys
from datetime import date, datetime, time, timedelta, timezone

from icalendar import Calendar, vRecur
from khal.settings import get_config


def find_file(uid: str) -> str | None:
    for cal in get_config()["calendars"].values():
        for root, _, files in os.walk(os.path.expanduser(cal["path"])):
            for f in files:
                if not f.endswith(".ics"):
                    continue
                path = os.path.join(root, f)
                with open(path, encoding="utf-8", errors="ignore") as fh:
                    content = fh.read().replace("\r\n ", "").replace("\n ", "")
                if any(line.strip() == "UID:" + uid for line in content.splitlines()):
                    return path
    return None


def set_text(component, key: str, value: str) -> None:
    if key in component:
        del component[key]
    if value:
        component.add(key, value)


def main() -> None:
    uid, data = sys.argv[1], json.loads(sys.argv[2])
    path = find_file(uid)
    if not path:
        sys.exit("Event not found")

    with open(path, "rb") as fh:
        cal = Calendar.from_ical(fh.read())
    events = [c for c in cal.walk("VEVENT") if str(c.get("UID")) == uid]
    master = next((e for e in events if "RECURRENCE-ID" not in e), None)
    if master is None:
        sys.exit("Event not found")

    old_start = master.decoded("DTSTART")
    tz = old_start.tzinfo if isinstance(old_start, datetime) else None
    old_day = old_start.date() if isinstance(old_start, datetime) else old_start
    day = date.fromisoformat(data["date"]) if data.get("date") else old_day

    # Text fields also go to overridden occurrences so the series stays consistent
    for e in events:
        set_text(e, "SUMMARY", data["title"])
        set_text(e, "LOCATION", data.get("location", ""))
        set_text(e, "DESCRIPTION", data.get("description", ""))
        # Outlook's HTML copy of the description would otherwise win in some clients
        if "X-ALT-DESC" in e:
            del e["X-ALT-DESC"]

    for key in ("DTSTART", "DTEND", "DURATION"):
        if key in master:
            del master[key]
    if data["allDay"]:
        master.add("DTSTART", day)
        master.add("DTEND", day + timedelta(days=1))
    else:
        sh, sm = map(int, data["start"].split(":"))
        eh, em = map(int, data["end"].split(":"))
        start = datetime.combine(day, time(sh, sm), tz)
        end = datetime.combine(day, time(eh, em), tz)
        if tz is None:
            # Floating times would be shown in UTC by some clients; use the local zone
            start, end = start.astimezone(), end.astimezone()
        master.add("DTSTART", start)
        master.add("DTEND", end)

    rule = master.get("RRULE")
    if not data["repeat"]:
        for key in ("RRULE", "RDATE", "EXDATE"):
            master.pop(key, None)
    else:
        rule = vRecur(rule) if rule else vRecur(FREQ="WEEKLY")
        if data.get("untilChanged") or "RRULE" not in master:
            rule.pop("COUNT", None)
            rule.pop("UNTIL", None)
            if data.get("until"):
                last = date.fromisoformat(data["until"])
                # Inclusive: the rule ends at the very end of the last day
                if data["allDay"]:
                    rule["UNTIL"] = last
                else:
                    end_of_day = datetime.combine(last, time(23, 59, 59), tz) if tz else \
                        datetime.combine(last, time(23, 59, 59)).astimezone()
                    rule["UNTIL"] = end_of_day.astimezone(timezone.utc)
        master.pop("RRULE", None)
        master.add("RRULE", rule)

    now = datetime.now(timezone.utc)
    master.pop("LAST-MODIFIED", None)
    master.add("LAST-MODIFIED", now)
    master.pop("DTSTAMP", None)
    master.add("DTSTAMP", now)
    seq = int(master.get("SEQUENCE", 0)) + 1
    master.pop("SEQUENCE", None)
    master.add("SEQUENCE", seq)

    tmp = path + ".tmp"
    with open(tmp, "wb") as fh:
        fh.write(cal.to_ical())
    os.replace(tmp, path)


if __name__ == "__main__":
    main()
