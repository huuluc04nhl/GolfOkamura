import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../shared_widgets/language_selector_pill.dart';

/// Màn hình Đăng Nhập & Đăng Ký tài khoản chuẩn Okamura Golfzon Lounge
/// Tự động phân quyền:
/// - Admin -> Chuyển vào Giao diện Quản trị Web/Desktop (/admin/dashboard)
/// - Khách hàng -> Chuyển vào Giao diện Mobile App (/home)
class AuthScreen extends StatefulWidget {
  final String? initialTab;
  const AuthScreen({super.key, this.initialTab});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Controllers Đăng nhập
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;
  bool _isLoggingIn = false;

  // Controllers Đăng ký
  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _regHandicapController = TextEditingController(text: '18.0');
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab == 'register' ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _regHandicapController.dispose();
    super.dispose();
  }

  void _showNotice(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? Colors.redAccent : const Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isError ? Colors.redAccent.withValues(alpha: 0.5) : AppColors.primaryGold.withValues(alpha: 0.5),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoggingIn = true);

    final provider = context.read<BookingProvider>();
    final result = await provider.login(
      usernameOrPhone: _loginUsernameController.text,
      password: _loginPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    if (result['success'] == true) {
      final role = result['role'] as String;
      final user = result['user'];
      _showNotice('Đăng nhập thành công! Xin chào ${user?.name ?? ""}');

      // PHÂN QUYỀN ĐIỀU HƯỚNG TỰ ĐỘNG
      if (role == 'admin') {
        context.go('/admin/dashboard');
      } else {
        context.go('/');
      }
    } else {
      _showNotice(result['message'] ?? 'Đăng nhập không thành công', isError: true);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (_regPasswordController.text != _regConfirmPasswordController.text) {
      _showNotice('Mật khẩu xác nhận không khớp!', isError: true);
      return;
    }

    setState(() => _isRegistering = true);

    final provider = context.read<BookingProvider>();
    final hcp = double.tryParse(_regHandicapController.text) ?? 18.0;

    final result = await provider.register(
      name: _regNameController.text,
      phone: _regPhoneController.text,
      email: _regEmailController.text,
      password: _regPasswordController.text,
      handicap: hcp,
    );

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (result['success'] == true) {
      _showNotice('Đăng ký tài khoản hội viên thành công! Bạn nhận được 100 điểm thưởng.');
      // Khách hàng đăng ký mới tự động chuyển vào giao diện Mobile
      context.go('/');
    } else {
      _showNotice(result['message'] ?? 'Đăng ký không thành công', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallMobile = screenWidth < 360;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Background họa tiết Golf & Gradient ánh kim
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0B1120),
                    Color(0xFF070B14),
                  ],
                ),
              ),
            ),
          ),

          // Bộ chuyển đổi ngôn ngữ quốc tế ở góc trên bên phải
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            right: 14,
            child: const LanguageSelectorPill(),
          ),

          // Nội dung chính
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile ? 12 : 20,
                vertical: isSmallMobile ? 16 : 30,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 32 : (isSmallMobile ? 16 : 22)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppColors.primaryGold.withValues(alpha: 0.08),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Logo & Branding
                      _buildHeader(isSmallMobile),
                      SizedBox(height: isSmallMobile ? 16 : 22),

                      // Tab selector: Đăng nhập / Đăng ký
                      _buildTabBar(isSmallMobile),
                      SizedBox(height: isSmallMobile ? 16 : 22),

                      // Tab views
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _tabController.index == 0
                            ? _buildLoginForm()
                            : _buildRegisterForm(),
                      ),

                      const SizedBox(height: 18),

                      // Tiếp tục mà không cần đăng nhập (Khách vãng lai)
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final provider = context.read<BookingProvider>();
                            await provider.continueAsGuest();
                            if (context.mounted) {
                              context.go('/');
                            }
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white60),
                          label: const Text(
                            'Tiếp tục mà không cần đăng nhập',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      children: [
        Container(
          width: isNarrow ? 52 : 64,
          height: isNarrow ? 52 : 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGold, AppColors.darkGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.sports_golf_rounded,
              size: isNarrow ? 28 : 34,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: isNarrow ? 10 : 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'OKAMURA GOLFZON LOUNGE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryGold,
              fontSize: isNarrow ? 16 : 18,
              fontWeight: FontWeight.w900,
              letterSpacing: isNarrow ? 0.8 : 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'HỆ THỐNG ĐIỀU HÀNH & ĐẶT BAY CAO CẤP',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isNarrow ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: isNarrow ? 0.4 : 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF090D18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE5C887),
              AppColors.primaryGold,
              Color(0xFFB58728),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: const [
          Tab(
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'ĐĂNG NHẬP',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Tab(
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'ĐĂNG KÝ HỘI VIÊN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tên đăng nhập / Số điện thoại
          _buildTextField(
            controller: _loginUsernameController,
            label: 'Tên đăng nhập / Số điện thoại / Email',
            hintText: 'admin hoặc 0912345678',
            icon: Icons.person_outline_rounded,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập tài khoản hoặc số điện thoại';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Mật khẩu
          _buildTextField(
            controller: _loginPasswordController,
            label: 'Mật khẩu',
            hintText: 'Nhập mật khẩu',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureLoginPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          // Nút Đăng nhập
          ElevatedButton(
            onPressed: _isLoggingIn ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
            child: _isLoggingIn
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ĐĂNG NHẬP HỆ THỐNG',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _regNameController,
            label: 'Họ và tên Golfer *',
            hintText: 'Ví dụ: Nguyễn Văn A',
            icon: Icons.badge_outlined,
            validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: _regPhoneController,
            label: 'Số điện thoại liên hệ *',
            hintText: 'Ví dụ: 0912345678',
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
              if (val.trim().length < 9) return 'Số điện thoại tối thiểu 9 số';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: _regEmailController,
            label: 'Email nhận thông báo (Không bắt buộc)',
            hintText: 'haosimla365@gmail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final isStack = constraints.maxWidth < 360;
              if (isStack) {
                return Column(
                  children: [
                    _buildTextField(
                      controller: _regPasswordController,
                      label: 'Mật khẩu *',
                      hintText: 'Tối thiểu 6 ký tự',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureRegPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRegPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                      ),
                      validator: (val) => val == null || val.length < 4 ? 'Tối thiểu 4 ký tự' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _regConfirmPasswordController,
                      label: 'Xác nhận mật khẩu *',
                      hintText: 'Nhập lại mật khẩu',
                      icon: Icons.lock_reset_rounded,
                      obscureText: _obscureRegConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRegConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureRegConfirmPassword = !_obscureRegConfirmPassword),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Vui lòng xác nhận' : null,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _regPasswordController,
                      label: 'Mật khẩu *',
                      hintText: 'Tối thiểu 6 ký tự',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureRegPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRegPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                      ),
                      validator: (val) => val == null || val.length < 4 ? 'Tối thiểu 4 ký tự' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _regConfirmPasswordController,
                      label: 'Xác nhận mật khẩu *',
                      hintText: 'Nhập lại mật khẩu',
                      icon: Icons.lock_reset_rounded,
                      obscureText: _obscureRegConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRegConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureRegConfirmPassword = !_obscureRegConfirmPassword),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Vui lòng xác nhận' : null,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: _regHandicapController,
            label: 'Điểm chấp Handicap (HCP)',
            hintText: 'Mặc định: 18.0',
            icon: Icons.golf_course_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isRegistering ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
            child: _isRegistering
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ĐĂNG KÝ HỘI VIÊN & NHẬN 100 ĐIỂM',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF131C31),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Color(0xFF1E293B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
