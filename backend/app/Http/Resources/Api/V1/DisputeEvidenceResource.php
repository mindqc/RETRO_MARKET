<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DisputeEvidenceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'dispute_id' => $this->dispute_id,
            'uploader_id' => $this->uploader_id,
            'uploader_role' => $this->uploader_role,
            'evidence_type' => $this->evidence_type,
            'file_url' => $this->file_url,
            'message_note' => $this->message_note,
            'created_at' => $this->created_at?->toIso8601String(),
            'uploader' => $this->whenLoaded('uploader', function () {
                return [
                    'id' => $this->uploader->id,
                    'display_name' => $this->uploader->display_name,
                    'role' => $this->uploader->role instanceof \BackedEnum ? $this->uploader->role->value : (string) $this->uploader->role,
                ];
            }),
        ];
    }
}
