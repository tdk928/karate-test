package com.example.karate;

import com.intuit.karate.junit5.Karate;

/**
 * Test runner for Karate tests
 * This class executes all Karate feature files
 */
public class TestRunner {
    
    /**
     * Run all tests in the features directory
     */
    @Karate.Test
    Karate testAll() {
        return Karate.run("classpath:features");
    }
}
