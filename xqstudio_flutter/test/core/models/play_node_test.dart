// test/core/models/play_node_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/play_node.dart';

void main() {
  group('PlayNode', () {
    test('root node has stepNo 0 and no children', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      expect(root.stepNo, 0);
      expect(root.lChild, isNull);
      expect(root.rChild, isNull);
      expect(root.strRec, '');
    });

    test('setLChild links parent and child correctly', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child = PlayNode(
        stepNo: 1,
        strRec: '炮二平五',
        xyf: 77,
        xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY),
      );
      root.setLChild(child);
      expect(root.lChild, child);
      expect(child.rParent, root);
      expect(child.lParent, isNull);
    });

    test('setRChild links as sibling (variation)', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final mainMove = PlayNode(
        stepNo: 1,
        strRec: '炮二平五',
        xyf: 77,
        xyt: 74,
        qiziXY: List<int>.from(kInitialPieceXY),
      );
      final variation = PlayNode(
        stepNo: 1,
        strRec: '马八进七',
        xyf: 10,
        xyt: 22,
        qiziXY: List<int>.from(kInitialPieceXY),
      );
      root.setLChild(mainMove);
      mainMove.setRChild(variation);
      expect(mainMove.rChild, variation);
      expect(variation.lParent, mainMove);
      expect(variation.rParent, isNull);
    });

    test('3-level deep tree with variations', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final step1 = PlayNode(stepNo: 1, strRec: 'S1', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final step2 = PlayNode(stepNo: 2, strRec: 'S2', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final step3 = PlayNode(stepNo: 3, strRec: 'S3', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final var2a = PlayNode(stepNo: 2, strRec: 'V2a', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      final var2b = PlayNode(stepNo: 2, strRec: 'V2b', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));

      root.setLChild(step1);
      step1.setLChild(step2);
      step2.setLChild(step3);
      step2.setRChild(var2a);
      var2a.setRChild(var2b);

      expect(root.lChild, step1);
      expect(step1.lChild, step2);
      expect(step2.lChild, step3);
      expect(step2.rChild, var2a);
      expect(var2a.rChild, var2b);
    });

    test('detach removes node from parent', () {
      final root = PlayNode.root(List<int>.from(kInitialPieceXY));
      final child = PlayNode(stepNo: 1, strRec: 'S1', xyf: 0, xyt: 0, qiziXY: List<int>.from(kInitialPieceXY));
      root.setLChild(child);
      child.detach();
      expect(root.lChild, isNull);
    });
  });
}
