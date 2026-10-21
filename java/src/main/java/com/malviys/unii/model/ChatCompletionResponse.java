package com.malviys.unii.model;

import java.util.List;

public record ChatCompletionResponse(
    String id,
    String object,
    long created,
    String model,
    List<ChatChoice> choices,
    Citation citation
) {}
