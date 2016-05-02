Feature: Be able to view data in the database

  Scenario: User can view a formatted table of data
    Given There exists 1 group of 5 evaluation records in the database for instructor Brent Walther
    And User is authenticated
    When User visits the evaluation index page
    Then User should see a table of 7 data rows

  Scenario: User can view all instructors
    Given There exists 1 group of 5 evaluation records in the database for instructor Brent Walther
    And There exists 1 group of 5 evaluation records in the database for instructor John Smith
    And User is authenticated
    When User vists the instructor index page
    Then User should see a link for instructor Brent Walther
    And User should see a link for instructor John Smith

  Scenario: User can view an instructors courses
    Given There exists 1 group of 5 evaluation records in the database for instructor Brent Walther
    And User is authenticated
    When User visits the evaluation index page
    And Clicks on the name of instructor Brent Walther
    Then User should see courses page for Brent Walther

  Scenario: User can view an empty row between groups and check weighted means are stored in the correct colums 
    Given There exists 3 group of 2 evaluation records in the database for instructor Brent Walther
    And User is authenticated
    When User visits the evaluation index page
    Then User should see a table of 12 data rows
    And User should see an empty row between the 3 groups, given there are 2 evaluation records for each group
    And User should see 6 empty cells in each sum and average row, given there are 3 groups and 2 evaluation records for each group

  Scenario: Administrator is able to access the manual evaluation entry screen
    Given There exists 4 users assigned admin, readWrite, readOnly, and guest as roles
    And User is of class admin
    And There exists 1 group of 5 evaluation records in the database for instructor Brent Walther
    When User visits the evaluation index page
    Then User should see a table of 7 data rows

  Scenario: Read/Write is able to access the manual evaluation entry screen
    Given There exists 4 users assigned admin, readWrite, readOnly, and guest as roles
    And User is of class readWrite
    And There exists 1 group of 5 evaluation records in the database for instructor Brent Walther
    When User visits the evaluation index page
    Then User should see a table of 7 data rows

  Scenario: Read Only is able to access the manual evaluation entry screen
    Given There exists 4 users assigned admin, readWrite, readOnly, and guest as roles
    And User is of class readOnly
    And There exists 1 group of 5 evaluation records in the database for instructor Brent Walther
    When User visits the evaluation index page
    Then User should see a table of 7 data rows
