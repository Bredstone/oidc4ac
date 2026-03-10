# OpenID Connect for Authentication Context (OIDC4AC)

[![Spec Status](https://img.shields.io/badge/status-Early%20Working%20Draft-orange)](https://github.com/Bredstone/oidc4ac)
[![Specification](https://img.shields.io/badge/specification-OIDC4AC-blue)](https://bredstone.github.io/oidc4ac/)
[![Build](https://img.shields.io/github/actions/workflow/status/Bredstone/oidc4ac/pages.yml?label=build)](https://github.com/Bredstone/oidc4ac/actions)
[![License](https://img.shields.io/github/license/Bredstone/oidc4ac)](LICENSE)

**Read the specification:** https://bredstone.github.io/oidc4ac/  

## Overview

OIDC4AC extends OpenID Connect with mechanisms for representing authentication methods and communicating authentication requirements.

While the standard `amr` claim identifies which authentication methods were used, it provides a compact representation that does not capture method-specific properties or contextual authentication metadata. OIDC4AC introduces a structured representation of authentication context that includes method-specific properties, provenance information, and assurance-related metadata.

**Key capabilities:**

- **Detailed representation**: Convey authentication method properties (e.g., password derivation algorithm, OTP parameters) along with contextual authentication metadata
- **Structured requests**: Request authentication methods with constraints using logical operators (`all_of`, `one_of`) and quantitative filters (`min`, `max`, `max_age`)
- **Interoperability**: Enable interoperable interpretation of authentication events across identity systems
- **Backward compatibility**: Fully compatible with existing OpenID Connect flows; non-supporting implementations can safely ignore new elements

## Quick Example

An `amr_details` claim representing multi-factor authentication:

```json
{
  "amr": ["pwd", "otp"],
  "amr_details": [
    {
      "amr_identifier": "pwd",
      "amr_metadata": {
        "iss": "https://idp.example.com",
        "trust_framework": "eidas",
        "assurance_level": "low",
        "time": "2025-09-30T18:23:41Z"
      },
      "amr_properties": {
        "pwd_derivation_algorithm": "argon2id",
        "pwd_policy_id": "password-policy-v2"
      }
    },
    {
      "amr_identifier": "otp",
      "amr_metadata": {
        "iss": "https://authbroker.example.com",
        "trust_framework": "custom-framework",
        "assurance_level": "substantial",
        "time": "2025-09-30T18:23:45Z"
      },
      "amr_properties": {
        "otp_length": 6,
        "otp_algorithm": "TOTP"
      }
    }
  ]
}
```

Requesting specific authentication methods:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "all_of": [
          {
            "amr_identifier": { "value": "face" }
          },
          {
            "one_of": [
              { "amr_identifier": { "value": "pwd" } },
              { "amr_identifier": { "value": "otp" } }
            ]
          }
        ]
      }
    }
  }
}
```

## Documentation

OIDC4AC is defined as an extension to OpenID Connect and introduces new claims, request syntax, and metadata elements. The specification defines:

- Authentication Method Representation using the `amr_details` claim
- Authentication Method Request syntax and operators
- OpenID Provider metadata for capability discovery
- Privacy and security considerations
- Conformance requirements

## Development

### Building the Specification

Build and preview the specification locally using Docker:

```bash
docker compose up --build
```

The live-reload environment monitors source files in `src/` and automatically regenerates the rendered specification in `docs/`.

### Repository Structure

```
src/          # Specification source (Markdown)
docs/         # Generated HTML and XML output
Dockerfile    # Build environment
docker-compose.yml
```

## Contributing

This specification is in active development. Feedback and contributions are welcome through issues and pull requests.

## Authors

- **Brendon Vicente Rocha Silva** — Operador Nacional do Registro Civil de Pessoas Naturais (ONRCPN)
- **Frederico Schardong** — Instituto Federal do Rio Grande do Sul (IFRS)
- **Ricardo Felipe Custódio** — Universidade Federal de Santa Catarina (UFSC)

## License

This project is licensed under the Apache License 2.0.

See the [LICENSE](LICENSE) file for details.