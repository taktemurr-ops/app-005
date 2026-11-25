/// Kalori Sayacı · Calorie Counter
///
/// Çevrimdışı besin tablosuyla günlük. Sağlık ve Spor merkez uygulamasında yer alır; gerçek
/// uygulama ortak motordadır (saglik_motoru), çatı studio_core/apps.
library;

import 'package:saglik_motoru/saglik_motoru.dart';
import 'package:studio_core/apps/apps.dart';

const String kaloriSayaciId = 'uyg-kalori-sayaci';

/// Merkezin kullandığı araç tanımı (33 dilde ad ve açıklama).
final AppTool kaloriSayaciTool = saglikTool(kaloriSayaciId);
