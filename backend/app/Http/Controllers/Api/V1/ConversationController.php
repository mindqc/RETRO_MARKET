<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Engagement\SendMessageRequest;
use App\Http\Requests\Api\V1\Engagement\StartConversationRequest;
use App\Http\Resources\Api\V1\ConversationResource;
use App\Http\Resources\Api\V1\MessageResource;
use App\Models\Conversation;
use App\Services\Communication\ConversationChatService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    public function __construct(
        protected ConversationChatService $chatService
    ) {}

    /**
     * List user conversations with unread counts.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 15);
        $paginator = $this->chatService->listUserConversations($request->user(), $perPage);

        return ApiResponse::paginated(
            $paginator,
            ConversationResource::collection($paginator->getCollection()),
            'Lấy danh sách cuộc trò chuyện thành công.'
        );
    }

    /**
     * Start a new conversation or retrieve existing one.
     */
    public function store(StartConversationRequest $request): JsonResponse
    {
        $conversation = $this->chatService->startOrGetConversation(
            $request->user(),
            (int) $request->input('recipient_id'),
            $request->input('context_product_id'),
            $request->input('context_order_id')
        );

        if ($request->filled('initial_message')) {
            $this->chatService->sendMessage(
                $request->user(),
                $conversation,
                (string) $request->input('initial_message'),
                $request->input('context_product_id')
            );
            $conversation->refresh();
        }

        return ApiResponse::created(
            new ConversationResource($conversation),
            'Khởi tạo cuộc trò chuyện thành công.'
        );
    }

    /**
     * Incremental short-polling of conversation messages (ADR-08, NFR-PER-03).
     */
    public function messages(Request $request, int $id): JsonResponse
    {
        $conversation = Conversation::findOrFail($id);
        $afterId = $request->has('after_id') ? (int) $request->input('after_id') : null;
        $limit = (int) $request->input('limit', 50);

        $result = $this->chatService->pollMessages(
            $request->user(),
            $conversation,
            $afterId,
            $limit
        );

        return ApiResponse::success([
            'conversation' => new ConversationResource($result['conversation']),
            'messages' => MessageResource::collection($result['messages']),
        ], 'Lấy tin nhắn thành công.');
    }

    /**
     * Send a new message to the conversation.
     */
    public function sendMessage(SendMessageRequest $request, int $id): JsonResponse
    {
        $conversation = Conversation::findOrFail($id);

        $message = $this->chatService->sendMessage(
            $request->user(),
            $conversation,
            (string) $request->input('message_text'),
            $request->input('attached_product_id')
        );

        return ApiResponse::created(
            new MessageResource($message),
            'Gửi tin nhắn thành công.'
        );
    }
}
