#!/bin/sh
set -e

# Variável pública (única)
INPUT="${INPUT:-src/main.md}"

# Variáveis derivadas (internas)
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
    echo "WARNING: $INPUT ainda não existe. Crie o arquivo para iniciar o build."
    return
  fi

  echo ">> Gerando XML com mmark..."
  mmark "$INPUT" > "$XML_OUT"
  echo "   -> $XML_OUT"

  case "$FORMAT" in
    html) FORMATS="--html" ;;
    text|txt) FORMATS="--text" ;;
    nroff) FORMATS="--nroff" ;;
    exp|xml) FORMATS="--exp" ;;
    *)
      echo "Formato '$FORMAT' não reconhecido, usando html como padrão."
      FORMATS="--html"
      ;;
  esac

  echo ">> Gerando saída com xml2rfc ($FORMAT)..."
  xml2rfc "$XML_OUT" $FORMATS
  echo "Build completo."
}

# Build inicial
build

# Watch recursivo no diretório do INPUT
while inotifywait -r \
  -e close_write,move,create,delete \
  "$WATCH_DIR"; do
  echo
  echo "Mudanças detectadas em '$WATCH_DIR'. Rebuild iniciado..."
  build
done