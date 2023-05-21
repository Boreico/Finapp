import 'dart:convert';
import 'package:http/http.dart' as http;

class MonobankApi {

  // Fetching exchange rates from Monobank API
  Future<List> fetchExchangeRates() async {
    final response = await http.get(
      Uri.parse('https://api.monobank.ua/bank/currency'),
    );
    // Checking if the response is successful
    if (response.statusCode == 200) {
      // Filtering the response to get only USD and EUR rates
      List jsonResponse = json.decode(response.body);
      List<int> currencyCodes = [840, 978];
      List filteredRates = jsonResponse.where((rate) {
        int currencyCodeA = rate['currencyCodeA'];
        int currencyCodeB = rate['currencyCodeB'];
        return currencyCodes.contains(currencyCodeA) && currencyCodeB == 980;
      }).toList();

      return filteredRates;
      // throw Exception('Failed to load exchange rates');
    } else {
      throw Exception('Failed to load exchange rates');
    }
  }
}
