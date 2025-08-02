# From:
# https://cucumber.io/blog/bdd/gherkin-rules/

@my_feature_tag
Feature: Library changes

  @my_rule_tag
  Rule: Members pay reservation of $1 per item

    @my_scenario_tag
    Scenario: Reserving a single book
      # this scenario has all three tags applied
      Then it works.

    Scenario: Reserving a single book
      # this scenario has two tags applied
      Then it works.
