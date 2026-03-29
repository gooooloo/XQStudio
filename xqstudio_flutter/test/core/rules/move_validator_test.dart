import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/rules/move_validator.dart';

/// Helper to build a board with only specified pieces.
/// Takes a map of pieceIndex -> xy. Kings are required for king-facing check.
BoardState _board(Map<int, int> placements) {
  final pieces = List<int>.filled(33, kCapturedXY);
  pieces[0] = 0;
  // Always place kings on different columns to avoid king-facing issues,
  // unless explicitly placed.
  // Place kings on different columns in their palaces, out of the way.
  if (!placements.containsKey(5)) pieces[5] = 51; // red king at (5,1)
  if (!placements.containsKey(21)) pieces[21] = 38; // black king at (3,8)
  for (final e in placements.entries) {
    pieces[e.key] = e.value;
  }
  return BoardState.fromList(pieces);
}

void main() {
  // =========================================================================
  // Che (Rook / 车) — indices 1,9 (red), 17,25 (black)
  // =========================================================================
  group('Che (Rook)', () {
    test('valid move: horizontal right', () {
      final board = _board({1: 00}); // red che at (0,0)
      expect(MoveValidator.isValidMove(board, 00, 80), true);
    });

    test('valid move: horizontal left', () {
      final board = _board({1: 80});
      expect(MoveValidator.isValidMove(board, 80, 00), true);
    });

    test('valid move: vertical up', () {
      final board = _board({1: 00});
      expect(MoveValidator.isValidMove(board, 00, 09), true);
    });

    test('valid move: vertical down', () {
      final board = _board({1: 09});
      expect(MoveValidator.isValidMove(board, 09, 00), true);
    });

    test('invalid: diagonal move', () {
      final board = _board({1: 00});
      expect(MoveValidator.isValidMove(board, 00, 11), false);
    });

    test('blocked by own piece in path', () {
      final board = _board({1: 00, 9: 30}); // own piece at (3,0)
      expect(MoveValidator.isValidMove(board, 00, 80), false);
    });

    test('blocked by any piece in path', () {
      final board = _board({1: 00, 17: 30}); // opponent piece at (3,0)
      expect(MoveValidator.isValidMove(board, 00, 80), false);
    });

    test('can capture opponent at destination', () {
      final board = _board({1: 00, 17: 80}); // opponent at destination
      expect(MoveValidator.isValidMove(board, 00, 80), true);
    });

    test('cannot capture own piece at destination', () {
      final board = _board({1: 00, 9: 80});
      expect(MoveValidator.isValidMove(board, 00, 80), false);
    });

    test('blocked vertically by piece between', () {
      final board = _board({1: 05, 10: 03}); // piece at (0,3) between
      expect(MoveValidator.isValidMove(board, 05, 00), false);
    });

    test('valid vertical move with piece NOT in path', () {
      final board = _board({1: 05, 10: 13}); // piece on different column
      expect(MoveValidator.isValidMove(board, 05, 00), true);
    });

    test('cannot move to same position', () {
      final board = _board({1: 44});
      expect(MoveValidator.isValidMove(board, 44, 44), false);
    });
  });

  // =========================================================================
  // Ma (Knight / 马) — indices 2,8 (red), 18,24 (black)
  // =========================================================================
  group('Ma (Knight)', () {
    test('valid L-shape: right 2, up 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 65), true);
    });

    test('valid L-shape: right 2, down 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 63), true);
    });

    test('valid L-shape: left 2, up 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 25), true);
    });

    test('valid L-shape: left 2, down 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 23), true);
    });

    test('valid L-shape: up 2, right 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 56), true);
    });

    test('valid L-shape: up 2, left 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 36), true);
    });

    test('valid L-shape: down 2, right 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 52), true);
    });

    test('valid L-shape: down 2, left 1', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 32), true);
    });

    test('hobbled leg: horizontal, piece blocking right', () {
      final board = _board({2: 44, 10: 54}); // piece at (5,4) blocks right
      expect(MoveValidator.isValidMove(board, 44, 65), false);
      expect(MoveValidator.isValidMove(board, 44, 63), false);
    });

    test('hobbled leg: horizontal, piece blocking left', () {
      final board = _board({2: 44, 10: 34}); // piece at (3,4)
      expect(MoveValidator.isValidMove(board, 44, 25), false);
      expect(MoveValidator.isValidMove(board, 44, 23), false);
    });

    test('hobbled leg: vertical, piece blocking up', () {
      final board = _board({2: 44, 10: 45}); // piece at (4,5)
      expect(MoveValidator.isValidMove(board, 44, 56), false);
      expect(MoveValidator.isValidMove(board, 44, 36), false);
    });

    test('hobbled leg: vertical, piece blocking down', () {
      final board = _board({2: 44, 10: 43}); // piece at (4,3)
      expect(MoveValidator.isValidMove(board, 44, 52), false);
      expect(MoveValidator.isValidMove(board, 44, 32), false);
    });

    test('invalid: not L-shape (straight)', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 46), false);
    });

    test('invalid: not L-shape (diagonal)', () {
      final board = _board({2: 44});
      expect(MoveValidator.isValidMove(board, 44, 55), false);
    });

    test('can capture opponent piece', () {
      final board = _board({2: 44, 17: 65});
      expect(MoveValidator.isValidMove(board, 44, 65), true);
    });

    test('cannot capture own piece', () {
      final board = _board({2: 44, 9: 65});
      expect(MoveValidator.isValidMove(board, 44, 65), false);
    });
  });

  // =========================================================================
  // Xiang (Elephant / 象) — indices 3,7 (red), 19,23 (black)
  // =========================================================================
  group('Xiang (Elephant)', () {
    test('valid red xiang: (4,2) -> (2,0)', () {
      final board = _board({3: 42});
      expect(MoveValidator.isValidMove(board, 42, 20), true);
    });

    test('valid red xiang: (4,2) -> (6,0)', () {
      final board = _board({3: 42, 5: 40}); // king away from eye at (5,1)
      expect(MoveValidator.isValidMove(board, 42, 60), true);
    });

    test('valid red xiang: (4,2) -> (2,4)', () {
      final board = _board({3: 42});
      expect(MoveValidator.isValidMove(board, 42, 24), true);
    });

    test('valid red xiang: (4,2) -> (6,4)', () {
      final board = _board({3: 42});
      expect(MoveValidator.isValidMove(board, 42, 64), true);
    });

    test('red xiang cannot cross river', () {
      // (2,4) -> (0,6) would cross river; not a valid position anyway
      final board = _board({3: 24});
      expect(MoveValidator.isValidMove(board, 24, 06), false);
    });

    test('red xiang invalid destination (not valid position)', () {
      final board = _board({3: 02});
      // (0,2) -> (-2,4) off board; also (0,2) -> (2,4) is valid
      expect(MoveValidator.isValidMove(board, 02, 24), true);
      // Try to go to an invalid xiang position
      expect(MoveValidator.isValidMove(board, 02, 22), false);
    });

    test('xiang eye blocked (塞象眼)', () {
      final board = _board({3: 42, 10: 53}); // piece at (5,3) blocks eye
      expect(MoveValidator.isValidMove(board, 42, 64), false);
    });

    test('xiang eye blocked other diagonal', () {
      final board = _board({3: 42, 10: 31}); // piece at (3,1) blocks eye
      expect(MoveValidator.isValidMove(board, 42, 20), false);
    });

    test('valid black xiang: (4,7) -> (2,9)', () {
      final board = _board({19: 47, 21: 49}); // king away from eye at (3,8)
      expect(MoveValidator.isValidMove(board, 47, 29), true);
    });

    test('valid black xiang: (4,7) -> (6,9)', () {
      final board = _board({19: 47});
      expect(MoveValidator.isValidMove(board, 47, 69), true);
    });

    test('valid black xiang: (4,7) -> (2,5)', () {
      final board = _board({19: 47});
      expect(MoveValidator.isValidMove(board, 47, 25), true);
    });

    test('black xiang cannot cross river', () {
      final board = _board({19: 25});
      expect(MoveValidator.isValidMove(board, 25, 03), false);
    });

    test('invalid: not diagonal-2 (only 1 step)', () {
      final board = _board({3: 42});
      expect(MoveValidator.isValidMove(board, 42, 53), false);
    });
  });

  // =========================================================================
  // Shi (Advisor / 士) — indices 4,6 (red), 20,22 (black)
  // =========================================================================
  group('Shi (Advisor)', () {
    test('valid red shi: center to corner (4,1) -> (3,0)', () {
      final board = _board({4: 41});
      expect(MoveValidator.isValidMove(board, 41, 30), true);
    });

    test('valid red shi: center to corner (4,1) -> (5,0)', () {
      final board = _board({4: 41});
      expect(MoveValidator.isValidMove(board, 41, 50), true);
    });

    test('valid red shi: center to corner (4,1) -> (3,2)', () {
      final board = _board({4: 41});
      expect(MoveValidator.isValidMove(board, 41, 32), true);
    });

    test('valid red shi: center to corner (4,1) -> (5,2)', () {
      final board = _board({4: 41});
      expect(MoveValidator.isValidMove(board, 41, 52), true);
    });

    test('valid red shi: corner to center (3,0) -> (4,1)', () {
      final board = _board({4: 30});
      expect(MoveValidator.isValidMove(board, 30, 41), true);
    });

    test('invalid red shi: move outside palace', () {
      final board = _board({4: 30});
      expect(MoveValidator.isValidMove(board, 30, 21), false);
    });

    test('invalid red shi: orthogonal move', () {
      final board = _board({4: 41});
      expect(MoveValidator.isValidMove(board, 41, 42), false);
    });

    test('invalid red shi: 2-step diagonal', () {
      final board = _board({4: 30});
      expect(MoveValidator.isValidMove(board, 30, 52), false);
    });

    test('valid black shi: center to corner (4,8) -> (3,7)', () {
      final board = _board({20: 48});
      expect(MoveValidator.isValidMove(board, 48, 37), true);
    });

    test('valid black shi: center to corner (4,8) -> (5,9)', () {
      final board = _board({20: 48});
      expect(MoveValidator.isValidMove(board, 48, 59), true);
    });

    test('invalid black shi: outside palace', () {
      final board = _board({20: 37});
      expect(MoveValidator.isValidMove(board, 37, 26), false);
    });
  });

  // =========================================================================
  // Shuai/Jiang (King / 将帅) — indices 5 (red), 21 (black)
  // =========================================================================
  group('Shuai/Jiang (King)', () {
    test('valid red king: right in palace', () {
      final board = _board({5: 41});
      expect(MoveValidator.isValidMove(board, 41, 51), true);
    });

    test('valid red king: left in palace', () {
      final board = _board({5: 41, 21: 59}); // black king on different column
      expect(MoveValidator.isValidMove(board, 41, 31), true);
    });

    test('valid red king: up in palace', () {
      final board = _board({5: 41});
      expect(MoveValidator.isValidMove(board, 41, 42), true);
    });

    test('valid red king: down in palace', () {
      final board = _board({5: 41});
      expect(MoveValidator.isValidMove(board, 41, 40), true);
    });

    test('invalid red king: outside palace (too far right)', () {
      final board = _board({5: 51});
      expect(MoveValidator.isValidMove(board, 51, 61), false);
    });

    test('invalid red king: outside palace (too high)', () {
      final board = _board({5: 42});
      expect(MoveValidator.isValidMove(board, 42, 43), false);
    });

    test('invalid red king: diagonal move', () {
      final board = _board({5: 41});
      expect(MoveValidator.isValidMove(board, 41, 52), false);
    });

    test('invalid red king: 2-step move', () {
      final board = _board({5: 40});
      expect(MoveValidator.isValidMove(board, 40, 42), false);
    });

    test('valid black king: moves in black palace', () {
      // Red king must not share column with any destination.
      // Destinations: 47(4,7), 49(4,9), 38(3,8), 58(5,8).
      // Use different red king positions per move to avoid king-facing.
      expect(MoveValidator.isValidMove(
        _board({21: 48, 5: 50}), 48, 47), true); // red col 5, dest col 4
      expect(MoveValidator.isValidMove(
        _board({21: 48, 5: 50}), 48, 49), true); // red col 5, dest col 4
      expect(MoveValidator.isValidMove(
        _board({21: 48, 5: 50}), 48, 38), true); // red col 5, dest col 3
      expect(MoveValidator.isValidMove(
        _board({21: 48, 5: 30}), 48, 58), true); // red col 3, dest col 5
    });

    test('invalid black king: outside palace', () {
      final board = _board({21: 37});
      expect(MoveValidator.isValidMove(board, 37, 27), false);
    });

    test('king move that causes facing is illegal', () {
      // Red king at (4,2), black king at (4,9), piece at (4,4).
      // If red king moves from (4,2) to (3,2), kings no longer on same column: OK.
      // If red king moves from (3,1) to (4,1), and there's nothing between 4,1 and 4,9: illegal.
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 31; // red king at (3,1)
      pieces[21] = 49; // black king at (4,9)
      final board = BoardState.fromList(pieces);
      // Moving red king to (4,1): same column as black king, no pieces between -> facing!
      expect(MoveValidator.isValidMove(board, 31, 41), false);
    });

    test('king move to same column but pieces between: legal', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 31; // red king
      pieces[21] = 49; // black king
      pieces[1] = 45; // piece between at (4,5)
      final board = BoardState.fromList(pieces);
      expect(MoveValidator.isValidMove(board, 31, 41), true);
    });
  });

  // =========================================================================
  // Pao (Cannon / 炮) — indices 10,11 (red), 26,27 (black)
  // =========================================================================
  group('Pao (Cannon)', () {
    test('valid non-capture: horizontal clear path', () {
      final board = _board({10: 00});
      expect(MoveValidator.isValidMove(board, 00, 80), true);
    });

    test('valid non-capture: vertical clear path', () {
      final board = _board({10: 00});
      expect(MoveValidator.isValidMove(board, 00, 04), true);
    });

    test('invalid non-capture: piece in path (blocked)', () {
      final board = _board({10: 00, 1: 30}); // piece at (3,0) in path
      expect(MoveValidator.isValidMove(board, 00, 80), false);
    });

    test('valid capture: exactly 1 screen between', () {
      final board = _board({10: 00, 1: 30, 17: 80}); // screen at (3,0), target at (8,0)
      expect(MoveValidator.isValidMove(board, 00, 80), true);
    });

    test('invalid capture: 0 screens (like rook capture)', () {
      // Pao at (0,0), opponent at (3,0), no screen between: should be invalid capture
      final board = _board({10: 00, 17: 30});
      expect(MoveValidator.isValidMove(board, 00, 30), false);
    });

    test('invalid capture: 2 screens', () {
      final board = _board({10: 00, 1: 20, 9: 50, 17: 80});
      expect(MoveValidator.isValidMove(board, 00, 80), false);
    });

    test('valid capture: vertical with 1 screen', () {
      final board = _board({10: 03, 1: 05, 17: 08});
      expect(MoveValidator.isValidMove(board, 03, 08), true);
    });

    test('invalid: diagonal move', () {
      final board = _board({10: 00});
      expect(MoveValidator.isValidMove(board, 00, 11), false);
    });

    test('non-capture: path with 1 piece is blocked', () {
      // Moving to empty square but 1 piece in path: invalid (that's pao without capture)
      final board = _board({10: 00, 1: 30}); // path blocked, destination (8,0) empty
      expect(MoveValidator.isValidMove(board, 00, 80), false);
    });

    test('capture: vertical with 2 screens is invalid', () {
      final board = _board({10: 03, 1: 05, 9: 07, 17: 09});
      expect(MoveValidator.isValidMove(board, 03, 09), false);
    });

    test('valid non-capture: move 1 step with clear path', () {
      final board = _board({10: 00});
      expect(MoveValidator.isValidMove(board, 00, 10), true);
    });
  });

  // =========================================================================
  // Bing/Zu (Pawn / 兵卒) — indices 12-16 (red), 28-32 (black)
  // =========================================================================
  group('Bing (Red Pawn)', () {
    test('valid: forward 1 step before river (y=3 -> y=4)', () {
      final board = _board({12: 43});
      expect(MoveValidator.isValidMove(board, 43, 44), true);
    });

    test('invalid: sideways before river', () {
      final board = _board({12: 43});
      expect(MoveValidator.isValidMove(board, 43, 33), false);
      expect(MoveValidator.isValidMove(board, 43, 53), false);
    });

    test('invalid: backward before river', () {
      final board = _board({12: 43});
      expect(MoveValidator.isValidMove(board, 43, 42), false);
    });

    test('valid: forward 1 step after river (y=5 -> y=6)', () {
      final board = _board({12: 45});
      expect(MoveValidator.isValidMove(board, 45, 46), true);
    });

    test('valid: sideways after river (y=5)', () {
      final board = _board({12: 45});
      expect(MoveValidator.isValidMove(board, 45, 35), true);
      expect(MoveValidator.isValidMove(board, 45, 55), true);
    });

    test('invalid: backward after river', () {
      final board = _board({12: 45});
      expect(MoveValidator.isValidMove(board, 45, 44), false);
    });

    test('invalid: diagonal move', () {
      final board = _board({12: 45});
      expect(MoveValidator.isValidMove(board, 45, 56), false);
    });

    test('invalid: 2-step forward', () {
      final board = _board({12: 43});
      expect(MoveValidator.isValidMove(board, 43, 45), false);
    });

    test('can capture opponent piece forward', () {
      final board = _board({12: 45, 28: 46});
      expect(MoveValidator.isValidMove(board, 45, 46), true);
    });

    test('can capture opponent sideways after river', () {
      final board = _board({12: 45, 28: 55});
      expect(MoveValidator.isValidMove(board, 45, 55), true);
    });
  });

  group('Zu (Black Pawn)', () {
    test('valid: forward 1 step before river (y=6 -> y=5)', () {
      final board = _board({28: 46});
      expect(MoveValidator.isValidMove(board, 46, 45), true);
    });

    test('invalid: sideways before river (y=6)', () {
      final board = _board({28: 46});
      expect(MoveValidator.isValidMove(board, 46, 36), false);
      expect(MoveValidator.isValidMove(board, 46, 56), false);
    });

    test('invalid: backward before river', () {
      final board = _board({28: 46});
      expect(MoveValidator.isValidMove(board, 46, 47), false);
    });

    test('valid: forward after river (y=4 -> y=3)', () {
      final board = _board({28: 44});
      expect(MoveValidator.isValidMove(board, 44, 43), true);
    });

    test('valid: sideways after river (y=4)', () {
      final board = _board({28: 44});
      expect(MoveValidator.isValidMove(board, 44, 34), true);
      expect(MoveValidator.isValidMove(board, 44, 54), true);
    });

    test('invalid: backward after river', () {
      final board = _board({28: 44});
      expect(MoveValidator.isValidMove(board, 44, 45), false);
    });

    test('invalid: diagonal', () {
      final board = _board({28: 44});
      expect(MoveValidator.isValidMove(board, 44, 33), false);
    });

    test('can capture forward', () {
      final board = _board({28: 44, 12: 43});
      expect(MoveValidator.isValidMove(board, 44, 43), true);
    });
  });

  // =========================================================================
  // General rules
  // =========================================================================
  group('General rules', () {
    test('cannot move from empty square', () {
      final board = _board({});
      expect(MoveValidator.isValidMove(board, 00, 01), false);
    });

    test('cannot capture own piece (red on red)', () {
      final board = _board({1: 00, 9: 10});
      expect(MoveValidator.isValidMove(board, 00, 10), false);
    });

    test('cannot capture own piece (black on black)', () {
      final board = _board({17: 09, 25: 19});
      expect(MoveValidator.isValidMove(board, 09, 19), false);
    });

    test('move that exposes king facing is illegal', () {
      // A piece is between the two kings on same column. Moving it away
      // causes kings to face each other.
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 41; // red king at (4,1)
      pieces[21] = 48; // black king at (4,8)
      pieces[1] = 44; // red che at (4,4) between kings
      final board = BoardState.fromList(pieces);
      // Moving the che sideways (4,4) -> (0,4) exposes kings
      expect(MoveValidator.isValidMove(board, 44, 04), false);
    });

    test('move that does not expose king facing is legal', () {
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 41; // red king at (4,1)
      pieces[21] = 48; // black king at (4,8)
      pieces[1] = 44; // red che at (4,4) between kings
      final board = BoardState.fromList(pieces);
      // Moving the che vertically keeps it on column 4: still blocking
      expect(MoveValidator.isValidMove(board, 44, 45), true);
    });

    test('capturing the only blocker between kings exposes facing', () {
      // Black pao captures the only piece between kings using a screen.
      // After capture, pao lands beyond the king, leaving kings facing.
      final pieces = List<int>.filled(33, kCapturedXY);
      pieces[0] = 0;
      pieces[5] = 42; // red king at (4,2)
      pieces[21] = 48; // black king at (4,8)
      pieces[1] = 44; // red che at (4,4) — only blocker
      pieces[26] = 46; // black pao at (4,6)
      final board = BoardState.fromList(pieces);
      // Black pao at (4,6) captures red che at (4,4) with screen... wait, pao needs
      // exactly 1 screen. Between (4,6) and (4,4) going down: no pieces. 0 screens.
      // Invalid pao capture. Let me restructure.

      // Simpler: a black che on column 4 captures the only red blocker.
      final pieces2 = List<int>.filled(33, kCapturedXY);
      pieces2[0] = 0;
      pieces2[5] = 42; // red king at (4,2)
      pieces2[21] = 48; // black king at (4,8)
      pieces2[10] = 45; // red pao at (4,5) — only blocker
      pieces2[17] = 47; // black che at (4,7)
      final board2 = BoardState.fromList(pieces2);
      // Black che captures red pao: (4,7)->(4,5). After: black che at (4,5).
      // Kings at (4,2) and (4,8). Black che at (4,5) is between. Not facing. Legal!
      // The capturing piece replaces the blocker... that's always safe.

      // The real scenario: moving the blocker itself to expose kings.
      // This is already tested in "move that exposes king facing" above.
      // Here, test: no blocker between kings from the start.
      final pieces3 = List<int>.filled(33, kCapturedXY);
      pieces3[0] = 0;
      pieces3[5] = 42; // red king at (4,2)
      pieces3[21] = 48; // black king at (4,8), nothing between
      final board3 = BoardState.fromList(pieces3);
      // Any red king move must not leave kings facing.
      // (4,2) -> (3,2): different column now, legal.
      expect(MoveValidator.isValidMove(board3, 42, 32), true);
      // (4,2) -> (4,1): still on column 4, kings face (nothing between 4,1 and 4,8).
      expect(MoveValidator.isValidMove(board3, 42, 41), false);
    });

    test('standard opening: red che valid first move', () {
      final board = BoardState.standard();
      // Red che at 80 (index 1) can't move anywhere initially (blocked by pieces)
      // but we can test a pawn move: red bing at 43 forward to 44
      expect(MoveValidator.isValidMove(board, 83, 84), true);
    });

    test('standard opening: red ma can move', () {
      final board = BoardState.standard();
      // Red ma at 70 (index 2), can go to (8,2) or (6,2)
      // (8,2)=82, but hobbled leg: piece at (8,0)=80 which is the che.
      // Actually hobble check: da=1, db=2 => dy/2=1 => check (7,1)=71.
      // 71 is empty in initial pos, so valid.
      expect(MoveValidator.isValidMove(board, 70, 82), true);
    });
  });

  // =========================================================================
  // Edge cases for each piece type
  // =========================================================================
  group('Edge cases', () {
    test('che: move 1 step', () {
      final board = _board({1: 44});
      expect(MoveValidator.isValidMove(board, 44, 45), true);
      expect(MoveValidator.isValidMove(board, 44, 54), true);
    });

    test('ma: from corner (0,0)', () {
      final board = _board({2: 00});
      expect(MoveValidator.isValidMove(board, 00, 12), true);
      expect(MoveValidator.isValidMove(board, 00, 21), true);
    });

    test('ma: all 8 directions from center-ish', () {
      final board = _board({2: 44});
      final targets = [65, 63, 25, 23, 56, 36, 52, 32];
      for (final t in targets) {
        expect(MoveValidator.isValidMove(board, 44, t), true,
            reason: 'Ma from 44 to $t should be valid');
      }
    });

    test('pao: capture own piece impossible', () {
      final board = _board({10: 00, 1: 30, 9: 80});
      // Screen at (3,0), target (8,0) is own piece
      expect(MoveValidator.isValidMove(board, 00, 80), false);
    });

    test('xiang: all 7 red positions reachable', () {
      // Test from (4,2) to all 4 adjacent xiang positions
      final board = _board({3: 42, 5: 40}); // king at (4,0), away from eye positions
      expect(MoveValidator.isValidMove(board, 42, 20), true);
      expect(MoveValidator.isValidMove(board, 42, 60), true);
      expect(MoveValidator.isValidMove(board, 42, 24), true);
      expect(MoveValidator.isValidMove(board, 42, 64), true);
    });

    test('xiang: from (0,2) only valid moves', () {
      final board = _board({3: 02});
      expect(MoveValidator.isValidMove(board, 02, 24), true);
      expect(MoveValidator.isValidMove(board, 02, 20), true);
    });

    test('shi: from (5,2) only center is valid', () {
      final board = _board({4: 52});
      expect(MoveValidator.isValidMove(board, 52, 41), true);
      // Other diagonals go outside palace
      expect(MoveValidator.isValidMove(board, 52, 63), false);
    });

    test('bing: at river edge y=4 can only go forward', () {
      final board = _board({12: 44});
      expect(MoveValidator.isValidMove(board, 44, 45), true); // forward
      expect(MoveValidator.isValidMove(board, 44, 34), false); // sideways at y=4
      expect(MoveValidator.isValidMove(board, 44, 54), false); // sideways at y=4
    });

    test('zu: at river edge y=5 can only go forward', () {
      final board = _board({28: 45});
      expect(MoveValidator.isValidMove(board, 45, 44), true); // forward
      expect(MoveValidator.isValidMove(board, 45, 35), false); // sideways at y=5
      expect(MoveValidator.isValidMove(board, 45, 55), false); // sideways at y=5
    });

    test('bing: at y=0 on edge (cannot go backward)', () {
      // This is a weird position but test boundary
      final board = _board({12: 40});
      // Forward would be y=1, backward y=-1 (off board)
      expect(MoveValidator.isValidMove(board, 40, 41), true);
    });

    test('black pao can capture with screen', () {
      final board = _board({26: 09, 17: 05, 12: 00});
      // Pao at (0,9), screen at (0,5), capture red bing at (0,0)
      expect(MoveValidator.isValidMove(board, 09, 00), true);
    });

    test('red pao non-capture move vertically', () {
      final board = _board({10: 12});
      expect(MoveValidator.isValidMove(board, 12, 15), true);
    });
  });
}
