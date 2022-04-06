class History {
  History(this.name, this.score);
  final String name;
  final int score;

  @override
  String toString() => '$name $score';
}
