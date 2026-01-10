import 'game_state.dart';
import 'package:uuid/uuid.dart';

class GameController {
  GameState _state = const GameState();
  final _uuid = const Uuid();

  GameState get state => _state;

  Player? addPlayer(String name) {
    if (_state.phase != GamePhase.lobby) return null;

    final newPlayer = Player(
      id: _uuid.v4(),
      name: name,
    );

    _state = _state.copyWith(players: [..._state.players, newPlayer]);
    return newPlayer;
  }

  void playerReady(String playerId) {
    final updatedPlayers = _state.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(isReady: true);
      }
      return p;
    }).toList();

    _state = _state.copyWith(players: updatedPlayers);

    if (updatedPlayers.isNotEmpty && updatedPlayers.every((p) => p.isReady)) {
      _advancePhase();
    }
  }

  void _advancePhase() {
    switch (_state.phase) {
      case GamePhase.lobby:
        _startGame();
        break;
      case GamePhase.rolesDistribution:
        _startNight();
        break;
      case GamePhase.day:
      case GamePhase.vote:
      case GamePhase.voteResult:
      case GamePhase.defenseSpeech:
        _endDay(null);
        break;
      case GamePhase.night:
        _nextNightTurn();
        break;
      default:
        break;
    }
  }

  void _startGame() {
    _distributeRoles();
    _resetReady();
    _state = _state.copyWith(phase: GamePhase.rolesDistribution);
  }

  void _resetReady() {
    final players =
        _state.players.map((p) => p.copyWith(isReady: false)).toList();
    _state = _state.copyWith(players: players);
  }

  void _distributeRoles() {
    var players = [..._state.players];
    players.shuffle();

    final totalPlayers = players.length;
    final roles = <Role>[];

    if (totalPlayers >= 6) {
      // Rule for 6+ players:
      // 1. Mandatory Specials: Seer, Witch, Hunter
      roles.add(Role.seer);
      roles.add(Role.witch);
      roles.add(Role.hunter);

      // 2. Remaining slots
      final remainingSlots = totalPlayers - roles.length;

      // 3. Wolves = half of remaining slots (rounded down), favoring Villagers slightly or equal
      // "Privilégier Villageois = Loup-Garou" implies remaining split roughly half-half.
      final wolfCount = (remainingSlots / 2).floor();

      for (var i = 0; i < wolfCount; i++) roles.add(Role.werewolf);

      // 4. Fill rest with Villagers
      while (roles.length < totalPlayers) {
        roles.add(Role.villager);
      }
    } else {
      // Fallback for < 6 players (Existing logic)

      // Basic Balancing: Minimum 1 Wolf
      int wolfCount = 1;
      // For 3-5 players: 1 Wolf is usually enough

      for (var i = 0; i < wolfCount; i++) roles.add(Role.werewolf);

      // Add Specials if enough players
      if (totalPlayers >= 4) {
        roles.add(Role.seer);
        roles.add(Role.witch);
      }

      // For very small dev games (3 players)
      if (totalPlayers < 4 && totalPlayers > 1) {
        if (!roles.contains(Role.seer)) roles.add(Role.seer);
      }

      // Fill rest with Villagers
      while (roles.length < totalPlayers) {
        roles.add(Role.villager);
      }
    }

    // Shuffle roles to ensure randomness (even though players were shuffled, shuffling roles again doesn't hurt)
    roles.shuffle();

    final updatedPlayers = <Player>[];
    for (var i = 0; i < totalPlayers; i++) {
      updatedPlayers.add(players[i].copyWith(role: roles[i]));
    }

    _state = _state.copyWith(players: updatedPlayers);
  }

  void _startNight() {
    _resetReady();
    _state = _state.copyWith(
      phase: GamePhase.night,
      subPhase: NightSubPhase.werewolfTurn, // Werewolves go first now
      votes: {},
      dyingPlayerIds: [],
      lastNightDeadIds: [],
      turnCount: _state.turnCount + 1,
      resetSeerRevealedId: true,
      resetWerewolfHuntTargetId: true,
    );
    // Check if Werewolf exists/is alive, otherwise skip
    if (!_isRoleAlive(Role.werewolf)) {
      _nextNightTurn();
    }
  }

  bool _isRoleAlive(Role role) {
    return _state.players.any((p) => p.role == role && p.isAlive);
  }

  void _nextNightTurn() {
    switch (_state.subPhase) {
      case NightSubPhase.werewolfTurn:
        _resolveWerewolfVote();
        startTransition(NightSubPhase.seerTurn);
        break;
      case NightSubPhase.seerTurn:
        startTransition(NightSubPhase.witchTurn);
        break;
      case NightSubPhase.witchTurn:
        startTransition(NightSubPhase.none); // End of night
        break;
      default:
        break;
    }
  }

  NightSubPhase? _pendingSubPhase;

  void startTransition(NightSubPhase nextSubPhase) {
    _pendingSubPhase = nextSubPhase;
    _state = _state.copyWith(
      isTransitioning: true,
      countdown: 3,
    );
  }

  void tickCountdown() {
    if (!_state.isTransitioning) return;

    if (_state.countdown > 1) {
      _state = _state.copyWith(countdown: _state.countdown - 1);
    } else {
      _state = _state.copyWith(
        isTransitioning: false,
        countdown: 0,
      );
      _completeTransition();
    }
  }

  void _completeTransition() {
    final nextSub = _pendingSubPhase;
    _pendingSubPhase = null;

    if (nextSub == null || nextSub == NightSubPhase.none) {
      _state = _state.copyWith(subPhase: NightSubPhase.none);
      _endNight();
    } else {
      _state = _state.copyWith(
        subPhase: nextSub,
        resetSeerRevealedId: nextSub == NightSubPhase.seerTurn,
      );
      // If the role for this subphase is not alive, skip but with another transition?
      // The user said "à la fin de chaque sous phase", so if it's skipped it might not need a countdown.
      // But let's check if the role is alive here.
      if (!_isRoleAliveForSubPhase(nextSub)) {
        _nextNightTurn();
      }
    }
  }

  bool _isRoleAliveForSubPhase(NightSubPhase subPhase) {
    switch (subPhase) {
      case NightSubPhase.werewolfTurn:
        return _isRoleAlive(Role.werewolf);
      case NightSubPhase.seerTurn:
        return _isRoleAlive(Role.seer);
      case NightSubPhase.witchTurn:
        return _isRoleAlive(Role.witch);
      default:
        return false;
    }
  }

  void _resolveWerewolfVote() {
    // Simple majority or first
    // For now, just take the first vote, extend logic later
    if (_state.votes.isNotEmpty) {
      final targetId = _state.votes.values.first; // Naive
      _state = _state.copyWith(
        dyingPlayerIds: [targetId],
        werewolfHuntTargetId: targetId,
      );
    }
    _state = _state.copyWith(votes: {}); // Reset votes
  }

  void _endNight() {
    // Process deaths
    final players = _state.players.map((p) {
      if (_state.dyingPlayerIds.contains(p.id)) {
        return p.copyWith(isAlive: false);
      }
      return p;
    }).toList();

    // Check Win Condition at sunrise
    if (_checkWinCondition(players)) return;

    // Check for Hunter Revenge
    // Rule: Hunter triggers if killed by Werewolves (not Witch)
    final hunter = players.cast<Player?>().firstWhere(
          (p) =>
              p?.role == Role.hunter && _state.dyingPlayerIds.contains(p?.id),
          orElse: () => null,
        );

    if (hunter != null && hunter.id == _state.werewolfHuntTargetId) {
      // Hunter was killed by Wolves -> Trigger Revenge
      _state = _state.copyWith(
        phase: GamePhase.hunterRevenge,
        players: players,
        lastNightDeadIds: List.from(_state.dyingPlayerIds),
        dyingPlayerIds: [],
      );
      return;
    }

    _state = _state.copyWith(
      phase: GamePhase.day,
      players: players,
      lastNightDeadIds: List.from(_state.dyingPlayerIds),
      dyingPlayerIds: [],
    );
  }

  void handleAction(String playerId, String actionType, dynamic payload) {
    if (_state.phase == GamePhase.night) {
      switch (actionType) {
        case 'SEER_REVEAL':
          if (_state.subPhase == NightSubPhase.seerTurn) {
            final targetId = payload['targetId'];
            _state = _state.copyWith(seerRevealedId: targetId);
          }
          break;

        case 'NIGHT_DONE':
          _nextNightTurn();
          break;

        case 'WEREWOLF_VOTE':
          if (_state.subPhase == NightSubPhase.werewolfTurn) {
            final targetId = payload['targetId'];
            final newVotes = Map<String, String>.from(_state.votes);
            newVotes[playerId] = targetId;
            _state = _state.copyWith(votes: newVotes);

            final activeWolves = _state.players
                .where((p) => p.role == Role.werewolf && p.isAlive);

            // Check if all wolves have voted
            if (newVotes.length >= activeWolves.length) {
              // Check for unanimity
              final uniqueTargets = newVotes.values.toSet();
              if (uniqueTargets.length == 1) {
                _nextNightTurn();
              }
              // If not unanimous, wait (players should see their disagreement in UI)
            }
          }
          break;

        case 'WITCH_ACTION':
          if (_state.subPhase == NightSubPhase.witchTurn) {
            List<String> currentDying = List.from(_state.dyingPlayerIds);

            if (payload['save'] == true &&
                _state.witchUsedLifePotion == false) {
              if (currentDying.isNotEmpty) currentDying.removeLast();
              _state = _state.copyWith(witchUsedLifePotion: true);
            }

            if (payload['killTargetId'] != null &&
                _state.witchUsedDeathPotion == false) {
              currentDying.add(payload['killTargetId']);
              _state = _state.copyWith(witchUsedDeathPotion: true);
            }

            _state = _state.copyWith(dyingPlayerIds: currentDying);
            _nextNightTurn();
          }
          break;
      }
    } else if (_state.phase == GamePhase.day) {
      if (actionType == 'START_VOTE') {
        _state = _state.copyWith(
          phase: GamePhase.vote,
          votes: {},
          voteRound: 1,
          voteCandidates: null,
        );
      }
    } else if (_state.phase == GamePhase.vote) {
      if (actionType == 'DAY_VOTE') {
        final targetId = payload['targetId'];
        final newVotes = Map<String, String>.from(_state.votes);
        if (targetId != null) {
          newVotes[playerId] = targetId;
        } else {
          // Abstain logic: we can store "ABSTAIN" or just handle it.
          // Let's store "ABSTAIN" to count participation, but ignore in tally
          newVotes[playerId] = "ABSTAIN";
        }

        _state = _state.copyWith(votes: newVotes);

        // Auto-end vote if everyone alive has voted
        final alivePlayers = _state.players.where((p) => p.isAlive);
        if (newVotes.length >= alivePlayers.length) {
          _resolveDayVote();
        }
      }
    } else if (_state.phase == GamePhase.voteResult) {
      if (actionType == 'END_SPEECH') {
        _endDay(_state.accusedPlayerId);
      } else if (actionType == 'VALIDATE_RESULT') {
        _endDay(null);
      } else if (actionType == 'START_REVOTE') {
        _state = _state.copyWith(
          phase: GamePhase.vote,
          voteRound: 2,
          votes: {},
        );
      }
    } else if (_state.phase == GamePhase.hunterRevenge) {
      if (actionType == 'HUNTER_SHOT') {
        final targetId = payload['targetId'];
        if (targetId != null) {
          // Kill the target
          killPlayer(targetId);

          // Check Win Condition again after Hunter shot
          if (_checkWinCondition(_state.players)) return;

          // Resume to Day
          _state = _state.copyWith(
            phase: GamePhase.day,
            // Only dyingPlayerIds from night are already moved to lastNightDeadIds
            // The hunter shot victim is now dead in players list.
            // We might want to add them to 'lastNightDeadIds' for the day announcement?
            // "Morts cette nuit" usually includes Hunter's victim.
            lastNightDeadIds: [..._state.lastNightDeadIds, targetId],
            dyingPlayerIds: [], // Clear any residuals
            accusedPlayerId: null,
            subPhase: NightSubPhase.werewolfTurn, // Reset for next night
            turnCount: _state.turnCount + 1,
            resetSeerRevealedId: true,
            resetWerewolfHuntTargetId: true,
            resetAccusedPlayerId: true,
            resetVoteCandidates: true,
          );

          // Re-check role alive status for next loops if needed, but we go to Day first.
        }
      }
    }
  }

  void _resolveDayVote() {
    // Count votes
    final voteCounts = <String, int>{};
    for (var targetId in _state.votes.values) {
      if (targetId == "ABSTAIN") continue;
      voteCounts[targetId] = (voteCounts[targetId] ?? 0) + 1;
    }

    String? accusedId;
    if (voteCounts.isEmpty) {
      // No valid votes -> No death
      accusedId = null;
    } else {
      // Find max
      var maxVotes = 0;
      var maxTargets = <String>[];
      voteCounts.forEach((targetId, count) {
        if (count > maxVotes) {
          maxVotes = count;
          maxTargets = [targetId];
        } else if (count == maxVotes) {
          maxTargets.add(targetId);
        }
      });

      if (maxTargets.length == 1) {
        accusedId = maxTargets.first;
      } else {
        // TIE
        if (_state.voteRound == 1) {
          // Go to Round 2
          _state = _state.copyWith(
            voteRound: 2,
            voteCandidates: maxTargets,
            votes: {},
          );
          return; // Stay in Vote phase
        } else {
          // Round 2 Tie -> No death
          accusedId = null;
        }
      }
    }

    // Proceed to Result
    _state = _state.copyWith(
      phase: GamePhase.voteResult,
      accusedPlayerId: accusedId,
    );
  }

  void _endDay(String? eliminatedId) {
    var players = [..._state.players];
    if (eliminatedId != null) {
      players = players.map((p) {
        if (p.id == eliminatedId) {
          return p.copyWith(isAlive: false);
        }
        return p;
      }).toList();
    }

    // Check Win Condition
    if (_checkWinCondition(players)) return; // Game Ends

    // Go to Night
    _state = _state.copyWith(
      phase: GamePhase.night,
      players: players,
      votes: {},
      dyingPlayerIds: [],
      accusedPlayerId: null,
      // Start of new night
      subPhase: NightSubPhase.werewolfTurn, // Order: Wolf -> Seer -> Witch
      turnCount: _state.turnCount + 1,
      resetSeerRevealedId: true,
      resetWerewolfHuntTargetId: true,
      resetAccusedPlayerId: true,
      resetVoteCandidates: true,
    );

    // Check if Werewolf exists/is alive, otherwise skip
    if (!_isRoleAlive(Role.werewolf)) {
      _nextNightTurn();
    }
  }

  bool _checkWinCondition(List<Player> players) {
    final activeWolves =
        players.where((p) => p.isAlive && p.role == Role.werewolf).length;
    final activeVillagers =
        players.where((p) => p.isAlive && p.role != Role.werewolf).length;

    if (activeWolves == 0) {
      _state = _state.copyWith(
        phase: GamePhase.end,
        players: players,
        winner: GameWinner.villagers,
      ); // Villagers Win
      return true;
    }

    if (activeWolves >= activeVillagers) {
      _state = _state.copyWith(
        phase: GamePhase.end,
        players: players,
        winner: GameWinner.werewolves,
      ); // Wolves Win
      return true;
    }
    return false;
  }

  void resetGame() {
    _state = const GameState(
      phase: GamePhase.lobby,
      players: [], // Clear all players
      votes: {},
      dyingPlayerIds: [],
      seerRevealedId: null,
      witchUsedLifePotion: false,
      witchUsedDeathPotion: false,
      accusedPlayerId: null,
      werewolfHuntTargetId: null,
    );
  }

  void forceNextPhase() {
    _advancePhase();
  }

  void killPlayer(String playerId) {
    _state = _state.copyWith(
      players: _state.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(isAlive: false);
        }
        return p;
      }).toList(),
    );
    // Trigger win check in case this kill ends the game
    _checkWinCondition(_state.players);
  }
}
