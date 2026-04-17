#!/bin/bash
# export-coverage.sh — Exports Xcode code coverage to a Markdown report
#
# Usage:
#   ./Scripts/export-coverage.sh [path/to/result.xcresult] [output.md]
#
# Defaults:
#   RESULT = /test-results/latest.xcresult
#   OUTPUT = TestCoverage.md
#
# Prerequisites:
#   1. Run tests with coverage enabled and a result bundle:
#      xcodebuild test \
#        -scheme SeeSaw \
#        -destination 'platform=iOS Simulator,name=iPhone 16' \
#        -testPlan SeeSaw \
#        -resultBundlePath /test-results/latest.xcresult
#
#   2. Code coverage must be enabled in SeeSaw.xctestplan
#      (codeCoverageEnabled: true — already configured)

set -euo pipefail

RESULT="${1:-test-results/latest.xcresult}"
OUTPUT="${2:-TestCoverage.md}"

if [ ! -d "$RESULT" ]; then
  echo "❌ Result bundle not found: $RESULT"
  echo "   Run tests first with: -resultBundlePath $RESULT"
  exit 1
fi

# Get JSON coverage report
JSON=$(xcrun xccov view --report --json "$RESULT")

# Build Markdown
{
  echo "# SeeSaw Companion — Test Coverage Report"
  echo ""
  echo "**Generated:** $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""

  # Target summary
  echo "## Target Summary"
  echo ""
  echo "| Target | Line Coverage |"
  echo "|--------|-------------|"
  echo "$JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for target in data.get('targets', []):
    name = target.get('name', 'Unknown')
    pct = target.get('lineCoverage', 0) * 100
    print(f'| {name} | {pct:.1f}% |')
"

  echo ""

  # Per-file coverage (non-test targets only)
  echo "## Per-File Coverage"
  echo ""
  echo "| File | Lines Covered | Total Lines | Coverage |"
  echo "|------|--------------|-------------|----------|"
  echo "$JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for target in data.get('targets', []):
    tname = target.get('name', '')
    if 'Tests' in tname:
        continue
    for f in sorted(target.get('files', []), key=lambda x: x.get('lineCoverage', 0), reverse=True):
        name = f.get('name', 'Unknown')
        pct = f.get('lineCoverage', 0) * 100
        covered = f.get('coveredLines', 0)
        total = f.get('executableLines', 0)
        if total == 0:
            continue
        print(f'| {name} | {covered} | {total} | {pct:.1f}% |')
"

  echo ""
  echo "---"
  echo "*Report generated from \`$RESULT\`*"
} > "$OUTPUT"

echo "✅ Coverage report saved to $OUTPUT"
