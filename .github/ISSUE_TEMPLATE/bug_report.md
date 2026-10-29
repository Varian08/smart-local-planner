---
name: Bug Report (Quality Standard)
about: Standard enterprise ticket template for defects, regressions, or exceptions
title: "[SLP-X] Fix <Imperative Summary of Bug>"
labels: "bug"
assignees: ""
---

## Problem Statement
<Describe the defect, observed behavior vs. expected behavior, and root cause if known.>

## Steps to Reproduce
1. <Step 1>
2. <Step 2>
3. <Observed failure or error message>

## Acceptance Criteria
- [ ] Root cause identified and resolved without regressions.
- [ ] Edge cases or boundary conditions covered by automated regression tests.

## Implementation Tasks
1. [Backend/Mobile] Write failing regression test reproducing the defect.
2. [Backend/Mobile] Implement minimal, robust architectural fix.
3. [Testing] Verify all test suites pass with 0 warnings.

## Definition of Done
- [ ] Unit & slice tests pass locally with 100% success (`mvn test` / `flutter test`).
- [ ] Static analysis passes with 0 warnings (`flutter analyze`).
- [ ] Pull Request submitted using standard 3-section template and approved by Lead.
- [ ] Dual CI quality gates (Backend + Mobile) pass on GitHub Actions.

