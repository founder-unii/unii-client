package com.malviys.unii.compose

import com.malviys.unii.UniiClient
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class UniiComposeTest {

    private val testDispatcher = StandardTestDispatcher()
    private val testScope = TestScope(testDispatcher)

    @Test
    fun testActionLifecycleExecutionFlow() = runTest {
        var beforeExecuted = false
        var handlerExecuted = false
        var afterExecuted = false

        val config = UniiActionConfig(
            name = "calculate_tax",
            description = "Calculates tax for order",
            onBeforeExecute = {
                beforeExecuted = true
                true
            },
            handler = { args ->
                handlerExecuted = true
                (args["amount"] as Double) * 0.1
            },
            onAfterExecute = { res, args ->
                afterExecuted = true
                assertEquals(10.0, res)
                assertEquals(100.0, args["amount"])
            }
        )

        val client = UniiClient(apiKey = "dummy_test_key")
        val state = UniiState(
            client = client,
            coroutineScope = testScope,
            stream = false
        )

        state.registerAction(config)
        assertEquals(config, state.getAction("calculate_tax"))

        val result = state.executeAction("calculate_tax", mapOf("amount" to 100.0))

        assertTrue(beforeExecuted)
        assertTrue(handlerExecuted)
        assertTrue(afterExecuted)
        assertEquals(10.0, result)
    }

    @Test
    fun testOnBeforeExecuteCancellation() = runTest {
        var handlerRan = false

        val config = UniiActionConfig(
            name = "delete_account",
            description = "Deletes user account",
            onBeforeExecute = { false },
            handler = {
                handlerRan = true
                "Deleted"
            }
        )

        val client = UniiClient(apiKey = "dummy_test_key")
        val state = UniiState(client = client, coroutineScope = testScope)
        state.registerAction(config)

        val res = state.executeAction("delete_account", emptyMap())
        assertNull(res)
        assertFalse(handlerRan)
    }

    @Test
    fun testOnErrorLifecycle() = runTest {
        var errorCaught = false

        val config = UniiActionConfig(
            name = "failing_action",
            description = "Fails deliberately",
            handler = {
                throw IllegalStateException("Payment gateway unavailable")
            },
            onError = { err, _ ->
                errorCaught = true
                assertEquals("Payment gateway unavailable", err.message)
            }
        )

        val client = UniiClient(apiKey = "dummy_test_key")
        val state = UniiState(client = client, coroutineScope = testScope)
        state.registerAction(config)

        try {
            state.executeAction("failing_action", emptyMap())
            fail("Expected exception was not thrown")
        } catch (e: IllegalStateException) {
            assertEquals("Payment gateway unavailable", e.message)
        }

        assertTrue(errorCaught)
    }

    @Test
    fun testJsonArgsParsing() {
        val client = UniiClient(apiKey = "dummy_test_key")
        val state = UniiState(client = client, coroutineScope = testScope)

        val raw = """
            {
                "query": "laptop",
                "priceMax": 1200.50,
                "inStock": true,
                "tags": ["tech", "sale"]
            }
        """.trimIndent()

        val parsed = state.parseJsonArgs(raw)
        assertEquals("laptop", parsed["query"])
        assertEquals(1200.50, parsed["priceMax"])
        assertEquals(true, parsed["inStock"])
        val tags = parsed["tags"] as List<*>
        assertEquals(2, tags.size)
        assertEquals("tech", tags[0])
    }

    @Test
    fun testToFrontendToolDefinition() {
        val config = UniiActionConfig(
            name = "get_weather",
            description = "Returns weather forecast"
        )
        val tool = config.toFrontendToolDefinition()
        assertEquals("get_weather", tool.name)
        assertEquals("Returns weather forecast", tool.description)
        assertNull(tool.parameters)
    }
}
