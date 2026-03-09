# Requesting Authentication Methods {#sec-req}

Authentication Methods and their properties are requested during the authentication process using the `amr_details` Claim within the `claims` parameter, as defined in [Section 5.5](https://openid.net/specs/openid-connect-core-1_0.html#ClaimsParameter) of [@!OpenID.Core, OIDC Core]. This mechanism allows RPs to express their assurance requirements and policy constraints in a standardized manner, granting them greater control over the Authentication Event. Clients can specify not only *which* Authentication Methods are required but also *how* those methods should be executed.

Unlike the representation of Authentication Methods used in the authentication response (which is a JSON Array), the `amr_details` Claim within the authentication request **MUST** be a JSON Object. This object serves as a logical template or filter that the OP **MUST** satisfy to issue the token.

Within the `amr_details` expression object, the RP **MAY**:

- Request the presence of specific attributes by using `null` values;
- Express value constraints using the `value` and `essential` operators;
- Group requirements using logical operators `all_of` and `one_of`.

A non-normative example of negotiating Authentication Methods and attributes using the `claims` parameter is provided below:

```json
{
  "id_token": {
    "amr_details": {
      "amr_identifier": { "value": "pwd", "location": null },
      "amr_properties": {
        "pwd_derivation_algorithm": null,
        "pwd_policy_id"           : null
      }
    }
  }
}
```

Besides including the `amr_details` Claim within the `claims` parameter in authentication requests, this specification does not define any other means for requesting Authentication Methods. However, some deployments **MAY** choose to negotiate or request Authentication Methods through scope values (*e.g.*, `scope=pwd+otp`) provided there is prior agreement between the RP and the OP regarding the semantics of such scopes. Such approaches are possible under OIDC Core but fall outside the normative scope of this specification.

## Operators and Constraints

The request structure for `amr_details` introduces a set of operators and constraints that extend OIDC's expressiveness for authentication negotiation.

{newline="true"}
`one_of` and `all_of`

: Logical operators for combining multiple Authentication Methods or attributes within a single request element. By using these operators, RPs can request combinations of methods and attributes with specific logical relationships: for example, requiring at least one method from a set (`one_of`) or mandating that all specified methods be used (`all_of`). These operators **MUST** only be used to group JSON objects rather than primitive values. If RPs need to express logical combinations of primitive values, they **MUST** use the `one_of` and `all_of` operators at the parent object level and make use of the `value` attribute within each grouped object. For example, to request either `TOTP` or `HOTP` as the OTP algorithm, the following structure would be used:

```json
{
  "otp_algorithm": {
    "one_of": [
      { "value": "TOTP" },
      { "value": "HOTP" }
    ]
  }
}
```

`min` and `max`

: Quantitative constraints applicable to numeric attributes. These operators **MUST** only be evaluated when the target attribute is a JSON Number. If a type mismatch occurs (*e.g.*, applying `min` to a JSON String), or if the attribute value does not satisfy the constraint, the OP **MUST** ignore the constraint for processing purposes, consistent with the treatment of descriptive attributes described in (#essential-logic).

`max_age`

: Temporal constraint indicating the maximum allowable age, in seconds, of an Authentication Method execution relative to the current request processing time. If the elapsed time since `amr_metadata.time` exceeds this value, the OP **SHOULD NOT** generate an error; instead, it **MUST** report the actual `amr_metadata.time` in the response, allowing the RP to enforce its own freshness policy.

These operators and constraints allow RPs to express complex Authentication Requirements in a structured and machine-interpretable manner, enhancing the negotiation capabilities of the OIDC protocol. The following non-normative example illustrate the use of these operators to express an authentication proccess where biometric authentication is required along with either a password or another OTP:

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
              {
                "amr_identifier": { "value": "pwd" }
              },
              {
                "amr_identifier": { "value": "otp" },
                "amr_properties": { "otp_length": null, "otp_algorithm": null }
              }
            ]
          }
        ]
      }
    }
  }
}
```

More examples of requesting Authentication Methods and attributes using the `claims` parameter are provided in (#sec-auth-method-request-examples).

## Logical Operators and the `essential` Clause {#essential-logic}

The semantic interpretation of the `essential` parameter within logical structures is defined as follows:

- When `essential` is applied to the `amr_details` claim as a whole, or to descriptive attributes of Authentication Methods (such as metadata or properties), its behavior follows the behavior described in [Section 5.5.1](https://openid.net/specs/openid-connect-core-1_0.html#IndividualClaimsRequests) of [@!OpenID.Core, OIDC Core]. In such cases, the Authorization Server **MUST NOT** generate an error if the requested information is not returned, regardless of whether it is marked as Essential or Voluntary.

- When `essential` is applied to a specific Authentication Method, identified through the `amr_identifier` element, it expresses a strict Authentication Requirement. If the Authorization Server is unable to authenticate the End-User using the specified Authentication Method, the Authorization Server **MUST** treat that outcome as a failed authentication attempt. The following rules apply when evaluating `essential` within different contexts of the requirement expression:

    {newline="true"}
    **Within `all_of`**
    
    : All elements marked as `essential` within an `all_of` group **MUST** be satisfied. Failure to satisfy any essential element results in an authentication failure.

    **Within `one_of`**
    
    : If a `one_of` group is required, the OP **MUST** satisfy at least one path that meets the essentiality requirements. If the RP marks specific elements within a `one_of` group as `essential`, it indicates a mandatory preference. If none of the essential elements within the group can be satisfied, the OP **MUST** treat the attempt as a failure, even if non-essential elements are available.

**Note:** This distinction allows RPs to strictly require specific Authentication Methods when necessary, while preserving OpenID Connect compatibility and avoiding unnecessary authentication failures when only descriptive authentication information is unavailable.

A non-normative example of requesting a password-based Authentication Method as essential is provided below:

```json
{
  "claims": {
    "id_token": {
      "amr_details": {
        "amr_identifier": {
          "value"    : "pwd",
          "essential": true
        }
      }
    }
  }
}
```

## Processing Requirements {#sec-processing-requirements}

When processing an `amr_details` request, the Authorization Server **MUST** evaluate the requirement expression as follows:

- The OP **MUST** attempt to satisfy the logical tree of the expression, prioritizing Authentication Methods that fulfill `essential: true` criteria applied to the `amr_identifier` element.

- For all other attributes, including metadata in `amr_properties` or contextual info in `amr_metadata`, the OP **SHOULD** perform a "best-effort" satisfaction of the constraints. Type mismatches or unsatisfied quantitative/temporal constraints on these descriptive attributes **MUST NOT** result in an authentication failure at the OP level.

- The OP **MAY** provide more information than requested if such data is mandatory under its own policy, or less information if some parameters are optional or unsupported.

- If an Authentication Method explicitly identified through the `amr_identifier` element is marked as `essential` and cannot be satisfied, the Authorization Server **MUST** return an error as defined in (#sec-error-handling).

- In all other cases, the OP **SHOULD** proceed with the authentication and return the `amr_details` claim reflecting the methods and metadata employed, enabling the RP to perform its own final policy evaluation.

This behavior preserves continuity of authentication while maintaining transparency for the RP, which can then evaluate the returned `amr_details` against its own acceptance criteria. If the RP requires strict adherence to its requested Authentication Methods, it **MUST** implement its own logic to assess the returned `amr_details` and decide whether to accept or reject the authentication based on the actual methods employed. The OP is not responsible for enforcing the RP's policies beyond attempting to meet the requested conditions.

## Error Handling {#sec-error-handling}

This specification does not introduce new error codes, error responses, or error handling mechanisms beyond those defined by [@!OpenID.Core, OpenID Connect Core] and related specifications. However, specific error conditions arise from the processing of `amr_details` requests and Authentication Method requirements:

- If a requirement expression contains Authentication Methods or constraints marked as `essential` that cannot be satisfied (due to OP limitations, End-User unavailability of factors, or verification failure), the Authorization Server **MUST** interrupt the flow and return an error to the RP.

- The OP **MUST** use the `access_denied` error code, as defined in [Section 4.1.2.1](https://www.rfc-editor.org/rfc/rfc6749#section-4.1.2.1) of [@!RFC6749, RFC 6749]. The OP **SHOULD** include an `error_description` parameter detailing which part of the requirement expression (*e.g.*, which `amr_identifier`) could not be satisfied to assist the RP in guiding the End-User.

All other error conditions arising from the processing of `amr_details` requests and Authentication Method requirements **MUST** be handled in accordance with the error handling rules defined by [@!OpenID.Core, OIDC], including those applicable to the Authorization Endpoint, Token Endpoint, and other relevant protocol endpoints.

If the Authorization Server does not support processing Authentication Method requirements conveyed through the `claims` parameter, as indicated by the absence of support declaration in its metadata, the Authorization Server **MUST NOT** treat such requests as an error. In this case, the Authorization Server **SHOULD** ignore the Authentication Method requirements and proceed with authentication according to its default behavior, subject to its internal policies and capabilities.
