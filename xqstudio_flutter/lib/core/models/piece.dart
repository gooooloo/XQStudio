enum PieceType { che, ma, xiang, shi, shuai, pao, bing }

enum Side { red, black }

class Piece {
  Piece._();

  static const _typeMap = [
    PieceType.che,    // 0
    PieceType.ma,     // 1
    PieceType.xiang,  // 2
    PieceType.shi,    // 3
    PieceType.shuai,  // 4
    PieceType.shi,    // 5
    PieceType.xiang,  // 6
    PieceType.ma,     // 7
    PieceType.che,    // 8
    PieceType.pao,    // 9
    PieceType.pao,    // 10
    PieceType.bing,   // 11
    PieceType.bing,   // 12
    PieceType.bing,   // 13
    PieceType.bing,   // 14
    PieceType.bing,   // 15
  ];

  static Side sideOf(int index) {
    assert(index >= 1 && index <= 32);
    return index <= 16 ? Side.red : Side.black;
  }

  static PieceType typeOf(int index) {
    assert(index >= 1 && index <= 32);
    return _typeMap[(index - 1) % 16];
  }
}
