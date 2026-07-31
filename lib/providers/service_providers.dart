import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/flag_service.dart';
import '../services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final flagServiceProvider = Provider<FlagService>((ref) => FlagService());

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);
