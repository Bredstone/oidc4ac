# Introduction

[@!OpenID.Core, OpenID Connect (OIDC)] enables Relying Parties (RPs) to obtain information about an Authentication Event performed by an OpenID Provider (OP) through a small set of standardized Claims. Among these, the Authentication Methods Reference (`amr`) Claim identifies the Authentication Methods that were used to authenticate the End-User. While widely deployed, the `amr` Claim provides information at a coarse level of granularity and does not support the representation of method-specific properties, contextual information, or assurance-related characteristics. Consequently, RPs are unable to express or evaluate detailed Authentication Requirements in an interoperable manner.

This specification defines an extension to OpenID Connect that introduces a structured framework for representing Authentication Methods and their associated metadata. The extension further enables Clients to request the use of specific Authentication Methods and to express constraints on their characteristics using standardized protocol elements. These capabilities enable consistent interpretation of Authentication Events across heterogeneous identity systems and support the enforcement of security, assurance, and compliance requirements.

The extension defined in this document is designed to be fully compatible with existing OpenID Connect flows and does not modify underlying authentication mechanisms, token formats, or authorization interactions defined by OpenID Connect. Implementations that do not support this extension continue to operate as specified by OpenID Connect, ignoring the additional elements introduced herein. Implementations that support this extension gain a standardized, machine-interpretable mechanism for representing and requesting Authentication Method information.

## Requirements Notation and Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [@!RFC2119, RFC 2119] and [@!RFC8174, RFC 8174].

In the .txt version of this specification, values are quoted to indicate that they are to be taken literally. When using these values in protocol messages, the quotes MUST NOT be used as part of the value. In the HTML version of this specification, values to be taken literally are indicated by the use of this fixed-width font.

All uses of [@!RFC7515, JSON Web Signature (JWS)] and [@!RFC7516, JSON Web Encryption (JWE)] data structures in this specification utilize the JWS Compact Serialization or the JWE Compact Serialization; the JWS JSON Serialization and the JWE JSON Serialization are not used.

## Scope

This document defines technical mechanisms that enable a Relying Party to request the use of specific Authentication Methods together with associated requirements, and that enable an OpenID Provider to represent and convey Authentication Method information in a structured and interoperable manner. These mechanisms support the evaluation of Authentication Events based on Authentication Method characteristics, contextual information, and assurance-related properties.

This specification does not define non-technical aspects required for the deployment of a complete authentication assurance framework, including, but not limited to, legal considerations, liability models, trust frameworks, operational policies, or commercial agreements. Deployments are expected to complement the technical mechanisms defined in this document with appropriate policy, regulatory, and contractual definitions. Although such considerations are out of scope, this specification is designed to provide sufficient flexibility to support deployment in environments subject to diverse legal, regulatory, and commercial requirements across jurisdictions. References to such requirements may be included in this document for illustrative purposes only.

## Terminology

The terminology defined in [@!OpenID.Core, OpenID Connect Core 1.0], [@!RFC6749, OAuth 2.0], and [@!RFC7519, JSON Web Token (JWT)] specifications applies throughout this document. In addition, this document defines the following terms, which are used with the meanings specified herein.

{newline="true"}
**Authentication Method**

: A procedure by which an End-User authenticates to the OP. Examples include password, one-time password, and biometrics.

**Authentication Method Identifier**

: A standardized identifier for an Authentication Method, typically derived from registered values, such as those defined in [@!RFC8176, RFC 8176], or from values defined by local policy.

**Authentication Method Execution**

: A concrete, successful application of an Authentication Method, including the actual time at which the method was successfully performed.

**Authentication Event**

: The complete set of successful Authentication Method Executions relied upon by the OP for a specific authorization. An Authentication Event may comprise multiple Authentication Methods performed sequentially, in combination, or reused from an existing SSO session.

**Authentication Method Properties**

: Structured information associated with an Authentication Method employed during an Authentication Event that describes method-specific properties, configuration parameters, or security characteristics.

**Authentication Method Metadata**

: Structured information associated with an Authentication Method that describes method-independent attributes, such as time and location, operational context, or assurance-related characteristics. Interpretation of such information, including its relevance to assurance, policy, or compliance evaluation, is delegated to the applicable trust framework, regulatory environment, or deployment-specific policy. Each Authentication Method employed in an Authentication Event has its associated Authentication Method Metadata.

**Authentication Context**

: The aggregate set of Authentication Methods, Authentication Method Properties, and Authentication Method Metadata associated with an Authentication Event.

**Authentication Context Snapshot**

: An immutable record of the Authentication Event associated with a specific authorization grant. In an SSO session, multiple authorization grants can rely on different subsets of previously performed or newly performed Authentication Method Executions; each grant therefore has its own snapshot.

**Authentication Method Request Expression**

: A structured condition expressed by an RP that constrains the Authentication Methods used in an Authentication Event or their associated Authentication Method Properties and Authentication Method Metadata. Depending on the request context, the expression can represent either an Authentication Requirement or an Authentication Preference.

**Authentication Requirement**

: An Authentication Method Request Expression that should be satisfied by the OP in order for the authorization request to succeed.

**Authentication Preference**

: An Authentication Method Request Expression that the OP should attempt to satisfy, but that does not prevent the authorization request from succeeding if it cannot be satisfied.


<!-- **Source and Contextual Information** -->

<!-- : Optional information describing the provenance, execution context, and assurance conditions under which the Authentication Method was executed. This information may include timestamps, device or network indicators, trust framework identifiers, or assurance-related classifications. -->
