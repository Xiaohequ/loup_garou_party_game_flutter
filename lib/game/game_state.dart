import 'package:json_annotation/json_annotation.dart';

part 'game_state.g.dart';

@JsonEnum()
enum GamePhase {
  lobby,
  rolesDistribution,
  night,
  day,
  vote,
  end,
}

@JsonEnum()
enum Role {
  villager,
  werewolf,
  seer,
  witch,
  hunter,
}

@JsonEnum()
enum NightSubPhase {
  none,
  werewolfTurn,
  seerTurn,
  witchTurn,
  hunterTurn, // Triggered if hunter dies
}

@JsonSerializable(explicitToJson: true)
class GameState {
  final GamePhase phase;
  final NightSubPhase subPhase;
  final List<Player> players;
  final int turnCount;

  // Voting & Actions Maps
  // generic voting map: voterId -> targetId
  // Used for Werewolf votes, Day votes, etc.
  final Map<String, String> votes;

  final bool witchUsedLifePotion;
  final bool witchUsedDeathPotion;
  final String? seerRevealedId; // ID of player revealed to Seer this turn
  final List<String> dyingPlayerIds; // Players marked for death

  const GameState({
    this.phase = GamePhase.lobby,
    this.subPhase = NightSubPhase.none,
    this.players = const [],
    this.turnCount = 0,
    this.votes = const {},
    this.witchUsedLifePotion = false,
    this.witchUsedDeathPotion = false,
    this.seerRevealedId,
    this.dyingPlayerIds = const [],
  });

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
  Map<String, dynamic> toJson() => _$GameStateToJson(this);

  GameState copyWith({
    GamePhase? phase,
    NightSubPhase? subPhase,
    List<Player>? players,
    int? turnCount,
    Map<String, String>? votes,
    bool? witchUsedLifePotion,
    bool? witchUsedDeathPotion,
    String? seerRevealedId,
    List<String>? dyingPlayerIds,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      subPhase: subPhase ?? this.subPhase,
      players: players ?? this.players,
      turnCount: turnCount ?? this.turnCount,
      votes: votes ?? this.votes,
      witchUsedLifePotion: witchUsedLifePotion ?? this.witchUsedLifePotion,
      witchUsedDeathPotion: witchUsedDeathPotion ?? this.witchUsedDeathPotion,
      seerRevealedId: seerRevealedId ?? this.seerRevealedId,
      dyingPlayerIds: dyingPlayerIds ?? this.dyingPlayerIds,
    );
  }
}

@JsonSerializable()
class Player {
  final String id;
  final String name;
  final bool isAlive;
  final Role role;
  final bool isReady;

  const Player({
    required this.id,
    required this.name,
    this.isAlive = true,
    this.role = Role.villager,
    this.isReady = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  Player copyWith({
    String? name,
    bool? isAlive,
    Role? role,
    bool? isReady,
  }) {
    return Player(
      id: this.id,
      name: name ?? this.name,
      isAlive: isAlive ?? this.isAlive,
      role: role ?? this.role,
      isReady: isReady ?? this.isReady,
    );
  }
}
