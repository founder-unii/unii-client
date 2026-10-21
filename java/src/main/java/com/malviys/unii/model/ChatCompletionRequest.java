package com.malviys.unii.model;

import java.util.List;

public record ChatCompletionRequest(
    List<ChatMessage> messages,
    Boolean stream,
    Double temperature,
    Integer maxTokens,
    String projectId
) {
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private List<ChatMessage> messages = List.of();
        private Boolean stream = false;
        private Double temperature;
        private Integer maxTokens;
        private String projectId;

        public Builder messages(List<ChatMessage> messages) {
            this.messages = messages;
            return this;
        }

        public Builder messages(ChatMessage... messages) {
            this.messages = List.of(messages);
            return this;
        }

        public Builder stream(Boolean stream) {
            this.stream = stream;
            return this;
        }

        public Builder temperature(Double temperature) {
            this.temperature = temperature;
            return this;
        }

        public Builder maxTokens(Integer maxTokens) {
            this.maxTokens = maxTokens;
            return this;
        }

        public Builder projectId(String projectId) {
            this.projectId = projectId;
            return this;
        }

        public ChatCompletionRequest build() {
            return new ChatCompletionRequest(messages, stream, temperature, maxTokens, projectId);
        }
    }
}
