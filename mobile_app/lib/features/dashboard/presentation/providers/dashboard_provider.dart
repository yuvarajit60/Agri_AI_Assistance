import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../farms/data/farm.dart';
import '../../data/dashboard_data.dart';
import '../../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => GatewayDashboardRepository());

class DashboardController extends StateNotifier<AsyncValue<DashboardData?>> {
  DashboardController(this._repository) : super(const AsyncValue.data(null));

  final DashboardRepository _repository;

  Future<void> loadForFarm(Farm farm) async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.fetchDashboard(
        latitude: farm.latitude,
        longitude: farm.longitude,
        areaAcres: farm.areaAcres,
        soilReport: farm.soilReport,
      );
      state = AsyncValue.data(data);
    } on DioException catch (e, st) {
      state = AsyncValue.error(DashboardFetchException.fromDioException(e), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clears stale data — call after the farm it was fetched for is deleted
  /// so the dashboard doesn't keep showing a removed farm's report.
  void reset() {
    state = const AsyncValue.data(null);
  }
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, AsyncValue<DashboardData?>>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});
