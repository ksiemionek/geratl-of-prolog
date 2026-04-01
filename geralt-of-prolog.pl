/* Geralt of Prolog - The Griffin Hunt, by Kacper Siemionek */

:- dynamic i_am_at/1, at/2, holding/1, money/1, timer/1, bait_placed/0, oil_applied/0, knows_oil/0, endriagas_alive/0, knows/1, boulders_open/0.

:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(holding(_)), retractall(money(_)), retractall(timer(_)), retractall(knows_oil), retractall(endriagas_alive), retractall(knows(_)), retractall(boulders_open).

/* initialization */
knows(thunderbolt_formula).
knows(bestiary).
i_am_at(tavern).
money(200).
timer(60).
endriagas_alive.

/* locations and paths */
path(tavern, n, town).
path(town, s, tavern).
path(town, n, blacksmith).
path(blacksmith, s, town).
path(town, e, merchant).
path(merchant, w, town).
path(town, w, cave_entrance).
path(cave_entrance, e, town).
path(cave_entrance, n, cave) :-
    boulders_open, !.
path(cave_entrance, n, cave) :-
    write('Big rocks block the way north. You need to move them somehow.'), nl, fail.
path(cave, s, cave_entrance).
path(tavern, w, herbalist_hut).
path(herbalist_hut, e, tavern).
path(herbalist_hut, n, hill).
path(hill, s, herbalist_hut).
path(tavern, s, river).
path(river, n, tavern).
path(tavern, e, cliff).
path(cliff, w, tavern).
path(cliff, n, nest).
path(nest, s, cliff).

/* inventory actions */
holding_count(Item, Count) :-
    aggregate_all(count, holding(Item), Count).

take(X) :-
    i_am_at(Place),
    at(X, Place), !,
    retract(at(X, Place)),
    assert(holding(X)),
    write('You pick up the '), write(X), write('.'), nl,
    tick.
take(_) :-
    write('There is nothing like that here.'), nl.

buy(Item) :-
    (i_am_at(blacksmith) ; i_am_at(merchant)),
    item_price(Item, Price),
    money(M), M >= Price, !,
    NM is M - Price,
    retract(money(M)), assert(money(NM)),
    assert(holding(Item)),
    write('You buy the '), write(Item), write(' for '), write(Price), write(' crowns.'), nl,
    tick.
buy(_) :-
    write('You cannot buy that here, or you do not have enough crowns.'), nl.

/* prices */
item_price(silver_sword, Price) :-
    timer(T),
    Price is 100 + (60 - T).

item_price(steel_sword, Price) :-
    timer(T),
    Price is 40 + (60 - T).

item_price(bolts, 30).
item_price(dwarven_spirit, 25).
item_price(cortinarius, 10).
item_price(dog_tallow, 10).

/* examine */
examine :-
    i_am_at(Loc),
    examine(Loc).

examine(nest) :-
    i_am_at(nest),
    \+ holding(griffin_feather), !,
    write('You look around the nest carefully.'), nl,
    write('You find a large feather and pick it up. It must be from the griffin.'), nl,
    nl,
    write('You check your bestiary for the Royal Griffin entry:'), nl,
    write('  "A large hybrid creature. Tough hide - ordinary weapons struggle to wound it.'), nl,
    write('   Wounded griffins are known to flee. Buckthorn can be used as bait.'), nl,
    write('   Hybrid oil increases damage against hybrid beasts."'), nl,
    nl,
    write('You pocket the griffin_feather as proof for the contract.'), nl,
    assert(holding(griffin_feather)),
    tick.
examine(nest) :-
    i_am_at(nest), !,
    write('You already searched the nest.'), nl.

examine(hill) :-
    i_am_at(hill), !,
    write('You search through the grass and flowers on the hillside.'), nl,
    write('You find clusters of white myrtle growing here. You gather four portions.'), nl,
    assert(holding(white_myrtle)), assert(holding(white_myrtle)),
    assert(holding(white_myrtle)), assert(holding(white_myrtle)),
    tick.

examine(river) :-
    i_am_at(river),
    \+ holding(buckthorn), !,
    write('You search along the muddy riverbank.'), nl,
    write('You pull a plant out of the water - buckthorn. It smells strong.'), nl,
    write('It might be useful as bait.'), nl,
    assert(holding(buckthorn)),
    tick.
examine(river) :-
    i_am_at(river), !,
    write('You already took what you needed from the river.'), nl.

examine(_) :-
    write('You look around but find nothing useful here.'), nl.

/* witcher signs */
witcher_sign(aard, 'Aard - A telekinetic blast that knocks down obstacles.').
witcher_sign(igni, 'Igni - A burst of fire that ignites enemies.').
witcher_sign(quen, 'Quen - A magical shield protecting against blows.').
witcher_sign(yrden, 'Yrden - A magical trap that slows movements.').
witcher_sign(axii, 'Axii - A mind-control sign.').

list_signs :-
    write('Available Witcher Signs:'), nl,
    witcher_sign(_, Desc),
    write('  '), write(Desc), nl,
    fail.
list_signs.

/* open boulders */
open(boulders, aard) :-
    i_am_at(cave_entrance),
    \+ boulders_open, !,
    write('You raise your hand and cast the Aard sign.'), nl,
    write('The rocks crack and fly apart. The cave entrance is open.'), nl,
    assert(boulders_open),
    tick.

open(boulders, _) :-
    i_am_at(cave_entrance),
    boulders_open, !,
    write('The path is already clear.'), nl.

open(boulders, Sign) :-
    i_am_at(cave_entrance),
    \+ boulders_open,
    witcher_sign(Sign, _), !,
    write('You cast '), write(Sign), write(', but it has no effect on the heavy boulders.'), nl,
    write('You wasted time trying the wrong sign!'), nl,
    nl,
    list_signs,
    tick.

open(boulders, _) :-
    i_am_at(cave_entrance),
    \+ boulders_open, !,
    write('You need to use a Witcher sign to clear the path. But which one?'), nl,
    nl,
    list_signs.

open(_, _) :-
    write('Nothing happens.'), nl.

/* cave actions */
kill_endriagas :-
    i_am_at(cave),
    endriagas_alive,
    (holding(silver_sword) ; holding(steel_sword)), !,
    write('The endriagas attack from the shadows. You fight them off one by one.'), nl,
    write('When the last one falls, you search the bodies.'), nl,
    write('You cut out a fresh embryo. It will be useful for alchemy.'), nl,
    retract(endriagas_alive),
    assert(holding(embryo)),
    tick.
kill_endriagas :-
    i_am_at(cave),
    endriagas_alive, !,
    write('The endriagas attack from the shadows, but you have no sword!'), nl,
    write('You barely manage to escape the cave with your life. Come back armed.'), nl,
    tick.
kill_endriagas :-
    i_am_at(cave), !,
    write('The endriagas are already dead.'), nl.
kill_endriagas :-
    write('There are no endriagas here.'), nl.

/* dialogues */
ask(client) :-
    i_am_at(tavern), !,
    write('The alderman looks tired and scared.'), nl,
    write('"Three nights in a row it has attacked us. Sheep, dogs, two farmhands."'), nl,
    write('"Its nest is on the cliff east of here. Kill it before it attacks again."'), nl,
    write('"I gave you 200 crowns upfront. The rest when you bring proof of the kill."'), nl,
    tick.
ask(client) :-
    write('Your client is not here.'), nl.

ask(herbalist) :-
    i_am_at(herbalist_hut), !,
    write('The old woman looks up from her work.'), nl,
    write('"Hybrid oil? For that you need one dog tallow and four white myrtle petals."'), nl,
    write('"You can brew it at my table if you have everything."'), nl,
    assert(knows_oil),
    tick.
ask(herbalist) :-
    write('There is no herbalist here.'), nl.

ask(_) :-
    write('There is nobody by that name here.'), nl.

/* alchemy */
craft(hybrid_oil) :-
    i_am_at(herbalist_hut),
    knows_oil,
    holding(dog_tallow),
    holding_count(white_myrtle, C), C >= 4, !,
    retract(holding(dog_tallow)),
    retract(holding(white_myrtle)), retract(holding(white_myrtle)),
    retract(holding(white_myrtle)), retract(holding(white_myrtle)),
    assert(holding(hybrid_oil)),
    write('You mix the ingredients at the table. The hybrid oil is ready.'), nl,
    tick.
craft(hybrid_oil) :-
    i_am_at(herbalist_hut), !,
    write('You need: the recipe (ask herbalist), 1x dog_tallow, 4x white_myrtle.'), nl.

craft(thunderbolt) :-
    i_am_at(herbalist_hut),
    holding(dwarven_spirit),
    holding(embryo),
    holding_count(cortinarius, C), C >= 2, !,
    retract(holding(dwarven_spirit)),
    retract(holding(embryo)),
    retract(holding(cortinarius)), retract(holding(cortinarius)),
    assert(holding(thunderbolt)),
    write('You follow Vesemir''s formula. The liquid turns deep blue. Thunderbolt is ready.'), nl,
    tick.
craft(thunderbolt) :-
    i_am_at(herbalist_hut), !,
    write('You need: 1x dwarven_spirit, 1x embryo, 2x cortinarius.'), nl.

craft(_) :-
    write('You cannot craft that here, or you are missing ingredients.'), nl.

/* fight preparation */
apply_oil :-
    holding(hybrid_oil),
    holding(silver_sword), !,
    assert(oil_applied),
    write('You coat the silver blade with the hybrid oil. It should hit harder now.'), nl.
apply_oil :-
    holding(hybrid_oil),
    holding(steel_sword), !,
    assert(oil_applied),
    write('You coat the steel blade with the hybrid oil.'), nl.
apply_oil :-
    write('You need hybrid_oil and a sword to do this.'), nl.

place_bait :-
    i_am_at(nest),
    holding(buckthorn), !,
    retract(holding(buckthorn)),
    assert(bait_placed),
    write('You place the buckthorn in the center of the nest.'), nl,
    write('The strong smell drifts out on the wind. Now you wait.'), nl.
place_bait :-
    i_am_at(nest), !,
    write('You have no bait. Find something with a strong smell to lure the griffin.'), nl.
place_bait :-
    write('You should be at the nest to place bait.'), nl.

/* fight */

/* Victory: silver sword + bolts + thunderbolt + oil */
fight :-
    i_am_at(nest), bait_placed,
    holding(silver_sword), holding(bolts),
    holding(thunderbolt), oil_applied, !,
    nl,
    write('The griffin dives out of the sky at full speed.'), nl,
    write('You drink the Thunderbolt. Everything slows down.'), nl,
    write('You dodge and swing - the silver blade cuts deep through its hide.'), nl,
    write('The griffin screams and tries to fly away.'), nl,
    write('You grab the crossbow and fire. The bolt takes it in the wing.'), nl,
    write('It crashes to the ground. One final blow finishes it.'), nl,
    nl,
    write('You take the griffin''s head as proof of the kill.'), nl,
    write('Return to the tavern to collect your reward. (end_game)'), nl,
    assert(holding(griffin_trophy)).

/* Defeat: no bolts - griffin flees */
fight :-
    i_am_at(nest), bait_placed,
    holding(silver_sword), \+ holding(bolts), !,
    nl,
    write('The griffin dives. You drink Thunderbolt and slash with the silver sword.'), nl,
    write('The cut is deep, but not deep enough.'), nl,
    write('The griffin screams, spreads its wings, and climbs into the sky.'), nl,
    write('You watch it disappear over the mountains.'), nl,
    write('Without a way to stop it from fleeing, the contract is failed.'), nl,
    finish.

/* Defeat: steel sword, no real damage */
fight :-
    i_am_at(nest), bait_placed,
    holding(steel_sword), \+ holding(silver_sword), !,
    nl,
    write('The griffin dives and you swing your steel sword with everything you have.'), nl,
    write('The blade bounces off its hide. Barely a scratch.'), nl,
    write('The griffin does not even flinch. It hits you like a wall.'), nl,
    write('You should have brought the right weapon for this.'), nl,
    die.

/* Defeat: no sword */
fight :-
    i_am_at(nest), bait_placed,
    \+ holding(silver_sword), \+ holding(steel_sword), !,
    nl,
    write('The griffin dives and you have nothing to fight it with.'), nl,
    write('This was a very bad idea.'), nl,
    die.

/* No bait yet */
fight :-
    i_am_at(nest), !,
    write('The nest is empty. You need to place bait first.'), nl.

fight :-
    write('You are not at the griffin''s nest.'), nl.

/* end game */
end_game :-
    i_am_at(tavern),
    holding(griffin_trophy), !,
    nl,
    write('You drop the griffin''s head on the table in front of the alderman.'), nl,
    write('He stares at it for a long moment, then starts counting out coins.'), nl,
    write('"It is done," you say. He nods and slides the rest of the reward across.'), nl,
    write('The village is safe. Contract closed.'), nl,
    finish.
end_game :-
    i_am_at(tavern), !,
    write('You have nothing to show the client yet.'), nl.
end_game :-
    write('You need to return to the tavern to collect your reward.'), nl.

/* time and movement */
tick :-
    timer(T), T > 0, !,
    NT is T - 1,
    retract(timer(T)), assert(timer(NT)),
    (NT =:= 0 ->
        (nl,
         write('You hear screaming from the direction of the village.'), nl,
         write('The griffin got tired of waiting and attacked on its own.'), nl,
         write('You were too slow. The contract is over.'), nl,
         die)
    ; true).
tick.

n :- go(n).
s :- go(s).
e :- go(e).
w :- go(w).

go(Direction) :-
    i_am_at(Here),
    path(Here, Direction, There), !,
    retract(i_am_at(Here)),
    assert(i_am_at(There)),
    tick, look.
go(_) :-
    write('You cannot go that way.'), nl.

/* look and inventory */
look :-
    i_am_at(Loc),
    nl, write('[ '), write(Loc), write(' ]'), nl,
    write('--------------------------------------------------'), nl,
    describe(Loc), nl,
    timer(T), write('Time remaining: '), write(T), write(' turns'), nl,
    money(M), write('Crowns: '), write(M), nl,
    inventory.

inventory :-
    findall(X, holding(X), L),
    write('Inventory: '), write(L), nl.

/* location descriptions */
describe(tavern) :-
    write('The White Orchard tavern. It smells of smoke and cheap ale.'), nl,
    write('The innkeeper pretends to clean glasses. In the corner sits the alderman'), nl,
    write('who hired you - the one who posted the griffin contract.'), nl,
    nl,
    write('Exits: North (n) Town | South (s) River | West (w) Herbalist | East (e) Cliff'), nl.

describe(town) :-
    write('The town square. Not much to it - a fountain, a few stalls.'), nl,
    write('You can hear the blacksmith working to the north.'), nl,
    nl,
    write('Exits: North (n) Blacksmith | East (e) Merchant | South (s) Tavern | West (w) Cave entrance'), nl.

describe(blacksmith) :-
    write('The blacksmith''s workshop. Hot and smoky.'), nl,
    write('Swords and crossbow bolts hang on the walls.'), nl,
    write('He tells you that sword prices are rising with every passing hour because of the monster roaming nearby.'), nl,
    nl,
    write('For sale: buy(silver_sword) 100cr + 1cr/move | buy(steel_sword) 40cr + 1cr/move | buy(bolts) 30cr'), nl,
    write('Exits: South (s) Town'), nl.

describe(merchant) :-
    write('A small shop packed with jars, bottles and dried herbs.'), nl,
    write('The merchant sells all kinds of strange ingredients.'), nl,
    nl,
    write('For sale: buy(dwarven_spirit) 25cr | buy(cortinarius) 10cr each | buy(dog_tallow) 10cr'), nl,
    write('Exits: West (w) Town'), nl.

describe(cave_entrance) :-
    (boulders_open ->
        (write('The rocks you blasted with Aard are scattered around the entrance.'), nl,
         write('A cold, unpleasant smell comes from inside.'), nl,
         write('Exits: North (n) Cave | East (e) Town'), nl)
    ;
        (write('A cave entrance blocked by a pile of large boulders.'), nl,
         write('There is no way through without moving them somehow.'), nl,
         write('Exits: East (e) Town'), nl)
    ).

describe(cave) :-
    (endriagas_alive ->
        (write('Dark inside. You hear clicking sounds from the ceiling.'), nl,
         write('Something is up there, watching you.'), nl,
         write('Exits: South (s) Cave entrance'), nl)
    ;
        (write('The cave is quiet now. Endriaga bodies are scattered on the floor.'), nl,
         write('The embryo is safely in your bag.'), nl,
         write('Exits: South (s) Cave entrance'), nl)
    ).

describe(herbalist_hut) :-
    write('A small hut stuffed with dried herbs and glass jars.'), nl,
    write('An alchemical table sits at the back. An old woman works near the window.'), nl,
    nl,
    write('Commands: ask(herbalist). | craft(hybrid_oil). | craft(thunderbolt).'), nl,
    write('Exits: East (e) Tavern | North (n) Hill'), nl.

describe(hill) :-
    write('A grassy hill above the village. Wildflowers grow on the slopes.'), nl,
    write('You can see the cliff with the griffin nest from up here.'), nl,
    nl,
    write('Use examine. to search for plants.'), nl,
    write('Exits: South (s) Herbalist'), nl.

describe(river) :-
    write('A muddy riverbank. The water is slow and dark.'), nl,
    write('Plants grow thick along the edge.'), nl,
    nl,
    write('Use examine. to search the bank.'), nl,
    write('Exits: North (n) Tavern'), nl.

describe(cliff) :-
    write('A tall cliff above the forest. The wind is strong up here.'), nl,
    write('You can see the griffin''s nest at the top.'), nl,
    nl,
    write('Exits: North (n) Griffin nest | West (w) Tavern'), nl.

describe(nest) :-
    write('The griffin''s nest. Bones and feathers cover the ground.'), nl,
    (bait_placed ->
        (write('The buckthorn bait is sitting in the middle of the nest.'), nl,
         write('The griffin should smell it soon. (fight. when ready)'), nl)
    ;
        (write('Use examine. to look for clues. Place bait when you are ready to fight.'), nl)
    ),
    write('Exits: South (s) Cliff'), nl.

/* die/finish */
die :-
    nl,
    write('=========================================='), nl,
    write('           YOUR STORY ENDS HERE          '), nl,
    write('=========================================='), nl,
    write('Enter "halt." to quit.'), nl.

finish :-
    nl,
    write('=========================================='), nl,
    write('              CONTRACT CLOSED             '), nl,
    write('=========================================='), nl,
    write('Enter "halt." to quit.'), nl.

/* instructions and start */
instructions :-
    nl,
    write('=============================================='), nl,
    write('   THE GRIFFIN CONTRACT - A Text Adventure   '), nl,
    write('=============================================='), nl,
    nl,
    write('MOVEMENT:  n.  s.  e.  w.'), nl,
    write('LOOK:      look.'), nl,
    write('EXAMINE:   examine.'), nl,
    write('TALK:      ask(client). ask(herbalist).'), nl,
    write('BUY:       buy(silver_sword). buy(steel_sword).'), nl,
    write('           buy(bolts). buy(dwarven_spirit). buy(cortinarius). buy(dog_tallow).'), nl,
    write('OPEN:      open(boulders, sign).'), nl,
    write('FIGHT:     kill_endriagas. fight.'), nl,
    write('ALCHEMY:   craft(hybrid_oil). craft(thunderbolt).'), nl,
    write('PREPARE:   apply_oil. place_bait.'), nl,
    write('FINISH:    end_game.'), nl,
    write('QUIT:      halt.'), nl,
    nl.

start :-
    instructions,
    nl,
    write('You are a witcher. You just took a contract to kill a Royal Griffin'), nl,
    write('that has been attacking the village of White Orchard.'), nl,
    nl,
    write('You have 200 crowns upfront and 60 turns before the beast attacks again.'), nl,
    write('Vesemir taught you the Thunderbolt formula before you parted ways.'), nl,
    write('You carry your witcher medallion and your bestiary.'), nl,
    nl,
    write('Figure out what you need and get it done.'), nl,
    nl,
    look.