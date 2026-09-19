import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DateFormat throws LocaleDataException for non-English locales (e.g. 'tr'
  // month names) until this runs once.
  await initializeDateFormatting();
  runApp(const WingmarkApp());
}
