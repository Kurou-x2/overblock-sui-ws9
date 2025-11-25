module challenge::marketplace;

use challenge::hero::Hero;
use sui::coin::{Self, Coin};
use sui::event;
use sui::sui::SUI;
use sui::object::{Self, UID, ID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};

// ========= ERRORS =========

const EInvalidPayment: u64 = 1;

// ========= STRUCTS =========

public struct ListHero has key, store {
    id: UID,
    nft: Hero,
    price: u64,
    seller: address,
}

// ========= CAPABILITIES =========

public struct AdminCap has key, store {
    id: UID,
}

// ========= EVENTS =========

public struct HeroListed has copy, drop {
    list_hero_id: ID,
    price: u64,
    seller: address,
    timestamp: u64,
}

public struct HeroBought has copy, drop {
    list_hero_id: ID,
    price: u64,
    buyer: address,
    seller: address,
    timestamp: u64,
}

// ========= FUNCTIONS =========

fun init(ctx: &mut TxContext) {
    // Admin yetkisi oluşturulup yayınlayana veriliyor
    let admin_cap = AdminCap {
        id: object::new(ctx)
    };
    transfer::public_transfer(admin_cap, ctx.sender());
}

public fun list_hero(nft: Hero, price: u64, ctx: &mut TxContext) {

    let id = object::new(ctx);
    let list_hero_id = object::uid_to_inner(&id);

    // Satış objesi oluşturuluyor
    let list_hero = ListHero {
        id,
        nft,
        price,
        seller: ctx.sender(),
    };

    // Event yayınlanıyor
    event::emit(HeroListed {
        list_hero_id,
        price,
        seller: ctx.sender(),
        timestamp: ctx.epoch_timestamp_ms(),
    });

    // Obje paylaşıma açılıyor
    transfer::share_object(list_hero);
}

#[allow(lint(self_transfer))]
public fun buy_hero(list_hero: ListHero, coin: Coin<SUI>, ctx: &mut TxContext) {

    // Satış objesi parçalanıyor
    let ListHero { id, nft, price, seller } = list_hero;

    // Ödeme kontrolü
    assert!(coin::value(&coin) == price, EInvalidPayment);

    // Coin satıcıya gidiyor
    transfer::public_transfer(coin, seller);

    // NFT alıcıya (işlemi yapana) gidiyor
    transfer::public_transfer(nft, ctx.sender());

    // Event yayınlanıyor
    event::emit(HeroBought {
        list_hero_id: object::uid_to_inner(&id),
        price,
        buyer: ctx.sender(),
        seller,
        timestamp: ctx.epoch_timestamp_ms(),
    });

    // Satış objesi siliniyor
    object::delete(id);
}

// ========= ADMIN FUNCTIONS =========

public fun delist(_: &AdminCap, list_hero: ListHero) {

    // Admin ilanı kaldırıyor, NFT satıcıya geri dönüyor
    let ListHero { id, nft, price: _, seller } = list_hero;

    transfer::public_transfer(nft, seller);
    object::delete(id);
}

public fun change_the_price(_: &AdminCap, list_hero: &mut ListHero, new_price: u64) {
    // Fiyat güncelleniyor
    list_hero.price = new_price;
}

// ========= GETTER FUNCTIONS =========

#[test_only]
public fun listing_price(list_hero: &ListHero): u64 {
    list_hero.price
}

// ========= TEST ONLY FUNCTIONS =========

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
        id: object::new(ctx),
    };
    transfer::public_transfer(admin_cap, ctx.sender());
}