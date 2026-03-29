import 'package:flutter_test/flutter_test.dart';
import 'package:xqstudio/core/constants.dart';
import 'package:xqstudio/core/models/game_metadata.dart';
import 'package:xqstudio/core/models/play_node.dart';
import 'package:xqstudio/core/xqf/xqf_reader.dart';
import 'package:xqstudio/core/xqf/xqf_writer.dart';

void main() {
  group('XqfWriter', () {
    test('empty game round-trip', () {
      final gameData = GameData(
        metadata: GameMetadata(redPlayer: 'Red', blkPlayer: 'Black'),
        playTree: PlayNode.root(List<int>.from(kInitialPieceXY)),
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1), // 32 elements
      );
      final bytes = XqfWriter.writeXqf(gameData);
      final parsed = XqfReader.readXqf(bytes);
      expect(parsed.metadata.redPlayer, 'Red');
      expect(parsed.metadata.blkPlayer, 'Black');
      // Reader returns 33-element 1-based array; writer input was 32-element 0-based
      for (var i = 0; i < 32; i++) {
        expect(parsed.initialPieceXY[i + 1], gameData.initialPieceXY[i]);
      }
    });

    test('game with 3 moves round-trip', () {
      // Build a game tree with 3 moves
      final pieces = List<int>.from(kInitialPieceXY);
      final root = PlayNode.root(pieces);

      // Step 1
      final step1Pieces = List<int>.from(pieces);
      step1Pieces[10] = 74; // move red pao from 72 to 74
      final step1 = PlayNode(
        stepNo: 1,
        strRec: '炮二平五',
        xyf: 72,
        xyt: 74,
        qiziXY: step1Pieces,
      );
      root.setLChild(step1);
      step1.lastStepNode = root;

      // Step 2
      final step2Pieces = List<int>.from(step1Pieces);
      step2Pieces[18] = 27; // move black ma from 19 to 27
      final step2 = PlayNode(
        stepNo: 2,
        strRec: '马８进７',
        xyf: 19,
        xyt: 27,
        qiziXY: step2Pieces,
      );
      step1.setLChild(step2);
      step2.lastStepNode = step1;

      // Step 3
      final step3Pieces = List<int>.from(step2Pieces);
      step3Pieces[2] = 22; // move red ma from 20 to 22
      final step3 = PlayNode(
        stepNo: 3,
        strRec: '马二进三',
        xyf: 20,
        xyt: 22,
        qiziXY: step3Pieces,
      );
      step2.setLChild(step3);
      step3.lastStepNode = step2;

      final gameData = GameData(
        metadata: GameMetadata(redPlayer: '张三', blkPlayer: '李四'),
        playTree: root,
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
      );

      final bytes = XqfWriter.writeXqf(gameData);
      final parsed = XqfReader.readXqf(bytes);

      // Verify tree structure
      expect(parsed.playTree.lChild, isNotNull);
      expect(parsed.playTree.lChild!.xyf, 72);
      expect(parsed.playTree.lChild!.xyt, 74);

      expect(parsed.playTree.lChild!.lChild, isNotNull);
      expect(parsed.playTree.lChild!.lChild!.xyf, 19);
      expect(parsed.playTree.lChild!.lChild!.xyt, 27);

      expect(parsed.playTree.lChild!.lChild!.lChild, isNotNull);
      expect(parsed.playTree.lChild!.lChild!.lChild!.xyf, 20);
      expect(parsed.playTree.lChild!.lChild!.lChild!.xyt, 22);
    });

    test('game with variation round-trip', () {
      final pieces = List<int>.from(kInitialPieceXY);
      final root = PlayNode.root(pieces);

      final step1 = PlayNode(
        stepNo: 1,
        strRec: '炮二平五',
        xyf: 72,
        xyt: 74,
        qiziXY: List<int>.from(pieces),
      );
      root.setLChild(step1);
      step1.lastStepNode = root;

      final var1 = PlayNode(
        stepNo: 1,
        strRec: '马二进三',
        xyf: 20,
        xyt: 22,
        qiziXY: List<int>.from(pieces),
      );
      step1.setRChild(var1);
      var1.lastStepNode = root;

      final gameData = GameData(
        metadata: GameMetadata(),
        playTree: root,
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
      );

      final bytes = XqfWriter.writeXqf(gameData);
      final parsed = XqfReader.readXqf(bytes);

      expect(parsed.playTree.lChild, isNotNull);
      expect(parsed.playTree.lChild!.xyf, 72);
      expect(parsed.playTree.lChild!.rChild, isNotNull);
      expect(parsed.playTree.lChild!.rChild!.xyf, 20);
    });

    test('game with remarks round-trip', () {
      final pieces = List<int>.from(kInitialPieceXY);
      final root = PlayNode.root(pieces);
      root.remark = ['开局注释'];

      final step1 = PlayNode(
        stepNo: 1,
        strRec: 'S1',
        xyf: 72,
        xyt: 74,
        qiziXY: List<int>.from(pieces),
      );
      step1.remark = ['好棋！', '精彩一步'];
      root.setLChild(step1);
      step1.lastStepNode = root;

      final gameData = GameData(
        metadata: GameMetadata(),
        playTree: root,
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
      );

      final bytes = XqfWriter.writeXqf(gameData);
      final parsed = XqfReader.readXqf(bytes);

      expect(parsed.playTree.remark, isNotNull);
      expect(parsed.playTree.remark!.join('\n'), contains('开局注释'));
      expect(parsed.playTree.lChild!.remark, isNotNull);
      expect(parsed.playTree.lChild!.remark!.join('\n'), contains('好棋'));
    });

    test('writeXqf produces valid header', () {
      final gameData = GameData(
        metadata: GameMetadata(),
        playTree: PlayNode.root(List<int>.from(kInitialPieceXY)),
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
      );
      final bytes = XqfWriter.writeXqf(gameData);
      expect(bytes.length, greaterThanOrEqualTo(1024));
      // Check signature
      expect(bytes[0], 0x58); // 'X'
      expect(bytes[1], 0x51); // 'Q'
    });

    test('multiple round-trips produce consistent results', () {
      // Verify that write->read->write->read gives same data
      final pieces = List<int>.from(kInitialPieceXY);
      final root = PlayNode.root(pieces);

      final step1 = PlayNode(
        stepNo: 1,
        strRec: '炮二平五',
        xyf: 72,
        xyt: 74,
        qiziXY: List<int>.from(pieces),
      );
      root.setLChild(step1);
      step1.lastStepNode = root;

      final gameData = GameData(
        metadata: GameMetadata(redPlayer: 'Test', blkPlayer: 'Player'),
        playTree: root,
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
      );

      final bytes1 = XqfWriter.writeXqf(gameData);
      final parsed1 = XqfReader.readXqf(bytes1);

      final bytes2 = XqfWriter.writeXqf(parsed1);
      final parsed2 = XqfReader.readXqf(bytes2);

      expect(parsed2.metadata.redPlayer, 'Test');
      expect(parsed2.metadata.blkPlayer, 'Player');
      // Both parsed results are 33-element 1-based arrays from the reader
      for (var i = 1; i <= 32; i++) {
        expect(parsed2.initialPieceXY[i], parsed1.initialPieceXY[i]);
      }
      expect(parsed2.playTree.lChild, isNotNull);
      expect(parsed2.playTree.lChild!.xyf, 72);
      expect(parsed2.playTree.lChild!.xyt, 74);
    });

    test('game with captured pieces round-trip', () {
      final pieces = List<int>.from(kInitialPieceXY);
      // Mark some pieces as captured (1-based indices)
      pieces[16] = kCapturedXY; // capture a red bing
      pieces[32] = kCapturedXY; // capture a black zu

      final root = PlayNode.root(pieces);
      final gameData = GameData(
        metadata: GameMetadata(),
        playTree: root,
        initialPieceXY: pieces.sublist(1), // 32-element 0-based
      );

      final bytes = XqfWriter.writeXqf(gameData);
      final parsed = XqfReader.readXqf(bytes);

      // Reader returns 33-element 1-based array
      expect(parsed.initialPieceXY[16], kCapturedXY); // piece 16
      expect(parsed.initialPieceXY[32], kCapturedXY); // piece 32
    });

    test('metadata fields preserved in round-trip', () {
      final gameData = GameData(
        metadata: GameMetadata(
          titleA: 'Title A',
          titleB: 'Title B',
          matchName: 'Tournament',
          matchTime: '2024-01-01',
          matchAddr: 'Beijing',
          redPlayer: 'Player1',
          blkPlayer: 'Player2',
          timeRule: '60+30',
          redTime: '30:00',
          blkTime: '25:00',
          rmkWriter: 'Writer',
          author: 'Author',
          result: GameResult.redWin,
          whoPlay: WhoPlay.red,
        ),
        playTree: PlayNode.root(List<int>.from(kInitialPieceXY)),
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
      );

      final bytes = XqfWriter.writeXqf(gameData);
      final parsed = XqfReader.readXqf(bytes);

      expect(parsed.metadata.titleA, 'Title A');
      expect(parsed.metadata.titleB, 'Title B');
      expect(parsed.metadata.matchName, 'Tournament');
      expect(parsed.metadata.matchTime, '2024-01-01');
      expect(parsed.metadata.matchAddr, 'Beijing');
      expect(parsed.metadata.redPlayer, 'Player1');
      expect(parsed.metadata.blkPlayer, 'Player2');
      expect(parsed.metadata.timeRule, '60+30');
      expect(parsed.metadata.redTime, '30:00');
      expect(parsed.metadata.blkTime, '25:00');
      expect(parsed.metadata.rmkWriter, 'Writer');
      expect(parsed.metadata.author, 'Author');
      expect(parsed.metadata.result, GameResult.redWin);
      expect(parsed.metadata.whoPlay, WhoPlay.red);
    });

    test('black to play round-trip', () {
      final gameData = GameData(
        metadata: GameMetadata(whoPlay: WhoPlay.black),
        playTree: PlayNode.root(List<int>.from(kInitialPieceXY)),
        initialPieceXY: List<int>.from(kInitialPieceXY).sublist(1),
      );

      final bytes = XqfWriter.writeXqf(gameData);
      final parsed = XqfReader.readXqf(bytes);
      expect(parsed.metadata.whoPlay, WhoPlay.black);
    });
  });
}
