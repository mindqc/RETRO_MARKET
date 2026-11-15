<?php

namespace App\Policies;

use App\Models\Conversation;
use App\Models\User;

class ConversationPolicy
{
    /**
     * Determine whether the user can access a conversation.
     */
    public function access(User $user, Conversation $conversation): bool
    {
        return $user->id === $conversation->user_one_id
            || $user->id === $conversation->user_two_id
            || $user->isAdmin()
            || $user->isSupport();
    }
}
