#!/bin/sh
set -e

INPUT="${INPUT:-src/main.md}"
XML_OUT="${XML_OUT:-docs/index.xml}"
FORMAT="${FORMAT:-html}"

mkdir -p "$(dirname "$XML_OUT")"

if [ ! -f "$INPUT" ]; then
  echo "ERROR: input file '$INPUT' not found."
  exit 1
fi

echo ">> Generating XML with mmark..."
mmark "$INPUT" > "$XML_OUT"
echo "   -> $XML_OUT"

case "$FORMAT" in
  html) FORMATS="--html" ;;
  text|txt) FORMATS="--text" ;;
  nroff) FORMATS="--nroff" ;;
  exp|xml) FORMATS="--exp" ;;
  *)
    echo "Format '$FORMAT' not recognized, using html as default."
    FORMATS="--html"
    ;;
esac

echo ">> Generating output with xml2rfc ($FORMAT)..."
xml2rfc "$XML_OUT" $FORMATS

echo "Build complete."