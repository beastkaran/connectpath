import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ─── Change this to your deployed backend URL ─────────────────────────────
  static const String baseUrl = 'http://127.0.0.1:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator

  String? _token;
  String? _adminToken;

  // ─── Token management ────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? profession,
    String? course,
    String? department,
    int? graduationYear,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        if (profession != null) 'profession': profession,
        if (course != null) 'course': course,
        if (department != null) 'department': department,
        if (graduationYear != null) 'graduation_year': graduationYear,
      }),
    );
    _check(response);
    return jsonDecode(response.body);
  }

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    _check(response);
    final data = jsonDecode(response.body);
    await saveToken(data['access_token']);
    return data['access_token'];
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/me'),
      headers: await _authHeaders(),
    );
    _check(response);
    return jsonDecode(response.body);
  }

  Future<void> updateProfileImage(String imageUrl) async {
  final response = await http.put(
    Uri.parse('$baseUrl/profile/image'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    },
    body: jsonEncode({'profile_image_url': imageUrl}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to update profile image');
  }
}

  Future<void> updateProfile({
    String? name,
    String? profession,
    String? course,
    String? department,
    int? graduationYear,
    String? skills,
    String? bio,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/me'),
      headers: await _authHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (profession != null) 'profession': profession,
        if (course != null) 'course': course,
        if (department != null) 'department': department,
        if (graduationYear != null) 'graduation_year': graduationYear,
        if (skills != null) 'skills': skills,
        if (bio != null) 'bio': bio,
      }),
    );
    _check(response);
  }

  Future<Map<String, dynamic>> toggleVisibility() async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/toggle-visibility'),
      headers: await _authHeaders(),
    );
    _check(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: await _authHeaders(),
    );
    _check(response);
    return jsonDecode(response.body);
  }

  // ─── Location ─────────────────────────────────────────────────────────────

  Future<void> updateLocation(double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/update'),
      headers: await _authHeaders(),
      body: jsonEncode({'latitude': lat, 'longitude': lng}),
    );
    _check(response);
  }

  Future<List<Map<String, dynamic>>> getCrossedPaths() async {
    final response = await http.get(
      Uri.parse('$baseUrl/location/crossed-paths'),
      headers: await _authHeaders(),
    );
    _check(response);
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['crossed_paths']);
  }

  // ─── Connections ──────────────────────────────────────────────────────────

  Future<void> sendConnectionRequest(int receiverId, {String? message}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/connections/request'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'receiver_id': receiverId,
        if (message != null) 'message': message,
      }),
    );
    _check(response);
  }

  Future<List<Map<String, dynamic>>> getPendingConnections() async {
    final response = await http.get(
      Uri.parse('$baseUrl/connections/pending'),
      headers: await _authHeaders(),
    );
    _check(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['requests']);
  }

  Future<List<Map<String, dynamic>>> getAcceptedConnections() async {
    final response = await http.get(
      Uri.parse('$baseUrl/connections/accepted'),
      headers: await _authHeaders(),
    );
    _check(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['connections']);
  }

  Future<void> respondToConnection(int connectionId, bool accept) async {
    final response = await http.put(
      Uri.parse('$baseUrl/connections/$connectionId/respond?accept=$accept'),
      headers: await _authHeaders(),
    );
    _check(response);
  }

  // ─── Events ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/events'));
    _check(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<void> registerForEvent(int eventId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/register'),
      headers: await _authHeaders(),
    );
    _check(response);
  }

  Future<void> unregisterFromEvent(int eventId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$eventId/register'),
      headers: await _authHeaders(),
    );
    _check(response);
  }

  Future<Map<String, dynamic>> getEventAttendees(int eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/attendees'),
      headers: await _authHeaders(),
    );
    _check(response);
    return jsonDecode(response.body);
  }

  // ─── Alumni ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchAlumni({
    String? department,
    int? graduationYear,
    String? skill,
    String? name,
  }) async {
    final params = <String, String>{};
    if (department != null) params['department'] = department;
    if (graduationYear != null) params['graduation_year'] = graduationYear.toString();
    if (skill != null) params['skill'] = skill;
    if (name != null) params['name'] = name;

    final uri = Uri.parse('$baseUrl/alumni/search').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _authHeaders());
    _check(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['results']);
  }

  // ─── Matchmaking ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMatchSuggestions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/matchmaking/suggestions'),
      headers: await _authHeaders(),
    );
    _check(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['suggestions']);
  }

  // ─── Badges ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyBadges() async {
    final response = await http.get(
      Uri.parse('$baseUrl/badges/my'),
      headers: await _authHeaders(),
    );
    _check(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['badges']);
  }

  // ─── Error handling ───────────────────────────────────────────────────────

  void _check(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        message = body['detail'] ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
