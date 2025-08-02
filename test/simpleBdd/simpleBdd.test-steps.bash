#! /usr/bin/env bash

Given 'setup for (all tests|test [ABC]) is ready.' setup_ready
function setup_ready {
  echo "Completed setup steps for $1"
}

When 'test ([ABC]) runs.' test_run
function test_run {
  echo "Test $1 ran."
}

Then 'test ([ABC]) passes assertions.' test_assertions
function test_assertions {
  echo "Test $1 passed."
}

When 'test with error runs.' test_run_error
function test_run_error {
  echo "Test had an error during run time."
  return 1
}

Then '^it works.$' true
