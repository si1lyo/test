import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class RecognizedItem {
  String name;
  String type;
  String genre;
  double price;
  int quantity;
  int? aiEstimatedDays;

  RecognizedItem({
    required this.name,
    this.type = '',
    required this.genre,
    this.price = 0,
    this.quantity = 1,
    this.aiEstimatedDays,
  });
}

class ReceiptResult {
  final String? date;
  final String? storeName;
  final double? total;
  final List<RecognizedItem> items;

  ReceiptResult({
    this.date,
    this.storeName,
    this.total,
    required this.items,
  });
}

class ReceiptRecognitionService {
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  static Future<Uint8List> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 800,
      minHeight: 800,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    return result ?? await file.readAsBytes();
  }

  static Future<ReceiptResult> recognizeReceipt(File imageFile) async {
    final bytes = await _compressImage(imageFile);
    final base64Image = base64Encode(bytes);
    const mediaType = 'image/jpeg';

    final callable = _functions.httpsCallable(
      'analyzeReceipt',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final result = await callable.call<Map<Object?, Object?>>({
      'imageBase64': base64Image,
      'mediaType': mediaType,
    });

    final data = Map<String, dynamic>.from(result.data);
    final itemsJson = data['items'] as List<dynamic>? ?? [];

    final items = itemsJson.map((e) {
      final item = Map<String, dynamic>.from(e as Map);
      return RecognizedItem(
        name: (item['name'] as String?) ?? '',
        type: '',
        genre: (item['genre'] as String?) ?? 'その他',
        price: (item['price'] as num?)?.toDouble() ?? 0,
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        aiEstimatedDays: (item['estimatedDays'] as num?)?.toInt(),
      );
    }).toList();

    return ReceiptResult(
      date: data['date'] as String?,
      storeName: data['store_name'] as String?,
      total: (data['total'] as num?)?.toDouble(),
      items: items,
    );
  }
}
