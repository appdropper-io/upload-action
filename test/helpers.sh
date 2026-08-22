#!/usr/bin/env bash
# Tiny assertion helpers shared by the test/*-test.sh files. No external test
# framework: these scripts wrap a handful of bash processes, and bats/shunit2
# would be more ceremony than the thing being tested.

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  ✗ $desc"
    echo "      expected: $expected"
    echo "      actual:   $actual"
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  ✗ $desc"
    echo "      expected to find: $needle"
    echo "      in: $haystack"
  fi
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  ✗ $desc"
    echo "      expected NOT to find: $needle"
    echo "      in: $haystack"
  fi
}

summarize() {
  echo
  if [ "$FAIL" -eq 0 ]; then
    echo "$PASS passing"
    exit 0
  else
    echo "$FAIL failing, $PASS passing"
    exit 1
  fi
}
