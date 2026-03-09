# OpenID Connect for Authentication Context (OIDC4AC)

OpenID Connect for Authentication Context (OIDC4AC) is a proposed extension to OpenID Connect that enables Relying Parties (RPs) to request specific authentication factors, such as passwords, OTPs, biometrics, or hardware keys, and allows OpenID Providers (OPs) to represent Authentication Events with structured, detailed metadata.

Instead of relying solely on the opaque `amr` array, OIDC4AC introduces the `amr_details` Claim, which provides a machine-readable description of how authentication was performed, including contextual evidence such as assurance level, trust framework, environmental attributes, and method-specific metadata.

This repository contains:

- A draft specification of the OIDC4AC extension
- A live-reload environment for building the draft using
`mmark → xml2rfc → HTML`

This allows you to iteratively edit the Markdown source and automatically generate updated XML and HTML outputs.

## Running the Project

### Prerequisites

- Docker
- Docker Compose

No other dependencies are required. All tools (`mmark`, `xml2rfc`, `inotify`) run inside the container.

### Running the Live-Reload Environment

To start the environment:

```bash
docker compose up --build
```

The container will:

1. Watch src/main.md for changes
2. Convert it to RFC XML using `mmark`
3. Convert the XML to HTML (or other formats) using `xml2rfc`
4. Automatically write all outputs to `docs/`

You'll see logs each time the draft is rebuilt.

### Editing the Draft

While the container is running, open any file inside `src` folder. Every save automatically regenerates:

- `docs/index.xml` — canonical XML for `xml2rfc`
- `docs/index.html` — formatted HTML RFC-style preview

You can open `docs/index.html` in your browser to preview the rendered specification.

### Changing the Output Format (optional)

`xml2rfc` supports multiple output formats:

- `html` (default)
- `text`
- `nroff`
- `exp` (expanded XML)

To change the format, edit the environment variable in `docker-compose.yml`:

```yaml
environment:
  - FORMAT=text
```

Or pass it inline:

```bash
FORMAT=text docker compose up
```

## About the Draft

The full draft specification explaining the OIDC4AC model, the `amr_details` Claim, and the motivation for the protocol is included in this repository.
It provides the formal definitions, schemas, and examples that underpin the protocol design.
