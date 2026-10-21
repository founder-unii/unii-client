package com.malviys.unii.model;

public record AuthVerificationResponse(
    String status,
    String keyId,
    String keyName,
    String organizationId,
    String projectId
) {}
