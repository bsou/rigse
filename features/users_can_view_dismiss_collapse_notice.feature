Feature: Users can view notices created by project staff

  As a user
  I should be able to view and dismiss notices created by the project staff
  In order to be notified about updates or important information

  Background:
    Given The default project and jnlp resources exist using factories
    
    And the following users exist:
      | login      | password   | roles          |
      | mymanager  | mymanager  | manager        |
      | author     | author     | member, author |
      | researcher | researcher | researcher     |
      | admin      | admin      | admin          |
    And the following teachers exist:
      | login   | password | first_name | last_name |
      | teacher | teacher  | John       | Nash      |
    And the following students exist:
      | login   | password | first_name | last_name |
      | student | student  | Albert     | Chuck     |
    And I login as an admin
    And I create the following notices:
      | notice_html          | roles                                   |
      | Notice for all users | Admin,Member,Researcher,Author,Manager  |
    
    
  @javascript
  Scenario: Member roles should see notices
    When I login with username: teacher password: teacher
    And am on the my home page
    Then I should see "Notice for all users"
    
    
  @javascript
  Scenario: Admin roles should see notices
    When I login as an admin
    And am on the my home page
    Then I should see "Notice for all users"
    
    
  @javascript
  Scenario: Author roles should see notices
    And I am logged in with the username author
    And am on the my home page
    Then I should see "Notice for all users"
    
    
  @javascript
  Scenario: Manager roles should see notices
    And I am logged in with the username mymanager
    And am on the my home page
    Then I should see "Notice for all users"
    
    
  @javascript
  Scenario: Researcher roles should see notices
    And I am logged in with the username researcher
    And am on the my home page
    Then I should see "Notice for all users"
    
    
  @javascript
  Scenario: Students should not see notices
    And I login with username: student password: student
    And am on the my home page
    Then I should not see "Notice for all users"
    
    
  @dialog
  @javascript
  Scenario: Users can dismiss a notice without affecting other users
    When I am logged in with the username mymanager
    And am on the my home page
    And I follow "x"
    And accept the dialog
    And I wait 2 seconds
    And I should not see "Notice for all users"
    # Notice should not be visible on revisiting the home page
    And am on the my home page
    Then I should not see "Notice for all users"
    # Notice should be visible for other users
    And I login as an admin
    And am on the my home page
    And I should see "Notice for all users"
    
    
  @javascript
  Scenario: Users can collapse and expand notices
    When I am logged in with the username mymanager
    And am on the my home page
    And I follow "Hide Notices"
    And I should wait 2 seconds
    Then I should see "Show Notices"
    When I follow "Show Notices"
    And I should wait 2 seconds
    Then I should see "Hide Notices"
    
    
  @javascript
  Scenario: Notice expand-collapse state should be maintained across sessions
    When I am logged in with the username mymanager
    And am on the my home page
    And I follow "Hide Notices"
    And I should wait 2 seconds
    Then I should see "Show Notices"
    When I log out
    And I am logged in with the username mymanager
    And am on the my home page
    Then I should see "Show Notices"
    When I follow "Show Notices"
    And I should wait 2 seconds
    Then I should see "Hide Notices"
    When I log out
    And I am logged in with the username mymanager
    And am on the my home page
    Then I should see "Hide Notices"
    
    