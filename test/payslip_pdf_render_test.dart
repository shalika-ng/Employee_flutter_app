import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

Uint8List _samplePdf() {
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 4 0 R >>',
    '<< /Length 0 >>\nstream\n\nendstream',
  ];
  var content = '%PDF-1.4\n';
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(utf8.encode(content).length);
    content += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final xref = utf8.encode(content).length;
  content += 'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n';
  for (final offset in offsets) {
    content += '${offset.toString().padLeft(10, '0')} 00000 n \n';
  }
  content +=
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xref\n%%EOF\n';
  return Uint8List.fromList(utf8.encode(content));
}

void main() {
  test('renders an in-memory PDF page using the real viewer engine', () async {
    final document = await PdfDocument.openData(
      _samplePdf(),
      sourceName: 'preview-test',
    );
    try {
      expect(document.pages, hasLength(1));
      final page = document.pages.first;
      final image = await page.render(width: 200, height: 200);
      expect(image, isNotNull);
      expect(image!.width, 200);
      expect(image.height, 200);
      image.dispose();
    } finally {
      await document.dispose();
    }
  });
}
