function fn() {
    var env = karate.env; // get system property 'karate.env'
    karate.log('karate.env system property was:', env);
    
    if (!env) {
        env = 'dev';
    }
    
    var config = {
        env: env,
        baseUrl: 'http://localhost:8082'  // Your local API server
    }
    
    if (env == 'dev') {
        config.baseUrl = 'http://localhost:8082';
        config.timeout = 5000;
    } else if (env == 'test') {
        config.baseUrl = 'http://localhost:8082';
        config.timeout = 10000;
    }
    
    // Test credentials - customize these for your environment
    config.testCredentials = {
        validEgnOrEik: '9308149045',
        validPassword: '9308149045',
        invalidEgnOrEik: '123',
        invalidPassword: 'wrong'
    };
    
    // Global configuration
    config.apiTimeout = config.timeout || 10000;
    config.retryCount = 3;
    config.retryInterval = 1000;
    
    // Common headers - customize these for your API
    config.commonHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Karate-Test-Framework'
        // Add any authentication headers here, e.g.:
        // 'Authorization': 'Bearer ' + config.token
    };
    
    karate.log('config:', config);
    return config;
}