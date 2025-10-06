package com.example.karate;

import com.intuit.karate.junit5.Karate;

/**
 * Test runner for Karate tests
 * This class executes all Karate feature files
 */
public class TestRunner {
    
    /**
     * Run the main test suite which orchestrates all tests
     */
    @Karate.Test
    Karate testAll() {
        return Karate.run("classpath:features/main-test-suite.feature");
    }
    
    /**
     * Run individual authentication tests
     */
    @Karate.Test
    Karate testAuth() {
        return Karate.run("classpath:features/auth.feature");
    }
}
