import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/phone.dart';

class ApiResponse<T> {
  final String status;
  final String message;
  final T data;

  ApiResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return ApiResponse(
      status: json['status'],
      message: json['message'],
      data: fromJson(json['data']),
    );
  }
}

class PhoneService {
  static const String baseUrl = 'https://resp-api-three.vercel.app';

  Future<List<Phone>> fetchPhones() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/phones'));
      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          (data) => (data as List).map((json) => Phone.fromJson(json)).toList(),
        );
        if (apiResponse.status == 'success') {
          return apiResponse.data;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to load phones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load phones: $e');
    }
  }

  Future<Phone> fetchPhoneDetail(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/phone/$id'));
      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          (data) => Phone.fromJson(data),
        );
        if (apiResponse.status == 'success') {
          return apiResponse.data;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to load phone detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load phone detail: $e');
    }
  }

  Future<bool> createPhone({
    required String name,
    required String brand,
    required String price,
    required String specification,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/phone'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'brand': brand,
          'price': int.parse(price),
          'specification': specification,
        }),
      );
      if (response.statusCode == 201) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          (data) => data,
        );
        return apiResponse.status == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Failed to create phone: $e');
    }
  }

  Future<bool> updatePhone({
    required int id,
    required String name,
    required String brand,
    required String price,
    required String specification,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/phone/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'brand': brand,
          'price': int.parse(price),
          'specification': specification,
        }),
      );
      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          (data) => data,
        );
        return apiResponse.status == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Failed to update phone: $e');
    }
  }

  Future<bool> deletePhone(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/phone/$id'));
      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(
          json.decode(response.body),
          (data) => data,
        );
        return apiResponse.status == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete phone: $e');
    }
  }
}
