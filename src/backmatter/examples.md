# Examples {#sec-examples}

All examples in this appendix are non-normative and provided for illustrative purposes only.

## Authentication Method Representation {#sec-auth-method-representation-examples}

The following example represents the complete Authentication Event relied upon for an authorization in which the End-User used a password and an OTP provided by an external authentication broker:

```JSON
{
  "amr"        : [ "pwd", "otp" ],
  "amr_details": [
    {
      "amr_identifier": "pwd",
      "amr_metadata"  : {
        "iss"            : "https://idp.gov.com",
        "trust_framework": "eidas",
        "assurance_level": "low",
        "time"           : "2025-09-30T18:23:41Z",
        "location"       : { "ip_address": "192.0.2.1", "country": "US" }
      },
      "amr_properties": {
        "pwd_derivation_algorithm": "argon2id",
        "pwd_policy_id"           : "govbr-password-v2"
      }
    },
    {
      "amr_identifier": "otp",
      "amr_metadata"  : {
        "iss"            : "https://authbroker.com",
        "trust_framework": "custom-broker-framework",
        "assurance_level": "substantial",
        "time"           : "2025-09-30T18:23:45Z",
        "location"       : { "ip_address": "192.0.2.1", "country": "US" }
      },
      "amr_properties": { "otp_length": 6, "otp_algorithm": "TOTP" }
    }
  ]
}
```

## Authentication Method Request {#sec-auth-method-request-examples}

### Voluntary and Essential Claim Requests

A voluntary unconstrained request asks for the complete Claim when available:

```json
{
  "claims": {
    "id_token": {
      "amr_details": null
    }
  }
}
```

An essential unconstrained request requires the complete Claim without prescribing the Authentication Methods:

```json
{
  "claims": {
    "id_token": {
      "amr_details": { "essential": true }
    }
  }
}
```

### Essential Single-Method Request

The following request requires the Authentication Event to include facial recognition. Additional methods are not prohibited:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "essential": true,
        "amr_identifier": { "value": "face" }
      }
    }
  }
}
```

### Using `all_of` and `one_of`

The following essential expression represents `(pwd AND pop) OR otp`:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "essential": true,
        "one_of": [
          {
            "all_of": [
              { "amr_identifier": { "value": "pwd" } },
              { "amr_identifier": { "value": "pop" } }
            ]
          },
          { "amr_identifier": { "value": "otp" } }
        ]
      }
    }
  }
}
```

Without the top-level `essential`, the same expression is a best-effort preference.

### Essential Method Property

The following request requires either facial recognition with successful liveness detection or proof of possession:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "essential": true,
        "one_of": [
          {
            "amr_identifier": { "value": "face" },
            "amr_properties": {
              "face_liveness_detection": {
                "essential": true,
                "value": true
              }
            }
          },
          { "amr_identifier": { "value": "pop" } }
        ]
      }
    }
  }
}
```

The locally essential property affects only the `face` branch. It does not become an independent requirement if the `pop` branch matches.

### Using `min`, `max`, and `max_age`

The following essential request requires a recent OTP execution with a disclosed length between 6 and 10 digits:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "essential": true,
        "amr_identifier": { "value": "otp" },
        "amr_metadata": {
          "time": { "essential": true, "max_age": 300 }
        },
        "amr_properties": {
          "otp_length": { "essential": true, "min": 6, "max": 10 },
          "otp_algorithm": null
        }
      }
    }
  }
}
```

If the existing OTP execution is older than 300 seconds, the OP must perform a fresh OTP execution to satisfy this expression. The `otp_algorithm` value is requested for disclosure but is not required for the method to match.

### ID Token and UserInfo Delivery

When ID Token and UserInfo contain different requests, their essential expressions are combined for the authorization transaction. Both returned Claims represent the same complete set of Authentication Method Executions, while optional fields may be disclosed independently.

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "essential": true,
        "amr_identifier": { "value": "face" },
        "amr_properties": {
          "face_liveness_detection": {
            "essential": true,
            "value": true
          }
        }
      }
    },
    "userinfo": {
      "amr_details": {
        "amr_identifier": { "value": "face" },
        "amr_properties": {
          "face_recognition_algorithm": null
        }
      }
    }
  }
}
```

### Error Response

If an essential expression cannot be satisfied, the OP returns an Authorization Error Response containing:

```text
error=unmet_authentication_requirements
error_description=The requested authentication requirements could not be satisfied.
```

The description does not reveal enrollment state, method availability, or verification failure.

## OP Metadata {#sec-op-metadata-example}

The following example illustrates an OP metadata document indicating support for the `amr_details` Claim and Authentication Method request processing:

```json
{
  "issuer": "https://op.example.com",
  "authorization_endpoint": "https://op.example.com/authorize",
  "token_endpoint": "https://op.example.com/token",
  "userinfo_endpoint": "https://op.example.com/userinfo",
  "jwks_uri": "https://op.example.com/jwks",
  "claims_supported": [ "sub", "name", "email", "amr_details" ],
  "amr_details_request_supported": true,
  "amr_identifiers_supported": [ "pwd", "otp", "face", "pop" ],
  "pwd_properties_supported": [ "pwd_derivation_algorithm", "pwd_policy_id" ],
  "otp_properties_supported": [ "otp_length", "otp_algorithm" ],
  "face_properties_supported": [ "face_recognition_algorithm", "face_liveness_detection" ],
  "pwd_derivation_algorithm_values_supported": [ "argon2id", "bcrypt", "scrypt" ],
  "otp_algorithm_values_supported": [ "TOTP", "HOTP" ],
  "face_recognition_algorithm_values_supported": [ "cnn", "eigenfaces", "fisherfaces" ],
  "trust_framework_values_supported": [ "eidas" ],
  "assurance_level_values_supported": [ "low", "substantial", "high" ],
  "location_types_supported": [ "ip_address", "country" ]
}
```
