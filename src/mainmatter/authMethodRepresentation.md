# Authentication Method Representation

This section defines the framework used by an OP to represent Authentication Methods and their associated Authentication Method Properties and Authentication Method Metadata.

The representation defined in this document is intended to complement, and not replace, existing OpenID Connect constructs such as the `amr` Claim defined in OpenID Connect Core. While the `amr` Claim identifies which Authentication Methods were used, it does not provide a mechanism to express method-level properties and metadata. This framework standardizes the representation of such information and enables RPs to evaluate Authentication Events based on Authentication Method Properties and Authentication Method Metadata rather than solely on method identifiers.

Authentication Method Executions relied upon in an Authentication Event are represented using **AMR Details Objects**, each of which corresponds to a single successful Authentication Method Execution. A complete Authentication Event is represented as a list of AMR Details Objects conveyed using a Claim named `amr_details`. The OP **MUST** preserve the event as an immutable Authentication Context Snapshot associated with the authorization grant. This representation enables RPs to perform deterministic evaluation of Authentication Events, assess conformance with method-level requirements, and interpret contextual attributes relevant to assurance, compliance, and policy evaluation.

This specification explicitly separates the concept of *which* Authentication Methods were performed, as conveyed by the `amr` Claim, from the concept of *how* those Authentication Methods were executed, as conveyed by the `amr_details` Claim. This separation preserves backward compatibility with existing OpenID Connect deployments while enabling richer semantics.

An OP implementing this specification **MUST** produce AMR Details Objects that conform to the structural and processing rules defined in this document. An RP implementing this specification **MUST** be capable of processing AMR Details Objects and, when applicable, evaluating them against Authentication Requirements expressed in authorization requests (see (#sec-req)).

<!-- Subsequent sections define the data structures, per-Authentication Method Metadata profiles, contextual attribute vocabularies, and normative processing rules associated with this specification. -->

## AMR Details Object

When returned, the value of the `amr_details` Claim **MUST** be a JSON array of AMR Details Objects. Each object represents a single successful Authentication Method Execution and is composed of an Authentication Method Identifier, Authentication Method Metadata, and, when available and permitted to be disclosed, Authentication Method Properties. Distinct successful executions with the same `amr_identifier` **MAY** be represented by separate AMR Details Objects. The requirements governing the Authentication Event represented by the Claim are defined in (#sec-amr-details-delivery).

The set of Authentication Method Identifiers represented by `amr_details` **MUST** be consistent with the `amr` Claim. Each identifier in `amr_details` **MUST** appear in `amr`, and each concrete Authentication Method Execution represented in `amr` **MUST** be represented by at least one AMR Details Object. Aggregate `amr` values that summarize the event, such as multi-factor or multi-channel indicators, need not have a separate AMR Details Object unless they correspond to a distinct Authentication Method Execution. Repeated executions **MAY** result in repeated AMR Details Objects; the `amr` Claim does not represent execution multiplicity.

The following non-normative example illustrates an `amr_details` Claim representing an Authentication Event where the End-User authenticated using a password method governed by the eIDAS trust framework. The example includes source and contextual information identifying the entity that performed the Authentication Method, along with method-specific metadata such as the password hashing algorithm and policy identifier.

```JSON
{
  "amr"        : [ "pwd" ],
  "amr_details": [
    {
      "amr_identifier": "pwd",
      "amr_metadata"  : {
        "iss"            : "https://idp.gov.com",
        "trust_framework": "eidas",
        "assurance_level": "low",
        "time"           : "2025-09-30T18:23:41Z"
      },
      "amr_properties": {
        "pwd_derivation_algorithm": "argon2id",
        "pwd_policy_id"           : "govbr-password-v2"
      }
    }
  ]
}

```

See (#sec-auth-method-representation-examples) for additional non-normative examples of `amr_details` representations.

The normative schema for the `amr_details` Claim is defined below.

{newline="true"}
`amr_details`

: When the `amr_details` Claim is returned, its value **MUST** be an array of JSON objects, each corresponding to an AMR Details Object. Each object is composed of the following top-level members:

`amr_identifier`

: REQUIRED. A standardized Authentication Method Identifier string referencing the Authentication Method employed. This value **MUST** correspond to one of the values listed in the `amr` Claim.

`amr_metadata`

: REQUIRED. A JSON object containing Authentication Method Metadata. The structure and content of this object are defined in (#sec-src).

`amr_properties`

: OPTIONAL. A JSON object containing Authentication Method Properties. The structure and content of this object are defined in (#sec-method-properties).

**Note:** Implementations **MUST** ignore members not defined by this specification or by extensions to it. Extensions that define additional members of `amr_details` **MAY** be created by the OpenID Foundation, ecosystem or scheme operators, or individual implementers using this specification.

Extensions of this specification, including trust framework definitions, can define further constraints on the data structure.

### Authentication Method Metadata Object {#sec-src}

Each AMR Details Object **MUST** include exactly one Authentication Method Metadata object, conveyed using the `amr_metadata` member. This object contains source and contextual information about the Authentication Method Execution. This information provides provenance and situational context that may be relevant for assurance evaluation, compliance checks, or policy enforcement by the RP.

This specification allows the OP to report Authentication Methods executed by external authenticators or brokers. In such cases, the `amr_metadata.iss` member identifies the entity that performed the Authentication Method, which may differ from the OP itself. An intermediary broker that did not perform the method **MUST NOT** be identified by this member solely because it conveyed the authentication information. The OP acts as the aggregator and reporter of the Authentication Context, includes the relevant information of the external authenticator in the `amr_metadata` member, and **MAY** perform validations on the reported data based on its own security policies or trust frameworks. Regardless of the validation level performed by the OP, the RP **MUST** independently evaluate whether it trusts the reported entities (`amr_metadata.iss`) before granting access to sensitive resources.

The value of the `amr_metadata` member **MUST** be a JSON object. The following members are defined for the `amr_metadata` object:

{newline="true"}
`iss`

: OPTIONAL. A string identifier of the entity that performed the Authentication Method (for example, the OP itself, an external authenticator, or a broker that performed the method). If present, the value **MUST** be a case-sensitive URL containing a scheme and host, and **MAY** include a port number and path components. The URL **MUST NOT** include query or fragment components. If this member is not present, the OP indicates that it itself performed the Authentication Method.

`trust_framework`

: OPTIONAL. A string identifier referencing the trust framework under which the Authentication Method was executed. The value **MUST** correspond to a trust framework defined and governed by a trust framework authority, such as a regulatory body, standards organization, or federation operator, that is applicable to the transaction context. An example value is `eidas`, which denotes an Authentication Method executed under the European [@!eIDAS, eIDAS framework].

`assurance_level`

: OPTIONAL. A string indicating the assurance level associated with the Authentication Method execution. The value **MUST** correspond to an assurance level defined by the referenced trust framework, local policy, or in a recognized trust framework registry, such as the [IANA Trust Frameworks registry](https://www.iana.org/assignments/loa-profiles). Examples include `eidas-loa-high` and `REFEDS-MFA`.

`time`

: REQUIRED. A timestamp indicating when the Authentication Method was successfully performed. The value **MUST** be represented in [@!RFC3339, RFC 3339] format. The OP **MUST** capture and preserve the actual execution time. The OP **MUST NOT** substitute token issuance time, authorization request time, session creation time, serialization time, or another approximate timestamp.

`location`

: OPTIONAL. A JSON object providing contextual information about the geographic or network origin of the authentication. Location-related data is considered sensitive and **SHOULD** be conveyed only when explicitly requested by the RP or required by an applicable policy or trust framework. While this specification enables the representation of high-precision information, OPs **SHOULD** apply data minimization practices where possible, such as truncating IP addresses or reducing the precision of geospatial coordinates. In certain high-assurance use cases, including regulated financial transaction environments, precise origin information **MAY** be required in order to satisfy security or compliance requirements. This object **MAY** include the standard `address` elements defined in [Section 5.1.1](https://openid.net/specs/openid-connect-core-1_0.html#AddressClaim) of [@!OpenID.Core, OIDC Core], and **MAY** additionally include network-related and geospatial attributes, as defined by this specification.

    {newline="true"}
    `ip_address`

    : OPTIONAL. A string representing the IP address from which the Authentication Method was executed, in either IPv4 or IPv6 format.

    `latitude`

    : OPTIONAL. A number representing the latitude coordinate of the location where the Authentication Method was executed, in decimal degrees.

    `longitude`

    : OPTIONAL. A number representing the longitude coordinate of the location where the Authentication Method was executed, in decimal degrees.

    `precision`

    : OPTIONAL. A number indicating the precision of the latitude and longitude coordinates, in meters.

### Authentication Method Properties Object {#sec-method-properties}

Each AMR Details Object **MAY** include exactly one Authentication Method Properties object, conveyed using the `amr_properties` member. Authentication Method Properties provide structured, machine-interpretable information describing *how* the corresponding Authentication Method was performed. These properties complement the Authentication Method Identifier conveyed by the `amr_identifier` member and the provenance and contextual information conveyed by Authentication Method Metadata in the `amr_metadata` member.

The `amr_properties` member is OPTIONAL, as not all Authentication Methods expose meaningful properties and some deployments **MAY** restrict the disclosure of such information due to privacy, policy, or regulatory considerations. If present, the value of the `amr_properties` member **MUST** be a JSON object.

Unless otherwise stated by a method-specific profile, the following processing rules apply:

- Each member of `amr_properties` **MUST** be a JSON value whose type is consistent with the definitions in this section (string, number, boolean, object, or array). Time-related values **SHOULD** use the same formatting requirements as `amr_metadata.time` (see (#sec-src)).

- A property designated as REQUIRED by an Authentication Method Properties profile is required only when the `amr_properties` object is emitted for that method. If the OP cannot truthfully provide every unconditionally REQUIRED property for the applicable profile, it **MUST** omit the entire `amr_properties` object rather than emit incomplete, inferred, or fabricated data. A property whose applicability depends on the manner in which the method was executed **MUST** state that condition explicitly. Trust frameworks or profiles **MAY** define stricter requirements.

- The set of members that **MAY** appear within `amr_properties` is bound to the value of `amr_identifier`. An OP **MUST NOT** emit Authentication Method Properties that are unrelated to the referenced Authentication Method.

- An OP **MUST NOT** include secrets, raw authenticators, replayable artifacts, or values that would enable offline attacks or impersonation. Prohibited content includes, but is not limited to, password hashes or salts, OTP values or seeds, biometric templates, private keys, or full device identifiers that are stable and enable cross-context correlation. When disclosure is necessary for auditability, the OP **SHOULD** prefer policy identifiers, coarse configuration descriptors, or non-sensitive measurements.

- Member names and values in `amr_properties` **SHOULD** be stable over time and, where feasible, shared across implementations. Deployments defining additional members (see (#sec-method-properties-extensibility)) **SHOULD** avoid introducing semantics that overlap with definitions established by this specification.

- RPs processing `amr_properties` **MUST** be tolerant of members not defined in this specification and **MUST** ignore any member that they do not process. The presence of additional members **MUST NOT** cause an RP to reject a token.

#### Extensibility {#sec-method-properties-extensibility}

This specification defines a baseline vocabulary for `amr_properties` applicable to a subset of commonly deployed Authentication Methods. Trust frameworks, scheme operators, and deployments **MAY** define additional Authentication Method Properties to support new Authentication Methods or to address additional assurance requirements.

Extensions **SHOULD** follow these conventions:

{newline="true"}
**Namespace and Collision Avoidance**

: Extensions **SHOULD** avoid defining Authentication Method Properties whose semantics overlap with those defined by other specifications, except where such overlap is strictly necessary to achieve interoperability or clarity.

**Minimal Disclosure**

: Extensions **MUST** be designed to disclose no more Authentication Method Properties than are necessary for the intended evaluation, in accordance with privacy-by-design principles and applicable deployment policies.

**Discovery Alignment**

: When [@!OpenID.Discovery, OpenID Connect Discovery] is used, OPs **SHOULD** advertise supported Authentication Method Properties using the capability advertisement mechanisms defined by this specification (see (#sec-op-metadata)), enabling RPs to determine which properties may be conveyed for a given `amr_identifier`.

## Authentication Method Properties Profiles {#sec-method-properties-profiles}

This section defines baseline vocabularies for method-specific `amr_properties`. The set of Authentication Methods addressed by this specification is derived from commonly deployed methods as described in [@!RFC8176, RFC 8176]. Not all Authentication Methods defined therein are associated with a distinct profile in this section.

Where multiple identifiers represent Authentication Methods with substantially overlapping functionality or semantics, this specification defines a profile for a representative identifier only. For example, while both `hwk` and `sc` denote hardware-based key mechanisms, a profile is defined for `hwk`, and the same profile **MAY** be applied to `sc` or equivalent identifiers by trust frameworks or deployments. Additionally, methods such as `mfa` or `mca` are intentionally omitted as they represent multi-factor or multi-channel constructs rather than standalone methods.

Each profile defined below applies when the value of `amr_identifier` equals the corresponding identifier. The profiles defined in this section are non-exhaustive and **MAY** be extended by trust frameworks or deployments as needed (see (#sec-method-properties-extensibility)).

### Facial Recognition (`face`)

Biometric Facial Recognition methods involve the use of facial features to authenticate an End-User. When `amr_identifier` is `face`, the `amr_properties` object **MAY** contain:

{newline="true"}
`face_recognition_algorithm`

: REQUIRED. A string indicating the facial recognition algorithm used during the Authentication Event. Acceptable values include (non-exhaustive):

    - `cnn`: Convolutional Neural Networks based recognition.

    - `deep_learning`: Generic deep learning/neural network models.

    - `eigenfaces`: Eigenfaces-based algorithm.

    - `fisherfaces`: Fisherfaces-based recognition algorithm.

    - `lbph`: Local Binary Patterns Histograms-based recognition algorithm.

`face_sensor_type`

: OPTIONAL. A string indicating the type of sensor used for facial recognition. Acceptable values include (non-exhaustive):

    - `2d`: Standard RGB camera (standard 2D image).

    - `3d`: Depth-sensing camera (e.g., Structured Light or Time-of-Flight).

    - `ir`: Passive or active Infrared sensor.

`face_match_score`

: OPTIONAL. A number representing the confidence score of the facial recognition match. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates a perfect match.

`face_image_quality`
: OPTIONAL. A number representing the quality of the facial image used for recognition. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates the highest quality.

`face_lighting_conditions`

: OPTIONAL. A number representing the lighting conditions during the facial recognition process. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates optimal lighting.

`face_pose_variation`

: OPTIONAL. A string indicating the degree of pose variation during the facial recognition process. Acceptable values include (non-exhaustive):

    - `frontal`: Frontal face pose.

    - `profile`: Profile face pose.

    - `tilted`: Tilted face pose.

`face_occlusion_level`

: OPTIONAL. A number representing the level of occlusion during the facial recognition process. This could include obstructions such as glasses, masks, or other objects partially covering the face. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates no occlusion.

`face_liveness_detection`

: OPTIONAL. A boolean indicating whether liveness detection was performed during the facial recognition process. A value of `true` indicates that liveness detection was employed to ensure that the face being recognized is from a live person rather than a static image or video.

`face_liveness_detection_method`

: OPTIONAL. An array of strings indicating the methods used for liveness detection during the facial recognition process. Acceptable values include (non-exhaustive):

    - `blink_detection`: Detection of eye blinks.

    - `head_movement`: Detection of head movements.

    - `texture_analysis`: Analysis of skin texture.

`face_policy_id`

: OPTIONAL. A string identifier referencing the facial recognition policy under which the method was executed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Fingerprint Recognition (`fpt`)

Fingerprint Recognition methods involve the use of fingerprint patterns to authenticate an End-User. When `amr_identifier` is `fpt`, the `amr_properties` object **MAY** contain:

{newline="true"}
`fpt_recognition_algorithm`

: REQUIRED. A string indicating the fingerprint recognition algorithm used during the Authentication Event. Acceptable values include (non-exhaustive):

    - `minutiae_based`: Minutiae-based recognition algorithm.

    - `pattern_based`: Pattern-based recognition algorithm.

    - `ridge_based`: Ridge-based recognition algorithm.

`fpt_sensor_type`

: OPTIONAL. A string indicating the type of sensor used for fingerprint recognition. Acceptable values include (non-exhaustive):

    - `optical`: Uses light to capture fingerprint images.

    - `capacitive`: Uses electrical capacitance to capture fingerprint images.

    - `ultrasonic`: Uses ultrasonic waves to capture fingerprint images.

`fpt_match_score`

: OPTIONAL. A number representing the confidence score of the fingerprint recognition match. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates a perfect match.

`fpt_image_quality`

: OPTIONAL. A number representing the quality of the fingerprint image used for recognition. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates the highest quality.

`fpt_finger_position`

: OPTIONAL. A string indicating the position of the finger used for recognition. Acceptable values include (non-exhaustive):

    - `right_thumb`: Right thumb.

    - `left_index`: Left index finger.

    - `right_middle`: Right middle finger.

`fpt_pressure_level`

: OPTIONAL. A number representing the pressure level applied during the fingerprint recognition process. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates optimal pressure.

`fpt_liveness_detection`

: OPTIONAL. A boolean indicating whether liveness detection was performed during the fingerprint recognition process. A value of `true` indicates that liveness detection was employed to ensure that the fingerprint being recognized is from a live person rather than a static image or artificial replica.

`fpt_liveness_method`

: OPTIONAL. An array of strings indicating the methods used for liveness detection during the fingerprint recognition process. Acceptable values include (non-exhaustive):

    - `sweat_detection`: Detection of sweat pores.

    - `temperature_analysis`: Analysis of skin temperature.

    - `pulse_detection`: Detection of pulse in the finger.

`fpt_policy_id`

: OPTIONAL. A string identifier referencing the fingerprint recognition policy under which the method was executed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### WebAuthn and Passkeys (`pop`)

A successfully verified WebAuthn assertion **MAY** be represented using the `pop` Authentication Method Identifier. The OP **MUST NOT** represent a WebAuthn assertion as `hwk` or `swk` unless it possesses trustworthy evidence supporting the corresponding key-protection classification. Backup eligibility, backup state, authenticator attachment, or an unattested AAGUID are insufficient by themselves. A non-backup-eligible credential does not by itself prove hardware protection, and software protection **MUST NOT** be inferred merely because hardware protection was not proven.

WebAuthn credential identifiers, public keys, attestation material, and AAGUIDs **SHOULD** be omitted unless necessary and permitted by applicable disclosure policy. Any disclosed credential reference **MUST** follow the pairwise and opacity requirements defined for key identifiers in the `hwk` and `swk` profiles.

### Hardware Secured Key Proof-of-Possession (`hwk`)

Hardware Secured Key Proof-of-Possession methods involve the use of cryptographic keys stored in secure hardware modules, such as Hardware Security Modules (HSMs), Trusted Platform Modules (TPMs), embedded Secure Elements, and other tamper-resistant cryptographic processors that ensure private keys remain within hardware boundaries. When `amr_identifier` is `hwk`, the `amr_properties` object **MAY** contain:

{newline="true"}
`hwk_key_id`

: OPTIONAL. An opaque identifier representing the hardware key used during the Authentication Event. This member **SHOULD** be omitted unless it is necessary for the RP's stated purpose. When disclosed, it **MUST NOT** contain the raw credential identifier, public key, or a globally stable internal identifier, and **MUST** be pairwise with respect to the RP or sector identifier.

`hwk_key_type`

: REQUIRED. A string indicating the type of cryptographic key used. Acceptable values include (non-exhaustive):

    - `RSA`: RSA key pair.

    - `EC`: Elliptic Curve key pair.

    - `EdDSA`: Edwards-curve Digital Signature Algorithm key pair.

`hwk_key_size`

: OPTIONAL. A number indicating the size of the cryptographic key in bits. For example, `2048` for RSA keys or `256` for certain elliptic curve keys. This value **MUST** be a positive integer.

`hwk_key_usage`

: OPTIONAL. A string indicating the intended usage of the hardware key. Acceptable values include (non-exhaustive):

    - `signing`: The key is used for digital signatures.

    - `encryption`: The key is used for encryption/decryption operations.

    - `key_agreement`: The key is used for key agreement protocols.

`hwk_key_algorithm`

: OPTIONAL. A string indicating the cryptographic algorithm associated with the hardware key. Acceptable values include (non-exhaustive):

    - `RSASSA-PSS`: RSA Signature Scheme with Appendix - Probabilistic Signature Scheme.

    - `ECDSA`: Elliptic Curve Digital Signature Algorithm.

    - `Ed25519`: Edwards-curve Digital Signature Algorithm using Curve25519.

`hwk_aaguid`

: OPTIONAL. The Authenticator Attestation Globally Unique Identifier (AAGUID), as defined in FIDO specifications, if applicable. When present, this value **MUST** be represented as a lowercase hexadecimal string formatted in the standard 8-4-4-4-12 pattern (e.g., `123e4567-e89b-12d3-a456-426614174000`). An AAGUID **MUST NOT** be treated as trustworthy evidence of hardware protection unless it is supported by verified attestation and an applicable trust source.

`hwk_fips_compliance`

: OPTIONAL. A string indicating the FIPS (Federal Information Processing Standards) compliance level of the hardware key or its containing module. Acceptable values include (non-exhaustive):

    - `none`: No FIPS compliance.

    - `fips_140_2_level_1`: Compliant with FIPS 140-2 Level 1.

    - `fips_140_2_level_2`: Compliant with FIPS 140-2 Level 2.

    - `fips_140_2_level_3`: Compliant with FIPS 140-2 Level 3.

    - `fips_140_2_level_4`: Compliant with FIPS 140-2 Level 4.

`hwk_cert_subject`

: OPTIONAL. A string representing the subject distinguished name (DN) of the X.509 certificate associated with the hardware key, if applicable.

`hwk_cert_issuer`

: OPTIONAL. A string representing the issuer distinguished name (DN) of the X.509 certificate associated with the hardware key, if applicable.

`hwk_cert_serial_number`

: OPTIONAL. A string representing the serial number of the X.509 certificate associated with the hardware key, if applicable.

`hwk_cert_valid_from`

: OPTIONAL. A timestamp indicating the start of the validity period of the X.509 certificate associated with the hardware key, if applicable. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`hwk_cert_valid_to`

: OPTIONAL. A timestamp indicating the end of the validity period of the X.509 certificate associated with the hardware key, if applicable. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`hwk_policy_id`

: OPTIONAL. A string identifier referencing the hardware key policy under which the key was created or is governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Iris Scan Recognition (`iris`)

Iris Scan Recognition methods involve the use of iris patterns to authenticate an End-User. When `amr_identifier` is `iris`, the `amr_properties` object **MAY** contain:

{newline="true"}
`iris_recognition_algorithm`

: REQUIRED. A string indicating the iris recognition algorithm used during the Authentication Event. Acceptable values include (non-exhaustive):

    - `wavelet_based`: Wavelet-based recognition algorithm.

    - `phase_based`: Phase-based recognition algorithm.

    - `texture_based`: Texture-based recognition algorithm.

`iris_match_score`

: OPTIONAL. A number representing the confidence score of the iris recognition match. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates a perfect match.

`iris_image_quality`

: OPTIONAL. A number representing the quality of the iris image used for recognition. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates the highest quality.

`iris_lighting_conditions`

: OPTIONAL. A number representing the lighting conditions during the iris recognition process. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates optimal lighting.

`iris_occlusion_level`

: OPTIONAL. A number representing the level of occlusion during the iris recognition process. This could include obstructions such as glasses or eyelids partially covering the iris. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates no occlusion.

`iris_liveness_detection`

: OPTIONAL. A boolean indicating whether liveness detection was performed during the iris recognition process. A value of `true` indicates that liveness detection was employed to ensure that the iris being recognized is from a live person rather than a static image or video.

`iris_liveness_method`

: OPTIONAL. An array of strings indicating the methods used for liveness detection during the iris recognition process. Acceptable values include (non-exhaustive):

    - `pupil_dilation`: Detection of pupil dilation.

    - `blink_detection`: Detection of eye blinks.

    - `texture_analysis`: Analysis of iris texture.

`iris_policy_id`

: OPTIONAL. A string identifier referencing the iris recognition policy under which the method was executed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Knowledge-Based Authentication (`kba`)

The attributes set for Knowledge-Based Authentication (KBA) methods can vary significantly based on the implementation, governing policies, and assurance requirements. These attributes are designed to provide insights into the nature and quality of the KBA process without exposing sensitive question or answer material. When `amr_identifier` is `kba`, the `amr_properties` object **MAY** contain:

{newline="true"}
`kba_question_count`

: REQUIRED. A number indicating the total count of knowledge-based questions presented to the End-User during the Authentication Event. This value **MUST** be a positive integer.

`kba_required_correct_answers`

: REQUIRED. A number indicating the minimum number of correct answers required for successful authentication. This value **MUST** be a positive integer and **MUST** be less than or equal to `kba_question_count`.

`kba_question_category`

: OPTIONAL. A string indicating the category or type of knowledge-based questions used. Acceptable values include (non-exhaustive):

    - `static`: Questions based on static personal information typically shared during registration processes (*e.g.*, "what is your mother's maiden name?", "what is your date of birth?").

    - `dynamic`: Dynamically generated questions based on recent or contextual information (*e.g.*, "what was the amount of your last transaction?", "which service did you access most recently?").

    - `behavioral`: Questions based on behavioral patterns or habits of the End-User (*e.g.*, "which of these locations have you visited in the last month?").

`kba_question_source`

: OPTIONAL. String identifier of the authority or dataset from which the knowledge questions were derived. OPs may define custom values to represent the provenance of knowledge questions. Examples include `credit_bureau`, `internal`, or `third_party_provider`.

`kba_max_attempts`

: OPTIONAL. A number indicating the maximum number of attempts allowed for answering the knowledge-based questions during the Authentication Event. This value **MUST** be a positive integer.

`kba_last_updated_at`

: OPTIONAL. A timestamp indicating when the knowledge-based questions were last updated or reviewed for accuracy and relevance. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`kba_created_at`

: OPTIONAL. A timestamp indicating when the knowledge-based questions were initially created or registered. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`kba_policy_id`

: OPTIONAL. A string identifier referencing the KBA policy under which the questions were created or are governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### One-Time Password (`otp`)

One-Time Password (OTP) authentication involves the use of a temporary, single-use code generated by an authenticator. OTPs can be delivered through various channels, including hardware tokens, mobile applications, or SMS messages. When `amr_identifier` is `otp`, the `amr_properties` object **MAY** contain:

{newline="true"}
`otp_length`

: REQUIRED. A number indicating the length of the OTP used during the Authentication Event. This value **MUST** be a positive integer.

`otp_algorithm`

: REQUIRED. A string indicating the OTP generation algorithm used. Acceptable values include (non-exhaustive):

    - `TOTP`: Time-based One-Time Password, as defined in [@!RFC6238, RFC 6238].

    - `HOTP`: HMAC-based One-Time Password, as defined in [@!RFC4226, RFC 4226].

`otp_format`

: OPTIONAL. A string indicating the format of the OTP. Acceptable values include (non-exhaustive):

    - `numeric`: The OTP consists solely of numeric digits (0-9).

    - `alpha`: The OTP includes only alphabetic letters (A-Z, a-z).

    - `alphanumeric`: The OTP includes both letters and digits.

`otp_delivery_method`

: OPTIONAL. A string indicating the delivery method used to transmit the OTP to the End-User. Acceptable values include (non-exhaustive):

    - `sms`: The OTP was delivered via SMS message.

    - `email`: The OTP was delivered via email.

    - `app`: The OTP was generated and displayed by a mobile or desktop application.

    - `push`: The OTP was delivered via a push notification to a registered device.

    - `hardware_token`: The OTP was generated by a hardware token device.

`otp_time_to_live`

: OPTIONAL. Integer value representing the duration, in seconds, during which the OTP remains valid. For TOTP, this corresponds to the time-step size; for HOTP, this represents the acceptable counter window defined by the verifier. It **MUST** be a positive integer.

`otp_delivery_time`

: OPTIONAL. A timestamp indicating when the OTP was delivered to the End-User. The value **MUST** be represented in [@!RFC3339, RFC 3339] format. This attribute **MUST** only be used if the OTP was delivered through an out-of-band channel.

`otp_max_attempts`

: OPTIONAL. A number indicating the maximum number of attempts allowed for entering the OTP during the Authentication Event. This value **MUST** be a positive integer.

`otp_attempts`

: OPTIONAL. A number indicating the actual number of attempts made by the End-User to enter the OTP during the Authentication Event. This value **MUST** be a positive integer.

`otp_policy_id`

: OPTIONAL. A string identifier referencing the OTP policy under which the OTP was created or is governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Personal Identification Number (`pin`)

Personal Identification Number (PIN) refers to knowledge-based authentication using a short numeric or alphanumeric code. While similar in nature to password-based verification, PIN authentication typically applies to constrained environments such as hardware tokens, mobile devices, or secure elements, where short secrets are locally verified and managed under stricter retry and locking policies. When `amr_identifier` is `pin`, the `amr_properties` object **MAY** contain:

{newline="true"}
`pin_length`

: REQUIRED. A number indicating the length of the PIN used during the Authentication Event. This value **MUST** be a positive integer.

`pin_format`

: REQUIRED. A string indicating the format of the PIN. Acceptable values include (non-exhaustive):

    - `numeric`: The PIN consists solely of numeric digits (0-9).

    - `alpha`: The PIN includes only alphabetic letters (A-Z, a-z).

    - `alphanumeric`: The PIN includes both letters and digits.

    - `pattern`: The PIN is represented as a pattern, such as a grid-based pattern on a touchscreen device.

`pin_max_attempts`

: OPTIONAL. A number indicating the maximum number of attempts allowed for entering the PIN during the Authentication Event. This value **MUST** be a positive integer.

`pin_attempts`

: OPTIONAL. A number indicating the actual number of attempts made by the End-User to enter the PIN during the Authentication Event. This value **MUST** be a positive integer.

`pin_last_updated_at`

: OPTIONAL. A timestamp indicating when the PIN was last set or updated. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`pin_created_at`

: OPTIONAL. A timestamp indicating when the PIN was initially created. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`pin_policy_id`

: OPTIONAL. A string identifier referencing the PIN policy under which the PIN was created or is governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Password-Based Authentication (`pwd`)

Password metadata is primarily intended to support auditability and assurance evaluation (*e.g.*, algorithm family and governing policy), without exposing sensitive password material. When `amr_identifier` is `pwd`, the `amr_properties` object **MAY** contain:

{newline="true"}
`pwd_derivation_algorithm`

: REQUIRED. A string indicating the password hashing or derivation algorithm used to store or verify the password. The value **MUST** correspond to a standardized password-based key derivation or hash function defined in relevant specifications. Acceptable values include (non-exhaustive):

  - `pbkdf2`, defined in [@!RFC8018, RFC 8018];
  - `scrypt`, defined in [@!RFC7914, RFC 7914];
  - `argon2id`, defined in [@!RFC9106, RFC 9106];
  - `sha256` or `sha512`, if a raw cryptographic hash is used, as registered in the [IANA Named Information Hash Algorithm registry](https://www.iana.org/assignments/named-information).

`pwd_iterations`

: OPTIONAL. A number indicating the iteration count or work factor used by the password derivation algorithm. This value is relevant for algorithms that support configurable iteration counts, such as PBKDF2 or Argon2. It **MUST** be a positive integer.

`pwd_salt_length`

: OPTIONAL. A number indicating the length, in bytes, of the salt used in the password hashing or derivation process. This value **MUST** be a positive integer.

`pwd_last_updated_at`

: OPTIONAL. A timestamp indicating when the password was last set or updated. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`pwd_created_at`

: OPTIONAL. A timestamp indicating when the password was initially created. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`pwd_policy_id`

: OPTIONAL. A string identifier referencing the password policy under which the password was created or is governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Retina Scan Recognition (`retina`)

Similar to Iris Scan Recognition, Retina Scan Recognition methods involve the use of retina patterns to authenticate an End-User. When `amr_identifier` is `retina`, the `amr_properties` object **MAY** contain:

{newline="true"}
`retina_recognition_algorithm`

: REQUIRED. A string indicating the retina recognition algorithm used during the Authentication Event. Acceptable values include (non-exhaustive):

    - `pattern_based`: Pattern-based recognition algorithm.

    - `vascular_based`: Vascular-based recognition algorithm.

`retina_match_score`

: OPTIONAL. A number representing the confidence score of the retina recognition match. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates a perfect match.

`retina_image_quality`

: OPTIONAL. A number representing the quality of the retina image used for recognition. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates the highest quality.

`retina_lighting_conditions`

: OPTIONAL. A number representing the lighting conditions during the retina recognition process. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates optimal lighting.

`retina_occlusion_level`

: OPTIONAL. A number representing the level of occlusion during the retina recognition process. This could include obstructions such as glasses or eyelids partially covering the retina. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates no occlusion.

`retina_liveness_detection`

: OPTIONAL. A boolean indicating whether liveness detection was performed during the retina recognition process. A value of `true` indicates that liveness detection was employed to ensure that the retina being recognized is from a live person rather than a static image or video.

`retina_liveness_method`

: OPTIONAL. An array of strings indicating the methods used for liveness detection during the retina recognition process. Acceptable values include (non-exhaustive):

    - `pupil_dilation`: Detection of pupil dilation.

    - `blink_detection`: Detection of eye blinks.

    - `texture_analysis`: Analysis of retina texture.

`retina_policy_id`

: OPTIONAL. A string identifier referencing the retina recognition policy under which the method was executed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### SMS-Based Authentication (`sms`)

Short Message Service (SMS)-based authentication is a widely adopted method for delivering one-time codes or verification messages to users' mobile devices. This delivery mechanism is classified as an out-of-band factor, complementing the core `otp` Authentication Method. SMS-based authentication introduces specific risks, such as SIM swapping and message interception. Given that, this specification focuses on conveying metadata that enhances the auditability and assurance evaluation of SMS delivery without exposing sensitive content. When `amr_identifier` is `sms`, the `amr_properties` object **MAY** contain:

{newline="true"}
`sms_gateway`

: REQUIRED. A string identifier representing the SMS gateway or service provider used to send the authentication messages. This value **MUST** correspond to a recognized identifier for the SMS service, such as a domain name or service name. Values **MAY** include:

    - A gateway service identifier, such as `twilio:us-east-1` or `nexmo:eu-west-1`.

    - An operator ID or Mobile Network Code (MNC) representing the mobile carrier used for delivery (*e.g.* `310 090` for AT&T USA).

    - A domain name or URL associated with the SMS service provider.

`sms_delivery_time`

: OPTIONAL. A timestamp indicating when the SMS message containing the authentication code was sent to the End-User. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`sms_origin`

: OPTIONAL. A string value identifying the sender identity used for SMS transmission, allowing for origin validation. Values **MAY** include:

    - A numeric E.164 formatted sender ID (*e.g.*, `+19876543210`).

    - An alphanumeric sender ID (*e.g.*, `MyPhoneService`).

    - An application identifier or short code used for sending the SMS (*e.g.*, `login-service`).

`sms_origin_type`

: OPTIONAL. A string indicating the type of sender identity used for SMS transmission. Acceptable values include (non-exhaustive):

    - `e164`: The sender ID is in E.164 numeric format.

    - `alphanumeric`: The sender ID is an alphanumeric string.

    - `short_code`: The sender ID is a short code or application identifier.

`sms_policy_id`

: OPTIONAL. A string identifier referencing the SMS authentication policy under which the SMS messages were sent or are governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

When `amr_identifier` is `sms`, and the authentication occurred through an OTP code, the OP **SHOULD** also include an entry for the `otp` method to represent the one-time code delivered via SMS. This dual representation allows RPs to evaluate both the OTP characteristics and the SMS delivery context for a comprehensive assurance assessment.

### Software Secured Key Proof-of-Possession (`swk`)

Similar to Hardware Secured Key methods, Software Secured Key Proof-of-Possession methods involve the use of cryptographic keys stored in software-based secure environments, such as software keystores, encrypted files, or secure enclaves within the operating system. These methods ensure that private keys are protected through software mechanisms, although they may not provide the same level of tamper resistance as hardware-based solutions. When `amr_identifier` is `swk`, the `amr_properties` object **MAY** contain:

{newline="true"}
`swk_key_id`

: OPTIONAL. An opaque identifier representing the software key used during the Authentication Event. This member **SHOULD** be omitted unless it is necessary for the RP's stated purpose. When disclosed, it **MUST NOT** contain the raw credential identifier, public key, or a globally stable internal identifier, and **MUST** be pairwise with respect to the RP or sector identifier.

`swk_key_type`

: REQUIRED. A string indicating the type of cryptographic key used. Acceptable values include (non-exhaustive):

    - `RSA`: RSA key pair.

    - `EC`: Elliptic Curve key pair.

    - `EdDSA`: Edwards-curve Digital Signature Algorithm key pair.

`swk_key_size`

: OPTIONAL. A number indicating the size of the cryptographic key in bits. For example, `2048` for RSA keys or `256` for certain elliptic curve keys. This value **MUST** be a positive integer.

`swk_key_usage`

: OPTIONAL. A string indicating the intended usage of the software key. Acceptable values include (non-exhaustive):

    - `signing`: The key is used for digital signatures.

    - `encryption`: The key is used for encryption/decryption operations.

    - `key_agreement`: The key is used for key agreement protocols.

`swk_key_algorithm`

: OPTIONAL. A string indicating the cryptographic algorithm associated with the software key. Acceptable values include (non-exhaustive):

    - `RSASSA-PSS`: RSA Signature Scheme with Appendix - Probabilistic Signature Scheme.

    - `ECDSA`: Elliptic Curve Digital Signature Algorithm.

    - `Ed25519`: Edwards-curve Digital Signature Algorithm using Curve25519.

`swk_attestation_type`

: OPTIONAL. A string indicating the level of isolation provided by the software environment. Acceptable values include (non-exhaustive):

    - `secure_enclave`: The key is stored within a secure enclave or trusted execution environment.

    - `software_keystore`: The key is stored in a software-based keystore with encryption.

    - `encrypted_file`: The key is stored in an encrypted file format.

`swk_fips_compliance`

: OPTIONAL. A string indicating the FIPS (Federal Information Processing Standards) compliance level of the software key or its containing environment. Acceptable values include (non-exhaustive):

    - `none`: No FIPS compliance.

    - `fips_140_2_level_1`: Compliant with FIPS 140-2 Level 1.

    - `fips_140_2_level_2`: Compliant with FIPS 140-2 Level 2.

    - `fips_140_2_level_3`: Compliant with FIPS 140-2 Level 3.

    - `fips_140_2_level_4`: Compliant with FIPS 140-2 Level 4.

`swk_cert_subject`

: OPTIONAL. A string representing the subject distinguished name (DN) of the X.509 certificate associated with the software key, if applicable.

`swk_cert_issuer`

: OPTIONAL. A string representing the issuer distinguished name (DN) of the X.509 certificate associated with the software key, if applicable.

`swk_cert_serial_number`

: OPTIONAL. A string representing the serial number of the X.509 certificate associated with the software key, if applicable.

`swk_cert_valid_from`

: OPTIONAL. A timestamp indicating the start of the validity period of the X.509 certificate associated with the software key, if applicable. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`swk_cert_valid_to`

: OPTIONAL. A timestamp indicating the end of the validity period of the X.509 certificate associated with the software key, if applicable. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`swk_policy_id`

: OPTIONAL. A string identifier referencing the software key policy under which the key was created or is governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Telephone-Based Authentication (`tel`)

Telephone-based Authentication Methods utilize telephony channels to verify the identity of the End-User. These methods often involve delivery of OTPs, user confirmation through Dual-Tone Multi-Frequency (DTMF) input, or out-of-band verification calls. This category encompasses both Interactive Voice Response (IVR) systems and human-operator-based confirmations, offering auditability of telephony-mediated authentication flows. When `amr_identifier` is `tel`, the `amr_properties` object **MAY** contain:

{newline="true"}
`tel_gateway`

: REQUIRED. A string identifier representing the telephony gateway or service provider used to facilitate the authentication process. This value **MUST** correspond to a recognized identifier for the telephony service, such as a domain name or service name. Values **MAY** include:

    - A gateway service identifier, such as `twilio:us-east-1` or `nexmo:eu-west-1`.

    - An operator ID or MNC representing the mobile carrier used for delivery (*e.g.* `310 090` for AT&T USA).

    - A domain name or URL associated with the telephony service provider.

`tel_call_type`

: OPTIONAL. A string indicating the type of telephone call used for authentication. Acceptable values include (non-exhaustive):

    - `ivr`: The authentication was performed through an IVR system.

    - `operator`: The authentication involved a human operator confirming the End-User's identity.

    - `callback`: The authentication involved a callback mechanism where the End-User initiated or received a call for verification.

`tel_call_time`

: OPTIONAL. A timestamp indicating when the telephone call for authentication was initiated or received. The value **MUST** be represented in [@!RFC3339, RFC 3339] format.

`tel_call_duration`

: OPTIONAL. A number indicating the duration of the telephone call used for authentication, measured in seconds. This value **MUST** be a positive integer.

`tel_call_recorded`

: OPTIONAL. A boolean indicating whether the telephone call was recorded for audit or verification purposes. A value of `true` indicates that the call was recorded.

`tel_call_confirmation_method`

: OPTIONAL. A string indicating the method used for user confirmation during the telephone-based authentication. Acceptable values include (non-exhaustive):

    - `dtmf`: The End-User confirmed their identity using DTMF input.

    - `voice`: The End-User's identity was confirmed through voice recognition technology.

    - `operator`: A human operator manually confirmed the End-User's identity.

`tel_voice_quality`

: OPTIONAL. A numeric value representing the perceived audio quality during the authentication call, typically measured using a Mean Opinion Score (MOS) or derived using ITU-T~P.862 (PESQ). This value **MUST** be a number between 1 and 5, where higher values indicate better quality.

`tel_policy_id`

: OPTIONAL. A string identifier referencing the telephone authentication policy under which the telephony interactions were conducted or are governed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

When `amr_identifier` is `tel`, and the authentication occurred through an OTP code delivered via telephone, the OP **SHOULD** also include an entry for the `otp` method to represent the one-time code delivered through the telephony channel. The same applies when the telephone method is used to conduct knowledge-based authentication; in such cases, the OP **SHOULD** also include an entry for the `kba` method.

### User Presence Test (`user`)

User Presence Test methods involve simple interactions by the End-User to confirm their presence during the Authentication Event. When `amr_identifier` is `user`, the `amr_properties` object **MAY** contain:

{newline="true"}
`user_test_type`

: REQUIRED. A string indicating the type of user presence test performed. Acceptable values include (non-exhaustive):

    - `button_press`: The End-User confirmed their presence by pressing a button.

    - `touch`: The End-User confirmed their presence by tapping on a touchscreen.

    - `motion`: The End-User confirmed their presence by performing a specific motion or gesture.

`user_test_duration`

: OPTIONAL. A number indicating the duration of the user presence test, measured in seconds. This value **MUST** be a positive integer.

`user_policy_id`

: OPTIONAL. A string identifier referencing the user presence test policy under which the method was executed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Voiceprint Recognition (`vbm`)

Voiceprint Recognition methods involve the use of voice patterns to authenticate an End-User. When `amr_identifier` is `vbm`, the `amr_properties` object **MAY** contain:

{newline="true"}
`vbm_recognition_algorithm`

: REQUIRED. A string indicating the voiceprint recognition algorithm used during the Authentication Event. Acceptable values include (non-exhaustive):

    - `mfcc_based`: Mel-Frequency Cepstral Coefficients-based recognition algorithm.

    - `dnn_based`: Deep Neural Network-based recognition algorithm.

`vbm_match_score`

: OPTIONAL. A number representing the confidence score of the voiceprint recognition match. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates a perfect match.

`vbm_audio_quality`

: OPTIONAL. A number representing the quality of the audio sample used for recognition. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates the highest quality.

`vbm_background_noise_level`

: OPTIONAL. A number representing the level of background noise during the voiceprint recognition process. The value **MUST** be a floating-point number between `0.0` and `1.0`, where `1.0` indicates no background noise.

`vbm_liveness_detection`

: OPTIONAL. A boolean indicating whether liveness detection was performed during the voiceprint recognition process. A value of `true` indicates that liveness detection was employed to ensure that the voice being recognized is from a live person rather than a recording.

`vbm_liveness_method`

: OPTIONAL. An array of strings indicating the methods used for liveness detection during the voiceprint recognition process. Acceptable values include (non-exhaustive):

    - `challenge_response`: Use of challenge-response prompts.

    - `spectral_analysis`: Analysis of audio spectral features.

    - `behavioral_analysis`: Analysis of speech patterns and behaviors.

`vbm_policy_id`

: OPTIONAL. A string identifier referencing the voiceprint recognition policy under which the method was executed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.

### Windows Integrated Authentication (`wia`)

Windows Integrated Authentication (WIA) leverages the authentication mechanisms provided by Windows operating systems, such as Kerberos or NTLM, to authenticate users seamlessly within a Windows domain environment. When `amr_identifier` is `wia`, the `amr_properties` object **MAY** contain:

{newline="true"}
`wia_protocol`

: REQUIRED. A string indicating the specific Windows authentication protocol used during the Authentication Event. Acceptable values include (non-exhaustive):

    - `kerberos`: The Kerberos authentication protocol.

    - `ntlm`: The NT LAN Manager (NTLM) authentication protocol.

    - `negotiate`: Indicates that the protocol was negotiated via SPNEGO (GSSAPI/SSP), typically resolving to Kerberos or NTLM.

`wia_domain`

: OPTIONAL. A string representing the Windows domain in which the End-User's account resides. This value **MUST** correspond to the domain name used in the Windows environment.

`wia_workstation`

: OPTIONAL. A string representing the name of the workstation or computer from which the End-User initiated the authentication. This value **MUST** correspond to the NetBIOS name or fully qualified domain name (FQDN) of the workstation.

`wia_policy_id`

: OPTIONAL. A string identifier referencing the Windows Integrated Authentication policy under which the method was executed. The value **MUST** correspond to a policy registered in a recognized policy registry or defined by local policy.
