import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'farm.dart';

abstract class FarmRepository {
  Future<List<Farm>> loadFarms();
  Future<void> saveFarms(List<Farm> farms);
}

/// Farms live on-device only for now — there's no farm_registry backend
/// connection yet (it needs a Postgres+PostGIS instance this environment
/// doesn't have; see backend/README.md). Swap this for an HTTP-backed
/// implementation once that service is reachable.
class SharedPrefsFarmRepository implements FarmRepository {
  static const _key = 'farms_v1';

  @override
  Future<List<Farm>> loadFarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Farm.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveFarms(List<Farm> farms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(farms.map((f) => f.toJson()).toList()));
  }
}
