import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'app_language_provider.dart';

/// Từ điển đa ngôn ngữ chuẩn Okamura Golfzon (Tiếng Việt, English, 한국어, 日本語)
class AppTranslations {
  static const Map<String, Map<String, String>> values = {
    // Tiếng Việt (Mặc định)
    'vi': {
      // Điều hướng đáy
      'nav_home': 'Trang chủ',
      'nav_booking': 'Đặt phòng',
      'nav_services': 'Dịch vụ',
      'nav_my_bookings': 'Vé của tôi',

      // Header & Chế độ
      'brand_name': 'OKAMURA GOLFZON',
      'brand_subtitle': 'Tổ hợp Golf 3D & Lounge cao cấp',
      'admin_mode': 'QUẢN TRỊ VIÊN',
      'view_user_app': 'Xem App Khách',
      'ai_caddie': 'Trợ Lý AI Caddie',
      'ai_caddie_sub': 'Trực tuyến 24/7 • Gemini AI',
      'ai_ask_hint': 'Hỏi AI Caddie về phòng chơi, giá vé, menu...',
      'live_status': 'TRỰC TUYẾN',
      'rooms_ready': 'phòng sẵn sàng',

      // Trang chủ
      'home_hero_tag': 'CÔNG NGHỆ GOLFZON TWOVISION NX 3D HÀNG ĐẦU',
      'home_hero_title': 'Trải Nghiệm Đẳng Cấp Golf Quốc Tế',
      'home_hero_desc': 'Mô phỏng chân thực hơn 200 sân golf danh tiếng thế giới với đồ họa Unreal Engine 5 đỉnh cao.',
      'book_bay_now': 'ĐẶT BAY NGAY',
      'view_schedule': 'Xem lịch đặt',
      'ask_ai_caddie_title': 'HỎI AI CADDIE',
      'ask_ai_caddie_desc': 'Tư vấn chọn Bay, giờ chơi 18 hố & menu quầy Bar 24/7',
      'chat_now': 'Chat ngay',
      'room_list_title': 'DANH SÁCH PHÒNG CHƠI',
      'filter_all': 'Tất cả',

      // Đặt phòng
      'booking_screen_title': 'ĐẶT PHÒNG GOLFZON',
      'step_1_date': 'Ngày chơi',
      'step_2_time': 'Khung giờ',
      'step_3_room': 'Chọn phòng',
      'step_4_info': 'Nhập TT',
      'step_4_guest_title': 'BƯỚC 4: THÔNG TIN KHÁCH HÀNG',
      'step_4_guest_sub': 'Dành cho khách vãng lai đặt phòng trực tuyến',
      'guest_booking_notice': 'Bạn đang đặt phòng với tư cách Khách vãng lai (không tích lũy điểm VIP)',
      'guest_banner_detail': 'Vui lòng nhập chính xác họ tên và số điện thoại để nhận mã PIN mở phòng & vé điện tử.',
      'login_now': 'Đăng nhập ngay →',
      'duration_label': 'Thời lượng chơi:',
      'players_label': 'Số lượng Golfer:',
      'guest_name_label': 'Họ và tên quý khách (*)',
      'guest_phone_label': 'Số điện thoại nhận mã vé (*)',
      'guest_email_label': 'Email nhận vé điện tử & hóa đơn (*)',
      'notes_label': 'Yêu cầu đặc biệt (gậy, đồ uống, caddie...)',
      'confirm_booking': 'XÁC NHẬN GIỮ CHỖ',
      'change_room': 'Đổi phòng',
      'back_to_rooms': 'Quay lại bước chọn phòng',
      'available': 'Còn trống',
      'booked': 'Đã đặt',
      'maintenance': 'Bảo trì',
      'select_this_room': 'Chọn phòng',
      'book_now_btn': 'Đặt ngay',

      // Dịch vụ F&B
      'services_screen_title': 'ORDER DỊCH VỤ & TIỆN ÍCH',
      'delivery_to_room': 'Giao tới phòng:',
      'tab_drinks': 'Đồ uống & Bar',
      'tab_food': 'Ẩm thực Lounge',
      'tab_clubs': 'Thuê Gậy TaylorMade',
      'tab_caddie': 'HLV & Caddie',
      'order_summary': 'món',
      'send_order': 'GỬI ORDER BẾP & BAR',

      // Vé của tôi
      'my_bookings_title': 'VÉ & LỊCH ĐẶT PHÒNG CỦA TÔI',
      'active_tickets': 'Vé đang có hiệu lực',
      'ticket_code': 'Mã PIN mở Bay:',
      'cancel_booking': 'Hủy đặt phòng',
      'no_bookings': 'Bạn chưa có lịch đặt phòng nào',

      // Xác thực
      'auth_title': 'OKAMURA GOLF LOUNGE',
      'auth_subtitle': 'Hội Viên & Đặt Chỗ Trực Tuyến',
      'auth_login': 'Đăng Nhập',
      'auth_register': 'Đăng Ký Hội Viên',
      'auth_guest_continue': 'Tiếp tục mà không cần đăng nhập',
      'auth_phone_hint': 'Số điện thoại',
      'auth_pass_hint': 'Mật khẩu',
      'auth_logout': 'Đăng xuất',
    },

    // English (International)
    'en': {
      // Navigation
      'nav_home': 'Home',
      'nav_booking': 'Book Bay',
      'nav_services': 'Services',
      'nav_my_bookings': 'My Bookings',

      // Header & Mode
      'brand_name': 'OKAMURA GOLFZON',
      'brand_subtitle': 'Luxury Indoor 3D Golf & Lounge',
      'admin_mode': 'ADMINISTRATOR',
      'view_user_app': 'View User App',
      'ai_caddie': 'AI Caddie Assistant',
      'ai_caddie_sub': '24/7 Online • Gemini AI',
      'ai_ask_hint': 'Ask AI Caddie about bays, rates, menu...',
      'live_status': 'ONLINE',
      'rooms_ready': 'bays ready',

      // Home
      'home_hero_tag': 'WORLD-LEADING GOLFZON TWOVISION NX 3D',
      'home_hero_title': 'World-Class Luxury Golf Experience',
      'home_hero_desc': 'Realistic simulation of 200+ world-famous golf courses powered by Unreal Engine 5 graphics.',
      'book_bay_now': 'BOOK BAY NOW',
      'view_schedule': 'View Schedule',
      'ask_ai_caddie_title': 'ASK AI CADDIE',
      'ask_ai_caddie_desc': 'Bay advice, 18-hole duration & F&B menu recommendations 24/7',
      'chat_now': 'Chat Now',
      'room_list_title': 'GOLFZON SIMULATOR BAYS',
      'filter_all': 'All',

      // Booking
      'booking_screen_title': 'BOOK GOLFZON BAY',
      'step_1_date': 'Date',
      'step_2_time': 'Time Slot',
      'step_3_room': 'Select Bay',
      'step_4_info': 'Contact Info',
      'step_4_guest_title': 'STEP 4: GUEST CONTACT INFORMATION',
      'step_4_guest_sub': 'For guest online booking without account',
      'guest_booking_notice': 'You are booking as a Guest (no VIP loyalty points)',
      'guest_banner_detail': 'Please provide accurate name and phone number to receive your bay PIN code and confirmation.',
      'login_now': 'Log in now →',
      'duration_label': 'Play Duration:',
      'players_label': 'Golfer Count:',
      'guest_name_label': 'Full Name (*)',
      'guest_phone_label': 'Phone Number (*)',
      'guest_email_label': 'E-ticket & Invoice Email (*)',
      'notes_label': 'Special Requests (clubs, drinks, caddie...)',
      'confirm_booking': 'CONFIRM RESERVATION',
      'change_room': 'Change Bay',
      'back_to_rooms': 'Back to Bay selection',
      'available': 'Available',
      'booked': 'Booked',
      'maintenance': 'Maintenance',
      'select_this_room': 'Select Bay',
      'book_now_btn': 'Book Now',

      // F&B Services
      'services_screen_title': 'IN-BAY SERVICE & F&B ORDER',
      'delivery_to_room': 'Deliver to bay:',
      'tab_drinks': 'Beverage & Bar',
      'tab_food': 'Lounge Culinary',
      'tab_clubs': 'TaylorMade Rental',
      'tab_caddie': 'PGA Coach & Caddie',
      'order_summary': 'items',
      'send_order': 'SUBMIT ORDER TO BAR & KITCHEN',

      // My Bookings
      'my_bookings_title': 'MY TICKETS & BOOKINGS',
      'active_tickets': 'Active Reservations',
      'ticket_code': 'Bay PIN Code:',
      'cancel_booking': 'Cancel Reservation',
      'no_bookings': 'You have no active reservations',

      // Auth
      'auth_title': 'OKAMURA GOLF LOUNGE',
      'auth_subtitle': 'Membership & Online Reservation',
      'auth_login': 'Sign In',
      'auth_register': 'Register Membership',
      'auth_guest_continue': 'Continue without sign-in',
      'auth_phone_hint': 'Phone Number',
      'auth_pass_hint': 'Password',
      'auth_logout': 'Sign Out',
    },

    // 한국어 (Korean)
    'ko': {
      // 내비게이션
      'nav_home': '홈',
      'nav_booking': '예약하기',
      'nav_services': '서비스',
      'nav_my_bookings': '내 예약',

      // 헤더 & 모드
      'brand_name': '오카무라 골프존',
      'brand_subtitle': '프리미엄 3D 실내 스크린골프 라운지',
      'admin_mode': '관리자 모드',
      'view_user_app': '고객 앱 보기',
      'ai_caddie': 'AI 캐디 어시스턴트',
      'ai_caddie_sub': '24시간 온라인 • Gemini AI',
      'ai_ask_hint': '방 선택, 이용 요금, 메뉴를 AI 캐디에게 물어보세요...',
      'live_status': '운영중',
      'rooms_ready': '개 룸 준비 완료',

      // 홈 화면
      'home_hero_tag': '세계 최고 수준 골프존 투비전 NX 3D',
      'home_hero_title': '품격 있는 프리미엄 골프 라이프',
      'home_hero_desc': '언리얼 엔진 5 그래픽으로 구현된 전 세계 200여 개 명문 코스를 생생하게 경험하세요.',
      'book_bay_now': '지금 예약하기',
      'view_schedule': '예약 현황',
      'ask_ai_caddie_title': '오카무라 AI 캐디에게 문의',
      'ask_ai_caddie_desc': '룸 추천, 18홀 예상시간 및 바 메뉴 안내 24시간 지원',
      'chat_now': '채팅 시작',
      'room_list_title': '스크린골프 룸 목록',
      'filter_all': '전체',

      // 예약
      'booking_screen_title': '골프존 룸 예약',
      'step_1_date': '이용 날짜',
      'step_2_time': '시간대',
      'step_3_room': '룸 선택',
      'step_4_info': '고객 정보',
      'step_4_guest_title': '4단계: 비회원 예약자 정보 입력',
      'step_4_guest_sub': '계정 없이 온라인 간편 예약',
      'guest_booking_notice': '현재 비회원으로 예약 중입니다 (VIP 포인트 미적립)',
      'guest_banner_detail': '입실 PIN 번호 및 전자 예약 티켓을 받으실 연락처를 정확히 입력해주세요.',
      'login_now': '로그인하기 →',
      'duration_label': '이용 시간:',
      'players_label': '플레이어 인원:',
      'guest_name_label': '예약자 성함 (*)',
      'guest_phone_label': '예약 확인 전화번호 (*)',
      'guest_email_label': '전자 티켓 수신 이메일 (*)',
      'notes_label': '특별 요청사항 (클럽, 음료, 캐디 등)',
      'confirm_booking': '예약 확정하기',
      'change_room': '룸 변경',
      'back_to_rooms': '룸 선택으로 돌아가기',
      'available': '예약 가능',
      'booked': '예약 마감',
      'maintenance': '점검중',
      'select_this_room': '룸 선택',
      'book_now_btn': '바로 예약',

      // F&B 서비스
      'services_screen_title': '룸 딜리버리 & F&B 주문',
      'delivery_to_room': '배달 대상 룸:',
      'tab_drinks': '음료 & 바',
      'tab_food': '라운지 요리',
      'tab_clubs': '테일러메이드 렌탈',
      'tab_caddie': 'PGA 레슨 & 캐디',
      'order_summary': '개 메뉴',
      'send_order': '주문 전송하기',

      // 내 예약
      'my_bookings_title': '내 티켓 및 예약 내역',
      'active_tickets': '현재 유효한 예약',
      'ticket_code': '룸 입장 PIN 번호:',
      'cancel_booking': '예약 취소',
      'no_bookings': '예약된 내역이 없습니다',

      // 인증
      'auth_title': '오카무라 골프 라운지',
      'auth_subtitle': 'VIP 회원 및 온라인 예약',
      'auth_login': '로그인',
      'auth_register': '회원가입',
      'auth_guest_continue': '로그인 없이 계속하기',
      'auth_phone_hint': '전화번호',
      'auth_pass_hint': '비밀번호',
      'auth_logout': '로그아웃',
    },

    // 日本語 (Japanese)
    'ja': {
      // ナビゲーション
      'nav_home': 'ホーム',
      'nav_booking': 'ブース予約',
      'nav_services': 'サービス',
      'nav_my_bookings': '予約一覧',

      // ヘッダー & モード
      'brand_name': 'オカムラ ゴルフゾン',
      'brand_subtitle': '高級インドア3Dゴルフ＆ラウンジ',
      'admin_mode': '管理者モード',
      'view_user_app': 'ユーザー画面',
      'ai_caddie': 'AIキャディ',
      'ai_caddie_sub': '24時間対応 • Gemini AI',
      'ai_ask_hint': 'ブース選び、料金、メニューについてAIに質問...',
      'live_status': '営業中',
      'rooms_ready': '部屋 準備完了',

      // ホーム画面
      'home_hero_tag': '世界最高峰 GOLFZON TWOVISION NX 3D',
      'home_hero_title': '上質なプレミアムゴルフ体験',
      'home_hero_desc': 'アンリアルエンジン5グラフィックで再現された世界の名門200以上のコースを体験。',
      'book_bay_now': '今すぐ予約',
      'view_schedule': '予約スケジュール',
      'ask_ai_caddie_title': 'AIキャディに相談',
      'ask_ai_caddie_desc': 'ブース提案、18ホール所要時間、飲食メニュー案内 24時間対応',
      'chat_now': 'チャット開始',
      'room_list_title': 'シミュレーターブース一覧',
      'filter_all': 'すべて',

      // 予約
      'booking_screen_title': 'ブース予約',
      'step_1_date': 'プレー日',
      'step_2_time': '時間帯',
      'step_3_room': 'ブース選択',
      'step_4_info': 'お客様情報',
      'step_4_guest_title': 'ステップ4: ゲスト連絡先入力',
      'step_4_guest_sub': 'アカウント登録なしのオンライン予約',
      'guest_booking_notice': 'ゲストとして予約しています（VIPポイント対象外）',
      'guest_banner_detail': '入室用PINコードおよび電子チケット送信用に正しいご連絡先を入力してください。',
      'login_now': 'ログインする →',
      'duration_label': 'プレー時間:',
      'players_label': 'プレイヤー人数:',
      'guest_name_label': 'ご氏名 (*)',
      'guest_phone_label': 'お電話番号 (*)',
      'guest_email_label': '電子チケット送信用メール (*)',
      'notes_label': 'ご要望（クラブ、お飲み物、キャディ等）',
      'confirm_booking': '予約を確定する',
      'change_room': 'ブース変更',
      'back_to_rooms': 'ブース選択に戻る',
      'available': '予約可能',
      'booked': '予約済',
      'maintenance': '点検中',
      'select_this_room': 'このブースを選択',
      'book_now_btn': '今すぐ予約',

      // サービス
      'services_screen_title': 'ルームオーダー＆F&Bサービス',
      'delivery_to_room': 'お届け先ブース:',
      'tab_drinks': 'ドリンク＆バー',
      'tab_food': 'ラウンジ料理',
      'tab_clubs': 'テーラーメイドレンタル',
      'tab_caddie': 'PGAレッスン＆キャディ',
      'order_summary': '品',
      'send_order': 'バー＆厨房へオーダー送信',

      // 予約一覧
      'my_bookings_title': '予約チケット一覧',
      'active_tickets': '有効な予約',
      'ticket_code': '入室PINコード:',
      'cancel_booking': '予約をキャンセル',
      'no_bookings': '予約中のチケットはありません',

      // 認証
      'auth_title': 'オカムラ ゴルフラウンジ',
      'auth_subtitle': '会員ログイン＆オンライン予約',
      'auth_login': 'ログイン',
      'auth_register': '会員登録',
      'auth_guest_continue': 'ログインせずに続ける',
      'auth_phone_hint': 'お電話番号',
      'auth_pass_hint': 'パスワード',
      'auth_logout': 'ログアウト',
    },
  };
}

/// Tiện ích mở rộng lấy bản dịch trực tiếp qua BuildContext: `context.tr('nav_home')`
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    try {
      final lang = Provider.of<AppLanguageProvider?>(this, listen: true)?.languageCode ?? 'vi';
      final dict = AppTranslations.values[lang] ?? AppTranslations.values['vi']!;
      return dict[key] ?? AppTranslations.values['vi']?[key] ?? key;
    } catch (_) {
      return AppTranslations.values['vi']?[key] ?? key;
    }
  }
}
