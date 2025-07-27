#! /usr/bin/env bash

step setup_ready '^Given setup for (.*) is ready.$'
function setup_ready {
  echo "Completed setup steps for $1"
}

step test_run '^When test (.*) runs.$'
function test_run {
  echo "Test $1 ran."
}

step test_assertions '^Then test (.*) passes assertions.$'
function test_assertions {
  echo "Test $1 passed."
}
