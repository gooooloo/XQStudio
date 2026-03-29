import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/game/variation_list.dart';
import 'package:xqstudio/core/models/board_state.dart';
import 'package:xqstudio/core/models/piece.dart';
import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/core/rules/move_notation.dart';
import 'package:xqstudio/core/rules/move_validator.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';

/// Central orchestrator for a xiangqi game session.
///
/// Manages board state, navigation through the move tree, move making with
/// validation, undo/redo, variation management, and remarks.
///
/// Ported from `dTXiangQi` in XQSystem.pas, with all UI references stripped.
class GameController {
  PlayNode _root;
  PlayNode _currentNode;

  /// Cached main-line path from root to the last move, for quick navigation.
  List<PlayNode> _mainLine = [];

  /// Creates a new game with the standard opening position.
  GameController()
      : _root = PlayNode.root(List<int>.from(kInitialPieceXY)),
        _currentNode = PlayNode.root(List<int>.from(kInitialPieceXY)) {
    _currentNode = _root;
    _rebuildMainLine();
  }

  /// Creates a game controller from pre-built game data (e.g., loaded from .xqf).
  GameController.fromGameData(GameData gameData)
      : _root = gameData.playTree,
        _currentNode = gameData.playTree {
    _rebuildMainLine();
  }

  // ---------------------------------------------------------------------------
  // State getters
  // ---------------------------------------------------------------------------

  /// Current step number (0 = opening position).
  int get currentStep => _currentNode.stepNo;

  /// Total number of steps in the current main line.
  int get totalSteps => _mainLine.length - 1;

  /// The board state at the current position.
  BoardState get currentBoard => BoardState.fromList(_currentNode.qiziXY);

  /// Whether it's red's turn to move.
  bool get isRedTurn => currentStep % 2 == 0;

  /// The current node in the move tree.
  PlayNode get currentNode => _currentNode;

  /// The root node of the move tree.
  PlayNode get root => _root;

  /// The cached main line (list of nodes from root to end).
  List<PlayNode> get mainLine => List.unmodifiable(_mainLine);

  /// Returns the list of variation nodes at the current position.
  ///
  /// These are all possible next moves (main line + alternatives) from the
  /// parent of the current move, i.e., the lChild chain of _currentNode's
  /// parent (or _currentNode itself if looking ahead).
  List<PlayNode> get variations {
    return VariationList.getVariations(_currentNode);
  }

  /// Returns the list of variation nodes that can follow from the current
  /// position (i.e., the children of _currentNode).
  List<PlayNode> get nextVariations {
    return VariationList.getVariations(_currentNode);
  }

  // ---------------------------------------------------------------------------
  // Move making
  // ---------------------------------------------------------------------------

  /// Attempts to make a move from [fromXY] to [toXY].
  ///
  /// Returns true if the move was legal and executed, false otherwise.
  /// If a move already exists at this position with the same from/to, we
  /// navigate to it instead of creating a duplicate.
  bool makeMove(int fromXY, int toXY) {
    final board = currentBoard;

    // Check turn: ensure the piece belongs to the current player
    final pieceIndex = board.pieceIndexAt(fromXY);
    if (pieceIndex == 0) return false;
    final side = Piece.sideOf(pieceIndex);
    if (isRedTurn && side != Side.red) return false;
    if (!isRedTurn && side != Side.black) return false;

    // Validate the move
    if (!MoveValidator.isValidMove(board, fromXY, toXY)) {
      return false;
    }

    // Check if this move already exists as a child or variation
    final existing = _findExistingMove(fromXY, toXY);
    if (existing != null) {
      _currentNode = existing;
      _rebuildMainLine();
      return true;
    }

    // Generate notation
    final notation =
        MoveNotation.generateNotation(board, fromXY, toXY) ?? '';

    // Build the new board state
    final newQiziXY = board.movePiece(fromXY, toXY).toList();

    final newNode = PlayNode(
      stepNo: _currentNode.stepNo + 1,
      strRec: notation,
      xyf: fromXY,
      xyt: toXY,
      qiziXY: newQiziXY,
      lastStepNode: _currentNode,
    );

    // Insert into tree
    if (_currentNode.lChild == null) {
      // No existing continuation — set as main line
      _currentNode.setLChild(newNode);
    } else {
      // Existing continuation — add as variation (append to rChild chain)
      final lastSibling =
          VariationList.findLastSibling(_currentNode.lChild!);
      lastSibling!.setRChild(newNode);
    }

    _currentNode = newNode;
    _rebuildMainLine();
    return true;
  }

  /// Finds an existing child/variation node matching the given move.
  PlayNode? _findExistingMove(int fromXY, int toXY) {
    var node = _currentNode.lChild;
    while (node != null) {
      if (node.xyf == fromXY && node.xyt == toXY) {
        return node;
      }
      node = node.rChild;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Undo / Redo
  // ---------------------------------------------------------------------------

  /// Undoes the last move (goes back one step).
  void undoMove() {
    if (_currentNode.stepNo == 0) return;
    final parent = _currentNode.lastStepNode ?? _currentNode.rParent;
    if (parent != null) {
      _currentNode = parent;
    }
  }

  /// Redoes the next move (follows main line / lChild).
  void redoMove() {
    if (_currentNode.lChild != null) {
      _currentNode = _currentNode.lChild!;
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Go to the first position (root / step 0).
  void goToFirst() {
    _currentNode = _root;
  }

  /// Go to the last position in the current main line.
  void goToLast() {
    _currentNode = _mainLine.last;
  }

  /// Go to the next move (follows main line lChild).
  void goToNext() {
    if (_currentNode.lChild != null) {
      _currentNode = _currentNode.lChild!;
    }
  }

  /// Go to the previous move.
  void goToPrev() {
    if (_currentNode.stepNo == 0) return;
    final parent = _currentNode.lastStepNode ?? _currentNode.rParent;
    if (parent != null) {
      _currentNode = parent;
    }
  }

  /// Jump to a specific step number in the main line.
  ///
  /// Returns true if the step was found and navigated to.
  bool goToStep(int step) {
    if (step < 0 || step >= _mainLine.length) return false;
    _currentNode = _mainLine[step];
    return true;
  }

  // ---------------------------------------------------------------------------
  // Variation management
  // ---------------------------------------------------------------------------

  /// Switch to a specific variation at the current parent.
  ///
  /// [index] is the 0-based index in the variation list.
  /// Returns true if the switch was successful.
  bool switchVariation(int index) {
    if (_currentNode.stepNo == 0) return false;

    final parent =
        _currentNode.lastStepNode ?? _currentNode.rParent;
    if (parent == null) return false;

    final vars = VariationList.getVariations(parent);
    if (index < 0 || index >= vars.length) return false;

    _currentNode = vars[index];
    _rebuildMainLine();
    return true;
  }

  /// Promotes a variation to become the main line at the current position.
  ///
  /// The current node must be a variation (have lParent != null).
  /// This swaps the variation with the main-line move.
  bool promoteVariation() {
    if (_currentNode.lParent == null) return false; // already main line

    final varNode = _currentNode;
    final prevSibling = varNode.lParent!;

    // Find the parent that owns the lChild chain
    PlayNode? chainParent;
    if (prevSibling.rParent != null) {
      chainParent = prevSibling.rParent;
    }

    // Swap: remove varNode from rChild chain and put it in place of prevSibling
    // This is a simplified version — swap the data of the two nodes' positions
    // in the chain. We follow the Delphi dExchangePlayVar approach.

    final tmpRChild = varNode.rChild;

    varNode.lParent = prevSibling.lParent;
    varNode.rParent = prevSibling.rParent;
    if (varNode.rChild != null) {
      varNode.rChild!.lParent = prevSibling;
    }
    varNode.rChild = prevSibling;

    if (prevSibling.lParent != null) {
      prevSibling.lParent!.rChild = varNode;
    }
    if (prevSibling.rParent != null) {
      prevSibling.rParent!.lChild = varNode;
    }

    prevSibling.lParent = varNode;
    prevSibling.rParent = null;
    prevSibling.rChild = tmpRChild;

    _rebuildMainLine();
    return true;
  }

  /// Deletes a variation node and its subtree.
  ///
  /// If the node is in the main line (rParent != null), its rChild takes over.
  /// If the node is a variation (lParent != null), it is removed from the chain.
  void deleteVariation(PlayNode node) {
    if (node == _root) return; // can't delete root

    if (node.rParent != null) {
      // Main-line node: replace with its first variation (rChild), or null
      node.rParent!.setLChild(node.rChild);
    } else if (node.lParent != null) {
      // Variation node: skip it in the chain
      node.lParent!.setRChild(node.rChild);
    }

    // If we deleted the current node, go back to parent
    if (_currentNode == node) {
      _currentNode = node.lastStepNode ?? _root;
    }

    _rebuildMainLine();
  }

  // ---------------------------------------------------------------------------
  // Delete current move
  // ---------------------------------------------------------------------------

  /// Deletes the current move and all its descendants.
  ///
  /// After deletion, the current position moves back to the parent.
  void deleteCurrentMove() {
    if (_currentNode == _root) return;

    final parent = _currentNode.lastStepNode ?? _root;

    if (_currentNode.rParent != null) {
      // Main-line child: replace with first variation
      _currentNode.rParent!.setLChild(_currentNode.rChild);
    } else if (_currentNode.lParent != null) {
      // Variation: skip in chain
      _currentNode.lParent!.setRChild(_currentNode.rChild);
    }

    _currentNode = parent;
    _rebuildMainLine();
  }

  // ---------------------------------------------------------------------------
  // Remarks
  // ---------------------------------------------------------------------------

  /// Sets a remark on the current node.
  void setRemark(String text) {
    if (text.isEmpty) {
      _currentNode.remark = null;
    } else {
      _currentNode.remark = text.split('\n');
    }
  }

  /// Gets the remark on the current node.
  String getRemark() {
    if (_currentNode.remark == null) return '';
    return _currentNode.remark!.join('\n');
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Resets the game to the standard opening position.
  void reset() {
    _root = PlayNode.root(List<int>.from(kInitialPieceXY));
    _currentNode = _root;
    _rebuildMainLine();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Rebuilds the main-line cache by following lChild from root.
  void _rebuildMainLine() {
    _mainLine = [];
    var node = _root;
    _mainLine.add(node);
    while (node.lChild != null) {
      node = node.lChild!;
      _mainLine.add(node);
    }
  }
}
