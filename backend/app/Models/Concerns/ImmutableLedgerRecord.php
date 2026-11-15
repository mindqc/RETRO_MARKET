<?php

namespace App\Models\Concerns;

use LogicException;

trait ImmutableLedgerRecord
{
    /**
     * Boot the trait to prevent updates and deletions.
     */
    public static function bootImmutableLedgerRecord(): void
    {
        static::updating(function () {
            throw new LogicException('Immutable ledger/audit record cannot be updated or deleted (BR-FN-07 / NFR-REL-04).');
        });

        static::deleting(function () {
            throw new LogicException('Immutable ledger/audit record cannot be updated or deleted (BR-FN-07 / NFR-REL-04).');
        });
    }
}
