class Player {
  final String id;
  String name;
  int score;
  bool isEliminated;
  int rank;
  int? eliminatedAtRound;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isEliminated = false,
    this.rank = 0,
    this.eliminatedAtRound,
  });

  Player copyWith({
    String? id,
    String? name,
    int? score,
    bool? isEliminated,
    int? rank,
    int? eliminatedAtRound,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isEliminated: isEliminated ?? this.isEliminated,
      rank: rank ?? this.rank,
      eliminatedAtRound: eliminatedAtRound ?? this.eliminatedAtRound,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'is_eliminated': isEliminated ? 1 : 0,
      'rank': rank,
      'eliminated_at_round': eliminatedAtRound,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      score: map['score'] as int? ?? 0,
      isEliminated: map['is_eliminated'] == 1,
      rank: map['rank'] as int? ?? 0,
      eliminatedAtRound: map['eliminated_at_round'] as int?,
    );
  }

  @override
  String toString() => 'Player($name, score: $score, eliminated: $isEliminated)';
}
