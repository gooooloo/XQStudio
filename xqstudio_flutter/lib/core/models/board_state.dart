import 'package:xqstudio/core/constants.dart';

/// Immutable representation of all 32 pieces' positions on the board.
/// Uses 1-based indexing (index 0 unused) matching Delphi's dTXQZXY[1..32].
class BoardState {
  final List<int> _pieces;

  BoardState._(this._pieces);

  factory BoardState.standard() => BoardState.fromList(kInitialPieceXY);

  factory BoardState.fromList(List<int> pieces) {
    assert(pieces.length == 33);
    return BoardState._(List<int>.unmodifiable(pieces));
  }

  int pieceXY(int index) => _pieces[index];

  int pieceIndexAt(int xy) {
    for (var i = 1; i <= 32; i++) {
      if (_pieces[i] == xy) return i;
    }
    return 0;
  }

  BoardState movePiece(int fromXY, int toXY) {
    final newPieces = List<int>.of(_pieces);
    final moverIndex = pieceIndexAt(fromXY);
    assert(moverIndex != 0, 'No piece at XY=$fromXY');
    final capturedIndex = pieceIndexAt(toXY);
    if (capturedIndex != 0) {
      newPieces[capturedIndex] = kCapturedXY;
    }
    newPieces[moverIndex] = toXY;
    return BoardState._(List<int>.unmodifiable(newPieces));
  }

  BoardState clone() => BoardState._(List<int>.of(_pieces));

  List<int> toList() => List<int>.of(_pieces);
}
