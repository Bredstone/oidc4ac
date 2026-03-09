# Stage 1: build mmark
FROM golang:alpine3.22 AS builder

RUN apk add --no-cache git
RUN go install github.com/mmarkdown/mmark/v2@v2.2.25

# Stage 2: Python + xml2rfc
FROM python:3.12-alpine

# inotify for live reload
RUN apk add --no-cache inotify-tools

# xml2rfc (html, text, etc.)
RUN pip install --no-cache-dir "xml2rfc"

# Copy the mmark binary
COPY --from=builder /go/bin/mmark /usr/local/bin/mmark

WORKDIR /work

# Watch script
COPY watch.sh /usr/local/bin/watch.sh
RUN chmod +x /usr/local/bin/watch.sh

# One-shot build script
COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

# Default values
ENV INPUT=src/main.md \
    XML_OUT=docs/index.xml \
    FORMAT=html

CMD ["watch.sh"]
