@main @suite
Feature: Main Test Suite
  This is the main orchestrator that runs all test scenarios

  Background:
    * url baseUrl
    * configure headers = commonHeaders

  Scenario: Step 1 - Login with valid EGN format
    * call read('auth.feature') { tagSelector: '@login' }

  Scenario: Step 2 - Login with invalid EGN length  
    * call read('auth.feature') { tagSelector: '@invalid' }

  Scenario: Step 3 - Login with empty credentials
    * call read('auth.feature') { tagSelector: '@missing' }

  Scenario: Step 4 - Login and Get Companies (chained)
    # Step 4a: Login first
    Given path 'gateway/auth/login'
    And request
    """
    {
      "egnOrEik": "#(testCredentials.validEgnOrEik)",
      "password": "#(testCredentials.validPassword)"
    }
    """
    When method POST
    Then status 200
    And match response.success == true
    And match response.accessToken != null
    * def accessToken = response.accessToken
    
    # Step 4b: Get companies with authorization header
    Given path 'gateway/companies/get-all-companies'
    And header Authorization = 'Bearer ' + accessToken
    When method GET
    Then status 200
    And match response != null
