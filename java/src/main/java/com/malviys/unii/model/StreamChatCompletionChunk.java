package com.malviys.unii.model;

import java.util.List;

public record StreamChatCompletionChunk(
    String id,
    String object,
    long created,
    String model,
    List<StreamChoice> choices
) {}
