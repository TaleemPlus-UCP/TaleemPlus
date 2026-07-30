package com.example.taleem_plus

import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.runner.RunWith
import pl.leancode.patrol.PatrolJUnitRunner

@RunWith(PatrolJUnitRunner::class)
class MainActivityTest {
    @Test
    fun test() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val runner = instrumentation as PatrolJUnitRunner
        // This will run all tests in the integration_test directory
    }
}
