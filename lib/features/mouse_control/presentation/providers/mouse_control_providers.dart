import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../connection/presentation/providers/connection_providers.dart';
import '../../domain/usecases/send_mouse_command.dart';

final sendMouseCommandUseCaseProvider = Provider<SendMouseCommand>((ref) {
  return SendMouseCommand(ref.watch(connectionRepositoryProvider));
});
