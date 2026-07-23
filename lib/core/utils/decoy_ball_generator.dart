import 'package:uuid/uuid.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/level.dart';

/// Generates misleading decoy balls that cannot merge with real level fragments.
abstract final class DecoyBallGenerator {
  static const _pool2 = [
    'XY',
    'QZ',
    'VK',
    'JT',
    'PW',
    'HX',
    'NB',
    'CM',
    'YD',
    'ZP',
    'WQ',
    'KF',
    'RV',
    'TG',
    'LH',
    'MX',
    'BP',
    'SN',
    'DW',
    'YH',
    'QF',
    'XZ',
    'JV',
    'WK',
    'PN',
    'RF',
    'GL',
    'TC',
    'BH',
    'ZK',
    'VJ',
    'TY',
    'QM',
    'HF',
    'LP',
    'NG',
    'WD',
    'XS',
    'BR',
    'KC',
    'AZ',
    'BY',
    'CX',
    'DV',
    'EU',
    'FW',
    'GT',
    'HS',
    'IR',
    'JO',
    'KP',
    'LQ',
    'MR',
    'NS',
    'OT',
    'PU',
    'QV',
    'RW',
    'SX',
    'TZ',
  ];

  static const _pool3 = [
    'XYQ',
    'QZV',
    'VKJ',
    'JTP',
    'PWH',
    'HXN',
    'NBC',
    'CMY',
    'YDZ',
    'ZPW',
    'WQK',
    'KFR',
    'RVT',
    'TGL',
    'LHM',
    'MXB',
    'BPS',
    'SND',
    'DWY',
    'YHQ',
    'QFX',
    'XZJ',
    'JVK',
    'WKN',
    'PNR',
    'RFG',
    'GLT',
    'TCB',
    'BHZ',
    'ZKV',
    'VJT',
    'TYQ',
    'QMH',
    'HFL',
    'LPN',
    'NGW',
    'WDX',
    'XSB',
    'BRK',
    'KCV',
    'VQM',
    'MHT',
    'TLZ',
    'ZPX',
    'XQN',
    'AZK',
    'BYL',
    'CXM',
    'DVN',
    'EUO',
    'FWP',
    'GTQ',
    'HSR',
    'IRT',
    'JOU',
    'KPV',
    'LQW',
    'MRX',
    'NSY',
    'OTZ',
    'PUA',
    'QVB',
    'RWC',
  ];

  /// Scales decoys with level size + difficulty so the board feels full.
  static int countForLevel(Level level) {
    final fragments = level.words.fold<int>(
      0,
      (sum, w) => sum + w.fragments.length,
    );
    final difficultyBonus = switch (level.difficulty) {
      Difficulty.easy => 18,
      Difficulty.medium => 22,
      Difficulty.hard => 26,
      Difficulty.expert => 30,
      Difficulty.master => 34,
    };
    return (fragments + difficultyBonus).clamp(20, 40);
  }

  static List<Ball> generate(Level level, Uuid uuid) {
    final target = countForLevel(level);
    final used = <String>{for (final w in level.words) ...w.fragments};
    final decoys = <Ball>[];

    for (final pool in [_pool2, _pool3]) {
      for (final chars in pool) {
        if (decoys.length >= target) break;
        if (used.contains(chars)) continue;
        if (_conflictsWithLevel(chars, level)) continue;

        decoys.add(
          Ball(
            id: uuid.v4(),
            chars: chars,
            type: BallType.decoy,
            wordId: 'decoy',
            category: level.category,
            isOnBoard: true,
          ),
        );
        used.add(chars);
      }
    }

    return decoys;
  }

  static bool _conflictsWithLevel(String decoy, Level level) {
    for (final word in level.words) {
      if (word.text == decoy) return true;
      if (word.text.contains(decoy) && decoy.length >= 2) return true;
      for (final frag in word.fragments) {
        for (final combo in ['$decoy$frag', '$frag$decoy']) {
          if (word.text == combo || word.text.startsWith(combo)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
