import 'package:json_annotation/json_annotation.dart';

part 'game_state.g.dart';

@JsonEnum()
enum GamePhase {
  lobby,
  rolesDistribution,
  night,
  day,
  vote,
  voteResult,
  defenseSpeech,
  hunterRevenge,
  end,
}

@JsonEnum()
enum GameWinner {
  none,
  villagers,
  werewolves,
  draw, // If everyone dies
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
  final GameWinner winner; // Added winner
  final List<Player> players;
  final int turnCount;
  final bool isTransitioning;
  final List<String> transitioningPlayerIds;
  final int countdown;

  // ... other fields ...
  final Map<String, String> votes;
  final bool witchUsedLifePotion;
  final bool witchUsedDeathPotion;
  final String? seerRevealedId;
  final String? accusedPlayerId;
  final String? werewolfHuntTargetId;
  final List<String> dyingPlayerIds;
  final List<String> lastNightDeadIds;
  final int voteRound;
  final List<String>? voteCandidates;

  const GameState({
    this.phase = GamePhase.lobby,
    this.subPhase = NightSubPhase.none,
    this.winner = GameWinner.none,
    this.players = const [],
    this.turnCount = 0,
    this.isTransitioning = false,
    this.transitioningPlayerIds = const [],
    this.countdown = 0,
    this.votes = const {},
    this.witchUsedLifePotion = false,
    this.witchUsedDeathPotion = false,
    this.seerRevealedId,
    this.accusedPlayerId,
    this.werewolfHuntTargetId,
    this.dyingPlayerIds = const [],
    this.lastNightDeadIds = const [],
    this.voteRound = 1,
    this.voteCandidates,
  });

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
  Map<String, dynamic> toJson() => _$GameStateToJson(this);

  GameState copyWith({
    GamePhase? phase,
    NightSubPhase? subPhase,
    GameWinner? winner,
    List<Player>? players,
    int? turnCount,
    bool? isTransitioning,
    List<String>? transitioningPlayerIds,
    int? countdown,
    Map<String, String>? votes,
    bool? witchUsedLifePotion,
    bool? witchUsedDeathPotion,
    String? seerRevealedId,
    String? accusedPlayerId,
    String? werewolfHuntTargetId,
    List<String>? dyingPlayerIds,
    List<String>? lastNightDeadIds,
    int? voteRound,
    List<String>? voteCandidates,
    // Reset flags
    bool resetSeerRevealedId = false,
    bool resetAccusedPlayerId = false,
    bool resetWerewolfHuntTargetId = false,
    bool resetVoteCandidates = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      subPhase: subPhase ?? this.subPhase,
      winner: winner ?? this.winner,
      players: players ?? this.players,
      turnCount: turnCount ?? this.turnCount,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      transitioningPlayerIds:
          transitioningPlayerIds ?? this.transitioningPlayerIds,
      countdown: countdown ?? this.countdown,
      votes: votes ?? this.votes,
      witchUsedLifePotion: witchUsedLifePotion ?? this.witchUsedLifePotion,
      witchUsedDeathPotion: witchUsedDeathPotion ?? this.witchUsedDeathPotion,
      seerRevealedId:
          resetSeerRevealedId ? null : (seerRevealedId ?? this.seerRevealedId),
      accusedPlayerId: resetAccusedPlayerId
          ? null
          : (accusedPlayerId ?? this.accusedPlayerId),
      werewolfHuntTargetId: resetWerewolfHuntTargetId
          ? null
          : (werewolfHuntTargetId ?? this.werewolfHuntTargetId),
      dyingPlayerIds: dyingPlayerIds ?? this.dyingPlayerIds,
      lastNightDeadIds: lastNightDeadIds ?? this.lastNightDeadIds,
      voteRound: voteRound ?? this.voteRound,
      voteCandidates:
          resetVoteCandidates ? null : (voteCandidates ?? this.voteCandidates),
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
