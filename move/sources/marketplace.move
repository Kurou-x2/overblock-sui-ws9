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

// YENİ EKLENEN EVENTLER
public struct HeroDelisted has copy, drop {
    list_hero_id: ID,
    seller: address,
    timestamp: u64,
}

public struct PriceChanged has copy, drop {
    list_hero_id: ID,
    new_price: u64,
    timestamp: u64,
}

// ========= FUNCTIONS =========

fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
        id: object::new(ctx)
    };
    transfer::public_transfer(admin_cap, ctx.sender());
}

public fun list_hero(nft: Hero, price: u64, ctx: &mut TxContext) {

    let id = object::new(ctx);
    let list_hero_id = object::uid_to_inner(&id);

    let list_hero = ListHero {
        id,
        nft,
        price,
        seller: ctx.sender(),
    };

    event::emit(HeroListed {
        list_hero_id,
        price,
        seller: ctx.sender(),
        timestamp: ctx.epoch_timestamp_ms(),
    });

    transfer::share_object(list_hero);
}

#[allow(lint(self_transfer))]
public fun buy_hero(list_hero: ListHero, coin: Coin<SUI>, ctx: &mut TxContext) {

    let ListHero { id, nft, price, seller } = list_hero;

    assert!(coin::value(&coin) == price, EInvalidPayment);

    transfer::public_transfer(coin, seller);
    transfer::public_transfer(nft, ctx.sender());

    event::emit(HeroBought {
        list_hero_id: object::uid_to_inner(&id),
        price,
        buyer: ctx.sender(),
        seller,
        timestamp: ctx.epoch_timestamp_ms(),
    });

    object::delete(id);
}

// ========= ADMIN FUNCTIONS (GÜNCELLENDİ) =========

// Parametrelere 'ctx' eklendi ve Event yayını yapıldı
public fun delist(_: &AdminCap, list_hero: ListHero, ctx: &mut TxContext) {

    let ListHero { id, nft, price: _, seller } = list_hero;
    
    // Olay yayınlanıyor
    event::emit(HeroDelisted {
        list_hero_id: object::uid_to_inner(&id),
        seller,
        timestamp: ctx.epoch_timestamp_ms(),
    });

    transfer::public_transfer(nft, seller);
    object::delete(id);
}

// Parametrelere 'ctx' eklendi ve Event yayını yapıldı
public fun change_the_price(_: &AdminCap, list_hero: &mut ListHero, new_price: u64, ctx: &mut TxContext) {
    
    list_hero.price = new_price;

    // Olay yayınlanıyor
    event::emit(PriceChanged {
        list_hero_id: object::uid_to_inner(&list_hero.id),
        new_price,
        timestamp: ctx.epoch_timestamp_ms(),
    });
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