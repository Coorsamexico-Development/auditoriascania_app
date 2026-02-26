import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.180:3001';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      return data;
    } else {
      throw Exception('Error al iniciar sesión');
    }
  }

  static Future<int> createPickingList(String number) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/picking-lists'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'number': number}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Error al crear Picking List: ${response.statusCode}');
    }
  }

  static Future<void> uploadEvidences(int pickingListId, List<String> filePaths) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/evidences'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['pickingListId'] = pickingListId.toString();

    for (String path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }

    var response = await request.send();
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al subir evidencias: ${response.statusCode}');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
