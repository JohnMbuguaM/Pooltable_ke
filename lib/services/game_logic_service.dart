import '../models/game.dart';
import '../models/player.dart';
import '../models/action.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';

class GameLogicService {
  static const _uuid = Uuid();

  /// Get the next target ball in sequence, skipping any already pocketed
  static int getNextTargetBall(Game game) {
    for (int i = 0; i < AppConstants.ballSequence.length; i++) {
      int seqIdx =
          (game.currentBallSequenceIndex + i) % AppConstants.ballSequence.length;
      int ball = AppConstants.ballSequence[seqIdx];
      if (game.remainingBalls.contains(ball)) {
        return ball;
      }
    }
    return -1;
  }

  /// Advance the ball sequence index to point at the next un-pocketed ball
  static int advanceBallSequenceIndex(Game game) {
    for (int i = 1; i <= AppConstants.ballSequence.length; i++) {
      int seqIdx =
          (game.currentBallSequenceIndex + i) % AppConstants.ballSequence.length;
      int ball = AppConstants.ballSequence[seqIdx];
      if (game.remainingBalls.contains(ball)) {
        return seqIdx;
      }
    }
    return game.currentBallSequenceIndex;
  }

  /// Move to the next active player
  static int getNextPlayerIndex(Game game) {
    int next = game.currentPlayerIndex;
    for (int i = 0; i < game.players.length; i++) {
      next = (next + 1) % game.players.length;
      if (!game.players[next].isEliminated) {
        return next;
      }
    }
    return game.currentPlayerIndex;
  }

  /// Apply a successful pocket action
  static GameAction applySuccessfulPocket(Game game) {
    final player = game.currentPlayer;
    final ball = game.currentTargetBall;
    if (ball == -1) return _createNoOpAction(game);

    final points = AppConstants.getBallValue(ball);

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: ActionType.successfulPocket,
      ballNumber: ball,
      pointsChange: points,
      timestamp: DateTime.now(),
      description: '${player.name} pocketed ball $ball (+$points)',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    player.score += points;
    game.remainingBalls.remove(ball);
    game.pocketedBalls.add(ball);
    game.currentBallSequenceIndex = advanceBallSequenceIndex(game);
    game.actions.add(action);

    // Same player continues on successful pocket
    return action;
  }

  /// Apply a combination shot (pocketed a different ball than target)
  static GameAction applyCombinationShot(Game game, int pocketedBall) {
    final player = game.currentPlayer;
    final points = AppConstants.getBallValue(pocketedBall);

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: ActionType.combinationShot,
      ballNumber: pocketedBall,
      pointsChange: points,
      timestamp: DateTime.now(),
      description:
          '${player.name} combo pocketed ball $pocketedBall (+$points)',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    player.score += points;
    game.remainingBalls.remove(pocketedBall);
    game.pocketedBalls.add(pocketedBall);

    // If the pocketed ball was the current target, advance sequence
    if (pocketedBall == game.currentTargetBall) {
      game.currentBallSequenceIndex = advanceBallSequenceIndex(game);
    }

    game.actions.add(action);

    // Same player continues on successful pocket
    return action;
  }

  /// Apply a neutral shot (target + cue ball pocketed together, or both jump off)
  static GameAction applyNeutralShot(Game game, {bool bothJumpedOff = false}) {
    final player = game.currentPlayer;
    final ball = game.currentTargetBall;

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: bothJumpedOff ? ActionType.bothJumpedOff : ActionType.neutralShot,
      ballNumber: ball != -1 ? ball : null,
      pointsChange: 0,
      timestamp: DateTime.now(),
      description: bothJumpedOff
          ? '${player.name}: both balls jumped off (neutral)'
          : '${player.name}: target + cue ball pocketed (neutral)',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    // If it's a neutral pocket (not jump off), the target ball goes back on the table
    // Actually per rules: target + cue ball pocketed = neutral, ball stays pocketed
    // but no points. Let me re-read: "Neutral (no points): target ball + cue ball pocketed together"
    // This means the ball IS pocketed but no points are awarded.
    if (!bothJumpedOff && ball != -1) {
      game.remainingBalls.remove(ball);
      game.pocketedBalls.add(ball);
      game.currentBallSequenceIndex = advanceBallSequenceIndex(game);
    }

    game.actions.add(action);
    game.currentPlayerIndex = getNextPlayerIndex(game);
    return action;
  }

  /// Apply a penalty action
  static GameAction applyPenalty(Game game, ActionType penaltyType,
      {int? ballNumber}) {
    final player = game.currentPlayer;
    int penalty;

    switch (penaltyType) {
      case ActionType.wrongBallContact:
        penalty = AppConstants.wrongBallContactPenalty;
      case ActionType.cueBallScratch:
        penalty = AppConstants.cueBallScratchPenalty;
      case ActionType.ballTouched:
        penalty = AppConstants.ballTouchedPenalty;
      case ActionType.ballJumpedOff:
        penalty = AppConstants.ballJumpedOffPenalty;
      case ActionType.cueBallJumpedOff:
        penalty = AppConstants.cueBallJumpedOffPenalty;
      case ActionType.carryBall:
        penalty = AppConstants.carryBallPenalty;
      default:
        penalty = 0;
    }

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: penaltyType,
      ballNumber: ballNumber,
      pointsChange: -penalty,
      timestamp: DateTime.now(),
      description: '${player.name}: ${penaltyType.label} (-$penalty)',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    player.score -= penalty;

    // If a ball jumped off the table, it's removed from play
    if (penaltyType == ActionType.ballJumpedOff && ballNumber != null) {
      game.remainingBalls.remove(ballNumber);
      game.pocketedBalls.add(ballNumber);
      if (ballNumber == game.currentTargetBall) {
        game.currentBallSequenceIndex = advanceBallSequenceIndex(game);
      }
    }

    game.actions.add(action);
    game.currentPlayerIndex = getNextPlayerIndex(game);
    return action;
  }

  /// Check and apply eliminations
  static List<Player> checkEliminations(Game game) {
    final eliminated = <Player>[];
    final activePlayers = game.activePlayers;

    if (activePlayers.length <= 1) return eliminated;

    final remainingValue = game.remainingBallsValue;

    for (final player in activePlayers) {
      // Find highest score among OTHER active players
      int highestOtherScore = 0;
      for (final other in activePlayers) {
        if (other.id != player.id && other.score > highestOtherScore) {
          highestOtherScore = other.score;
        }
      }

      // If even getting all remaining balls can't beat/tie the leader, eliminate
      if (player.score + remainingValue < highestOtherScore) {
        player.isEliminated = true;
        player.eliminatedAtRound = game.roundNumber;
        eliminated.add(player);
      }
    }

    return eliminated;
  }

  /// Apply handicap: deduct points from leader when a player is eliminated
  static GameAction? applyHandicap(Game game, Player eliminatedPlayer) {
    final activePlayers = game.activePlayers;
    if (activePlayers.isEmpty) return null;

    // Find the leader
    final leader =
        activePlayers.reduce((a, b) => a.score >= b.score ? a : b);

    // Calculate: how many points does the eliminated player need to tie/win?
    final deficit = leader.score - eliminatedPlayer.score;
    if (deficit <= 0) return null;

    // Deduct the deficit from the leader
    final handicapPoints = deficit;

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: leader.id,
      type: ActionType.handicapAdjustment,
      pointsChange: -handicapPoints,
      timestamp: DateTime.now(),
      description:
          'Handicap: ${leader.name} -$handicapPoints (${eliminatedPlayer.name} eliminated)',
      previousScore: leader.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    leader.score -= handicapPoints;
    game.actions.add(action);

    return action;
  }

  /// Check for early win condition
  static bool checkEarlyWin(Game game) {
    final activePlayers = game.activePlayers;
    if (activePlayers.length <= 1) return true;

    final remainingValue = game.remainingBallsValue;

    // Sort by score descending
    final sorted = List<Player>.from(activePlayers)
      ..sort((a, b) => b.score.compareTo(a.score));

    final leader = sorted[0];
    final secondPlace = sorted[1];

    // If second place + all remaining balls still can't beat leader
    if (secondPlace.score + remainingValue < leader.score) {
      game.status = GameStatus.completed;
      game.winnerId = leader.id;
      game.completedAt = DateTime.now();
      return true;
    }

    return false;
  }

  /// Check if game is naturally over (all balls pocketed)
  static bool checkGameOver(Game game) {
    if (game.remainingBalls.isEmpty) {
      final activePlayers = game.activePlayers;
      if (activePlayers.isNotEmpty) {
        final winner =
            activePlayers.reduce((a, b) => a.score >= b.score ? a : b);
        game.status = GameStatus.completed;
        game.winnerId = winner.id;
        game.completedAt = DateTime.now();
      }
      return true;
    }

    // Only one player left
    if (game.activePlayers.length == 1) {
      game.status = GameStatus.completed;
      game.winnerId = game.activePlayers.first.id;
      game.completedAt = DateTime.now();
      return true;
    }

    return false;
  }

  /// Undo the last action
  static bool undoLastAction(Game game) {
    if (game.actions.isEmpty) return false;

    final lastAction = game.actions.removeLast();
    final player =
        game.players.firstWhere((p) => p.id == lastAction.playerId);

    // Restore player score
    if (lastAction.previousScore != null) {
      player.score = lastAction.previousScore!;
    }

    // Restore ball state
    if (lastAction.previousCurrentBallIndex != null) {
      game.currentBallSequenceIndex = lastAction.previousCurrentBallIndex!;
    }
    if (lastAction.previousRemainingBalls != null) {
      game.remainingBalls = List.from(lastAction.previousRemainingBalls!);
    }
    if (lastAction.previousPocketedBalls != null) {
      game.pocketedBalls = List.from(lastAction.previousPocketedBalls!);
    }
    if (lastAction.previousIsEliminated != null) {
      player.isEliminated = lastAction.previousIsEliminated!;
      if (!player.isEliminated) {
        player.eliminatedAtRound = null;
      }
    }

    // Restore game status if it was completed
    if (game.status == GameStatus.completed) {
      game.status = GameStatus.active;
      game.winnerId = null;
      game.completedAt = null;
    }

    return true;
  }

  /// Advance turn to next player (for miss / no action)
  static void advanceTurn(Game game) {
    game.currentPlayerIndex = getNextPlayerIndex(game);
  }

  /// Assign final rankings based on scores
  static void assignRankings(Game game) {
    final sorted = List<Player>.from(game.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    for (int i = 0; i < sorted.length; i++) {
      sorted[i].rank = i + 1;
    }
  }

  static GameAction _createNoOpAction(Game game) {
    return GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: game.currentPlayer.id,
      type: ActionType.neutralShot,
      pointsChange: 0,
      timestamp: DateTime.now(),
      description: 'No action (no balls remaining)',
    );
  }
}
