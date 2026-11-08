#!/bin/sh
# Copies the text inside a screen region (tesseract, Spanish + English)

langs=$(tesseract --list-langs 2>/dev/null | grep -xE 'spa|eng' | paste -sd+)
if [ -z "$langs" ]; then
    notify-send -a PaleShell -i dialog-error "OCR unavailable" "Install tesseract-data-spa and tesseract-data-eng"
    exit 1
fi

# Let the launcher close before picking
sleep 0.25
region=$(slurp) || exit 0
# Twice the resolution reads small UI text much better
text=$(grim -s 2 -g "$region" - | tesseract -l "$langs" - - 2>/dev/null | sed -e 's/[[:space:]]*$//' | sed -e '/./,$!d')

if [ -z "$(printf '%s' "$text" | tr -d '[:space:]')" ]; then
    notify-send -a PaleShell -i edit-find "No text found" "Try a bigger or sharper region"
    exit 1
fi

printf '%s' "$text" | wl-copy
notify-send -a PaleShell -i edit-copy "Text copied" "$(printf '%s' "$text" | head -c 160)"
