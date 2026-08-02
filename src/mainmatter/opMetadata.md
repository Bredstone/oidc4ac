# OP Metadata {#sec-op-metadata}

This specification defines additional OpenID Provider Metadata parameters ([@!OpenID.Discovery, see OpenID Connect Discovery 1.0]) that allow RPs to determine the level of support for the `amr_details` Claim and for Authentication Method requests.

Support for this specification is intentionally divided into two distinct and independent capabilities:

{newline="true"}
**Informational Support**

: Which indicates the ability of the OP to return the `amr_details` Claim describing the Authentication Methods used during an Authentication Event.

**Request Processing Support**

: Which indicates the ability of the OP to process Authentication Method requirements expressed by the RP through the claims parameter.

**Note:** This separation allows OPs to adopt this specification incrementally, supporting the emission of `amr_details` as an informational claim without necessarily implementing Authentication Method negotiation.

## Informational Support for `amr_details`

An OP that is capable of returning the `amr_details` Claim as part of an ID Token or via the UserInfo Endpoint **MUST** declare this capability by including `amr_details` in the `claims_supported` metadata parameter defined by [@!OpenID.Discovery, OpenID Connect Discovery].

The presence of `amr_details` in `claims_supported` indicates that the OP **MAY** return the `amr_details` Claim when requested, describing the Authentication Methods used during the authentication of the End-User.

This declaration does not imply that the OP supports processing Authentication Method requirements expressed by the RP.

## Request Processing Support for Authentication Method Negotiation

An OP that supports processing Authentication Method requirements expressed through the `claims` parameter, including top-level essentiality and method-specific constraints, **MUST** support informational delivery of `amr_details` and declare that capability in `claims_supported`. It **MUST** also declare its request-processing capability using the following metadata parameter:

{newline="true"}
`amr_details_request_supported`

: OPTIONAL. Boolean value indicating whether the OP supports processing Authentication Method requests conveyed via the `claims` parameter, as defined in this specification. If omitted or set to `false`, the OP does not process Authentication Method requirements and treats any such request as informational only. An OP that sets `amr_details_request_supported` to `true` **MUST** comply with the processing rules defined in this specification for Authentication Method requests, including the handling of essential Claim requests, essential expressions, and authentication failure conditions.

RPs that require strict enforcement of Authentication Method requirements **MUST** verify that `amr_details_request_supported` is set to `true` before issuing such requests.

If `amr_details_request_supported` is omitted or set to `false`, the OP **MUST NOT** treat an Authentication Method expression received through the `claims` parameter as an error. It **SHOULD** ignore the expression and proceed according to its default behavior, subject to its internal policies and capabilities. A request for the `amr_details` Claim itself remains subject to the OP's informational support and ordinary Claim processing rules.

The following metadata parameters are OPTIONAL and provide additional information about the Authentication Methods and constraints supported by the OP. When present, they **MUST** accurately reflect the provider's capabilities.

{newline="true"}
`amr_identifiers_supported`

: OPTIONAL. JSON array of strings. Enumerates Authentication Method Identifiers that the OP is capable of returning in `amr_details` and, when `amr_details_request_supported` is `true`, processing in Authentication Method Request Expressions. This parameter is an informational capability advertisement and does not assert that every listed identifier is available for every End-User or authorization transaction. Identifiers SHOULD be registered in [@!RFC8176, RFC 8176] when applicable (*e.g.*, `pwd`, `otp`, `face`, `hwk`).

`<amr>_properties_supported`

: OPTIONAL. For each Authentication Method `<amr>` listed in `amr_identifiers_supported`, the OP **MAY** declare a corresponding metadata field named `<amr>_properties_supported`. This field is a JSON array of strings enumerating the specific properties that the OP can return in `amr_details` and, when `amr_details_request_supported` is `true`, process in Authentication Method Request Expressions. This parameter is an informational capability advertisement and does not assert that every listed property is available for every End-User or Authentication Method Execution. For example, if `otp` is listed in `amr_identifiers_supported`, the OP **SHOULD** declare `otp_properties_supported` to indicate which OTP-related properties (*e.g.*, `otp_length`, `otp_algorithm`) it can process or provide. The OP **SHOULD** use the property names defined in (#sec-method-properties) of this specification.

`<property>_values_supported`

: OPTIONAL. For a string-valued property, an OP **MAY** declare a corresponding metadata field named `<property>_values_supported` when the values it can return or, when `amr_details_request_supported` is `true`, process can be represented by a finite JSON array of strings. This field enumerates the OP's supported values; it does not assert that the array exhausts the property's vocabulary as defined by its profile. It **MUST NOT** be used to enumerate numbers, booleans, timestamps, objects, identifiers, or an open or unbounded value domain. The JSON type and semantics of each property are defined by the applicable Authentication Method Properties profile and need not be repeated in Discovery. Advertising a property indicates capability; it does not imply that the property is available for every End-User or Authentication Method Execution, or that every requested value can be satisfied.

`trust_framework_values_supported`

: OPTIONAL. JSON array of strings. Enumerates trust frameworks recognized or supported by the OP for contextual information (*e.g.*, `eIDAS`, `NIST SP 800-63`).

`assurance_level_values_supported`

: OPTIONAL. JSON array of strings. Enumerates assurance levels recognized or supported by the OP for contextual information (*e.g.*, `low`, `medium`, `high`). Its values **MUST** correspond to those defined by relevant trust frameworks declared in `trust_framework_values_supported`.

`location_types_supported`

: OPTIONAL. JSON array of strings. List of supported location-related attributes within the `amr_metadata.location` object. It **MAY** include any combination of the following values: `formatted`, `street_address`, `locality`, `region`, `postal_code`, `country`, `ip_address`, `latitude`, `longitude`, `precision`.

An example OP Metadata declaration including these parameters is provided in (#sec-op-metadata-example).
