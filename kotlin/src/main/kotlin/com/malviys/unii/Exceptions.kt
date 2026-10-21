package com.malviys.unii

class UniiApiException(
    val statusCode: Int,
    message: String,
    val details: String? = null
) : RuntimeException(
    if (details != null && details.isNotBlank()) "UniiApiException ($statusCode): $message - $details"
    else "UniiApiException ($statusCode): $message"
)
