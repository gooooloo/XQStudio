import 'package:xqstudio/core/models/play_node.dart';

/// Helper to traverse the rChild chain of a node and return all variation nodes.
///
/// In the move tree, when a position has multiple continuations, the first
/// continuation is the lChild (main line), and alternative moves are linked
/// via the rChild chain starting from that lChild.
class VariationList {
  VariationList._();

  /// Returns all variation nodes (including the main-line move) at the
  /// given parent node's lChild chain.
  ///
  /// If [parent] has no lChild, returns an empty list.
  static List<PlayNode> getVariations(PlayNode parent) {
    final result = <PlayNode>[];
    var node = parent.lChild;
    while (node != null) {
      result.add(node);
      node = node.rChild;
    }
    return result;
  }

  /// Returns the number of variations at the given parent node.
  static int count(PlayNode parent) {
    var n = 0;
    var node = parent.lChild;
    while (node != null) {
      n++;
      node = node.rChild;
    }
    return n;
  }

  /// Finds the last sibling in the rChild chain starting from [node].
  static PlayNode? findLastSibling(PlayNode node) {
    var current = node;
    while (current.rChild != null) {
      current = current.rChild!;
    }
    return current;
  }
}
