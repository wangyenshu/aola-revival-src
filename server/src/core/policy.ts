// Flash socket policy. Real Flash Player asks for it on port 843 and, failing
// that, as the first bytes on the game port itself. Ruffle never asks.

import { fromUtf8, utf8 } from "./bytes.ts";

export const POLICY_REQUEST = "<policy-file-request/>";

export function isPolicyRequest(chunk: Uint8Array): boolean {
  return chunk.length >= POLICY_REQUEST.length && fromUtf8(chunk.subarray(0, POLICY_REQUEST.length)) === POLICY_REQUEST;
}

export function policyResponse(ports = "*"): Uint8Array {
  const xml =
    '<?xml version="1.0"?>' +
    '<!DOCTYPE cross-domain-policy SYSTEM "/xml/dtds/cross-domain-policy.dtd">' +
    "<cross-domain-policy>" +
    '<site-control permitted-cross-domain-policies="master-only"/>' +
    `<allow-access-from domain="*" to-ports="${ports}"/>` +
    "</cross-domain-policy>";
  return utf8(xml + "\0");
}

/** HTTP crossdomain.xml for when the mirror has no captured one. */
export const CROSSDOMAIN_XML =
  '<?xml version="1.0"?>\n<cross-domain-policy>\n  <allow-access-from domain="*"/>\n</cross-domain-policy>\n';
