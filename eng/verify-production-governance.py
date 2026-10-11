#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(rel: str) -> dict:
    value = json.loads((ROOT / rel).read_text(encoding="utf-8-sig"))
    if not isinstance(value, dict):
        raise SystemExit(f"FAIL not-object: {rel}")
    return value


def ok(condition: bool, message: str, failures: list[str]) -> None:
    print(("PROD-GOV-PASS " if condition else "PROD-GOV-FAIL ") + message)
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    participants = load(".pmcro/protocol/participant-governance.json")
    rights = load(".pmcro/protocol/data-rights.json")
    runtime = load(".pmcro/protocol/private-runtime-boundary.json")

    ok(participants.get("governanceRoute") == "@governance-agent /pmcro-governance:agt-governance", "reuses registered governance capability", failures)
    ok(participants.get("autonomy", {}).get("rootSeedFirstPhase") == "ORCHESTRATE", "autonomy remains ORCHESTRATE-first", failures)
    ok(participants.get("autonomy", {}).get("questionGate") is False, "no clarification gate", failures)
    ok(participants.get("evidenceLaw", {}).get("evidenceIsAuthority") is False, "evidence is not authority", failures)
    ok(participants.get("evidenceLaw", {}).get("denialMayBeBypassed") is False, "denials cannot be bypassed", failures)
    ok(all(v.get("mayGrantAuthority") is False for v in participants.get("principals", {}).values()), "principals do not self-grant authority", failures)
    ok(participants.get("releaseGate", {}).get("customerComplaintAloneMayDeploy") is False, "customer evidence cannot directly deploy", failures)

    provider = rights.get("providerBoundary", {})
    ok(provider.get("respectProviderRefusal") is True and provider.get("bypassRefusal") is False, "provider refusal respected", failures)
    ok(provider.get("hiddenTrainingCorpusExtraction") is False, "no hidden training-corpus extraction", failures)
    ok(provider.get("confidentialCompetitiveDataExtraction") is False, "no confidential competitive-data extraction", failures)
    ok(rights.get("deletionSemantics", {}).get("deletionMayBeClaimedCompleteOnlyWithObservedEvidence") is True, "deletion requires observed completion evidence", failures)

    private = runtime.get("privateRuntime", {})
    public = runtime.get("publicSurface", {})
    boundary = runtime.get("executionBoundary", {})
    ok(private.get("distribution") == "PRIVATE-NON-DISTRIBUTABLE", "private runtime is non-distributable", failures)
    ok(private.get("registrationRequired") is True and private.get("governanceRequired") is True, "private runtime requires registration and governance", failures)
    ok("private machine paths" in public.get("mustNotContain", []), "public contract excludes private machine paths", failures)
    ok(boundary.get("runtimeMayWidenGrant") is False, "private runtime cannot widen grant", failures)
    ok(boundary.get("rawRuntimeOutputIsEvidenceUntilChecked") is True, "runtime output remains evidence until checked", failures)

    verdict = "PASS" if not failures else "LOOP"
    print(f"PROD-GOV-SUMMARY verdict={verdict} failures={len(failures)}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
