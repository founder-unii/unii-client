<?php

declare(strict_types=1);

namespace Unii\Tests;

use InvalidArgumentException;
use PHPUnit\Framework\TestCase;
use Unii\Client;
use Unii\Models\ChatMessage;
use Unii\Models\ChatCompletionRequest;
use Unii\Models\ChatCompletionResponse;
use Unii\Models\AuthVerificationResponse;

class ClientTest extends TestCase
{
    public function testConstructorRejectsEmptyApiKey(): void
    {
        $this->expectException(InvalidArgumentException::class);
        new Client('');
    }

    public function testConstructorSetsBaseUrlAndProjectId(): void
    {
        $client = new Client('test-key', 'https://api.unii.dev/', 'proj-123');
        $this->assertSame('https://api.unii.dev', $client->getBaseUrl());
        $this->assertSame('proj-123', $client->getProjectId());
    }

    public function testChatMessageSerialization(): void
    {
        $msg = ChatMessage::user('Hello world');
        $array = $msg->toArray();

        $this->assertSame('user', $array['role']);
        $this->assertSame('Hello world', $array['content']);

        $restored = ChatMessage::fromArray($array);
        $this->assertSame('user', $restored->role);
        $this->assertSame('Hello world', $restored->content);
    }

    public function testChatCompletionRequestToArray(): void
    {
        $req = new ChatCompletionRequest(
            messages: [ChatMessage::user('Test query')],
            temperature: 0.7,
            projectId: 'p-1'
        );

        $data = $req->toArray();
        $this->assertFalse($data['stream']);
        $this->assertCount(1, $data['messages']);
        $this->assertSame(0.7, $data['temperature']);
        $this->assertSame('p-1', $data['projectId']);
    }

    public function testAuthVerificationResponseFromArray(): void
    {
        $auth = AuthVerificationResponse::fromArray([
            'status' => 'authenticated',
            'keyId' => 'key-1',
            'keyName' => 'default',
            'organizationId' => 'org-1',
            'projectId' => 'proj-1',
        ]);

        $this->assertSame('authenticated', $auth->status);
        $this->assertSame('key-1', $auth->keyId);
        $this->assertSame('proj-1', $auth->projectId);
    }

    public function testChatCompletionResponseWithCitation(): void
    {
        $res = ChatCompletionResponse::fromArray([
            'id' => 'chatcmpl-123',
            'object' => 'chat.completion',
            'created' => 1700000000,
            'model' => 'unii-rag',
            'choices' => [
                [
                    'index' => 0,
                    'message' => [
                        'role' => 'assistant',
                        'content' => 'Grounded answer',
                    ],
                    'finish_reason' => 'stop',
                ],
            ],
            'citation' => [
                'documentName' => 'handbook.pdf',
                'excerpt' => 'Policy details...',
                'confidence' => 0.95,
            ],
        ]);

        $this->assertSame('chatcmpl-123', $res->id);
        $this->assertCount(1, $res->choices);
        $this->assertSame('Grounded answer', $res->choices[0]->message->content);
        $this->assertNotNull($res->citation);
        $this->assertSame('handbook.pdf', $res->citation->documentName);
        $this->assertSame(0.95, $res->citation->confidence);
    }
}
