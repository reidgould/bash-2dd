#! /usr/bin/env bash

given 'setup for (.*) is ready.' setup_ready
function setup_ready {
  echo "Completed setup steps for $1"
}

when 'test (.*) runs.' test_run
function test_run {
  echo "Test $1 ran."
}

then_ 'test (.*) passes assertions.' test_assertions
function test_assertions {
  echo "Test $1 passed."
}
