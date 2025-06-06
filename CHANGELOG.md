## Unreleased


## 1.2.10 - 0001-01-01

## v1.2.9 - 2025-06-06

## v1.2.8 - 2025-06-06

## v1.2.7 - 2025-06-05

## v1.2.6 - 2025-06-05
### Fix
- added missing maven flags to all maven invocations


## v1.2.5 - 2025-06-05

## v1.2.4 - 2025-05-22
### Fix
- Simplify Maven variable usage in ci/maven.mk

### Refactor
- Simplify publish logic and add publish-version target


## v1.2.3 - 2025-05-22
### Refactor
- Simplify publish logic and add publish-version target


## v1.2.2 - 2025-05-22
### Fix
- Add missing newline at end of Makefile


## v1.2.1 - 2025-05-22
### Fix
- Improve logic for release branch creation
- Enforce fast-forward pulls for release branch creation
- Update release-branch target for proper remote sync
- Add 'git pull' to release-branch target in Makefile
- Update Makefile to handle branch-specific bump flags


## v1.2.0+1.aca21a8 - 2025-05-22
### Fix
- Add `release-branch` target and update CI workflow


## v1.2.0 - 2025-05-22
### Feat
- Add promotion targets to Makefile

### Fix
- Add missing git push command in Makefile
- Add conditional version handling in Makefile targets
- Remove unused branch strategy from Makefile
- Add missing newline in Makefile
- JSON syntax in GSEMVER branch strategy argument
- Makefile by escaping dollar sign in branch strategy
- Correct JSON escaping in Makefile's branch strategy flag
- Fix JSON escaping in branch strategy flag in Makefile
- Adjust pre-release bump flags in Makefile
- Enable git push by uncommenting the command in Makefile
- Remove GoCD pipeline configuration.
- Enable push for promotion branch in Makefile.
- Correct promotion branch handling in Makefile
- Remove trailing blank lines in Makefile
- Add newline at the end of Makefile
- Disable `git push` command in Makefile
- VERSION.txt generation in Makefile target
- Update Makefile to use GSEMVER variable for version bump
- Update Makefile to simplify executable variable names
- Improve version handling and cleanup Makefile

### Fix
- push target dependency in Makefile

### Refactor
- Simplify CI pipeline by removing pre-release steps


## v1.1.2 - 2025-05-20
### Fix
- Update Makefile to handle pre-release overwrite


## v1.1.1 - 2025-05-20
### Fix
- updated makefile flow 2


## v1.1.0 - 2025-05-20
### Chore
- test

### Fix
- updated makefile flow
- fixes10
- fixes2
- fixes2
- fixes
- test2
- test
- test
- test
- add all
- added pipeline

