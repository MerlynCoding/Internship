import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> predictEfficiency({
  required double temperature,
  required double humidity,
  required double voltage,
  required double current,
  required int hour,
}) async {
  final url = Uri.parse(
    'https://your-app-name.onrender.com/predict',
  ); // 🔁 Replace this!

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'temperature': temperature,
      'humidity': humidity,
      'voltage': voltage,
      'current': current,
      'hour': hour,
    }),
  );

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return json['efficiency'];
  } else {
    throw Exception('Failed to get prediction: ${response.body}');
  }
}
