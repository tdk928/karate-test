@protected @auth @ignore
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

  @addToFavorites
  Scenario: Add First Product to Favorites with Field Validation
    # Use the existing products data from the main test suite
    # The products variable should be available from the @products scenario
    * print 'Using existing products data from previous scenarios'
    * def firstProductId = products[0].productId
    * print 'First Product ID to add to favorites:', firstProductId
    
    # Store the first product data for validation
    * def originalProduct = products[0]
    * print 'Original Product Data:', originalProduct
    
    # Call add to favorites endpoint with dynamic productId
    Given path 'gateway/favorites/add/' + firstProductId
    And header Authorization = 'Bearer ' + accessToken
    When method POST
    Then status 200
    And match response != null
    And match response.productId == firstProductId
    And match response.isActive == true
    
    # Field Mapping Validation - Compare favorites response with original product
    * print 'Validating field mapping between original product and favorites response...'
    * def favoritesResponse = response
    
    # Validate that productId matches
    * match favoritesResponse.productId == originalProduct.productId
    * print '✅ productId matches:', favoritesResponse.productId
    
    # Validate that product names match
    * match favoritesResponse.productNameEN == originalProduct.productNameEN
    * match favoritesResponse.productNameBG == originalProduct.productNameBG
    * print '✅ Product names match - EN:', favoritesResponse.productNameEN, 'BG:', favoritesResponse.productNameBG
    
    # Validate that barcode matches
    * match favoritesResponse.productBarcode == originalProduct.barcode
    * print '✅ Product barcode matches:', favoritesResponse.productBarcode
    
    # Validate that image URL matches
    * match favoritesResponse.productImageUrl == originalProduct.imageUrl
    * print '✅ Product image URL matches:', favoritesResponse.productImageUrl
    
    # Validate that response has expected fields
    * match favoritesResponse.id != null
    * match favoritesResponse.userId != null
    * match favoritesResponse.addedAt != null
    * print '✅ Response has all required fields'
    
    * print '🎉 Add to favorites with field validation passed!'

  @removeFromFavorites
  Scenario: Remove Product from Favorites with Validation
    * print 'Using products data for remove from favorites'
    * def firstProductId = products[0].productId
    * print 'Product ID to remove from favorites:', firstProductId
    
    # Store the first product data for validation
    * def originalProduct = products[0]
    * print 'Original Product Data:', originalProduct
    
    # Call remove from favorites endpoint with dynamic productId
    Given path 'gateway/favorites/remove/' + firstProductId
    And header Authorization = 'Bearer ' + accessToken
    When method DELETE
    Then status 204
    
    # Validate that the removal was successful (204 No Content indicates successful deletion)
    * print 'Validating remove from favorites response...'
    * print '✅ DELETE operation successful - Product removed from favorites'
    * print '✅ Product ID that was removed:', firstProductId
    * print '✅ Original product data:', originalProduct.productNameEN, '(ID:', originalProduct.productId, ')'
    
    * print '🎉 Remove from favorites completed successfully!'
