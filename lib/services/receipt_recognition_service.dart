import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class RecognizedItem {
  String name;
  String type;
  String genre;

  RecognizedItem({required this.name, required this.type, required this.genre});
}

class ReceiptRecognitionService {
  // 日本語モデルを使用
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  static Future<List<RecognizedItem>> recognizeReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    return _parse(recognized.text);
  }

  static List<RecognizedItem> _parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 末尾に金額パターン（例: ¥198 / 198 / 1,980）がある行を商品行と判定
    final pricePattern = RegExp(r'[¥￥*＊]?\s*\d[\d,]+\s*$');

    // 商品行ではない行（合計・税・店舗情報など）を除外するキーワード
    final skipPattern = RegExp(
      r'(合計|小計|税|おつり|お釣り|割引|ポイント|外税|内税|消費税|'
      r'レシート|領収|ありがとう|またのご来店|電話|TEL|FAX|住所|〒|'
      r'お買い上げ|枚|点|品|番|No\.|no\.|割|合|軽減|対象|非課税)',
      caseSensitive: false,
    );

    final items = <RecognizedItem>[];

    for (final line in lines) {
      if (skipPattern.hasMatch(line)) continue;
      if (line.length < 2) continue;
      if (!pricePattern.hasMatch(line)) continue;

      // 末尾の金額部分を除いた文字列が商品名
      final name = line.replaceAll(pricePattern, '').replaceAll(RegExp(r'[\s　]+$'), '');
      if (name.isEmpty) continue;

      items.add(RecognizedItem(
        name: name,
        type: '',
        genre: _guessGenre(name),
      ));
    }

    return items;
  }

  // 商品名のキーワードからジャンルを推定
  static String _guessGenre(String name) {
    const food = [
      '牛乳', '豆腐', 'パン', '米', '肉', '魚', '野菜', '果物', '卵', '玉子',
      'ジュース', '飲料', 'お茶', 'コーヒー', 'ビール', '酒', '酎', 'ワイン',
      '弁当', 'おにぎり', 'サラダ', 'ヨーグルト', 'チーズ', 'バター',
      '醤油', '味噌', '油', 'スープ', 'カップ麺', 'インスタント',
      'お菓子', 'チョコ', 'アイス', 'ケーキ', 'クッキー', 'せんべい',
      'うどん', 'そば', 'パスタ', 'ラーメン', 'カレー', '豚', '鶏', '牛',
      'キャベツ', 'レタス', 'トマト', 'にんじん', 'じゃがいも', 'たまねぎ',
      'りんご', 'バナナ', 'みかん', '納豆', '豆', 'こんにゃく', 'しらたき',
    ];
    const daily = [
      'シャンプー', 'リンス', 'コンディショナー', '洗剤', 'ティッシュ',
      'トイレ', 'ペーパー', '歯ブラシ', '歯磨', 'ハンドソープ', '石鹸',
      '柔軟剤', '漂白', 'ゴミ袋', 'ラップ', 'アルミホイル', 'スポンジ',
      '綿棒', '生理', 'おむつ', 'ナプキン', '除菌', '消毒', 'マスク',
      '電池', '洗顔', '化粧', 'クリーム', 'ローション',
    ];

    for (final kw in food) {
      if (name.contains(kw)) return '食品';
    }
    for (final kw in daily) {
      if (name.contains(kw)) return '日用品';
    }
    return 'その他';
  }
}
