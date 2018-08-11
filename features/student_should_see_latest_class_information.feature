Feature: Student should see latest class information
  
  In order to only work on active offerings
  As a student
  I should always see latest class information
  
  Background:
    Given The default settings and jnlp resources exist using factories
    And the database has been seeded
    And I am logged in with the username teacher
    And I am on the class edit page for "Mathematics"
    And I fill in Class Name with "Basic Electronics"
    And I fill Description with "This is a biology class"
    And I fill Class Word with "betrx"
    And I press "Save"
    Then I should not see "Save"

  @javascript
  Scenario: Student should see the updated class name
    When I login with username: taylor
    Then I should see "Basic Electronics"
    
  @javascript
  Scenario: Student should see all the updated information of a class
    When I login with username: taylor
    And I follow "Basic Electronics"
    Then I should see "Class Word: betrx"
    And I should see "NON LINEAR DEVICES"
    And I should see "STATIC DISCIPLINE"
    
    
