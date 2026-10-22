import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/user_theme.dart';
import 'shared/providers/booking_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Bật định dạng URL web không có dấu '#' (/admin/dashboard thay vì /#/admin/dashboard)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(const GolfBookingApp());
}

class GolfBookingApp extends StatelessWidget {
  const GolfBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: UserTheme.theme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
