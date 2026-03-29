/// Constants ported from XQDataT.pas and XQSystem.pas.
const String kProductName = 'XQStudio';
const String kMainVersion = '1.63';
const int kFileVersion = 18;
const int kMaxRecNo = 1023;
const int kMaxVarNo = 1023;

/// XY value for a captured (off-board) piece.
const int kCapturedXY = 0xFF;

/// Initial positions of all 32 pieces (1-based, index 0 unused).
/// Encoding: tens digit = X (0-8), ones digit = Y (0-9).
/// Piece ordering follows Delphi dCXqzXY [1..32]:
///   Red (1-16): Che Ma Xiang Shi Shuai Shi Xiang Ma Che Pao Pao Bing×5
///   Black (17-32): same layout
const List<int> kInitialPieceXY = [
  0,  // index 0 unused (1-based)
  // Red pieces (1-16)
  80, 70, 60, 50, 40, 30, 20, 10, 00, // back row right-to-left
  72, 12, // Pao
  83, 63, 43, 23, 03, // Bing
  // Black pieces (17-32)
  09, 19, 29, 39, 49, 59, 69, 79, 89, // back row right-to-left
  17, 77, // Pao
  06, 26, 46, 66, 86, // Zu
];

/// Red numbering system (一二三...九). Index 0 unused.
const List<String> kRedNum = ['0', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

/// Black numbering system (９８７...１). Index 0 unused.
const List<String> kBlkNum = ['0', '９', '８', '７', '６', '５', '４', '３', '２', '１'];
