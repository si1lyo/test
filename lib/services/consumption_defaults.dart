/// AI-estimated default consumption days per product.
/// Used as a prior when purchase history is limited.
class ConsumptionDefaults {
  // keyword → days map (longest-match wins)
  static const _table = <String, int>{
    // 生鮮食品
    '豆腐': 3,
    '納豆': 4,
    '刺身': 2,
    '鮮魚': 2,
    'さしみ': 2,
    '肉': 3,
    '豚肉': 3,
    '鶏肉': 3,
    '牛肉': 3,
    'ひき肉': 3,
    '野菜': 5,
    'キャベツ': 7,
    'レタス': 5,
    'ほうれん草': 4,
    'トマト': 5,
    'きゅうり': 4,
    'なす': 4,
    'にんじん': 10,
    'じゃがいも': 14,
    'たまねぎ': 14,
    'ねぎ': 7,
    'にんにく': 21,
    'しょうが': 14,
    'もやし': 3,
    'きのこ': 5,
    'しいたけ': 5,
    'えのき': 5,
    '果物': 5,
    'りんご': 10,
    'バナナ': 5,
    'みかん': 7,
    'いちご': 3,
    // 乳製品・卵
    '牛乳': 7,
    'ミルク': 7,
    'ヨーグルト': 10,
    'チーズ': 14,
    'バター': 30,
    '卵': 14,
    'たまご': 14,
    // パン・麺
    '食パン': 5,
    'パン': 4,
    '麺': 7,
    'うどん': 7,
    'そば': 7,
    'パスタ': 30,
    'ラーメン': 7,
    // 冷凍食品
    '冷凍': 30,
    // 飲み物
    'ジュース': 7,
    '飲料': 7,
    'お茶': 14,
    'コーヒー': 14,
    'ミネラルウォーター': 14,
    '水': 14,
    'ビール': 7,
    'お酒': 14,
    '酒': 14,
    // 調味料・保存食
    '醤油': 60,
    'しょうゆ': 60,
    '味噌': 60,
    'みそ': 60,
    '塩': 90,
    '砂糖': 90,
    '油': 45,
    'サラダ油': 45,
    'オリーブオイル': 45,
    'ソース': 60,
    'マヨネーズ': 45,
    'ケチャップ': 45,
    'みりん': 60,
    '料理酒': 60,
    'だし': 30,
    '鶏がらスープ': 45,
    'コンソメ': 45,
    // 缶詰・レトルト
    '缶詰': 180,
    'レトルト': 90,
    'カレー': 14,
    // お菓子・スナック
    'お菓子': 14,
    'チョコ': 14,
    'クッキー': 14,
    'スナック': 14,
    'ポテチ': 14,
    'アイス': 14,
    'ガム': 21,
    // 米・穀類
    '米': 30,
    'ご飯': 7,
    'シリアル': 21,
    'オートミール': 30,
    // 日用品
    'シャンプー': 45,
    'コンディショナー': 45,
    'リンス': 45,
    'トリートメント': 45,
    'ボディソープ': 30,
    'ボディーソープ': 30,
    '石鹸': 30,
    '石けん': 30,
    '洗顔': 30,
    '洗顔料': 30,
    '化粧水': 45,
    '乳液': 45,
    '日焼け止め': 60,
    '歯磨き粉': 45,
    '歯ブラシ': 90,
    '洗剤': 45,
    '柔軟剤': 45,
    'トイレットペーパー': 21,
    'ティッシュ': 21,
    'キッチンペーパー': 21,
    'ラップ': 30,
    'アルミホイル': 30,
    'ゴミ袋': 30,
    'ジップロック': 30,
    '食器用洗剤': 30,
    '台所用洗剤': 30,
    '漂白剤': 60,
    '除菌': 30,
    '消毒': 30,
    'マスク': 14,
    '絆創膏': 90,
    '綿棒': 60,
    '電池': 90,
    'トナー': 180,
    'インク': 180,
  };

  /// Returns estimated default consumption days for [name] in [genre].
  static int estimate(String name, String genre) {
    final lower = name.toLowerCase();

    // longest-match: try longer keywords first
    final sorted = _table.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sorted) {
      if (lower.contains(key)) return _table[key]!;
    }

    // genre-based fallback
    return switch (genre) {
      '食品' => 7,
      '日用品' => 30,
      _ => 14,
    };
  }

  /// Blended estimate: combines AI prior with observed purchase intervals.
  /// [aiEstimatedDays] is the Claude-generated estimate stored in Firestore;
  /// falls back to the local keyword table when absent.
  static int personalized({
    required String name,
    required String genre,
    required List<DateTime> sortedDates,
    int? aiEstimatedDays,
  }) {
    final prior = aiEstimatedDays ?? estimate(name, genre);
    if (sortedDates.length < 2) return prior;

    // calculate average observed interval
    int totalDays = 0;
    for (int i = 1; i < sortedDates.length; i++) {
      totalDays += sortedDates[i].difference(sortedDates[i - 1]).inDays;
    }
    final n = sortedDates.length - 1; // number of intervals
    final observed = (totalDays / n).round().clamp(1, 365);

    // blend: prior weight = 1 / (n + 1), observed weight = n / (n + 1)
    final blended = ((observed * n + prior * 1) / (n + 1)).round();
    return blended.clamp(1, 365);
  }
}
