import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/admin_theme.dart';
import '../theme/user_theme.dart';
import '../../presentation/admin/screens/admin_bookings_screen.dart';
import '../../presentation/admin/screens/admin_dashboard_screen.dart';
import '../../presentation/admin/screens/admin_revenue_screen.dart';
import '../../presentation/admin/screens/admin_rooms_screen.dart';
import '../../presentation/admin/shells/admin_shell.dart';
import '../../presentation/auth/screens/auth_screen.dart';
import '../../presentation/user/screens/user_booking_screen.dart';
import '../../presentation/user/screens/user_home_screen.dart';
import '../../presentation/user/screens/user_my_bookings_screen.dart';
import '../../presentation/user/screens/user_services_screen.dart';
import '../../presentation/user/shells/user_shell.dart';

/// Bộ điều hướng trung tâm quản lý luồng Đăng nhập, User Mobile & Admin Web
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      // ==========================================
      // NHÁNH 0: ĐĂNG NHẬP / ĐĂNG KÝ HỆ THỐNG OKAMURA
      // ==========================================
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      // ==========================================
      // NHÁNH 1: USER MOBILE (THEME OKAMURA GOLFZON)
      // ==========================================
      ShellRoute(
        builder: (context, state, child) {
          return Theme(
            data: UserTheme.theme,
            child: UserShell(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const UserHomeScreen(),
          ),
          GoRoute(
            path: '/booking',
            builder: (context, state) => const UserBookingScreen(),
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) => const UserServicesScreen(),
          ),
          GoRoute(
            path: '/my-bookings',
            builder: (context, state) => const UserMyBookingsScreen(),
          ),
        ],
      ),

      // ==========================================
      // NHÁNH 2: ADMIN WEB (THEME FLUTTER WEB ADMIN)
      // ==========================================
      ShellRoute(
        builder: (context, state, child) {
          return Theme(
            data: AdminTheme.theme,
            child: AdminShell(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (context, state) => '/admin/dashboard',
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/bookings',
            builder: (context, state) => const AdminBookingsScreen(),
          ),
          GoRoute(
            path: '/admin/rooms',
            builder: (context, state) => const AdminRoomsScreen(),
          ),
          GoRoute(
            path: '/admin/revenue',
            builder: (context, state) => const AdminRevenueScreen(),
          ),
        ],
      ),
    ],
  );
}
