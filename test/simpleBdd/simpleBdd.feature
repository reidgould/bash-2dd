@tagOnFeature
Feature: Simple BDD
  Each scenario is run in a separate subprocess.
  Step files are loaded and functions invokded based on
  how they match to statements in the feature file.

  @tagOnBackground
  Background:
    Given setup for all tests is ready.

  @tagOnScenarioA
  Scenario: Test A is run.
    Given setup for test A is ready.
    When test A runs.
    Then test A passes assertions.

  Scenario: Test B is run.
    Given setup for test B is ready.
    When test B runs.
    Then test B passes assertions.

  @skip @tagOnScenarioC
  Scenario: Test C is run.
    Given setup for test C is ready.
    When test C runs.
    Then test C passes assertions.

  Scenario: Test with error is run.
    Given setup for test C is ready.
    When test with error runs.
    Then test C passes assertions.
