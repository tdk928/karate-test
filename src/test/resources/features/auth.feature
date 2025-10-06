@auth @login
Feature: Authentication API Tests
  This feature tests the authentication endpoints

  Background:
    * url baseUrl
    * configure headers = commonHeaders

  Scenario: Login with valid EGN format
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
    And match response != null
    And match response.success == true
    # EGN format is valid (10 characters), so success should be true
    # The API validates EGN/EIK length correctly!

  Scenario: Login with invalid EGN length
    Given path 'gateway/auth/login'
    And request
    """
    {
      "egnOrEik": "#(testCredentials.invalidEgnOrEik)",
      "password": "#(testCredentials.invalidPassword)"
    }
    """
    When method POST
    Then status 200
    And match response.success == false
    And match response.errorMessage contains "EGNOrEIK must be 9 or 10 characters"

  Scenario: Login with empty credentials
    Given path 'gateway/auth/login'
    And request
    """
    {
      "egnOrEik": "",
      "password": ""
    }
    """
    When method POST
    Then status 200
    And match response.success == false
    And match response.errorMessage contains "EGNOrEIK must be 9 or 10 characters"
