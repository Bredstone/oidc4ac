# Examples {#sec-examples}

All examples in this appendix are non-normative and provided for illustrative purposes only.

## Authentication Method Representation {#sec-auth-method-representation-examples}

The following non-normative example illustrates an `amr_details` Claim representing an Authentication Event where the End-User authenticated using a password alongside a one-time password method provided by an external authentication broker. The example includes source/contextual information indicating the broker as the issuer of the OTP method including method-specific metadata such as OTP length and algorithm.

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

These examples illustrate how a RP can request specific Authentication Methods and attributes using the `claims` parameter in an OpenID Connect authentication request.

### Userinfo Request Example

This example demonstrates how to request an OTP Authentication Method with specific length constraints and algorithm via the UserInfo endpoint:

```json
{
  "claims": {
    "userinfo": {
      "amr_details": {
        "amr_identifier": { "value": "otp" },
        "amr_properties": {
          "otp_length"   : null,
          "otp_algorithm": { "value": "TOTP" }
        }
      }
    }
  }
}
```

### Using `all_of` and `one_of` Operators

In the scenario below, the RP requests that the End-User authenticate using biometric authentication (`face`) along with either a password (`pwd`). Both methods are marked as essential:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "all_of": [ 
          {
            "amr_identifier": {
              "value": "face",
              "essential": true
            }
          }, {
            "amr_identifier": {
              "value": "pwd",
              "essential": true
            }
          } 
        ]
      }
    }
  }
}
```

By using the `one_of` operator, the RP can request that the End-User authenticate using either a password (`pwd`) or a one-time password (`otp`):

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "one_of": [
          {
            "amr_identifier": { 
              "value": "pwd"
            }
          },
          {
            "amr_identifier": {
              "value": "otp"
            }
          }
        ]
      }
    }
  }
}
```

#### Using `all_of` and `one_of` with Method Metadata

It is also possible to combine the `all_of` and `one_of` operators with method metadata. In the following example, the RP requests OTP authentication with either numeric or alphanumeric format, along with biometric authentication:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "all_of": [
          {
            "amr_identifier": { "value": "otp" },
            "amr_properties": {
              "one_of": [
                {
                  "otp_format": { "value": "alphanumeric" }
                },
                {
                  "otp_format": { "value": "numeric" }
                }
              ]
            }
          },
          {
            "amr_identifier": { "value": "face" }
          }
        ]
      }
    }
  }
}
```

### Using `max` and `min` Operators

The following example demonstrates how to request an OTP Authentication Method with specific length constraints using the `min` and `max` operators:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "amr_identifier": { "value": "otp" },
        "amr_properties": {
          "otp_length": { "min": 6, "max": 10 }
        }
      }
    }
  }
}
```

### Using `max_age` Operator

The following example demonstrates how to request a biometric Authentication Method (`face`) with a requirement that the verification must have occurred within the last 300 seconds relative to the current processing time:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "amr_identifier": { "value": "face" },
        "amr_metadata"  : {
          "time": { "max_age": 300 }
        }
      }
    }
  }
}
```

### Combined Requirements Example

In this example, the RP expresses a complex Authentication Requirement where the End-User must authenticate using a password (`pwd`) and either a one-time password (`otp`) or facial recognition (`face`) with specific constraints:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "all_of": [
          {
            "amr_identifier": { "value": "pwd", "essential": true }
          },
          {
            "one_of": [
              {
                "amr_identifier": { "value": "otp" },
                "amr_properties": {
                  "otp_length"   : { "min": 6, "max": 10 },
                  "otp_algorithm": { "value": "TOTP" }
                }
              },
              {
                "amr_identifier": { "value": "face" },
                "amr_metadata"  : {
                  "time": { "max_age": 300 }
                }
              }
            ]
          }
        ]
      }
    }
  }
}
```

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
  "amr_identifiers_supported": [ "pwd", "otp", "face" ],
  "pwd_properties_supported": [ "pwd_derivation_algorithm", "pwd_policy_id" ],
  "otp_properties_supported": [ "otp_length", "otp_algorithm" ],
  "face_properties_supported": [ "face_recognition_algorithm", "face_image_quality" ],
  "pwd_derivation_algorithm_values_supported": [ "argon2id", "bcrypt", "scrypt" ],
  "pwd_policy_id_values_supported": [ "gov-password-v1", "gov-password-v2" ],
  "otp_algorithm_values_supported": [ "TOTP", "HOTP" ],
  "face_recognition_algorithm_values_supported": [ "cnn", "eigenfaces", "fisherfaces" ],
  "trust_framework_values_supported": [ "eidas" ],
  "assurance_level_values_supported": [ "low", "substantial", "high" ],
  "location_types_supported": [ "ip_address", "country" ]
}
```