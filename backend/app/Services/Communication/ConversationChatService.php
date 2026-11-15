<?php

namespace App\Services\Communication;

use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ConversationChatService
{
    /**
     * List user conversations with participant details and unread messages count.
     */
    public function listUserConversations(User $user, int $perPage = 15): LengthAwarePaginator
    {
        return Conversation::where(function ($q) use ($user) {
            $q->where('user_one_id', $user->id)
                ->orWhere('user_two_id', $user->id);
        })
            ->with([
                'userOne.profile',
                'userOne.sellerProfile',
                'userTwo.profile',
                'userTwo.sellerProfile',
                'contextProduct.primaryImage',
                'contextOrder',
            ])
            ->withCount([
                'messages as unread_count' => function ($q) use ($user) {
                    $q->where('sender_id', '!=', $user->id)
                        ->where('is_read', false);
                },
            ])
            ->orderByRaw('last_message_at DESC NULLS LAST, id DESC')
            ->paginate($perPage);
    }

    /**
     * Start a new conversation or retrieve an existing one between two users (OQ-P6-03, BR-AC-02).
     */
    public function startOrGetConversation(
        User $sender,
        int $recipientId,
        ?int $contextProductId = null,
        ?int $contextOrderId = null
    ): Conversation {
        if ($sender->id === $recipientId) {
            throw new SelfTransactionForbiddenException('Không thể bắt đầu cuộc trò chuyện với chính mình (BR-AC-02).');
        }

        $recipient = User::findOrFail($recipientId);

        [$userOneId, $userTwoId] = Conversation::normalizeParticipants($sender->id, $recipient->id);

        return DB::transaction(function () use ($userOneId, $userTwoId, $contextProductId, $contextOrderId) {
            $conversation = Conversation::firstOrCreate(
                ['user_one_id' => $userOneId, 'user_two_id' => $userTwoId],
                ['context_product_id' => $contextProductId, 'context_order_id' => $contextOrderId]
            );

            $updates = array_filter([
                'context_product_id' => $contextProductId,
                'context_order_id' => $contextOrderId,
            ], fn ($v) => ! is_null($v));

            if (! empty($updates)) {
                $conversation->update($updates);
            }

            return $conversation->fresh([
                'userOne.profile',
                'userOne.sellerProfile',
                'userTwo.profile',
                'userTwo.sellerProfile',
                'contextProduct.primaryImage',
                'contextOrder',
            ]);
        });
    }

    /**
     * Incremental short-polling of messages (ADR-08, NFR-PER-03).
     */
    public function pollMessages(
        User $viewer,
        Conversation $conversation,
        ?int $afterId = null,
        int $limit = 50
    ): array {
        if (
            $viewer->id !== (int) $conversation->user_one_id
            && $viewer->id !== (int) $conversation->user_two_id
            && ! $viewer->isInternalStaff()
        ) {
            throw new RolePermissionDeniedException('Bạn không có quyền truy cập cuộc trò chuyện này.');
        }

        $query = Message::where('conversation_id', $conversation->id);

        if ($afterId !== null && $afterId > 0) {
            $messages = $query->where('id', '>', $afterId)
                ->with(['sender.profile', 'attachedProduct.primaryImage'])
                ->orderBy('id', 'asc')
                ->get();
        } else {
            $messages = $query->with(['sender.profile', 'attachedProduct.primaryImage'])
                ->orderBy('id', 'desc')
                ->limit($limit)
                ->get()
                ->reverse()
                ->values();
        }

        // Mark opponent's unread messages as read if viewer is participant
        if (
            $viewer->id === (int) $conversation->user_one_id
            || $viewer->id === (int) $conversation->user_two_id
        ) {
            Message::where('conversation_id', $conversation->id)
                ->where('sender_id', '!=', $viewer->id)
                ->where('is_read', false)
                ->update([
                    'is_read' => true,
                    'read_at' => now(),
                ]);
        }

        return [
            'conversation' => $conversation->fresh([
                'userOne.profile',
                'userOne.sellerProfile',
                'userTwo.profile',
                'userTwo.sellerProfile',
                'contextProduct.primaryImage',
                'contextOrder',
            ]),
            'messages' => $messages,
        ];
    }

    /**
     * Send a new message within an active conversation.
     */
    public function sendMessage(
        User $sender,
        Conversation $conversation,
        string $messageText,
        ?int $attachedProductId = null
    ): Message {
        if (
            $sender->id !== (int) $conversation->user_one_id
            && $sender->id !== (int) $conversation->user_two_id
        ) {
            throw new RolePermissionDeniedException('Bạn không có quyền gửi tin nhắn trong cuộc trò chuyện này.');
        }

        if ($conversation->blocked_by_user_id !== null) {
            throw new InvalidStateTransitionException('Cuộc trò chuyện này đã bị chặn nên không thể gửi thêm tin nhắn.');
        }

        return DB::transaction(function () use ($sender, $conversation, $messageText, $attachedProductId) {
            $message = Message::create([
                'conversation_id' => $conversation->id,
                'sender_id' => $sender->id,
                'message_text' => trim($messageText),
                'attached_product_id' => $attachedProductId,
                'is_read' => false,
            ]);

            $conversation->update([
                'last_message_preview' => Str::limit(trim($messageText), 200),
                'last_message_at' => now(),
            ]);

            return $message->load(['sender.profile', 'attachedProduct.primaryImage']);
        });
    }
}
