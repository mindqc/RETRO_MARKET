<?php

namespace Tests\Feature\Api\V1;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Brand;
use App\Models\Category;
use App\Models\Favorite;
use App\Models\Product;
use App\Models\User;
use App\Models\UserAddress;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class UserProfileAndCatalogTest extends TestCase
{
    /**
     * 1. Test GET /api/v1/profile returns unified account, wallet, and order status counters (M-PF-01).
     */
    public function test_get_profile_returns_unified_account_wallet_summary_and_order_counters(): void
    {
        $user = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $token = $user->createToken('profile_test')->plainTextToken;

        try {
            $response = $this->withHeader('Authorization', "Bearer {$token}")
                ->getJson('/api/v1/profile');

            $response->assertStatus(200);
            $response->assertJsonStructure([
                'success',
                'message',
                'server_time',
                'data' => [
                    'user' => [
                        'id',
                        'display_name',
                        'email',
                        'role',
                        'status',
                        'profile',
                        'seller_profile',
                    ],
                    'order_status_counts' => [
                        'pending_payment',
                        'paid',
                        'preparing',
                        'shipped',
                        'delivered',
                        'completed',
                        'disputed',
                    ],
                    'favorites_count',
                    'following_count',
                ],
            ]);

            $this->assertTrue($response->json('success'));
            $this->assertEquals($user->id, $response->json('data.user.id'));
            $this->assertArrayNotHasKey('password_hash', $response->json('data.user'));
            $this->assertIsInt($response->json('data.order_status_counts.completed'));
            $this->assertIsInt($response->json('data.favorites_count'));
        } finally {
            $user->tokens()->delete();
        }
    }

    /**
     * 2. Test update profile with avatar upload and seasonal decor toggle (M-PF-02 / NFR-UX-02 / NFR-SEC-05).
     */
    public function test_update_profile_with_avatar_upload_and_seasonal_decor_settings_toggle(): void
    {
        Storage::fake('public');

        $user = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $originalName = $user->display_name;
        $token = $user->createToken('update_profile_test')->plainTextToken;

        try {
            // 2.1. Toggle seasonal decor to false then true
            $settingsRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->putJson('/api/v1/profile/settings', ['seasonal_decor_enabled' => false]);

            $settingsRes->assertStatus(200);
            $this->assertFalse($settingsRes->json('data.seasonal_decor_enabled'));

            $settingsRes2 = $this->withHeader('Authorization', "Bearer {$token}")
                ->putJson('/api/v1/profile/settings', ['seasonal_decor_enabled' => true]);

            $settingsRes2->assertStatus(200);
            $this->assertTrue($settingsRes2->json('data.seasonal_decor_enabled'));

            // 2.2. Update display_name, bio, and avatar upload
            $avatar = UploadedFile::fake()->image('test_avatar.png', 200, 200)->size(500);

            $updateRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->post('/api/v1/profile', [
                    'display_name' => 'Linh Vintage Lover',
                    'bio' => 'Dam me suu tam thoi trang vintage thập niên 90',
                    'avatar' => $avatar,
                ], ['Accept' => 'application/json']);

            $updateRes->assertStatus(200);
            $this->assertEquals('Linh Vintage Lover', $updateRes->json('data.display_name'));
            $this->assertEquals('Dam me suu tam thoi trang vintage thập niên 90', $updateRes->json('data.profile.bio'));
            $this->assertNotNull($updateRes->json('data.profile.avatar_url'));
        } finally {
            // Restore original name
            $user->update(['display_name' => $originalName]);
            $user->tokens()->delete();
        }
    }

    /**
     * 3. Test change password verifies current password and updates password_hash.
     */
    public function test_change_password_verifies_current_password_and_updates_password_hash(): void
    {
        $user = User::where('email', 'buyer.kiet@izithrift.local')->firstOrFail();
        $token = $user->createToken('change_pass_test')->plainTextToken;

        try {
            // 3.1. Wrong current password -> 422 INVALID_CURRENT_PASSWORD
            $wrongRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->putJson('/api/v1/profile/password', [
                    'current_password' => 'WrongCurrentPassword123!',
                    'password' => 'NewSecretPassword@2026',
                    'password_confirmation' => 'NewSecretPassword@2026',
                ]);

            $wrongRes->assertStatus(422);
            $this->assertFalse($wrongRes->json('success'));
            $this->assertEquals('INVALID_CURRENT_PASSWORD', $wrongRes->json('error_code'));

            // 3.2. Correct current password -> 200 OK
            $correctRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->putJson('/api/v1/profile/password', [
                    'current_password' => 'Retro@2026',
                    'password' => 'NewSecretPassword@2026',
                    'password_confirmation' => 'NewSecretPassword@2026',
                ]);

            $correctRes->assertStatus(200);
            $this->assertTrue($correctRes->json('success'));

            // 3.3. Verify login with new password succeeds
            $loginRes = $this->postJson('/api/v1/auth/login', [
                'email' => 'buyer.kiet@izithrift.local',
                'password' => 'NewSecretPassword@2026',
            ]);
            $loginRes->assertStatus(200);
        } finally {
            // Restore seeded password
            $user->update(['password_hash' => Hash::make('Retro@2026')]);
            $user->tokens()->delete();
        }
    }

    /**
     * 4. Test address book CRUD enforces single default address invariant (M-PF-03 / M-PF-04).
     */
    public function test_address_book_crud_enforces_single_default_address_invariant(): void
    {
        $user = User::create([
            'display_name' => 'Test Address User',
            'email' => 'address.test@izithrift.test',
            'password_hash' => Hash::make('SecretPass@2026'),
            'role' => UserRole::REGISTERED_USER,
            'status' => UserStatus::ACTIVE,
        ]);
        $token = $user->createToken('address_test')->plainTextToken;

        try {
            // 4.1. Add first address (should automatically be is_default = true)
            $addr1Res = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/profile/addresses', [
                    'recipient_name' => 'Ha Nguyen',
                    'recipient_phone' => '0901234567',
                    'province_city' => 'TP Ho Chi Minh',
                    'district_ward' => 'Quan 1',
                    'street_address' => '123 Nguyen Hue',
                    'is_default' => false, // Request false, but first address must become true!
                ]);

            $addr1Res->assertStatus(201);
            $this->assertTrue($addr1Res->json('data.is_default'));
            $id1 = $addr1Res->json('data.id');

            // 4.2. Add second address with is_default = true
            $addr2Res = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/profile/addresses', [
                    'recipient_name' => 'Ha Nguyen Work',
                    'recipient_phone' => '0901234567',
                    'province_city' => 'TP Ho Chi Minh',
                    'district_ward' => 'Quan 3',
                    'street_address' => '456 Le Loi',
                    'is_default' => true,
                ]);

            $addr2Res->assertStatus(201);
            $this->assertTrue($addr2Res->json('data.is_default'));
            $id2 = $addr2Res->json('data.id');

            // Verify address 1 is no longer default
            $this->assertFalse(UserAddress::find($id1)->is_default);

            // 4.3. Delete address 2 (default) -> address 1 must be promoted back to default
            $delRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->deleteJson("/api/v1/profile/addresses/{$id2}");

            $delRes->assertStatus(200);
            $this->assertTrue(UserAddress::find($id1)->is_default);
        } finally {
            $user->addresses()->delete();
            $user->tokens()->delete();
            $user->delete();
        }
    }

    /**
     * 5. Test user cannot update or delete another user's address returning 403.
     */
    public function test_user_cannot_update_or_delete_another_users_address_returns_403(): void
    {
        $userA = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $userB = User::where('email', 'buyer.kiet@izithrift.local')->firstOrFail();

        // Create an address belonging to User A
        $addressA = $userA->addresses()->create([
            'recipient_name' => 'Linh Nguyen',
            'recipient_phone' => '0911223344',
            'province_city' => 'Ha Noi',
            'district_ward' => 'Hoan Kiem',
            'street_address' => '10 Trang Tien',
            'is_default' => false,
        ]);

        $tokenB = $userB->createToken('intruder_token')->plainTextToken;

        try {
            // User B attempts to update User A's address -> 403
            $updateRes = $this->withHeader('Authorization', "Bearer {$tokenB}")
                ->putJson("/api/v1/profile/addresses/{$addressA->id}", [
                    'recipient_name' => 'Hacked Name',
                ]);

            $updateRes->assertStatus(403);
            $this->assertFalse($updateRes->json('success'));
            $this->assertEquals('ROLE_PERMISSION_DENIED', $updateRes->json('error_code'));

            // User B attempts to delete User A's address -> 403
            $deleteRes = $this->withHeader('Authorization', "Bearer {$tokenB}")
                ->deleteJson("/api/v1/profile/addresses/{$addressA->id}");

            $deleteRes->assertStatus(403);
            $this->assertFalse($deleteRes->json('success'));
            $this->assertEquals('ROLE_PERMISSION_DENIED', $deleteRes->json('error_code'));
        } finally {
            $addressA->delete();
            $userB->tokens()->delete();
        }
    }

    /**
     * 6. Test catalog taxonomy returns hierarchical categories and active brands (M-DS-01).
     */
    public function test_catalog_taxonomy_returns_hierarchical_categories_and_active_brands(): void
    {
        $response = $this->getJson('/api/v1/catalog/taxonomy');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'message',
            'server_time',
            'data' => [
                'categories' => [
                    '*' => [
                        'id',
                        'name',
                        'slug',
                        'icon_name',
                        'approved_products_count',
                        'children',
                    ],
                ],
                'brands' => [
                    '*' => [
                        'id',
                        'name',
                        'slug',
                        'approved_products_count',
                    ],
                ],
            ],
        ]);

        $this->assertTrue($response->json('success'));
        $this->assertGreaterThanOrEqual(8, count($response->json('data.categories')));
        $this->assertGreaterThanOrEqual(8, count($response->json('data.brands')));
    }

    /**
     * 7. Test home feed returns live auctions and only approved products with viewer flags (M-HM-01 / BR-PR-02).
     */
    public function test_home_feed_returns_live_auctions_and_only_approved_products_with_viewer_flags(): void
    {
        // 7.1. Guest Access
        $guestRes = $this->getJson('/api/v1/home');
        $guestRes->assertStatus(200);
        $guestRes->assertJsonStructure([
            'success',
            'data' => [
                'categories',
                'live_auctions',
                'featured_sellers',
                'latest_products',
            ],
        ]);

        // Verify BR-PR-02: All products must be APPROVED
        $products = $guestRes->json('data.latest_products');
        $this->assertNotEmpty($products);
        foreach ($products as $product) {
            $this->assertEquals('APPROVED', $product['status']);
            $this->assertFalse($product['is_favorited']);
            $this->assertFalse($product['is_owner']);
        }

        // 7.2. Authenticated Viewer Access with Favorited Flags
        $userWithFavorite = User::find(7); // User 7 has favorites in database
        $this->assertNotNull($userWithFavorite);

        $token = $userWithFavorite->createToken('viewer_feed_test')->plainTextToken;

        try {
            $authRes = $this->withHeader('Authorization', "Bearer {$token}")
                ->getJson('/api/v1/home');

            $authRes->assertStatus(200);
            $authProducts = $authRes->json('data.latest_products');

            // Find at least one product favorited by this user
            $favProductIds = Favorite::where('user_id', $userWithFavorite->id)->pluck('product_id')->toArray();
            $foundFavorited = false;
            foreach ($authProducts as $p) {
                if (in_array($p['id'], $favProductIds, true)) {
                    $this->assertTrue($p['is_favorited']);
                    $foundFavorited = true;
                }
            }
            $this->assertTrue($foundFavorited, 'Expected at least one favorited product to have is_favorited = true.');
        } finally {
            $userWithFavorite->tokens()->delete();
        }
    }

    /**
     * 8. Test public seller storefront hides unapproved products and paginates verified reviews (M-US-03 / BR-PR-02).
     */
    public function test_public_seller_storefront_hides_unapproved_products_and_paginates_verified_reviews(): void
    {
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();

        // 8.1. Storefront Detail
        $response = $this->getJson("/api/v1/sellers/{$seller->id}");

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data' => [
                'seller' => [
                    'id',
                    'display_name',
                    'shop_slug',
                    'trust_score',
                    'average_rating',
                ],
                'followers_count',
                'is_following',
                'is_owner',
                'products',
                'meta' => [
                    'current_page',
                    'total',
                ],
            ],
        ]);

        $this->assertTrue($response->json('success'));
        $this->assertEquals('gau.vintage@izithrift.local', $seller->email);

        // Verify all returned storefront products are APPROVED
        foreach ($response->json('data.products') as $item) {
            $this->assertEquals('APPROVED', $item['status']);
        }

        // 8.2. Sold tab
        $soldRes = $this->getJson("/api/v1/sellers/{$seller->id}?tab=sold");
        $soldRes->assertStatus(200);
        foreach ($soldRes->json('data.products') as $item) {
            $this->assertEquals('SOLD', $item['status']);
        }

        // 8.3. Verified Reviews Pagination
        $reviewRes = $this->getJson("/api/v1/sellers/{$seller->id}/reviews");
        $reviewRes->assertStatus(200);
        $reviewRes->assertJsonStructure([
            'success',
            'data',
            'meta' => [
                'current_page',
                'total',
            ],
        ]);

        // 8.4. Non-existent seller -> 404 RESOURCE_NOT_AVAILABLE
        $notFoundRes = $this->getJson('/api/v1/sellers/999999');
        $notFoundRes->assertStatus(404);
        $this->assertEquals('RESOURCE_NOT_AVAILABLE', $notFoundRes->json('error_code'));
    }
}
