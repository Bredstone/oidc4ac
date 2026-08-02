# `amr_details` Delivery {#sec-amr-details-delivery}

This section defines the rules governing *when* and *how* the `amr_details` Claim is returned by the OP.

The delivery of the `amr_details` Claim follows the general OIDC principles for Claims issuance defined in [Section 5](https://openid.net/specs/openid-connect-core-1_0.html#Claims) of [@!OpenID.Core, OIDC Core], subject to the additional completeness, consistency, and essential-request rules defined by this specification.

## Conditions for Delivery of the `amr_details` Claim

An OP is not required to return the `amr_details` Claim unless it is explicitly requested by the RP.

When requested, the OP **MUST** evaluate the request according to its capabilities and the processing rules defined in this specification (see (#sec-processing-requirements)). If the request is non-essential and the OP cannot construct and disclose a complete and conforming `amr_details` Claim, the OP **MAY** omit the entire Claim. It **MUST NOT** return a partial Authentication Event as though it were complete. If the request is essential, the OP **MUST** satisfy it or fail the request as defined in (#sec-error-handling).

An OP **MAY** return the `amr_details` Claim without an explicit request from the RP, based on internal policies, trust frameworks, regulatory obligations, or default Claim issuance rules. The determination of such policies is outside the scope of this specification.

## Complete Authentication Event

When the `amr_details` Claim is returned, it **MUST** contain an AMR Details Object for every Authentication Method Execution included in the corresponding Authentication Event. Expression-based disclosure **MUST NOT** remove Authentication Method Executions from the Claim. Each returned AMR Details Object **MUST** include at least `amr_identifier` and the mandatory `amr_metadata.time`. Partial disclosure **MAY** apply only to optional Authentication Method Metadata and Authentication Method Properties.

The OP **MUST** bind the immutable Authentication Context Snapshot to the corresponding authorization grant. An authorization that reuses an SSO session **MAY** rely on earlier Authentication Method Executions, but their original execution times **MUST** be preserved. ID Tokens issued in response to refresh token requests **MUST** use the snapshot associated with the corresponding authorization grant. UserInfo responses **MUST** use the snapshot associated with the corresponding Access Token. Concurrent authorization grants **MUST** remain isolated, and refresh-derived tokens or UserInfo responses **MUST NOT** acquire Authentication Method Executions from another grant or from later mutable session state.

## Delivery Mechanisms

When an RP explicitly requests the `amr_details` Claim, the OP **MUST**, subject to the omission and error rules above, return the Claim in the location or locations specified in the request, such as within the ID Token or via the UserInfo Endpoint, as defined by [@!OpenID.Core, OIDC Core]. If the RP does not explicitly request the Claim and the OP elects to return it based on internal policy, the OP **MAY** choose the delivery location.

Claims delivered through different locations **MUST** refer to the same Authentication Context Snapshot and **MUST** represent the same complete set of Authentication Method Executions. Optional metadata and properties disclosed for each execution **MAY** differ according to the request and applicable disclosure policy (see (#sec-disclosure-policy)). Any field disclosed in more than one location **MUST** have the same value and semantic meaning. Authentication Method Executions that occurred after the corresponding authorization **MUST NOT** be added to a later UserInfo response or refresh-derived token.

When the ID Token and UserInfo requests contain different Authentication Method expressions, the OP **MUST** combine their essential authentication requirements conjunctively for the authorization transaction. Non-essential expressions remain independent best-effort preferences. Disclosure is evaluated independently for each location, subject to the complete-event requirements above.
