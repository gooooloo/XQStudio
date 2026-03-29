/// A position on the 9×10 xiangqi board.
///
/// XY encoding: tens digit = X (column, 0-8), ones digit = Y (row, 0-9).
/// Origin (0,0) is bottom-left from Red's perspective.
class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  factory Position.fromXY(int xy) => Position(xy ~/ 10, xy % 10);

  int toXY() => x * 10 + y;

  bool get isValid => x >= 0 && x <= 8 && y >= 0 && y <= 9;

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => x * 10 + y;

  @override
  String toString() => 'Position($x, $y)';
}
