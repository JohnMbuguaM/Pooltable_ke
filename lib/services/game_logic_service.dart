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

  /// Apply a through shot (balls + cue ball pocketed together)
  /// No points awarded because cue ball was also pocketed
  static GameAction applyThroughShot(Game game, List<int> ballNumbers) {
    final player = game.currentPlayer;
    final ballsStr = ballNumbers.join(', ');

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: ActionType.throughShot,
      ballNumber: ballNumbers.isNotEmpty ? ballNumbers.first : null,
      pointsChange: 0,
      timestamp: DateTime.now(),
      description: '${player.name}: through shot - ball(s) $ballsStr + cue pocketed (0 pts)',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    // No points awarded
    // Pocket all the balls
    for (final ball in ballNumbers) {
      game.remainingBalls.remove(ball);
      game.pocketedBalls.add(ball);

      // If target ball was pocketed, advance the sequence
      if (ball == game.currentTargetBall) {
        game.currentBallSequenceIndex = advanceBallSequenceIndex(game);
      }
    }

    game.actions.add(action);
    // Player loses turn because cue ball was also pocketed
    game.currentPlayerIndex = getNextPlayerIndex(game);
    return action;
  }

  /// Apply a through + foul action.
  /// The first ball in the list is the one the player touched first,
  /// and its value is deducted as penalty. All selected balls are
  /// removed from the table. Turn advances to the next player.
  static GameAction applyThroughFoul(Game game, List<int> ballNumbers) {
    final player = game.currentPlayer;
    final penaltyBall = ballNumbers.first;
    final penalty = AppConstants.getBallValue(penaltyBall);
    final ballsStr = ballNumbers.join(', ');

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: ActionType.throughFoul,
      ballNumber: penaltyBall,
      pointsChange: -penalty,
      timestamp: DateTime.now(),
      description:
          '${player.name}: through + foul - ball(s) $ballsStr pocketed, penalty ball $penaltyBall (-$penalty pts)',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    // Deduct penalty based on the first ball selected
    player.score -= penalty;

    // Remove all selected balls from the table
    for (final ball in ballNumbers) {
      game.remainingBalls.remove(ball);
      game.pocketedBalls.add(ball);

      if (ball == game.currentTargetBall) {
        game.currentBallSequenceIndex = advanceBallSequenceIndex(game);
      }
    }

    game.actions.add(action);
    game.currentPlayerIndex = getNextPlayerIndex(game);
    return action;
  }

  /// Apply a penalty action
  /// For ball-specific fouls (wrongBallContact, ballTouched, ballJumpedOff),
  /// the penalty is the value of the specific ball involved.
  /// For cue ball scratch, penalty is the value of the current target ball.
  /// For non-ball fouls (cue off, carry), a flat penalty applies.
  static GameAction applyPenalty(Game game, ActionType penaltyType,
      {int? ballNumber}) {
    final player = game.currentPlayer;
    int penalty;

    // Ball-specific penalties use the ball's point value
    if (ballNumber != null &&
        (penaltyType == ActionType.wrongBallContact ||
         penaltyType == ActionType.ballTouched ||
         penaltyType == ActionType.ballJumpedOff)) {
      penalty = AppConstants.getBallValue(ballNumber);
    } else {
      switch (penaltyType) {
        case ActionType.wrongBallContact:
          penalty = AppConstants.wrongBallContactPenalty;
        case ActionType.cueBallScratch:
          // Scratch penalty is the value of the current target ball
          penalty = AppConstants.getBallValue(game.currentTargetBall);
        case ActionType.ballTouched:
          penalty = AppConstants.ballTouchedPenalty;
        case ActionType.ballJumpedOff:
          penalty = AppConstants.ballJumpedOffPenalty;
        case ActionType.cueBallJumpedOff:
          penalty = AppConstants.cueBallJumpedOffPenalty;
        case ActionType.carryBall:
          penalty = AppConstants.getBallValue(game.currentTargetBall);
        default:
          penalty = 0;
      }
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

  /// Apply a miss: deduct the current target ball's value and advance turn
  static GameAction applyMiss(Game game) {
    final player = game.currentPlayer;
    final ball = game.currentTargetBall;
    if (ball == -1) return _createNoOpAction(game);

    final penalty = AppConstants.getBallValue(ball);

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: ActionType.miss,
      ballNumber: ball,
      pointsChange: -penalty,
      timestamp: DateTime.now(),
      description: '${player.name} missed ball $ball (-$penalty)',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    player.score -= penalty;
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

  /// Check if any eliminated players can re-enter the game.
  /// A player re-enters if their score + remaining balls value >= leader's score
  /// (meaning they could potentially tie or beat the leader).
  static List<Player> checkReEntries(Game game) {
    final reEntered = <Player>[];
    final activePlayers = game.activePlayers;

    if (activePlayers.isEmpty) return reEntered;

    final leader =
        activePlayers.reduce((a, b) => a.score >= b.score ? a : b);
    final remainingValue = game.remainingBallsValue;

    for (final player in game.players) {
      if (!player.isEliminated) continue;

      // If eliminated player can now tie or beat the leader with remaining balls
      if (player.score + remainingValue >= leader.score) {
        player.isEliminated = false;
        player.eliminatedAtRound = null;
        reEntered.add(player);
      }
    }

    return reEntered;
  }

  /// Check if the current target ball is a "money ball" for the leader.
  /// Returns the leader if pocketing the current ball would clinch an
  /// unbeatable win for them, otherwise returns null.
  static Player? checkMoneyBall(Game game) {
    final activePlayers = game.activePlayers;
    if (activePlayers.length < 2) return null;

    final ball = game.currentTargetBall;
    if (ball <= 0) return null;

    final ballValue = AppConstants.getBallValue(ball);
    final remainingAfter = game.remainingBallsValue - ballValue;

    // Sort by score descending
    final sorted = List<Player>.from(activePlayers)
      ..sort((a, b) => b.score.compareTo(a.score));

    final leader = sorted[0];
    final leaderNewScore = leader.score + ballValue;

    // Check if every other player can't catch the leader even with all
    // remaining balls (after this one is pocketed)
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].score + remainingAfter >= leaderNewScore) {
        return null; // Someone can still catch up
      }
    }

    return leader;
  }

  /// Check all players for whom the current target ball is their "money ball."
  /// For each active player, check: if THIS player pockets the current ball,
  /// would their new score be unbeatable by every OTHER active player?
  static List<Player> checkMoneyBallPlayers(Game game) {
    final activePlayers = game.activePlayers;
    if (activePlayers.length < 2) return [];

    final ball = game.currentTargetBall;
    if (ball <= 0) return [];

    final ballValue = AppConstants.getBallValue(ball);
    final remainingAfter = game.remainingBallsValue - ballValue;

    final moneyBallPlayers = <Player>[];

    for (final candidate in activePlayers) {
      final candidateNewScore = candidate.score + ballValue;

      bool uncatchable = true;
      for (final other in activePlayers) {
        if (other.id == candidate.id) continue;
        if (other.score + remainingAfter >= candidateNewScore) {
          uncatchable = false;
          break;
        }
      }

      if (uncatchable) {
        moneyBallPlayers.add(candidate);
      }
    }

    return moneyBallPlayers;
  }

  /// Check for early win condition
  static bool checkEarlyWin(Game game) {
    final activePlayers = game.activePlayers;

    // If only one or zero active players left, game is over
    if (activePlayers.length <= 1) {
      game.status = GameStatus.completed;
      if (activePlayers.length == 1) {
        game.winnerId = activePlayers.first.id;
      }
      game.completedAt = DateTime.now();
      return true;
    }

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
      type: ActionType.bothJumpedOff,
      pointsChange: 0,
      timestamp: DateTime.now(),
      description: 'No action (no balls remaining)',
    );
  }
}
