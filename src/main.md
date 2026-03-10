%%%
title = "OpenID Connect for Authentication Context 1.0"
abbrev = "openid-connect-4-authentication-context-1_0"
workgroup = "connect"
ipr = "none"
keyword = ["authentication method", "openid", "authentication context"]

[seriesInfo]
    name = "OpenID-Draft"
    value = "openid-connect-4-authentication-context-1_0-00"
    status = "standard"

[[author]]
initials="B."
surname="Vicente"
fullname="Brendon Vicente Rocha Silva"
organization="ONRCPN"
    [author.address]
    email = "brendon.vicente@onrcpn.org.br"

[[author]]
initials="F."
surname="Schardong"
fullname="Frederico Schardong"
organization="IFRS"
    [author.address]
    email = "frederico.schardong@rolante.ifrs.edu.br"

[[author]]
initials="R."
surname="Custódio"
fullname="Ricardo Felipe Custódio"
organization="UFSC"
    [author.address]
    email = "ricardo.custodio@ufsc.br"
%%%

.# Abstract

This specification defines an extension to OpenID Connect that enables Relying Parties to obtain detailed information about the Authentication Methods used to authenticate the End-User. In addition, it allows Clients to request the use of specific Authentication Methods and to express requirements associated with those methods during the authentication process.

.# Warning

This document is not an OIDF International Standard. It is distributed for review and comment. It is subject to change without notice and may not be referred to as an International Standard.

Recipients of this draft are invited to submit, with their comments, notification of any relevant patent rights of which they are aware and to provide supporting documentation.

.# Foreword

The OpenID Foundation (OIDF) promotes, protects and nurtures the OpenID community and technologies. As a non-profit international standardizing body, it is comprised by over 160 participating entities (workgroup participants). The work of preparing implementer drafts and final international standards is carried out through OIDF workgroups in accordance with the OpenID Process. Participants interested in a subject for which a workgroup has been established has the right to be represented in that workgroup. International organizations, governmental and non-governmental, in liaison with OIDF, also take part in the work. OIDF collaborates closely with other standardizing bodies in the related fields.

{mainmatter}

{{mainmatter/introduction.md}}
{{mainmatter/authMethodRepresentation.md}}
{{mainmatter/authMethodRequest.md}}
{{mainmatter/opMetadata.md}}
{{mainmatter/conformance.md}}
{{mainmatter/references.md}}

{backmatter}

{{backmatter/examples.md}}
{{backmatter/notices.md}}
{{backmatter/acknowledgements.md}}
{{backmatter/documentHistory.md}}
