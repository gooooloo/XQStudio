// lib/core/models/play_node.dart

/// A node in the game move tree, ported from dTXQPlayNode (XQPNode.pas).
///
/// Tree structure:
/// - [lChild]: next move in main line (left child)
/// - [rChild]: first variation at this position (right child / sibling)
/// - [lParent]: non-null if this node is a variation (sibling link back)
/// - [rParent]: non-null if this node is a main-line child
class PlayNode {
  int stepNo;
  String strRec;
  int xyf;
  int xyt;
  List<int> qiziXY;
  List<String>? remark;
  PlayNode? lastStepNode;
  PlayNode? lParent;
  PlayNode? rParent;
  PlayNode? lChild;
  PlayNode? rChild;

  PlayNode({
    required this.stepNo,
    required this.strRec,
    required this.xyf,
    required this.xyt,
    required this.qiziXY,
    this.remark,
    this.lastStepNode,
    this.lParent,
    this.rParent,
  });

  factory PlayNode.root(List<int> initialPieceXY) => PlayNode(
        stepNo: 0,
        strRec: '',
        xyf: 0,
        xyt: 0,
        qiziXY: initialPieceXY,
      );

  void setLChild(PlayNode? node) {
    lChild = node;
    if (node != null) {
      node.rParent = this;
      node.lParent = null;
    }
  }

  void setRChild(PlayNode? node) {
    rChild = node;
    if (node != null) {
      node.lParent = this;
      node.rParent = null;
    }
  }

  void detach() {
    if (lParent != null) {
      lParent!.rChild = null;
      lParent = null;
    }
    if (rParent != null) {
      rParent!.lChild = null;
      rParent = null;
    }
  }
}
