#!/usr/bin/env bash
# Builds a small summary (a few hundred bytes) from a Trivy JSON vulnerability report (tens of MB),
# so that tools like the image catalog viewer can show counts without downloading the full report.
#
# Usage: trivy-summary.sh <trivy_vuln_report.json> <trivy_summary.json>
#
# Output (schemaVersion 1):
#   findings  - one entry per (vulnerability, package) pair, i.e. what Trivy lists
#   unique    - one entry per vulnerability ID; severity is the highest one reported for that ID,
#               fixable if any affected package has a fixed version
#   byClass   - findings split by Trivy result class (os-pkgs, lang-pkgs)
# Each counter object has: total, fixable, CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN.
# Severities with no findings (or filtered out by trivy --severity) are reported as 0.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <trivy_vuln_report.json> <trivy_summary.json>" >&2
  exit 1
fi
trap 'rm -f -- "$2.tmp"' EXIT

jq -c '
  def severities: ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"];
  def rank: {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1}[.] // 0;
  def fixable: (.FixedVersion // "") != "";
  def counts:
    reduce .[] as $v
      ((severities | map({(.): 0}) | add) + {total: 0, fixable: 0};
       .total += 1
       | .[$v.Severity] += 1
       | if ($v | fixable) then .fixable += 1 else . end);

  [ .Results[]? | .Class as $class
    | (.Vulnerabilities // [])[]
    | {id: .VulnerabilityID, Severity: (.Severity // "UNKNOWN"), FixedVersion: (.FixedVersion // ""), class: $class} ] as $all
  | {
      schemaVersion: 1,
      trivyVersion: .Trivy.Version,
      reportCreatedAt: .CreatedAt,
      findings: ($all | counts),
      unique: ($all
               | group_by(.id)
               | map({Severity: (max_by(.Severity | rank) | .Severity),
                      FixedVersion: (if any(.[]; fixable) then "yes" else "" end)})
               | counts),
      byClass: ($all | group_by(.class) | map({key: .[0].class, value: counts}) | from_entries)
    }
' "$1" > "$2.tmp"
# Only replace the output on success, so a failed run never leaves an empty or partial summary to be uploaded.
mv -- "$2.tmp" "$2"
