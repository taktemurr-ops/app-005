import 'package:flutter_test/flutter_test.dart';
import 'package:uyg_kalori_sayaci/uyg_kalori_sayaci.dart';

void main() {
  test('33 dilde ad ve açıklama, doğru kimlik', () {
    expect(kaloriSayaciTool.id, kaloriSayaciId);
    expect(kaloriSayaciTool.title.length, 33);
    expect(kaloriSayaciTool.tagline.length, 33);
  });
}
