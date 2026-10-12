import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiHelper {
  static Future<http.Response> get(Uri uri) async {
    try {
      return await http.get(uri).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('Server is down. Please try again later.');
    } on TimeoutException {
      throw Exception('Server is down. Please try again later.');
    } on HandshakeException {
      throw Exception('Server is down. Please try again later.');
    } catch (_) {
      throw Exception('Server is down. Please try again later.');
    }
  }

  static Future<http.Response> post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      return await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('Server is down. Please try again later.');
    } on TimeoutException {
      throw Exception('Server is down. Please try again later.');
    } catch (_) {
      throw Exception('Server is down. Please try again later.');
    }
  }

  static Future<http.Response> put(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      return await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('Server is down. Please try again later.');
    } on TimeoutException {
      throw Exception('Server is down. Please try again later.');
    } catch (_) {
      throw Exception('Server is down. Please try again later.');
    }
  }

  static Future<http.Response> delete(Uri uri) async {
    try {
      return await http.delete(uri).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('Server is down. Please try again later.');
    } on TimeoutException {
      throw Exception('Server is down. Please try again later.');
    } catch (_) {
      throw Exception('Server is down. Please try again later.');
    }
  }
}
