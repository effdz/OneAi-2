import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseRecord {
  final String id;
  final Map<String, dynamic> data;
  final DateTime created;
  final DateTime updated;

  PocketBaseRecord({
    required this.id,
    required this.data,
    required this.created,
    required this.updated,
  });

  factory PocketBaseRecord.fromJson(Map<String, dynamic> json) {
    return PocketBaseRecord(
      id: json['id'] ?? '',
      data: json,
      created: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updated: DateTime.parse(json['updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => data;
}

class PocketBaseAuth {
  String? token;
  PocketBaseRecord? model;
  bool get isValid => token != null && token!.isNotEmpty;

  void clear() {
    token = null;
    model = null;
  }

  void save(String authToken, PocketBaseRecord user) {
    token = authToken;
    model = user;
  }
}

class PocketBaseCollection {
  final String name;
  final PocketBaseClient client;

  PocketBaseCollection(this.name, this.client);

  Future<List<PocketBaseRecord>> getList({
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'perPage': perPage.toString(),
      };

      if (filter != null) queryParams['filter'] = filter;
      if (sort != null) queryParams['sort'] = sort;

      final uri = Uri.parse('${client.baseUrl}/api/collections/$name/records')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: client._getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        return items.map((item) => PocketBaseRecord.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting records: $e');
    }
  }

  Future<PocketBaseRecord> getOne(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${client.baseUrl}/api/collections/$name/records/$id'),
        headers: client._getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PocketBaseRecord.fromJson(data);
      } else {
        throw Exception('Failed to get record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting record: $e');
    }
  }

  Future<PocketBaseRecord> create(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${client.baseUrl}/api/collections/$name/records'),
        headers: client._getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return PocketBaseRecord.fromJson(responseData);
      } else {
        throw Exception('Failed to create record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating record: $e');
    }
  }

  Future<PocketBaseRecord> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('${client.baseUrl}/api/collections/$name/records/$id'),
        headers: client._getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PocketBaseRecord.fromJson(responseData);
      } else {
        throw Exception('Failed to update record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating record: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${client.baseUrl}/api/collections/$name/records/$id'),
        headers: client._getHeaders(),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting record: $e');
    }
  }
}

class PocketBaseHealth {
  final PocketBaseClient client;

  PocketBaseHealth(this.client);

  Future<Map<String, dynamic>> check() async {
    try {
      final response = await http.get(
        Uri.parse('${client.baseUrl}/api/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Health check error: $e');
    }
  }
}

class PocketBaseClient {
  final String baseUrl;
  final PocketBaseAuth authStore = PocketBaseAuth();
  late final PocketBaseHealth health;

  PocketBaseClient(this.baseUrl) {
    health = PocketBaseHealth(this);
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authStore.isValid) {
      headers['Authorization'] = 'Bearer ${authStore.token}';
    }

    return headers;
  }

  PocketBaseCollection collection(String name) {
    return PocketBaseCollection(name, this);
  }

  Future<PocketBaseRecord> authWithPassword(
      String collection,
      String identity,
      String password,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/collections/$collection/auth-with-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': identity,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = PocketBaseRecord.fromJson(data['record']);
        authStore.save(data['token'], user);

        // Save auth data to local storage
        await _saveAuthData(data['token'], data['record']);

        return user;
      } else {
        throw Exception('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Auth error: $e');
    }
  }

  Future<PocketBaseRecord> authRefresh() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/collections/users/auth-refresh'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = PocketBaseRecord.fromJson(data['record']);
        authStore.save(data['token'], user);

        // Save refreshed auth data
        await _saveAuthData(data['token'], data['record']);

        return user;
      } else {
        throw Exception('Auth refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Auth refresh error: $e');
    }
  }

  Future<void> authLogout() async {
    try {
      if (authStore.isValid) {
        await http.post(
          Uri.parse('$baseUrl/api/collections/users/auth-logout'),
          headers: _getHeaders(),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      authStore.clear();
      await _clearAuthData();
    }
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pb_auth_token', token);
      await prefs.setString('pb_auth_user', jsonEncode(user));
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pb_auth_token');
      await prefs.remove('pb_auth_user');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  Future<void> loadAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('pb_auth_token');
      final userJson = prefs.getString('pb_auth_user');

      if (token != null && userJson != null) {
        final userData = jsonDecode(userJson);
        final user = PocketBaseRecord.fromJson(userData);
        authStore.save(token, user);
        print('✅ Auth data loaded from storage');
      }
    } catch (e) {
      print('Error loading auth data: $e');
    }
  }
}
