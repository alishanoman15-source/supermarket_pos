import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Shares raw bytes through the platform share sheet — CSV exports (SPEC §64),
/// receipt PDFs (SPEC §40) and ESC/POS tickets (SPEC §39).
Future<void> shareBytesFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: mimeType,
          name: fileName,
        ),
      ],
      title: fileName,
    ),
  );
}

/// Opens the platform share sheet with [csv] attached as `fileName`
/// (SPEC §64 export).
Future<void> shareCsvFile({required String fileName, required String csv}) =>
    shareBytesFile(fileName: fileName, bytes: utf8.encode(csv), mimeType: 'text/csv');

/// Shares an Excel workbook (SPEC §64 export).
Future<void> shareXlsxFile({required String fileName, required List<int> bytes}) =>
    shareBytesFile(
      fileName: fileName,
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

/// Shares a generated PDF (SPEC §40 digital receipt).
Future<void> sharePdfFile({required String fileName, required List<int> bytes}) =>
    shareBytesFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
    );

/// Shares an ESC/POS ticket for a raw thermal channel (SPEC §39).
Future<void> shareEscPosFile({required String fileName, required List<int> bytes}) =>
    shareBytesFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/octet-stream',
    );
