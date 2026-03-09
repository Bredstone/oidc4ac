#!/bin/sh
set -e

# Public variables
INPUT="${INPUT:-src/main.md}"

# Derived variables (internal)
XML_OUT="${XML_OUT:-docs/index.xml}"
FORMAT="${FORMAT:-html}"
WATCH_DIR="$(dirname "$INPUT")"

mkdir -p "$(dirname "$XML_OUT")"

echo "Main input file : '$INPUT'"
echo "Watching dir    : '$WATCH_DIR'"
echo "XML out         : '$XML_OUT'"
echo "Format          : '$FORMAT'"

build() {
  if [ ! -f "$INPUT" ]; then
    echo "WARNING: $INPUT does not exist. Waiting for it to be created..."
    return
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
}

# Initial build
build

# Recursive watch for changes in the input directory
while inotifywait -r \
  -e close_write,move,create,delete \
  "$WATCH_DIR"; do
  echo
  echo "Changes detected in '$WATCH_DIR'. Rebuild initiated..."
  build
done