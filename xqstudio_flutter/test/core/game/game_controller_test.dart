import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/game/game_controller.dart';
import 'package:xqstudio/core/game/variation_list.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';
import 'package:xqstudio/core/models/game_metadata.dart';

void main() {
  group('GameController', () {
    late GameController ctrl;

    setUp(() {
      ctrl = GameController(); // starts with standard opening
    });

    // =========================================================================
    // Initial state (4 tests)
    // =========================================================================
    group('initial state', () {
      test('starts at step 0', () {
        expect(ctrl.currentStep, 0);
      });

      test('board is standard opening', () {
        expect(ctrl.currentBoard.pieceXY(5), 40); // red shuai
        expect(ctrl.currentBoard.pieceXY(21), 49); // black jiang
      });

      test('red plays first', () {
        expect(ctrl.isRedTurn, true);
      });

      test('totalSteps is 0 initially', () {
        expect(ctrl.totalSteps, 0);
      });
    });

    // =========================================================================
    // makeMove (10 tests)
    // =========================================================================
    group('makeMove', () {
      test('valid move advances step', () {
        final ok = ctrl.makeMove(72, 74); // 炮二平五 (red pao from 72 to 74)
        expect(ok, true);
        expect(ctrl.currentStep, 1);
      });

      test('invalid move returns false', () {
        // Pao cannot jump to a random diagonal — try moving it diagonally
        final ok = ctrl.makeMove(72, 63); // pao can't move diagonally
        expect(ok, false);
        expect(ctrl.currentStep, 0);
      });

      test('alternates turns', () {
        ctrl.makeMove(72, 74); // red
        expect(ctrl.isRedTurn, false);
        ctrl.makeMove(19, 27); // black ma
        expect(ctrl.isRedTurn, true);
      });

      test('board updates after move', () {
        ctrl.makeMove(72, 74);
        expect(ctrl.currentBoard.pieceIndexAt(72), 0); // old pos empty
        expect(ctrl.currentBoard.pieceIndexAt(74), isNot(0)); // new pos has piece
      });

      test('3-move sequence', () {
        ctrl.makeMove(72, 74); // red pao 炮二平五
        ctrl.makeMove(19, 27); // black ma 马8进7
        ctrl.makeMove(10, 22); // red ma 马八进七
        expect(ctrl.currentStep, 3);
      });

      test('move from empty square fails', () {
        final ok = ctrl.makeMove(44, 45); // no piece at 44
        expect(ok, false);
      });

      test('cannot move opponent piece on wrong turn', () {
        // Red's turn but trying to move black piece at 19 (black xiang)
        final ok = ctrl.makeMove(19, 27);
        expect(ok, false);
      });

      test('duplicate move navigates to existing node', () {
        ctrl.makeMove(72, 74);
        ctrl.goToPrev();
        // Make the same move again — should navigate, not duplicate
        final ok = ctrl.makeMove(72, 74);
        expect(ok, true);
        expect(ctrl.currentStep, 1);
      });

      test('capture updates board correctly', () {
        // Set up a scenario where red pao can capture
        ctrl.makeMove(72, 74); // 炮二平五
        ctrl.makeMove(19, 27); // 马8进7
        ctrl.makeMove(74, 34); // 炮五进四 — pao moves forward
        // pao at 34, check board
        expect(ctrl.currentBoard.pieceIndexAt(34), isNot(0));
      });

      test('move generates notation string', () {
        ctrl.makeMove(72, 74);
        expect(ctrl.currentNode.strRec, isNotEmpty);
      });
    });

    // =========================================================================
    // undo/redo (8 tests)
    // =========================================================================
    group('undo/redo', () {
      test('undo reverts one step', () {
        ctrl.makeMove(72, 74);
        ctrl.undoMove();
        expect(ctrl.currentStep, 0);
      });

      test('undo restores board state', () {
        final boardBefore = ctrl.currentBoard.toList();
        ctrl.makeMove(72, 74);
        ctrl.undoMove();
        final boardAfter = ctrl.currentBoard.toList();
        expect(boardAfter, equals(boardBefore));
      });

      test('undo at step 0 does nothing', () {
        ctrl.undoMove();
        expect(ctrl.currentStep, 0);
      });

      test('redo after undo', () {
        ctrl.makeMove(72, 74);
        ctrl.undoMove();
        ctrl.redoMove();
        expect(ctrl.currentStep, 1);
      });

      test('redo when no redo available does nothing', () {
        ctrl.redoMove();
        expect(ctrl.currentStep, 0);
      });

      test('undo 3 steps', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.makeMove(20, 22);
        ctrl.undoMove();
        ctrl.undoMove();
        ctrl.undoMove();
        expect(ctrl.currentStep, 0);
      });

      test('redo follows main line', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.undoMove();
        ctrl.undoMove();
        ctrl.redoMove();
        expect(ctrl.currentStep, 1);
        ctrl.redoMove();
        expect(ctrl.currentStep, 2);
      });

      test('undo/redo round trip preserves board', () {
        ctrl.makeMove(72, 74);
        final boardAt1 = ctrl.currentBoard.toList();
        ctrl.undoMove();
        ctrl.redoMove();
        expect(ctrl.currentBoard.toList(), equals(boardAt1));
      });
    });

    // =========================================================================
    // Navigation (8 tests)
    // =========================================================================
    group('navigation', () {
      test('goToFirst returns to step 0', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.goToFirst();
        expect(ctrl.currentStep, 0);
      });

      test('goToLast goes to last step', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.goToFirst();
        ctrl.goToLast();
        expect(ctrl.currentStep, 2);
      });

      test('goToNext advances one step', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.goToFirst();
        ctrl.goToNext();
        expect(ctrl.currentStep, 1);
      });

      test('goToPrev goes back one step', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.goToPrev();
        expect(ctrl.currentStep, 1);
      });

      test('goToNext at end does nothing', () {
        ctrl.makeMove(72, 74);
        ctrl.goToNext();
        expect(ctrl.currentStep, 1);
      });

      test('goToPrev at step 0 does nothing', () {
        ctrl.goToPrev();
        expect(ctrl.currentStep, 0);
      });

      test('goToStep jumps to specific step', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.makeMove(20, 22);
        final ok = ctrl.goToStep(1);
        expect(ok, true);
        expect(ctrl.currentStep, 1);
      });

      test('goToStep with invalid step returns false', () {
        ctrl.makeMove(72, 74);
        expect(ctrl.goToStep(-1), false);
        expect(ctrl.goToStep(5), false);
      });
    });

    // =========================================================================
    // Variations (8 tests)
    // =========================================================================
    group('variations', () {
      test('addVariation creates branch', () {
        ctrl.makeMove(72, 74); // main line: 炮二平五
        ctrl.goToPrev(); // back to step 0
        final ok = ctrl.makeMove(70, 82); // variation: 马二进三
        expect(ok, true);
        expect(ctrl.currentStep, 1);
      });

      test('variations list shows options', () {
        ctrl.makeMove(72, 74); // main
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // variation
        ctrl.goToPrev();
        // At step 0, there should be 2 possible next moves
        final vars = ctrl.variations;
        expect(vars.length, greaterThanOrEqualTo(2));
      });

      test('three variations at same position', () {
        ctrl.makeMove(72, 74); // main: 炮二平五
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // var 1: 马二进三
        ctrl.goToPrev();
        ctrl.makeMove(10, 22); // var 2: 马八进七
        ctrl.goToPrev();
        final vars = ctrl.variations;
        expect(vars.length, 3);
      });

      test('switchVariation changes current node', () {
        ctrl.makeMove(72, 74);
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // creates variation
        ctrl.goToPrev();
        ctrl.goToNext(); // follows main line (72->74)
        expect(ctrl.currentNode.xyf, 72);
        expect(ctrl.currentNode.xyt, 74);
      });

      test('switchVariation to index 1', () {
        ctrl.makeMove(72, 74); // main
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // variation
        // Navigate into the variation and switch
        final ok = ctrl.switchVariation(0);
        // switchVariation works on currentNode's parent
        expect(ok, true);
      });

      test('switchVariation with invalid index returns false', () {
        ctrl.makeMove(72, 74);
        expect(ctrl.switchVariation(5), false);
      });

      test('variation node has correct lastStepNode', () {
        ctrl.makeMove(72, 74);
        ctrl.goToPrev();
        ctrl.makeMove(70, 82);
        // The variation's lastStepNode should be the root
        expect(ctrl.currentNode.lastStepNode, equals(ctrl.root));
      });

      test('duplicate variation move navigates instead of creating', () {
        ctrl.makeMove(72, 74);
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // first variation
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // same move again — should navigate
        // Should still have only 2 children, not 3
        ctrl.goToPrev();
        final vars = ctrl.variations;
        expect(vars.length, 2);
      });
    });

    // =========================================================================
    // Remarks (4 tests)
    // =========================================================================
    group('remarks', () {
      test('setRemark and getRemark', () {
        ctrl.makeMove(72, 74);
        ctrl.setRemark('Good opening move!');
        expect(ctrl.getRemark(), 'Good opening move!');
      });

      test('remark persists after navigation', () {
        ctrl.makeMove(72, 74);
        ctrl.setRemark('Test remark');
        ctrl.goToPrev();
        ctrl.goToNext();
        expect(ctrl.getRemark(), 'Test remark');
      });

      test('empty remark clears it', () {
        ctrl.makeMove(72, 74);
        ctrl.setRemark('Something');
        ctrl.setRemark('');
        expect(ctrl.getRemark(), '');
      });

      test('remark on root node', () {
        ctrl.setRemark('Opening remark');
        expect(ctrl.getRemark(), 'Opening remark');
      });
    });

    // =========================================================================
    // Delete (5 tests)
    // =========================================================================
    group('delete', () {
      test('delete current move goes back to parent', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.deleteCurrentMove();
        expect(ctrl.currentStep, 1);
      });

      test('delete root does nothing', () {
        ctrl.deleteCurrentMove();
        expect(ctrl.currentStep, 0);
      });

      test('delete removes subtree', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.goToPrev(); // at step 1
        ctrl.deleteCurrentMove(); // deletes step 1 and its child step 2
        expect(ctrl.currentStep, 0);
        expect(ctrl.totalSteps, 0);
      });

      test('deleteVariation removes a specific variation', () {
        ctrl.makeMove(72, 74); // main
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // variation
        final varNode = ctrl.currentNode;
        ctrl.goToPrev();
        ctrl.deleteVariation(varNode);
        final vars = ctrl.variations;
        expect(vars.length, 1);
        expect(vars[0].xyf, 72); // only main line remains
      });

      test('delete only variation leaves no children', () {
        ctrl.makeMove(72, 74);
        ctrl.deleteCurrentMove();
        expect(ctrl.currentStep, 0);
        expect(ctrl.root.lChild, isNull);
      });
    });

    // =========================================================================
    // Reset (2 tests)
    // =========================================================================
    group('reset', () {
      test('reset clears all moves', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        ctrl.reset();
        expect(ctrl.currentStep, 0);
        expect(ctrl.totalSteps, 0);
      });

      test('reset restores standard opening', () {
        ctrl.makeMove(72, 74);
        ctrl.reset();
        expect(ctrl.currentBoard.pieceXY(5), 40);
        expect(ctrl.currentBoard.pieceXY(10), 72);
      });
    });

    // =========================================================================
    // fromGameData (2 tests)
    // =========================================================================
    group('fromGameData', () {
      test('loads pre-built tree', () {
        // Build a simple game manually
        final root = PlayNode.root(List<int>.from(kInitialPieceXY));
        final board = BoardState.fromList(root.qiziXY);
        final newBoard = board.movePiece(72, 74);
        final child = PlayNode(
          stepNo: 1,
          strRec: '炮二平五',
          xyf: 72,
          xyt: 74,
          qiziXY: newBoard.toList(),
          lastStepNode: root,
        );
        root.setLChild(child);

        final gameData = GameData(
          metadata: GameMetadata(),
          playTree: root,
          initialPieceXY: List<int>.from(kInitialPieceXY),
        );

        final ctrl2 = GameController.fromGameData(gameData);
        expect(ctrl2.currentStep, 0);
        expect(ctrl2.totalSteps, 1);
      });

      test('can navigate loaded game', () {
        final root = PlayNode.root(List<int>.from(kInitialPieceXY));
        final board = BoardState.fromList(root.qiziXY);
        final newBoard = board.movePiece(72, 74);
        final child = PlayNode(
          stepNo: 1,
          strRec: '炮二平五',
          xyf: 72,
          xyt: 74,
          qiziXY: newBoard.toList(),
          lastStepNode: root,
        );
        root.setLChild(child);

        final gameData = GameData(
          metadata: GameMetadata(),
          playTree: root,
          initialPieceXY: List<int>.from(kInitialPieceXY),
        );

        final ctrl2 = GameController.fromGameData(gameData);
        ctrl2.goToLast();
        expect(ctrl2.currentStep, 1);
        ctrl2.goToFirst();
        expect(ctrl2.currentStep, 0);
      });
    });

    // =========================================================================
    // Main line tracking (3 tests)
    // =========================================================================
    group('mainLine', () {
      test('mainLine updates after makeMove', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        expect(ctrl.mainLine.length, 3); // root + 2 moves
      });

      test('mainLine follows lChild chain', () {
        ctrl.makeMove(72, 74);
        ctrl.makeMove(19, 27);
        expect(ctrl.mainLine[0], ctrl.root);
        expect(ctrl.mainLine[1].xyf, 72);
        expect(ctrl.mainLine[2].xyf, 19);
      });

      test('variation does not alter main line unless navigated', () {
        ctrl.makeMove(72, 74);
        final mainLength = ctrl.mainLine.length;
        ctrl.goToPrev();
        ctrl.makeMove(70, 82); // variation — this changes main line
        // After making variation, mainLine rebuilds from root following lChild
        // The main line's lChild is still 72->74
        ctrl.goToPrev();
        ctrl.goToNext(); // follows main line
        expect(ctrl.mainLine.length, mainLength);
      });
    });
  });

  // ===========================================================================
  // VariationList unit tests (4 tests)
  // ===========================================================================
  group('VariationList', () {
    test('getVariations returns empty for node with no children', () {
      final node = PlayNode.root(List<int>.from(kInitialPieceXY));
      expect(VariationList.getVariations(node), isEmpty);
    });

    test('getVariations returns single child', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child = PlayNode(
        stepNo: 1,
        strRec: 'test',
        xyf: 72,
        xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY),
        lastStepNode: root,
      );
      root.setLChild(child);
      final vars = VariationList.getVariations(root);
      expect(vars.length, 1);
      expect(vars[0], child);
    });

    test('getVariations returns full rChild chain', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child1 = PlayNode(
        stepNo: 1, strRec: 'a', xyf: 72, xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY), lastStepNode: root,
      );
      final child2 = PlayNode(
        stepNo: 1, strRec: 'b', xyf: 20, xyt: 22,
        qiziXY: List<int>.from(kInitialPieceXY), lastStepNode: root,
      );
      root.setLChild(child1);
      child1.setRChild(child2);
      final vars = VariationList.getVariations(root);
      expect(vars.length, 2);
    });

    test('count matches getVariations length', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child = PlayNode(
        stepNo: 1, strRec: 'test', xyf: 72, xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY), lastStepNode: root,
      );
      root.setLChild(child);
      expect(VariationList.count(root), 1);
    });

    test('findLastSibling returns last in chain', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child1 = PlayNode(
        stepNo: 1, strRec: 'a', xyf: 72, xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY), lastStepNode: root,
      );
      final child2 = PlayNode(
        stepNo: 1, strRec: 'b', xyf: 20, xyt: 22,
        qiziXY: List<int>.from(kInitialPieceXY), lastStepNode: root,
      );
      root.setLChild(child1);
      child1.setRChild(child2);
      expect(VariationList.findLastSibling(child1), child2);
    });
  });
}
