@protected @auth
Feature: Protected Endpoints Tests
  This feature contains reusable authentication logic for protected endpoints

  Background:
    * url baseUrl
    * configure headers = commonHeaders

  @companies
  Scenario: Get All Companies with Authentication and Data Extraction
    # Use the shared accessToken from main test suite
    Given path 'gateway/companies/get-all-companies'
    And header Authorization = 'Bearer ' + accessToken
    When method GET
    Then status 200
    And match response != null
    And match response[*].id != null
    # Extract all company IDs into an array for reuse
    * def companyIds = karate.map(response, function(x) x.id)
    # Create a lookup map for company validation: {id: name}
    * def companyMap = {}
    * karate.forEach(response, function(x) companyMap[x.id] = x.name)
    * print 'Extracted Company IDs:', companyIds
    * print 'Company Lookup Map:', companyMap

  @favorites
  Scenario: Get All Subscribed Products with Authentication
    # Use the shared accessToken from main test suite
    Given path 'gateway/favorites/get-all-subscribed-products'
    And header Authorization = 'Bearer ' + accessToken
    When method GET
    Then status 200
    And match response != null

  @products
  Scenario: Get All Products with Dynamic Company IDs and Data Validation
    # Use the shared accessToken from main test suite
    Given path 'gateway/products/get-all-products'
    And param page = 0
    And param size = 10
    And header Authorization = 'Bearer ' + accessToken
    And request
    """
    {
      "companyIds": #(companyIds),
      "productName": null
    }
    """
    When method POST
    Then status 200
    And match response != null
    And match response.content != null
    And match response.content[*].companyId != null
    And match response.content[*].companyName != null
    
    # Data Relationship Validation
    * print 'Validating data relationships between companies and products...'
    * def products = response.content
    
    # Validate that every product's companyId exists in the companies list
    * def invalidCompanyIds = karate.filter(products, function(x) companyIds.indexOf(x.companyId) == -1)
    * match invalidCompanyIds == []
    * print '✅ All product companyIds exist in companies list'
    
    # Validate that every product's companyName matches the company name from companies list
    * def nameMismatches = karate.filter(products, function(x) companyMap[x.companyId] != x.companyName)
    * match nameMismatches == []
    * print '✅ All product companyNames match companies list'
    
    * print '🎉 Data relationship validation passed!'
