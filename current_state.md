# CURRENT STATE - GOLF BOOKING APP

> **Cập nhật lần cuối:** 14/09/2026  
> **Dự án:** Ứng dụng & Nền tảng Đặt sân / Phòng Golf (Golf Booking & Simulation Management)  
> **Khách hàng mục tiêu:** Khách chơi golf (User Mobile) & Ban quản lý trung tâm golf (Admin Web)

---

## 1. Tổng quan Dự án & Yêu cầu cốt lõi

- **Mục tiêu:** Xây dựng hệ thống đồng bộ trên **1 codebase Flutter duy nhất** phục vụ 2 luồng người dùng:
  1. **User (Mobile App / Responsive Web):** Dành cho khách đặt phòng golf mô phỏng 3D Screen Golf, tham khảo thiết kế và nhận diện từ thương hiệu **[Okamura Golfzon](https://okamuragolfzon.com/)**.
  2. **Admin (Web Dashboard):** Dành cho quản lý cơ sở, theo dõi tình trạng phòng theo thời gian thực (Real-time Room Matrix), duyệt đơn đặt, quản lý giá và doanh thu.
- **Yêu cầu kỹ thuật đặc thù:**
  - **Chung Database & Business Logic:** Dùng chung 1 tầng Models, Repositories, Services, Data Sources.
  - **Tách biệt Theme & UX:** 
    - User: Sang trọng, màu chủ đạo Champagne Gold (`#B69568`), Dark Charcoal, bo góc mềm mại, touch-friendly.
    - Admin: Giao diện web chuẩn quản trị, slate/navy kết hợp gold accent, mật độ thông tin cao (`VisualDensity.compact`), hỗ trợ chuột, phím, thanh cuộn rõ ràng.
  - **Khả năng Responsive sâu:**
    - Mobile đời cũ / màn hình nhỏ (width < 360px)
    - Mobile tiêu chuẩn & dòng màn hình gập dọc **Samsung Galaxy Z Flip** (tỷ lệ màn hình dài 21:9 - 22:9)
    - Màn hình gập mở rộng **Galaxy Z Fold / Tablet** (chia 2 cột / Master-Detail layout)
    - Desktop / Web Admin màn hình lớn (Sidebar co giãn, bảng dữ liệu đa cột).

---

## 2. Ngăn xếp Công nghệ (Tech Stack)

| Thành phần | Công nghệ / Thư viện | Mục đích |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.47.0 / Dart 3.13.0 | Đa nền tảng (iOS, Android, Web, Desktop) |
| **Routing** | `go_router` (>=14.8.0) | Quản lý định tuyến dạng cây, hỗ trợ URL Web không `#` và ShellRoute tách Theme |
| **Styling & Theme** | Material 3 + Google Fonts (`Inter` / `Roboto`) | Chuẩn nhận diện thương hiệu Okamura Golfzon |
| **Formatters** | `intl` | Định dạng tiền tệ VNĐ, ngày tháng tiếng Việt / Anh |
| **Icons** | `cupertino_icons` + Material Symbols | Bộ icon đa dạng cho thể thao, phòng ốc và quản trị |
| **State Management** | ChangeNotifier / Repository Pattern (Giai đoạn 1) -> Sẵn sàng nâng cấp Bloc/Riverpod | Quản lý trạng thái đơn đặt phòng và phòng realtime |

---

## 3. Tiến độ Thực hiện (Progress Tracker)

- [x] **Khảo sát & Phân tích nghiệp vụ:**
  - Bóc tách nhận diện thương hiệu, màu sắc, quy trình 3 bước (Date -> Time -> Room A1..A5) từ `okamuragolfzon.com`.
  - Phân tích yêu cầu màn hình gập (Flip / Fold) và responsive desktop.
- [x] **Khởi tạo tài liệu kiến trúc:**
  - Tạo `current_state.md` (Tài liệu trạng thái).
  - Tạo `codebase_map.md` (Bản đồ cấu trúc mã nguồn).
  - Tạo `implementation_plan.md` (Kế hoạch triển khai kỹ thuật).
- [x] **Giai đoạn 1: Thiết lập nền tảng Core & Theme:**
  - Cập nhật `pubspec.yaml` với các thư viện tương thích nhất (`go_router: ^18.0.1`, `google_fonts: ^8.2.1`, `intl: ^0.20.3`, `provider: ^6.1.5+1`, `shared_preferences: ^2.5.5`).
  - Thiết lập bảng màu `AppColors` chuẩn Okamura Golfzon (`#B69568`, Dark Charcoal).
  - Xây dựng `UserTheme` (Luxury Gold) và `AdminTheme` (Web Slate & Gold).
  - Viết tiện ích `ResponsiveLayout` hỗ trợ Mobile, Flip (màn dài), Fold (màn đôi), Tablet, Desktop.
- [x] **Giai đoạn 2: Tầng dữ liệu & Logic thực tế dùng chung (Shared Layer):**
  - Tạo `RoomModel` (phân loại phòng Smoking / Non-Smoking, cảm biến Golfzon NX 3D, giá).
  - Tạo `BookingModel` (thông tin khách, giờ, ngày, giá tiền, trạng thái, mã QR).
  - Tạo `StorageService` lưu trữ thực tế trên SharedPreferences (không dùng dữ liệu ảo hiển thị).
  - Tạo `BookingProvider` quản lý trạng thái khả dụng của phòng và đồng bộ realtime giữa User & Admin.
- [x] **Giai đoạn 3: Xây dựng Giao diện User Mobile (Okamura Golfzon):**
  - Khung điều hướng `UserShell` hỗ trợ BottomBar cho Mobile/Flip và NavigationRail cho Fold/Tablet.
  - Trang chủ (`UserHomeScreen`): Banner công nghệ 3D Golfzon, thanh đặt nhanh 3 bước, danh sách phòng thực tế, giới thiệu dịch vụ F&B.
  - Trang đặt phòng (`UserBookingScreen`): Luồng 3 bước chuẩn Okamura: Chọn Ngày -> Chọn Khung giờ -> Lưới phòng A1..A5 (kèm tag Smoking/No-Smoking và trạng thái Phòng trống / Đã đặt), Form xác nhận đặt phòng thực tế.
  - Trang quản lý vé (`UserMyBookingsScreen`): Thẻ vé điện tử Boarding Pass kèm mã QR check-in tại quầy lễ tân, chức năng hủy vé giải phóng phòng realtime.
- [x] **Giai đoạn 4: Bộ khung Giao diện Admin Web Dashboard:**
  - Khung điều hướng `AdminShell`: Sidebar co giãn responsive, Header có nút chuyển đổi nhanh giữa User và Admin.
  - Trang tổng quan (`AdminDashboardScreen`): Thẻ KPI doanh thu thực, Ma trận phòng thời gian thực (Room Matrix), Bảng đơn mới nhất từ khách hàng.
  - Trang quản lý đơn (`AdminBookingsScreen`): Bảng dữ liệu quản lý, tìm kiếm và hủy đơn.
  - Trang quản lý phòng (`AdminRoomsScreen`): Bật/tắt chế độ bảo trì thiết bị cảm biến Golfzon.
- [x] **Giai đoạn 5: Kết nối Firebase Realtime Database thời gian thực (Okamura Golfzon):**
  - Cấu hình kết nối thành công URL: `https://golf-booking-10108-default-rtdb.asia-southeast1.firebasedatabase.app/`
  - Thiết kế cấu trúc dữ liệu chuẩn thương hiệu Okamura Golfzon: Phòng A1..A5 (Smoking/No-Smoking), VIP 1 Suite, GDR Plus Driving Range, khung giờ chơi tiêu chuẩn 2h, thông tin cơ sở Thuận An (hotline, địa chỉ).
  - Triển khai `FirebaseRealtimeService` giao tiếp REST API trực tiếp không phụ thuộc thư viện native nặng nề, hỗ trợ chuẩn ký tự tiếng Việt UTF-8.
  - Đồng bộ 2 chiều: Khách đặt phòng từ User Mobile tự động gửi lên Firebase -> Admin Web Dashboard đồng bộ lập tức; Admin bật/tắt bảo trì phòng đồng bộ ngược lại cho User.
- [x] **Giai đoạn 6: Tích hợp Bộ Kỹ năng Trợ lý AI (Custom Agent Skills):**
  - Tích hợp 4 bộ kỹ năng chuyên sâu vào `.agents/skills/`:
    1. **`graphify`** (`Graphify-Labs/graphify`): Trích xuất kiến trúc dự án thành Knowledge Graph để truy vấn, tối ưu token.
    2. **`ponytail`** (`DietrichGebert/ponytail`): Tư duy giải pháp tinh gọn (YAGNI), hạn chế over-engineering, review và audit mã nguồn.
    3. **`taste-skill`** (`Leonxlnx/taste-skill`): Chuẩn mực thẩm mỹ frontend cao cấp, chống rập khuôn, tối ưu typography và spacing.
    4. **`impeccable`** (`pbakaus/impeccable`): Thiết kế giao diện và trải nghiệm UI/UX đỉnh cao, visual hierarchy, micro-interactions và responsive đa thiết bị.

---

## 4. Nhật ký công việc (Work Log)

- **14/09/2026 - 12:31:** Đọc và khảo sát dự án ban đầu (Flutter template cơ bản).
- **14/09/2026 - 12:35:** Tư vấn kiến trúc chia sẻ 1 codebase cho cả Web Admin và Mobile App.
- **14/09/2026 - 12:47:** Khảo sát website thực tế `okamuragolfzon.com`, bóc tách mã màu `#B69568`, cấu trúc phòng A1..A5.
- **14/09/2026 - 12:51:** Thiết lập tài liệu `current_state.md`, `codebase_map.md` và kế hoạch chi tiết.
- **14/09/2026 - 13:02:** Hoàn thiện kiến trúc cơ bản, hệ thống lưu trữ SharedPreferences và logic đồng bộ realtime.
- **14/09/2026 - 13:20:** Tái thiết kế giao diện User theo chuẩn Native Mobile App sang trọng.
- **14/09/2026 - 13:25:** Loại bỏ hoàn toàn Sidebar khỏi luồng User, áp dụng 100% Bottom Navigation Bar trên mọi thiết bị và màn hình.
- **14/09/2026 - 13:38:** Kết nối thành công Firebase Realtime Database `https://golf-booking-10108-default-rtdb.asia-southeast1.firebasedatabase.app/`.
- **12/10/2026 - 23:07:** Tích hợp thành công 4 bộ kỹ năng Agent Skills: `graphify`, `ponytail`, `taste-skill`, `impeccable` vào thư mục `.agents/skills/` của dự án theo chuẩn Antigravity Customization.
- **12/10/2026 - 23:27:** Tối ưu hóa layout `UserShell` và cấu trúc `UserHomeScreen`, thiết lập `autoSyncFirebase` thông minh cho `BookingProvider`, vượt qua toàn bộ 100% kiểm thử (12/12 tests passed, `dart analyze` không còn lỗi nào).
