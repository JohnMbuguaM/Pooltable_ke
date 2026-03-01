import '../models/game.dart';
import '../models/game_rules.dart';
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
    // Turn stays with current player — user must manually select next player
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
    // Turn stays with current player — user must manually select next player
    return action;
  }

  /// Apply a penalty action.
  ///
  /// All fouls use the involved ball's point value rather than a fixed number:
  ///   - wrongBallContact  → value of the ball contacted (or target ball if unknown)
  ///   - cueBallScratch    → value of the current target ball
  ///   - carryBall         → value of the current target ball
  ///   - ballTouched       → value of the ball touched (or target ball if unknown)
  ///   - cueBallJumpedOff  → value of the current target ball
  ///   - ballJumpedOff     → value of the jumped ball; effect depends on
  ///                         [BallJumpOffMode] set in rules (deduct/neutral/add)
  static GameAction applyPenalty(Game game, ActionType penaltyType,
      {int? ballNumber}) {
    final player = game.currentPlayer;

    // Resolve the base ball value used for this foul.
    final int ballValue;
    if (ballNumber != null) {
      ballValue = AppConstants.getBallValue(ballNumber);
    } else {
      // Fall back to current target ball when no specific ball is known.
      ballValue = AppConstants.getBallValue(game.currentTargetBall);
    }

    // Determine the net score change (positive = gain, negative = loss).
    int pointsChange;
    String descSuffix;

    if (penaltyType == ActionType.ballJumpedOff) {
      final mode = AppConstants.ballJumpOffMode;
      switch (mode) {
        case BallJumpOffMode.deduct:
          pointsChange = -ballValue;
          descSuffix = '(-$ballValue)';
        case BallJumpOffMode.neutral:
          pointsChange = 0;
          descSuffix = '(neutral)';
        case BallJumpOffMode.add:
          pointsChange = ballValue;
          descSuffix = '(+$ballValue)';
      }
    } else {
      // All other fouls deduct the ball value.
      pointsChange = -ballValue;
      descSuffix = '(-$ballValue)';
    }

    final action = GameAction(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: player.id,
      type: penaltyType,
      ballNumber: ballNumber,
      pointsChange: pointsChange,
      timestamp: DateTime.now(),
      description: '${player.name}: ${penaltyType.label} $descSuffix',
      previousScore: player.score,
      previousCurrentBallIndex: game.currentBallSequenceIndex,
      previousRemainingBalls: List.from(game.remainingBalls),
      previousPocketedBalls: List.from(game.pocketedBalls),
    );

    player.score += pointsChange;

    // If a ball jumped off the table, it's removed from play regardless of mode.
    if (penaltyType == ActionType.ballJumpedOff && ballNumber != null) {
      game.remainingBalls.remove(ballNumber);
      game.pocketedBalls.add(ballNumber);
      if (ballNumber == game.currentTargetBall) {
        game.currentBallSequenceIndex = advanceBallSequenceIndex(game);
      }
    }

    game.actions.add(action);
    // Turn stays with current player — user must manually select next player
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
    // Turn stays with current player — user must manually select next player
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

  /// Check if pocketing the current (and last) ball would create a draw.
  ///
  /// Returns the list of OTHER active players whose score would TIE with the
  /// current player after the pocket. An empty list means no draw would occur.
  ///
  /// A draw is only possible when only ONE ball remains — if there are more
  /// balls left, a future pocket could still break the tie.
  ///
  /// This is a pure read — it does NOT mutate [game].
  static List<Player> checkDrawBallPlayers(Game game) {
    final activePlayers = game.activePlayers;
    if (activePlayers.length < 2) return [];

    // Draw only triggers when the board is cleared by this pocket.
    if (game.remainingBalls.length != 1) return [];

    final ball = game.currentTargetBall;
    if (ball <= 0) return [];

    final ballValue = AppConstants.getBallValue(ball);
    final pocketer = game.currentPlayer;
    final pocketerNewScore = pocketer.score + ballValue;

    final drawPartners = <Player>[];
    for (final other in activePlayers) {
      if (other.id == pocketer.id) continue;
      if (other.score == pocketerNewScore) {
        drawPartners.add(other);
      }
    }
    return drawPartners;
  }

  /// Simulate pocketing the current target ball and return the list of active
  /// players who would be eliminated as a result.
  ///
  /// This is a pure read — it does NOT mutate [game].
  /// Used to show an elimination-warning banner before the player shoots.
  static List<Player> checkPotentialEliminationsOnPocket(Game game) {
    final activePlayers = game.activePlayers;
    if (activePlayers.length < 2) return [];

    final ball = game.currentTargetBall;
    if (ball <= 0) return [];

    final ballValue = AppConstants.getBallValue(ball);
    final pocketer = game.currentPlayer;

    // Simulate scores after pocket
    final simulatedPocketerScore = pocketer.score + ballValue;
    final simulatedRemainingValue = game.remainingBallsValue - ballValue;

    final wouldBeEliminated = <Player>[];

    for (final player in activePlayers) {
      // The pocketer gains points — they can't be eliminated by their own pocket
      if (player.id == pocketer.id) continue;

      // Highest score among all OTHER active players after the simulated pocket
      int highestOtherScore = simulatedPocketerScore;
      for (final other in activePlayers) {
        if (other.id == player.id || other.id == pocketer.id) continue;
        if (other.score > highestOtherScore) {
          highestOtherScore = other.score;
        }
      }

      // Elimination condition: can't catch up even with all remaining balls
      if (player.score + simulatedRemainingValue < highestOtherScore) {
        wouldBeEliminated.add(player);
      }
    }

    return wouldBeEliminated;
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
      game.completedAt = DateTime.now();
      if (activePlayers.isNotEmpty) {
        final maxScore =
            activePlayers.fold(0, (m, p) => p.score > m ? p.score : m);
        final topPlayers =
            activePlayers.where((p) => p.score == maxScore).toList();

        if (topPlayers.length > 1) {
          // DRAW — multiple players share the highest score
          game.status = GameStatus.draw;
          game.winnerId = null;
          game.drawPlayerIds = topPlayers.map((p) => p.id).toList();
        } else {
          game.status = GameStatus.completed;
          game.winnerId = topPlayers.first.id;
          game.drawPlayerIds = null;
        }
      }
      return true;
    }

    // Only one player left
    if (game.activePlayers.length == 1) {
      game.status = GameStatus.completed;
      game.winnerId = game.activePlayers.first.id;
      game.drawPlayerIds = null;
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

    // Restore game status if it was completed or a draw
    if (game.status == GameStatus.completed || game.status == GameStatus.draw) {
      game.status = GameStatus.active;
      game.winnerId = null;
      game.drawPlayerIds = null;
      game.completedAt = null;
      // Clear rankings
      for (final p in game.players) {
        p.rank = 0;
      }
    }

    // Recalculate elimination status for ALL players based on restored state.
    // This fixes the bug where undoing an action only restored the action
    // player's elimination state but left other players incorrectly eliminated.
    recalculateEliminations(game);

    return true;
  }

  /// Recalculate which players should be eliminated based on current scores
  /// and remaining ball values. Used after undo / win revocation to ensure
  /// consistency. Works correctly even when only 1 active player remains.
  static void recalculateEliminations(Game game) {
    final remainingValue = game.remainingBallsValue;

    // Find the highest score among non-eliminated players.
    // If everyone is eliminated (edge case) use the overall highest.
    int highestScore = game.players
        .where((p) => !p.isEliminated)
        .fold(0, (max, p) => p.score > max ? p.score : max);
    if (highestScore == 0 && game.players.isNotEmpty) {
      highestScore = game.players
          .fold(0, (max, p) => p.score > max ? p.score : max);
    }

    // Check every eliminated player — should any come back?
    for (final player in game.players) {
      if (!player.isEliminated) continue;

      // If eliminated player can now tie or beat the leader with remaining balls
      if (player.score + remainingValue >= highestScore) {
        player.isEliminated = false;
        player.eliminatedAtRound = null;
      }
    }
  }

  /// Advance turn to next player (for miss / no action)
  static void advanceTurn(Game game) {
    game.currentPlayerIndex = getNextPlayerIndex(game);
  }

  /// Assign final rankings based on scores, giving equal ranks to tied players.
  static void assignRankings(Game game) {
    final sorted = List<Player>.from(game.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    int rank = 1;
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].score == sorted[i - 1].score) {
        sorted[i].rank = sorted[i - 1].rank; // same rank for equal scores
      } else {
        sorted[i].rank = rank;
      }
      rank++;
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
