# Character Classes - PZ Data Map
Source: projectzomboid.jar (decompiled) | Generated: 2026-03-22

## Section Index
| # | Topic | Lines |
|-|-|-|
| 1 | Inheritance Chain | 14-25 |
| 2 | IsoGameCharacter | 26-161 |
| 3 | IsoLivingCharacter | 162-191 |
| 4 | IsoPlayer | 192-273 |
| 5 | IsoZombie | 274-390 |
| 6 | Key Enums | 391-416 |

## 1. Inheritance Chain

```
IsoObject
  -> IsoMovingObject
       -> IsoGameCharacter          (zombie.characters)
            -> IsoLivingCharacter   (zombie.characters)
                 -> IsoPlayer       (zombie.characters)
                 -> IsoSurvivor     (zombie.characters)
            -> IsoZombie            (zombie.characters)
```

## 2. IsoGameCharacter
**Extends:** IsoMovingObject | **Package:** zombie.characters

### Key Fields

| Access | Type | Field | Purpose |
|-|-|-|-|
| [pub] | float | health | Current health 0.0-1.0 |
| [pub] | float | speedMod | Movement speed multiplier (default 1.0) |
| [pub] | boolean | asleep | Whether character is sleeping |
| [pub] | boolean | isResting | Whether character is resting |
| [pub] | boolean | blockTurning | Prevent character rotation |
| [pub] | boolean | doDirtBloodEtc | Enable blood/dirt textures |
| [pub] | boolean | callOut | Character is calling out |
| [pub] | float | knockbackAttackMod | Knockback multiplier (default 1.0) |
| [pub] | int | bumpNbr | Bump counter |
| [pub] | IsoAIModule | ai | AI module reference |
| [pub] | long | vocalEvent | FMOD vocal event handle |
| [prot] | float | health | Health 0.0-1.0 |
| [prot] | boolean | dead | Death flag |
| [prot] | BodyDamage | bodyDamage | Body damage system |
| [prot] | ItemContainer | inventory | Character inventory |
| [prot] | InventoryItem | leftHandItem | Primary hand item |
| [prot] | InventoryItem | rightHandItem | Secondary hand item |
| [prot] | HandWeapon | useHandWeapon | Currently used weapon |
| [prot] | StateMachine | stateMachine | AI state machine |
| [prot] | Moodles | moodles | Moodle system |
| [prot] | Stats | stats | Character stats (hunger, thirst, etc.) |
| [prot] | SurvivorDesc | descriptor | Survivor description/appearance |
| [prot] | WornItems | wornItems | Worn clothing items |
| [prot] | Vector2 | forwardDirection | Facing direction vector |
| [prot] | float | fallTime | Time spent falling |
| [prot] | BaseVehicle | vehicle | Currently occupied vehicle |
| [prot] | XP | xp | Experience points system |
| [prot] | CharacterTraits | characterTraits | Trait collection |
| [priv] | boolean | female | Gender flag |
| [priv] | boolean | running | Is running |
| [priv] | boolean | sprinting | Is sprinting |
| [priv] | boolean | sneaking | Is sneaking |
| [priv] | int | zombieKills | Total zombie kills |
| [priv] | int | survivorKills | Total survivor kills |
| [priv] | int | maxWeight | Carry capacity |
| [priv] | int | maxWeightBase | Base carry capacity (default 8) |
| [priv] | float | meleeDelay | Melee attack cooldown |
| [priv] | float | recoilDelay | Ranged recoil cooldown |
| [priv] | float | aimingDelay | Aiming warmup timer |
| [priv] | float | beenMovingFor | Movement duration timer |

### Key Methods

| Access | Return | Method | Purpose |
|-|-|-|-|
| [pub] | float | getHealth() | Get health 0.0-1.0 |
| [pub] | void | setHealth(float) | Set health value |
| [pub] | boolean | isDead() | Check if dead |
| [pub] | boolean | isAlive() | Check if alive |
| [pub] | boolean | isZombie() | Check if this is a zombie |
| [pub] | boolean | isFemale() | Check gender |
| [pub] | BodyDamage | getBodyDamage() | Get body damage system |
| [pub] | ItemContainer | getInventory() | Get inventory container |
| [pub] | Stats | getStats() | Get character stats |
| [pub] | Moodles | getMoodles() | Get moodle system |
| [pub] | StateMachine | getStateMachine() | Get AI state machine |
| [pub] | SurvivorDesc | getDescriptor() | Get survivor description |
| [pub] | XP | getXp() | Get XP system |
| [pub] | CharacterTraits | getCharacterTraits() | Get traits collection |
| [pub] | InventoryItem | getPrimaryHandItem() | Get left hand item |
| [pub] | void | setPrimaryHandItem(InventoryItem) | Set left hand item |
| [pub] | InventoryItem | getSecondaryHandItem() | Get right hand item |
| [pub] | void | setSecondaryHandItem(InventoryItem) | Set right hand item |
| [pub] | HandWeapon | getUseHandWeapon() | Get weapon in use |
| [pub] | HandWeapon | getAttackingWeapon() | Get current attack weapon |
| [pub] | WornItems | getWornItems() | Get worn clothing |
| [pub] | void | setWornItem(ItemBodyLocation, InventoryItem) | Equip clothing |
| [pub] | void | removeWornItem(InventoryItem) | Remove clothing |
| [pub] | AttachedItems | getAttachedItems() | Get attached items |
| [pub] | Vector2 | getForwardDirection() | Get facing direction |
| [pub] | void | setForwardDirection(Vector2) | Set facing direction |
| [pub] | float | getDirectionAngle() | Get facing angle degrees |
| [pub] | int | getPerkLevel(PerkFactory.Perk) | Get skill level |
| [pub] | void | LevelPerk(PerkFactory.Perk) | Level up a skill |
| [pub] | boolean | hasTrait(CharacterTrait) | Check if has trait |
| [pub] | boolean | hasEquipped(String) | Check equipped item type |
| [pub] | void | DoDeath(HandWeapon, IsoGameCharacter) | Trigger death |
| [pub] | float | Hit(HandWeapon, IsoGameCharacter, float, boolean, float, boolean) | Apply hit damage |
| [pub] | void | hitConsequences(HandWeapon, IsoGameCharacter, boolean, float, boolean) | Apply hit effects |
| [pub] | void | changeState(State) | Change AI state |
| [pub] | State | getCurrentState() | Get current AI state |
| [pub] | boolean | isCurrentState(State) | Check current state |
| [pub] | boolean | isMoving() | Check if moving |
| [pub] | boolean | isPlayerMoving() | Check if player is moving |
| [pub] | boolean | isAttacking() | Check if attacking |
| [pub] | boolean | isDriving() | Check if driving vehicle |
| [pub] | boolean | isSeatedInVehicle() | Check if in vehicle seat |
| [pub] | BaseVehicle | getVehicle() | Get current vehicle |
| [pub] | void | setVehicle(BaseVehicle) | Set vehicle |
| [pub] | void | enterVehicle(BaseVehicle, int, Vector3f) | Enter vehicle at seat |
| [pub] | boolean | isAsleep() | Check if sleeping |
| [pub] | void | setAsleep(boolean) | Set sleeping state |
| [pub] | boolean | isOutside() | Check if outdoors |
| [pub] | boolean | isOnFire() | Check if burning |
| [pub] | void | SetOnFire() | Set character on fire |
| [pub] | void | StopBurning() | Extinguish fire |
| [pub] | boolean | Eat(InventoryItem, float) | Consume food item |
| [pub] | boolean | DrinkFluid(InventoryItem, float) | Drink fluid |
| [pub] | void | autoDrink() | Auto-drink water if thirsty |
| [pub] | boolean | isRecipeKnown(String) | Check if recipe is known |
| [pub] | boolean | learnRecipe(String) | Learn a recipe |
| [pub] | List | getKnownRecipes() | Get known recipe list |
| [pub] | int | getZombieKills() | Get zombie kill count |
| [pub] | int | getSurvivorKills() | Get survivor kill count |
| [pub] | int | getMaxWeight() | Get carry capacity |
| [pub] | void | setMaxWeight(int) | Set carry capacity |
| [pub] | float | getInventoryWeight() | Get current inventory weight |
| [pub] | void | dropHandItems() | Drop held items |
| [pub] | void | Callout() | Shout/callout |
| [pub] | void | Say(String) | Say a line of text |
| [pub] | long | playSound(String) | Play a sound |
| [pub] | void | PlayAnim(String) | Play an animation |
| [pub] | boolean | CanSee(IsoMovingObject) | Line of sight check |
| [pub] | void | pathToCharacter(IsoGameCharacter) | Pathfind to character |
| [pub] | void | pathToLocationF(float, float, float) | Pathfind to position |
| [pub] | float | calculateBaseSpeed() | Calculate base move speed |
| [pub] | float | calculateCombatSpeed() | Calculate combat speed |
| [pub] | void | load(ByteBuffer, int, boolean) | Deserialize from save |
| [pub] | void | save(ByteBuffer, boolean) | Serialize to save |
| [pub] | void | update() | Main update tick |
| [pub] | void | render(float, float, float, ColorInfo, boolean, boolean, Shader) | Render character |
| [pub] | void | removeFromWorld() | Remove from world |
| [pub] | boolean | isGodMod() | Check god mode |
| [pub] | boolean | isInvisible() | Check invisibility |
| [pub] | void | faceLocation(float, float) | Face a world position |
| [pub] | boolean | isClimbing() | Check if climbing |
| [pub] | boolean | isFalling() | Check if falling |
| [pub] | void | exert(float) | Apply exertion to endurance |

## 3. IsoLivingCharacter
**Extends:** IsoGameCharacter | **Package:** zombie.characters

### Fields

| Access | Type | Field | Purpose |
|-|-|-|-|
| [pub] | float | useChargeDelta | Charge attack progress |
| [pub] | HandWeapon | bareHands | Reference to bare hands weapon |
| [pub] | boolean | collidedWithPushable | Collided with pushable object |
| [pub] | IsoGameCharacter | targetOnGround | Downed target for stomp |
| [priv] | boolean | doShove | Wants to shove |

### Methods

| Access | Return | Method | Purpose |
|-|-|-|-|
| [pub] | boolean | AttemptAttack(float) | Attempt attack with charge delta |
| [pub] | boolean | DoAttack(float) | Execute attack |
| [pub] | boolean | isDoShove() | Check shove intent |
| [pub] | void | setDoShove(boolean) | Set shove intent |
| [pub] | boolean | isShoving() | Check if shoving (not stomping) |
| [pub] | boolean | isDoStomp() | Check if stomping (shove + aim floor) |
| [pub] | HandWeapon | getAttackingWeapon() | Get weapon (bareHands if shove) |
| [pub] | void | clearHandToHandAttack() | Reset shove/grapple state |
| [pub] | boolean | isDoHandToHandAttack() | Check shove or grapple |
| [pub] | boolean | isShovingWhileAiming() | Check shove while aiming |
| [pub] | boolean | isGrapplingWhileAiming() | Check grapple while aiming |
| [pub] | boolean | isCollidedWithPushableThisFrame() | Check pushable collision |

## 4. IsoPlayer
**Extends:** IsoLivingCharacter | **Package:** zombie.characters

### Key Fields

| Access | Type | Field | Purpose |
|-|-|-|-|
| [pub/static] | IsoPlayer[] | players | All player instances (max 4) |
| [pub/static] | int | numPlayers | Active player count |
| [pub] | int | playerIndex | Local player index 0-3 |
| [pub] | int | serverPlayerIndex | Server-side player index |
| [pub] | String | username | Player display name |
| [pub] | String | saveFileName | Save file name |
| [pub] | float | closestZombie | Distance to nearest zombie |
| [pub] | boolean | targetedByZombie | Being targeted |
| [pub] | float | contextPanic | Context-based panic value |
| [pub] | float | currentSpeed | Current movement speed |
| [pub] | boolean | deathFinished | Death sequence complete |
| [pub] | boolean | remote | Is remote (MP) player |
| [pub] | Role | role | Server role |
| [pub] | short | onlineId | Network player ID |
| [pub] | int | joypadBind | Controller binding |
| [pub] | float | maxWeightDelta | Weight capacity modifier |
| [pub] | float | chargeTime | Charge attack timer |
| [pub] | boolean | isCharging | Is charge attacking |
| [pub] | boolean | bannedAttacking | Attack banned (MP) |
| [prot] | float | timeSinceLastStab | Stab cooldown timer |
| [prot] | float | asleepTime | Time spent sleeping |
| [prot] | Stack | spottedList | Spotted entity list |
| [priv] | boolean | allowSprint | Sprint allowed |
| [priv] | boolean | allowRun | Run allowed |
| [priv] | AttackType | attackType | Current attack type |

### Key Methods

| Access | Return | Method | Purpose |
|-|-|-|-|
| [pub/static] | IsoPlayer | getInstance() | Get local player instance |
| [pub/static] | void | setInstance(IsoPlayer) | Set local player instance |
| [pub/static] | IsoPlayer | getPlayer(int) | Get player by index |
| [pub/static] | boolean | allPlayersDead() | Check if all players dead |
| [pub/static] | boolean | allPlayersAsleep() | Check if all players sleeping |
| [pub] | int | getIndex() | Get player index |
| [pub] | boolean | isLocalPlayer() | Check if local (not remote) |
| [pub] | Nutrition | getNutrition() | Get nutrition system |
| [pub] | Fitness | getFitness() | Get fitness/exercise system |
| [pub] | boolean | isAiming() | Check if aiming weapon |
| [pub] | boolean | isAttacking() | Check if attacking |
| [pub] | boolean | pressedAttack() | Handle attack input |
| [pub] | int | calculateCritChance(IsoGameCharacter) | Calc crit chance vs target |
| [pub] | float | getMoveSpeed() | Get current movement speed |
| [pub] | float | getAimingMod() | Get aiming skill modifier |
| [pub] | float | getReloadingMod() | Get reloading modifier |
| [pub] | float | getAimingRangeMod() | Get aiming range modifier |
| [pub] | float | getTorchStrength() | Get flashlight strength |
| [pub] | float | getGlobalMovementMod(boolean) | Get movement noise modifier |
| [pub] | boolean | isPathfindRunning() | Check if pathfinding |
| [pub] | BaseVehicle | getUseableVehicle() | Get nearby useable vehicle |
| [pub] | BaseVehicle | getNearVehicle() | Get nearest vehicle |
| [pub] | boolean | hopFence(IsoDirections, boolean) | Climb fence |
| [pub] | boolean | canClimbOverWall(IsoDirections) | Check wall climbability |
| [pub] | boolean | doContext() | Execute context action |
| [pub] | String | getTimeSurvived() | Get survival time string |
| [pub] | boolean | isOutside() | Check if outdoors |
| [pub] | boolean | pressedMovement(boolean) | Check movement input |
| [pub] | boolean | pressedAim() | Check aim input |
| [pub] | void | OnDeath() | Death handler |
| [pub] | long | getSteamID() | Get Steam ID |
| [pub] | String | getUsername() | Get display username |
| [pub] | short | getOnlineID() | Get network ID |
| [pub] | boolean | isGhostMode() | Check ghost/noclip |
| [pub] | void | setGhostMode(boolean) | Set ghost mode |
| [pub] | boolean | isNoClip() | Check noclip |
| [pub] | void | setNoClip(boolean) | Set noclip |
| [pub] | void | updateLOS() | Update line of sight |
| [pub] | float | getPlayerClothingTemperature() | Get clothing warmth |
| [pub] | float | getPlayerClothingInsulation() | Get clothing insulation |
| [pub] | void | save(String) | Save player to file |
| [pub] | void | load(String) | Load player from file |
| [pub] | void | updateMovementRates() | Update walk/run/sprint speeds |
| [pub] | void | setVehicleHitLocation(BaseVehicle) | Set vehicle impact location |

## 5. IsoZombie
**Extends:** IsoGameCharacter | **Package:** zombie.characters

### Key Fields

| Access | Type | Field | Purpose |
|-|-|-|-|
| [pub] | IsoMovingObject | target | Current target |
| [pub] | float | timeSinceSeenFlesh | Time since last saw target |
| [pub] | int | zombieId | Unique zombie ID |
| [pub] | boolean | ghost | Ghost mode (invisible) |
| [pub] | float | lungeTimer | Lunge attack timer |
| [pub] | boolean | staggerBack | Stagger state |
| [pub] | boolean | alerted | Alert state |
| [pub] | boolean | indoorZombie | Spawned indoors |
| [pub] | int | thumpFlag | Thump sound type |
| [pub] | int | speedType | Speed type (-1 = unset) |
| [pub] | int | strength | Strength level |
| [pub] | int | cognition | Cognition level |
| [pub] | int | memory | Memory level |
| [pub] | int | sight | Sight level |
| [pub] | int | hearing | Hearing level |
| [pub] | ZombieGroup | group | Zombie group |
| [pub] | boolean | inactive | Inactive (dormant) |
| [pub] | float | soundAttract | Sound attraction value |
| [pub] | IsoDeadBody | bodyToEat | Body being eaten |
| [pub] | IsoMovingObject | eatBodyTarget | Eat target |
| [pub] | int | lastPlayerHit | Last player that hit this zombie |
| [pub/static] | float | EAT_BODY_DIST | Eat body distance (1.0) |
| [pub/static] | float | EAT_BODY_TIME | Eat body duration (3600) |
| [pub/static] | float | LUNGE_TIME | Lunge duration (180) |
| [pub/static] | float | CRAWLER_DAMAGE_DOT | Crawler dot product for damage (0.9) |
| [pub/static] | float | CRAWLER_DAMAGE_RANGE | Crawler damage range (1.5) |
| [priv] | boolean | fakeDead | Playing dead |
| [priv] | boolean | becomeCrawler | Will become crawler |
| [priv] | boolean | reanimate | Will reanimate |
| [priv] | boolean | knifeDeath | Killed by knife |
| [priv] | float | eatSpeed | Eating speed multiplier |
| [priv] | int | crawlerType | Crawler variant type |

### Speed Constants

| Access | Type | Field | Value |
|-|-|-|-|
| [pub/static] | byte | SPEED_SPRINTER | 1 |
| [pub/static] | byte | SPEED_FAST_SHAMBLER | 2 |
| [pub/static] | byte | SPEED_SHAMBLER | 3 |
| [pub/static] | byte | SPEED_RANDOM | 4 |

### Hearing Constants

| Access | Type | Field | Value |
|-|-|-|-|
| [pub/static] | byte | HEARING_PINPOINT | 1 |
| [pub/static] | byte | HEARING_NORMAL | 2 |
| [pub/static] | byte | HEARING_POOR | 3 |
| [pub/static] | byte | HEARING_RANDOM | 4 |
| [pub/static] | byte | HEARING_NORMAL_OR_POOR | 5 |

### Thump Flag Constants

| Access | Type | Field | Value |
|-|-|-|-|
| [pub/static] | byte | THUMP_FLAG_GENERIC | 1 |
| [pub/static] | byte | THUMP_FLAG_WINDOW_EXTRA | 2 |
| [pub/static] | byte | THUMP_FLAG_WINDOW | 3 |
| [pub/static] | byte | THUMP_FLAG_METAL | 4 |
| [pub/static] | byte | THUMP_FLAG_GARAGE_DOOR | 5 |
| [pub/static] | byte | THUMP_FLAG_CHAINLINK_FENCE | 6 |
| [pub/static] | byte | THUMP_FLAG_METAL_POLE_GATE | 7 |
| [pub/static] | byte | THUMP_FLAG_WOOD | 8 |

### Key Methods

| Access | Return | Method | Purpose |
|-|-|-|-|
| [pub] | void | initializeStates() | Init AI state machine |
| [pub] | void | pathToCharacter(IsoGameCharacter) | Pathfind to target |
| [pub] | void | pathToLocationF(float, float, float) | Pathfind to position |
| [pub] | float | Hit(HandWeapon, IsoGameCharacter, float, boolean, float, boolean) | Take hit damage |
| [pub] | void | hitConsequences(HandWeapon, IsoGameCharacter, boolean, float, boolean) | Apply hit effects |
| [pub] | void | spotted(IsoMovingObject, boolean) | Spot a target |
| [pub] | void | spottedNew(IsoMovingObject, boolean) | First spot of target |
| [pub] | void | Move(Vector2) | Move in direction |
| [pub] | void | RespondToSound() | React to heard sound |
| [pub] | boolean | tryThump(IsoGridSquare) | Attempt to thump object |
| [pub] | void | Wander() | Wander randomly |
| [pub] | void | DoZombieStats() | Update zombie stats |
| [pub] | void | DoZombieSpeeds(float) | Set zombie speeds |
| [pub] | boolean | isCrawling() | Check if crawler |
| [pub] | void | setCrawler(boolean) | Set crawler state |
| [pub] | boolean | isFakeDead() | Check if playing dead |
| [pub] | void | setFakeDead(boolean) | Set playing dead |
| [pub] | boolean | isReanimate() | Check reanimate flag |
| [pub] | void | setReanimate(boolean) | Set reanimate |
| [pub] | boolean | isUseless() | Check if useless zombie |
| [pub] | void | knockDown(boolean) | Knock zombie down |
| [pub] | boolean | shouldGetUpFromCrawl() | Check if should stand up |
| [pub] | void | toggleCrawling() | Toggle crawl state |
| [pub] | float | onHitByVehicle(BaseVehicle, float, Vector2, Vector2, boolean) | Handle vehicle impact |
| [pub] | void | addBloodFromVehicleImpact(float) | Blood from vehicle hit |
| [pub] | void | removeFromWorld() | Remove zombie from world |
| [pub] | void | resetForReuse() | Reset for object pooling |
| [pub] | void | DoZombieInventory() | Generate zombie inventory |
| [pub] | void | DoCorpseInventory() | Generate corpse loot |
| [pub] | HumanVisual | getHumanVisual() | Get visual appearance |
| [pub] | void | dressInRandomOutfit() | Randomize outfit |
| [pub] | void | dressInNamedOutfit(String) | Apply named outfit |
| [pub] | boolean | isSkeleton() | Check if skeleton zombie |
| [pub] | boolean | isZombie() | Always returns true |
| [pub] | void | setEatBodyTarget(IsoMovingObject, boolean, float) | Set body to eat |
| [pub] | void | addItemToSpawnAtDeath(InventoryItem) | Add loot drop |
| [pub] | void | clearAggroList() | Clear aggro targets |
| [pub] | void | addAggro(IsoMovingObject, float) | Add aggro entry |
| [pub] | boolean | isLeadAggro(IsoMovingObject) | Check if top aggro |
| [pub] | boolean | isTargetInCone(float, float) | Check target in vision cone |

## 6. Key Enums

### PerkFactory.Perks (zombie.characters.skills)
Skills/perks used with getPerkLevel() and LevelPerk():
- Fitness, Strength
- Sprinting, Lightfoot, Nimble, Sneaking
- Axe, Blunt, SmallBlunt, LongBlade, ShortBlade, Spear
- Maintenance, Woodwork, Cooking, Farming, Doctor, Electricity
- Metalworking, Mechanics, Tailoring, Aiming, Reloading
- Fishing, Trapping, PlantScavenging, Foraging

### CharacterTrait (zombie.scripting.objects)
Common traits referenced in code:
- EMACIATED, VERY_UNDERWEIGHT, UNDERWEIGHT, OVERWEIGHT, OBESE
- WEIGHT_GAIN, WEIGHT_LOSS
- SMOKER, BRAVE, COWARDLY, DESENSITIZED
- STRONG, STOUT, WEAK, FEEBLE

### Side (zombie.characters)
- LEFT, RIGHT

### FallSeverity (zombie.characters)
- NONE, LOW, MEDIUM, HIGH, DEATH

### Stance (zombie.characters)
- Standing, Crouching, Prone
