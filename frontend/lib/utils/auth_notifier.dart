import 'package:flutter/foundation.dart';

/// GoRouter bu notifier'ı dinler.
/// 401 alınınca increment edilir → router redirect yeniden çalışır → /login'e gider.
final authRefreshNotifier = ValueNotifier<int>(0);
