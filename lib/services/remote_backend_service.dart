import 'user_data_service.dart';

class RemoteBackendService implements UserDataService {
  @override
  Future<void> init() async {
    // Hook Firebase/Supabase client initialization here later.
  }

  @override
  Future<UserLibraryData> loadLibrary(String email) {
    throw UnimplementedError('Remote user data backend is not configured yet.');
  }

  @override
  Future<void> saveLibrary(String email, UserLibraryData data) {
    throw UnimplementedError('Remote user data backend is not configured yet.');
  }
}
