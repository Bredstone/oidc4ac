# Requesting Authentication Methods {#sec-req}

Authentication Methods and their properties are requested during the authentication process using the `amr_details` Claim within the `claims` parameter, as defined in [Section 5.5](https://openid.net/specs/openid-connect-core-1_0.html#ClaimsParameter) of [@!OpenID.Core, OIDC Core]. This mechanism allows RPs to express assurance requirements and policy constraints in a standardized manner. RPs can specify not only *which* Authentication Methods they prefer or require, but also constraints on *how* those methods are performed.

Unlike the representation of Authentication Methods in a response, whose value is a JSON array, an individual `amr_details` Claim request **MUST** be either `null` or a JSON object. A `null` request asks for voluntary disclosure of the complete Claim without prescribing Authentication Methods. A JSON object is an outer Claim Request Object: it **MAY** contain the top-level `essential` member and **MAY** contain exactly one Authentication Method Request Expression. An object that contains only `essential`, or neither `essential` nor an expression, is an unconstrained request. The syntax and semantics of Claim requests and expressions are defined below.

Besides including the `amr_details` Claim within the `claims` parameter in authentication requests, this specification does not define any other means for requesting Authentication Methods. However, some deployments **MAY** choose to negotiate or request Authentication Methods through scope values (*e.g.*, `scope=pwd+otp`) provided there is prior agreement between the RP and the OP regarding the semantics of such scopes. Such approaches are possible under OIDC Core but fall outside the normative scope of this specification.

## Operators and Constraints

The request structure for `amr_details` introduces a set of operators and constraints that extend OIDC's expressiveness for authentication negotiation.

{newline="true"}
`one_of` and `all_of`

: Logical operators for combining Authentication Method Request Expressions. An `all_of` expression matches when every child expression matches. A `one_of` expression matches when at least one child expression matches; it does not require exactly one matching child. Their values **MUST** be non-empty JSON arrays whose elements are Authentication Method Request Expressions. Expressions **MAY** be nested recursively. The same Authentication Method Execution **MAY** satisfy more than one child expression, including children of the same `all_of` expression; this specification does not define an operator that requires distinct executions. Failure of one `one_of` branch does not prevent another branch from satisfying the expression, and attempting a branch does not commit the OP to that branch. Array order does not define a preference order.

`null`

: Requests disclosure of the named metadata or property when available and permitted.

`value`

: Expresses one acceptable value. The `amr_identifier` constraint **MUST** contain a single `value` member whose value is a string identifying one Authentication Method. Alternatives between Authentication Methods or Authentication Method Request Expressions **MUST** be represented using `one_of`. For metadata and properties, `value` expresses a value constraint whose effect depends on `essential`, as defined in (#essential-logic).

`values`

: Expresses a set of acceptable values for a metadata or property field. The `values` member **MUST** be a non-empty JSON array and **MUST NOT** be used with `amr_identifier`. `value` and `values` **MUST NOT** occur in the same constraint. Alternatives between primitive metadata or property values **MUST** be expressed using `values`, rather than by placing `one_of` or `all_of` inside a field constraint.

`min` and `max`

: Quantitative constraints applicable only to JSON Numbers. A type mismatch or a value outside the requested range means that the constraint is not satisfied. When both are present, `min` **MUST NOT** be greater than `max`.

`max_age`

: A temporal constraint, in seconds, that **MAY** appear only in an `amr_metadata.time` constraint and is applied to the actual execution time of the corresponding Authentication Method Execution. Its value **MUST** be a non-negative integer. A non-essential `max_age` is a best-effort freshness preference: the OP **SHOULD** attempt a fresh execution but **MAY** reuse an older execution and report its actual execution time. When locally essential, the execution used to match the method expression **MUST** be within the requested age. If an existing execution is too old, the OP **MUST** perform a fresh execution of that method to satisfy the constraint. Executing another method or refreshing the general session **MUST NOT** change the execution time of the requested method.

Each Authentication Method Request Expression object **MUST** contain exactly one of `amr_identifier`, `all_of`, or `one_of`. A single-method expression **MAY** also contain `amr_metadata` and `amr_properties` constraints applying to that method. The value of `amr_identifier` **MUST** be a non-empty object containing exactly one `value` member whose value is a string identifying one Authentication Method. Each requested metadata or property field **MUST** have either a `null` value or a non-empty constraint object. When multiple constraint operators occur in the same object, they are evaluated conjunctively. The Claim Request Object's top-level `essential` member **MAY** appear only in the outer `amr_details` Claim Request Object and **MUST** be a JSON Boolean. A constraint object for an `amr_metadata` or `amr_properties` field **MAY** contain its own `essential` member, which **MUST** be a JSON Boolean and has the local semantics defined in (#essential-logic). A constraint-level `essential` **MUST NOT** appear in `amr_identifier`, and neither form of `essential` **MUST** appear in a nested logical expression object. An empty expression, an empty logical-operator array, an expression containing more than one expression-form member, an unknown operator, `max_age` outside `amr_metadata.time`, or an invalid JSON type **MUST** result in `invalid_request`. An unsupported Authentication Method causes the corresponding single-method expression not to match. An unrecognized metadata or property field has no matching value; a locally essential constraint on that field causes the corresponding single-method expression not to match, while a non-essential constraint does not prevent it from matching. The OP **MUST NOT** fabricate or disclose a value for an unrecognized field.

The following non-normative example expresses a preference for facial recognition together with either a password or an OTP:

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
                "amr_properties": {
                  "otp_length": null,
                  "otp_algorithm": null
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

More examples of requesting Authentication Methods and attributes using the `claims` parameter are provided in (#sec-auth-method-request-examples).

## Essential and Non-Essential Requests {#essential-logic}

The semantic interpretation of the `essential` parameter within logical structures is defined as follows:

- When applied to the top-level `amr_details` Claim Request Object, `essential` serves two purposes:
  1. If the `amr_details` Claim request is unconstrained (contains no expression), `essential` indicates whether the RP requires the OP to return a complete and conforming `amr_details` Claim. If `essential` is omitted or set to `false`, the OP **MAY** return a complete Claim but **MAY** also omit it without causing authentication failure.
  2. If the `amr_details` Claim request contains an Authentication Method Request Expression, `essential` indicates whether the RP requires the OP to satisfy the expression. If `essential` is omitted or set to `false`, the OP **SHOULD** attempt to satisfy the expression but **MAY** continue according to its own authentication policy if it cannot do so. If `essential` is set to `true`, the OP **MUST** satisfy the expression and return a complete and conforming `amr_details` Claim; otherwise, it **MUST** fail the request as specified in (#sec-error-handling).

- When `essential` is applied to an Authentication Method Metadata or Authentication Method Properties constraint, it indicates whether the RP requires the OP to satisfy that specific constraint. When set to `true`, the named field **MUST** be present and its value **MUST** satisfy the constraint for the corresponding Authentication Method Execution to match the single-method expression. When omitted or set to `false`, the constraint is best-effort and does not prevent the method from matching. A locally essential constraint affects only the expression in which it occurs and does not become an independent requirement outside an enclosing `one_of` expression.

For example, the following request requires either facial recognition with successful liveness detection or proof of possession of a key:

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
          {
            "amr_identifier": { "value": "pop" }
          }
        ]
      }
    }
  }
}
```

If `face_liveness_detection` is absent or false, only the `face` branch fails; the `pop` branch can still satisfy the expression.

## Processing Requirements {#sec-processing-requirements}

An OP that declares `amr_details_request_supported` as `true` **MUST** process an `amr_details` request as follows:

- Validate the request structure and return an `invalid_request` error when it is malformed;

- Plan and perform authentication according to its own policy while considering the requested expression;

- Evaluate a single-method expression as matching when at least one successful Authentication Method Execution has an acceptable `amr_identifier` and satisfies every locally essential metadata or property constraint;

- Evaluate logical expressions according to the `all_of` and `one_of` semantics defined above;

- Return an error as specified in (#sec-error-handling) when a top-level essential request cannot be satisfied;

- For a non-essential request that cannot be satisfied, the OP **MAY** continue according to its own authentication policy and return the `amr_details` Claim describing the Authentication Event that actually occurred.

Non-essential metadata and property constraints **SHOULD** be satisfied on a best-effort basis and **MUST NOT** independently cause authentication failure. Requested values **MUST NOT** replace the values that were actually observed. Claim completeness, disclosure, consistency across delivery locations, and snapshot reuse are governed by (#sec-amr-details-delivery).

RPs **MUST** evaluate the returned `amr_details` Claim against their local policies, particularly when the request is non-essential. RPs seeking an abstract assurance level rather than a concrete Authentication Method **SHOULD** use `acr` and use `amr_details` to understand how the OP satisfied that assurance requirement.

## Error Handling {#sec-error-handling}

A malformed request structure, invalid JSON type, unknown or prohibited operator, empty expression, or structurally invalid combination **MUST** result in `invalid_request`.

If an essential `amr_details` Claim request or Authentication Method Request Expression cannot be satisfied, the OP **MUST** return the `unmet_authentication_requirements` error defined by [@!OpenID.UnmetAuthn, OpenID Connect Core Error Code unmet_authentication_requirements]. This includes inability to produce a complete and conforming Claim, failure of every expression branch because of a locally essential constraint, or inability to perform a required fresh Authentication Method Execution.

The public `error_description` **MUST** remain generic and **MUST NOT** identify the method or distinguish lack of enrollment, unsupported or unavailable methods, missing credentials, verification failure, or failure of a method-specific constraint. Detailed diagnostics **MAY** be logged internally or displayed locally by the OP.

The `access_denied` error **SHOULD** be used when the End-User explicitly cancels or refuses the authentication or authorization request.
