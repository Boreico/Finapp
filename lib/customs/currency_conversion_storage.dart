import 'package:shared_preferences/shared_preferences.dart';

Future<bool> getCurrencyConversionEnabled() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('currencyConversionEnabled') ?? true;
}

Future<void> setCurrencyConversionEnabled(bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('currencyConversionEnabled', value);
}

