# Privacy Considerations

This specification introduces new mechanisms for representing and requesting Authentication Methods and attributes. Implementers **MUST** consider the privacy implications of exposing detailed Authentication Method information, as this could potentially reveal sensitive information about users' authentication practices or capabilities. 

OPs and RPs **MUST** ensure that their use of the mechanisms defined in this specification complies with applicable data protection and privacy regulations. The interpretation and application of such regulations are outside the scope of this specification.

RPs and OPs **SHOULD** also implement appropriate safeguards to protect user privacy, such as minimizing the amount of information shared and adhering to relevant data protection regulations.

This specification does not define requirements for user consent, notification, or user interface behavior. Such mechanisms, when applicable, are deployment-specific and may be governed by trust frameworks, contractual agreements, or regulatory requirements.

OPs and RPs **SHOULD** limit the retention of such information to what is necessary for their intended purposes and **SHOULD** avoid secondary use of Authentication Context information beyond the scope for which it was collected.

## Location Privacy and Regulatory Compliance

The disclosure of network and geospatial location data facilitates advanced fraud detection but introduces significant privacy risks. This specification provides the mechanisms for such disclosure but does not encourage its inadvertent or default use.
  
Implementers **MUST** recognize that the collection and transmission of location data are subject to regional laws, regulations, and privacy standards which are outside the scope of this document. It is the responsibility of the OP and RP to ensure that the level of detail provided is proportionate to the risk, justified by a valid legal basis, and compliant with applicable data protection requirements.
  
Data minimization remains a core principle; OPs **SHOULD** only provide the minimum level of location precision necessary to satisfy the RP's security or compliance objectives.

# Security Considerations

The `amr_details` Claim provides structured information about the Authentication Context and therefore introduces additional security and privacy considerations beyond those associated with the `amr` Claim.

## Integrity and Authenticity

RPs **MUST** treat the `amr_details` Claim as trustworthy only when it is obtained through mechanisms that provide integrity and authenticity guarantees equivalent to those defined by OIDC.

Specifically, a RP **MUST** only rely on `amr_details` when the Claim is:

- Included in a valid ID Token issued by the OP and whose signature, issuer (`iss`), audience (`aud`), and temporal Claims (such as `exp` and `iat`) have been successfully validated; or

- Returned by the UserInfo Endpoint over a secure transport channel and bound to a valid access token issued by the same OP.

RPs **MUST NOT** rely on `amr_details` obtained outside these contexts or without performing the appropriate validation steps defined by OIDC.

## Downgrade Attacks and Enforcement of Authentication Requirements

When Authentication Method requirements are expressed by the RP, the OP may authenticate the End-User using the best available Authentication Method according to its capabilities and policies, unless strict requirements are explicitly enforced as defined in this specification.

Regardless of the OP behavior, RPs **MUST** evaluate the returned `amr_details` Claim against their local authentication policies.

If the Authentication Methods used do not satisfy the RP's requirements, the RP **MUST** treat the Authentication Event as incomplete and **MUST NOT** grant access solely based on the successful completion of the OpenID Connect flow.

This specification intentionally assigns the final enforcement of Authentication Requirements to the RP in order to prevent downgrade attacks and to preserve compatibility with OPs that support informational reporting without Authentication Method negotiation.

## Trust Relationships and Federated Authentication Sources

The `amr_details` Claim may include authentication information originating from different issuers, such as in federated, brokered, or delegated authentication scenarios.

The inclusion of an issuer identifier (`amr_metadata.iss`) within the authentication descriptor does not inherently imply trust. RPs **MUST** maintain a list of trusted issuers or rely on a shared trust framework to evaluate the validity of methods performed by third-party authenticators. An OP reporting a third-party Authentication Method effectively acts as a relayer; the ultimate security decision regarding the provenance of the factor remains with the RP.

This specification does not define trust frameworks, federation policies, or mechanisms for establishing trust between RPs and external authentication sources. Such trust decisions are outside the scope of this specification and **MUST** be established through out-of-band agreements, federation metadata, or applicable trust frameworks.

## Fingerprinting, Correlation, and Data Minimization

The information conveyed by the `amr_details` Claim may reveal characteristics of the End-User's authentication capabilities and environment, which could enable correlation or fingerprinting across RPs.

OPs **SHOULD** apply data minimization principles when returning `amr_details`, limiting the information provided to what is necessary to describe the Authentication Context.

RPs **SHOULD** request `amr_details` only when required to meet security, regulatory, or compliance objectives. OPs **SHOULD NOT** return highly identifying or fine-grained authentication details by default unless required by internal policy, trust frameworks, or regulatory obligations.

## Replay and Temporal Considerations

The `amr_details` Claim include temporal information describing when Authentication Methods were performed or validated. RPs **MAY** use such information to evaluate the freshness of the Authentication Context according to their security policies.

RPs **SHOULD** evaluate the temporal attributes of Authentication Methods to mitigate replay attacks and ensure that the Authentication Context remains valid for the duration of the session or transaction. If the temporal information indicates that Authentication Methods are stale or outdated, the RP **MAY** require re-authentication or additional verification steps.

This specification does not define specific temporal thresholds or policies; such decisions **MUST** be made by the RP based on its security requirements.

# Implementation and Interoperability

This specification is designed to be fully compatible with existing OpenID Connect implementations. RPs and OPs that do not support the extensions defined in this document will continue to operate according to the base OpenID Connect specifications, ignoring any additional parameters or claims introduced here. Implementers **MUST** ensure that their systems can gracefully handle cases where the other party does not support these extensions.