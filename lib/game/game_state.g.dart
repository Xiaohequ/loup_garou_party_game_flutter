// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameState _$GameStateFromJson(Map<String, dynamic> json) => GameState(
      phase: $enumDecodeNullable(_$GamePhaseEnumMap, json['phase']) ??
          GamePhase.lobby,
      subPhase: $enumDecodeNullable(_$NightSubPhaseEnumMap, json['subPhase']) ??
          NightSubPhase.none,
      players: (json['players'] as List<dynamic>?)
              ?.map((e) => Player.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      turnCount: (json['turnCount'] as num?)?.toInt() ?? 0,
      votes: (json['votes'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      witchUsedLifePotion: json['witchUsedLifePotion'] as bool? ?? false,
      witchUsedDeathPotion: json['witchUsedDeathPotion'] as bool? ?? false,
      seerRevealedId: json['seerRevealedId'] as String?,
      dyingPlayerIds: (json['dyingPlayerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$GameStateToJson(GameState instance) => <String, dynamic>{
      'phase': _$GamePhaseEnumMap[instance.phase]!,
      'subPhase': _$NightSubPhaseEnumMap[instance.subPhase]!,
      'players': instance.players.map((e) => e.toJson()).toList(),
      'turnCount': instance.turnCount,
      'votes': instance.votes,
      'witchUsedLifePotion': instance.witchUsedLifePotion,
      'witchUsedDeathPotion': instance.witchUsedDeathPotion,
      'seerRevealedId': instance.seerRevealedId,
      'dyingPlayerIds': instance.dyingPlayerIds,
    };

const _$GamePhaseEnumMap = {
  GamePhase.lobby: 'lobby',
  GamePhase.rolesDistribution: 'rolesDistribution',
  GamePhase.night: 'night',
  GamePhase.day: 'day',
  GamePhase.vote: 'vote',
  GamePhase.end: 'end',
};

const _$NightSubPhaseEnumMap = {
  NightSubPhase.none: 'none',
  NightSubPhase.werewolfTurn: 'werewolfTurn',
  NightSubPhase.seerTurn: 'seerTurn',
  NightSubPhase.witchTurn: 'witchTurn',
  NightSubPhase.hunterTurn: 'hunterTurn',
};

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
      id: json['id'] as String,
      name: json['name'] as String,
      isAlive: json['isAlive'] as bool? ?? true,
      role: $enumDecodeNullable(_$RoleEnumMap, json['role']) ?? Role.villager,
      isReady: json['isReady'] as bool? ?? false,
    );

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isAlive': instance.isAlive,
      'role': _$RoleEnumMap[instance.role]!,
      'isReady': instance.isReady,
    };

const _$RoleEnumMap = {
  Role.villager: 'villager',
  Role.werewolf: 'werewolf',
  Role.seer: 'seer',
  Role.witch: 'witch',
  Role.hunter: 'hunter',
};
