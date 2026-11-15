<?php

namespace App\Exceptions;

class ProductOutOfStockException extends DomainException
{
    public function __construct(
        string $message = 'Sản phẩm đã hết hàng hoặc vừa được người khác đặt mua.',
        ?array $errors = null,
        ?array $latestState = null
    ) {
        parent::__construct($message, 'PRODUCT_OUT_OF_STOCK', 409, $errors, $latestState);
    }
}
