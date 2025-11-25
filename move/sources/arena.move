module challenge::arena;

use challenge::hero::{Self, Hero};
use sui::event;
use sui::object::{Self, UID, ID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};

// ========= STRUCTS =========

public struct Arena has key, store {
    id: UID,
    warrior: Hero,
    owner: address,
}

// ========= EVENTS =========

public struct ArenaCreated has copy, drop {
    arena_id: ID,
    timestamp: u64,
}

public struct ArenaCompleted has copy, drop {
    winner_hero_id: ID,
    loser_hero_id: ID,
    timestamp: u64,
}

// ========= FUNCTIONS =========

public fun create_arena(hero: Hero, ctx: &mut TxContext) {

    let id = object::new(ctx);
    let arena_id = object::uid_to_inner(&id);

    // Arena objesi oluşturuluyor
    let arena = Arena {
        id,
        warrior: hero,
        owner: ctx.sender(),
    };

    // Event yayınlanıyor
    event::emit(ArenaCreated {
        arena_id,
        timestamp: ctx.epoch_timestamp_ms(),
    });

    // Herkese açık (Shared Object) yapılıyor
    transfer::share_object(arena);
}

#[allow(lint(self_transfer))]
public fun battle(hero: Hero, arena: Arena, ctx: &mut TxContext) {
    
    // Arena parçalanıyor (Destructure)
    let Arena { id, warrior, owner } = arena;

    let hero_power = hero::hero_power(&hero);
    let warrior_power = hero::hero_power(&warrior);

    // Savaş mantığı
    if (hero_power >= warrior_power) {
        // Meydan okuyan (hero) kazanırsa: İkisini de alır
        event::emit(ArenaCompleted {
            winner_hero_id: object::id(&hero),
            loser_hero_id: object::id(&warrior),
            timestamp: ctx.epoch_timestamp_ms(),
        });
        
        transfer::public_transfer(hero, ctx.sender());
        transfer::public_transfer(warrior, ctx.sender());
    } else {
        // Savunan (warrior) kazanırsa: İkisi de arena sahibine gider
        event::emit(ArenaCompleted {
            winner_hero_id: object::id(&warrior),
            loser_hero_id: object::id(&hero),
            timestamp: ctx.epoch_timestamp_ms(),
        });

        transfer::public_transfer(hero, owner);
        transfer::public_transfer(warrior, owner);
    };

    // Arena objesi siliniyor (savaş bitti)
    object::delete(id);
}