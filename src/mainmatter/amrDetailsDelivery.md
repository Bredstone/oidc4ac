# `amr_details` Delivery {#sec-amr-details-delivery}

This section defines the rules governing *when* and *how* the `amr_details` Claim is returned by the OP.

The delivery of the `amr_details` Claim follows the general OIDC principles for Claims issuance defined in [Section 5](https://openid.net/specs/openid-connect-core-1_0.html#Claims) of OIDC Core [@!OpenID.Core], subject to the additional completeness, consistency, and essential-request rules defined by this specification.

## Conditions for Delivery of the `amr_details` Claim

An OP is not required to return the `amr_details` Claim unless it is explicitly requested by the RP.

When requested, the OP **MUST** evaluate the `amr_details` Claim request according to its capabilities and the processing rules defined in this specification (see (#sec-processing-requirements)). Essentiality is determined by the top-level `essential` member of that Claim request, as defined in (#essential-logic). If that member is absent or `false` and the OP cannot construct and disclose a complete and conforming `amr_details` Claim, the OP **MAY** omit the entire Claim. It **MUST NOT** return a partial Authentication Event as though it were complete. If the top-level member is `true`, an OP supporting request processing **MUST** satisfy the Claim request or fail the Authentication Request as defined in (#sec-error-handling).

An OP **MAY** return the `amr_details` Claim without an explicit request from the RP, based on internal policies, trust frameworks, regulatory obligations, or default Claim issuance rules. The determination of such policies is outside the scope of this specification.

## Complete Authentication Event

When the `amr_details` Claim is returned, it **MUST** contain an AMR Details Object for every Authentication Method Execution included in the corresponding Authentication Event. Authentication Method Request Expressions (see (#sec-req)) **MUST NOT** remove Authentication Method Executions from the returned Claim. Each returned AMR Details Object **MUST** include at least `amr_identifier` and the mandatory `amr_metadata.time`. Partial disclosure **MAY** apply only to optional Authentication Method Metadata and Authentication Method Properties.

## Authentication Event Consistency

The `amr_details` Claim **MUST** describe the Authentication Event relied upon by the OP for the corresponding authorization grant. Authentication Method Executions performed subsequently in the same SSO session **MUST NOT** be added to Claims returned for that grant. Concurrent grants **MUST NOT** cause the Authentication Event reported for one grant to be replaced by the event associated with another grant.

An Authentication Request that reuses an SSO session **MAY** rely on earlier Authentication Method Executions, but their original execution times **MUST** be preserved.

If `amr_details` is included in an ID Token returned in response to a refresh token request, it **MUST** describe the Authentication Event associated with that authorization grant. If included in a UserInfo response, it **MUST** describe the Authentication Event associated with the authorization grant under which the Access Token was issued.

## Delivery Mechanisms

When an RP explicitly requests the `amr_details` Claim, the OP **MUST**, subject to the omission and error rules above, return the Claim in the location or locations specified in the request, such as within the ID Token or via the UserInfo Endpoint, as defined by OIDC Core [@!OpenID.Core]. If the RP does not explicitly request the Claim and the OP elects to return it based on internal policy, the OP **MAY** choose the delivery location.

Claims delivered through different locations for the same authorization grant **MUST** represent the same complete set of Authentication Method Executions. Optional metadata and properties disclosed for each execution **MAY** differ according to the request and applicable disclosure policy (see (#sec-disclosure-policy)). Any field disclosed in more than one location **MUST** have the same value and semantic meaning.

When the `id_token` and `userinfo` members of the `claims` parameter contain different Authentication Method Request Expressions, the OP **MUST** combine the expressions from top-level essential Claim requests conjunctively for the Authentication Request. Expressions from non-essential Claim requests remain independent best-effort preferences. Disclosure is evaluated independently for each location, subject to the complete-event requirements above.
