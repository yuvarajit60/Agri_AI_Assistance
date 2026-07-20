import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/farm.dart';
import '../../data/farm_repository.dart';
import '../../data/farm_sync_repository.dart';

final farmRepositoryProvider = Provider<FarmRepository>((ref) => SharedPrefsFarmRepository());

class FarmsController extends StateNotifier<AsyncValue<List<Farm>>> {
  FarmsController(this._repository, this._sync, this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final FarmRepository _repository;
  final FarmSyncRepository _sync;
  final Ref _ref;

  String? get _backendUserId => _ref.read(authControllerProvider).user?.backendUserId;

  Future<void> _load() async {
    try {
      final farms = await _repository.loadFarms();
      state = AsyncValue.data(farms);
      _pullFromBackendIfLocalEmpty();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// One-time adoption of server data on a fresh install/device — if this
  /// device has no local farms but the backend has some for this phone
  /// number, pull them down. Deliberately simple (no merge/conflict
  /// resolution): once there's anything local, this is a no-op forever,
  /// since real multi-device sync is out of scope for now.
  Future<void> _pullFromBackendIfLocalEmpty() async {
    final ownerId = _backendUserId;
    if (ownerId == null) return;
    final current = state.value ?? [];
    if (current.isNotEmpty) return;
    final serverFarms = await _sync.fetchFarms(ownerId);
    if (serverFarms.isEmpty) return;
    state = AsyncValue.data(serverFarms);
    await _repository.saveFarms(serverFarms);
  }

  Future<void> addFarm(Farm farm) async {
    final current = state.value ?? [];
    final updated = [...current, farm];
    state = AsyncValue.data(updated);
    await _repository.saveFarms(updated);
    _syncCreate(farm);
  }

  /// Fire-and-forget: creates the farm server-side and, once it resolves,
  /// stamps the local copy with the server-assigned id so later edits sync
  /// as updates instead of duplicate creates.
  void _syncCreate(Farm farm) {
    final ownerId = _backendUserId;
    if (ownerId == null) return;
    _sync.createFarm(ownerId: ownerId, farm: farm).then((serverId) async {
      if (serverId == null) return;
      final current = state.value ?? [];
      final updated = [
        for (final f in current)
          if (f.id == farm.id) f.copyWith(serverId: serverId) else f,
      ];
      state = AsyncValue.data(updated);
      await _repository.saveFarms(updated);
    });
  }

  Future<void> updateFarm(Farm updated) async {
    final current = state.value ?? [];
    final newList = [
      for (final farm in current)
        if (farm.id == updated.id) updated else farm,
    ];
    state = AsyncValue.data(newList);
    await _repository.saveFarms(newList);

    if (updated.serverId != null) {
      _sync.updateFarm(updated); // fire-and-forget
    } else {
      _syncCreate(updated); // never synced (e.g. created while offline) — try now
    }
  }

  Future<void> removeFarm(String id) async {
    final current = state.value ?? [];
    Farm? removed;
    for (final f in current) {
      if (f.id == id) {
        removed = f;
        break;
      }
    }
    final updated = current.where((f) => f.id != id).toList();
    state = AsyncValue.data(updated);
    await _repository.saveFarms(updated);

    final serverId = removed?.serverId;
    if (serverId != null) {
      _sync.deleteFarm(serverId); // fire-and-forget
    }
  }

  /// Roughly ~100m at the equator — close enough to catch "added the same
  /// spot again" (repeated GPS reads of the same farm naturally vary by a
  /// few meters) without flagging genuinely separate nearby fields.
  static const _duplicateThresholdDegrees = 0.0009;

  Farm? findNearbyFarm(double latitude, double longitude) {
    final farms = state.value ?? [];
    for (final farm in farms) {
      final latClose = (farm.latitude - latitude).abs() < _duplicateThresholdDegrees;
      final lonClose = (farm.longitude - longitude).abs() < _duplicateThresholdDegrees;
      if (latClose && lonClose) return farm;
    }
    return null;
  }

  Farm? get mostRecent {
    final farms = state.value;
    if (farms == null || farms.isEmpty) return null;
    return farms.last;
  }
}

final farmsControllerProvider = StateNotifierProvider<FarmsController, AsyncValue<List<Farm>>>((ref) {
  return FarmsController(ref.watch(farmRepositoryProvider), ref.watch(farmSyncRepositoryProvider), ref);
});

/// The farm whose report is currently loaded on the dashboard. Explicitly
/// set whenever a farm's dashboard is fetched (add-farm flow, tapping a
/// farm in the list, the "View dashboard" menu action) — NOT simply "the
/// last farm in the list", which previously caused the dashboard's farm
/// banner and soil-report shortcut to silently point at a different farm
/// than the one whose data was actually being shown.
final selectedFarmIdProvider = StateProvider<String?>((ref) => null);

/// The farm currently shown on the dashboard — the explicitly selected
/// farm if one is set, otherwise falls back to the most recently added
/// farm (e.g. right after a fresh app launch, before anything's been
/// tapped yet).
final activeFarmProvider = Provider<Farm?>((ref) {
  final farms = ref.watch(farmsControllerProvider).value;
  if (farms == null || farms.isEmpty) return null;
  final selectedId = ref.watch(selectedFarmIdProvider);
  if (selectedId != null) {
    for (final farm in farms) {
      if (farm.id == selectedId) return farm;
    }
  }
  return farms.last;
});
