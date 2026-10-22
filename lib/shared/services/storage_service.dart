import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/golf_category_model.dart';
import '../models/golfer_model.dart';
import '../models/room_model.dart';
import '../models/service_order_model.dart';

/// Dịch vụ lưu trữ dữ liệu thực tế trên thiết bị (SharedPreferences)
/// Đảm bảo không sử dụng dữ liệu ảo cố định, mọi thao tác đặt/hủy phòng đều được lưu trữ và cập nhật thật.
class StorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Danh sách phòng thực tế ban đầu tại cơ sở Okamura Golfzon
  static List<RoomModel> get initialRooms => const [
        RoomModel(
          id: 'room_a1',
          name: 'A1 - Smoking',
          isSmoking: true,
          pricePerHour: 450000,
          capacity: 4,
          sensorModel: 'Golfzon TwoVision NX 3D',
          description: 'Phòng chơi tiêu chuẩn có khu vực hút thuốc riêng biệt, màn hình 3D góc rộng.',
          category: 'standard',
        ),
        RoomModel(
          id: 'room_a2',
          name: 'A2 - Smoking',
          isSmoking: true,
          pricePerHour: 450000,
          capacity: 4,
          sensorModel: 'Golfzon TwoVision NX 3D',
          description: 'Phòng chơi tiêu chuẩn có khu vực hút thuốc, cảm biến chuyển động cao cấp.',
          category: 'standard',
        ),
        RoomModel(
          id: 'room_a3',
          name: 'A3 - Smoking',
          isSmoking: true,
          pricePerHour: 450000,
          capacity: 4,
          sensorModel: 'Golfzon TwoVision NX 3D',
          description: 'Phòng chơi tiêu chuẩn có hút thuốc, sofa tiếp khách thoải mái.',
          category: 'standard',
        ),
        RoomModel(
          id: 'room_a4',
          name: 'A4 - No Smoking',
          isSmoking: false,
          pricePerHour: 450000,
          capacity: 4,
          sensorModel: 'Golfzon TwoVision NX 3D',
          description: 'Phòng chơi không hút thuốc, không gian trong lành, phù hợp gia đình và nhóm bạn.',
          category: 'standard',
        ),
        RoomModel(
          id: 'room_a5',
          name: 'A5 - No Smoking',
          isSmoking: false,
          pricePerHour: 450000,
          capacity: 4,
          sensorModel: 'Golfzon TwoVision NX 3D',
          description: 'Phòng chơi không hút thuốc, thiết bị Golfzon cao cấp nhất.',
          category: 'standard',
        ),
        RoomModel(
          id: 'room_a6_dual',
          name: 'A6 - Dual Tee (Trái & Phải)',
          isSmoking: false,
          pricePerHour: 480000,
          capacity: 4,
          sensorModel: 'Golfzon TwoVision NX 3D Dual Sensor',
          description: 'Phòng thiết kế đặc biệt hỗ trợ cả Golfer thuận tay trái và tay phải với thảm Swing Plate 2 chiều độc quyền.',
          category: 'dual',
        ),
        RoomModel(
          id: 'room_vip1',
          name: 'VIP 1 - President Suite',
          isSmoking: false,
          pricePerHour: 750000,
          capacity: 8,
          sensorModel: 'Golfzon TwoVision Real Dual Sensor',
          description: 'Phòng VIP siêu rộng, tích hợp quầy bar mini, màn hình cong siêu lớn và hệ thống swing plate đa góc độ.',
          category: 'vip',
        ),
        RoomModel(
          id: 'room_vip2',
          name: 'VIP 2 - Royal Penthouse',
          isSmoking: false,
          pricePerHour: 950000,
          capacity: 12,
          sensorModel: 'Golfzon TwoVision NX 3D Panorama',
          description: 'Phòng Tổng thống xa hoa bậc nhất, màn hình Panorama 180°, phòng tiệc riêng, Cigar lounge cao cấp cho sự kiện và tiếp đối tác.',
          category: 'vip',
        ),
        RoomModel(
          id: 'room_b1_b2',
          name: 'Connecting Suite B1+B2',
          isSmoking: false,
          pricePerHour: 850000,
          capacity: 10,
          sensorModel: 'Golfzon TwoVision NX Network Play',
          description: 'Phòng đôi thông nhau với 2 màn chiếu kết nối song song, lý tưởng cho nhóm bạn đông người hoặc giải đấu đối kháng Match Play.',
          category: 'connecting',
        ),
        RoomModel(
          id: 'room_dr1',
          name: 'Driving Range 01',
          isSmoking: false,
          pricePerHour: 280000,
          capacity: 2,
          sensorModel: 'GDR Plus Driving Range Simulator',
          description: 'Làn tập chuyên nghiệp với phân tích thông số bóng, góc gậy chính xác bằng radar AI.',
          category: 'range',
        ),
        RoomModel(
          id: 'room_dr2',
          name: 'Driving Range 02 (High-Speed)',
          isSmoking: false,
          pricePerHour: 280000,
          capacity: 2,
          sensorModel: 'GDR Plus High-Speed AI Simulator',
          description: 'Làn tập cá nhân tích hợp camera siêu tốc độ 2.000 fps soi quỹ đạo đánh, độ xoáy và tư thế swing.',
          category: 'range',
        ),
        RoomModel(
          id: 'room_studio1',
          name: 'PGA Pro Coaching Studio',
          isSmoking: false,
          pricePerHour: 650000,
          capacity: 3,
          sensorModel: 'Golfzon NX + TrackMan 4 Studio',
          description: 'Phòng Studio chuyên sâu phục vụ chỉnh swing cùng HLV PGA Tour, đo đạc thông số fitting gậy và tối ưu khoảng cách.',
          category: 'studio',
        ),
      ];

  /// Đọc danh sách phòng từ lưu trữ
  static Future<List<RoomModel>> loadRooms() async {
    final p = await prefs;
    final jsonStr = p.getString(AppConstants.prefsKeyRooms);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Lưu danh sách ban đầu vào storage
      await saveRooms(initialRooms);
      return initialRooms.toList();
    }

    try {
      final List<dynamic> list = json.decode(jsonStr);
      final loaded = list.map((e) => RoomModel.fromMap(e as Map<String, dynamic>)).toList();
      // Tự động bổ sung các loại phòng mới nếu storage chưa có
      final existingIds = loaded.map((r) => r.id).toSet();
      bool hasNew = false;
      for (final r in initialRooms) {
        if (!existingIds.contains(r.id)) {
          loaded.add(r);
          hasNew = true;
        }
      }
      if (hasNew) {
        await saveRooms(loaded);
      }
      return loaded;
    } catch (_) {
      return initialRooms.toList();
    }
  }

  /// Lưu danh sách phòng vào lưu trữ
  static Future<void> saveRooms(List<RoomModel> rooms) async {
    final p = await prefs;
    final jsonStr = json.encode(rooms.map((e) => e.toMap()).toList());
    await p.setString(AppConstants.prefsKeyRooms, jsonStr);
  }

  /// Đọc danh sách đơn đặt phòng từ lưu trữ
  static Future<List<BookingModel>> loadBookings() async {
    final p = await prefs;
    final jsonStr = p.getString(AppConstants.prefsKeyBookings);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => BookingModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Lưu danh sách đơn đặt phòng vào lưu trữ
  static Future<void> saveBookings(List<BookingModel> bookings) async {
    final p = await prefs;
    final jsonStr = json.encode(bookings.map((e) => e.toMap()).toList());
    await p.setString(AppConstants.prefsKeyBookings, jsonStr);
  }

  /// Lưu thông tin khách đặt lần trước để tự động điền
  static Future<void> saveCustomerProfile(String name, String phone) async {
    final p = await prefs;
    await p.setString(AppConstants.prefsKeyUserName, name);
    await p.setString(AppConstants.prefsKeyUserPhone, phone);
  }

  static Future<Map<String, String>> loadCustomerProfile() async {
    final p = await prefs;
    return {
      'name': p.getString(AppConstants.prefsKeyUserName) ?? '',
      'phone': p.getString(AppConstants.prefsKeyUserPhone) ?? '',
    };
  }

  /// Danh mục món F&B & Dịch vụ chuẩn ban đầu để đồng bộ lên Firebase
  static List<ServiceItemModel> get initialServiceItems => const [
        ServiceItemModel(
          id: 'drink_americano',
          category: 0,
          name: 'Iced Americano Arabica',
          subtitle: 'Hạt rang mộc Cầu Đất pha máy Ý',
          price: 60000,
          tag: 'Bán chạy',
          iconKey: 'coffee',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_tiger_bac',
          category: 0,
          name: 'Tiger Bạc',
          subtitle: 'Lon 330ml ướp lạnh',
          price: 30000,
          tag: 'Bán chạy',
          iconKey: 'beer',
          accentHex: '0275D8',
          imageUrl: 'https://images.unsplash.com/photo-1608270586620-248524c67de9?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_sapporo',
          category: 0,
          name: 'Bia Sapporo',
          subtitle: 'Lon 330ml nhập khẩu',
          price: 45000,
          tag: 'Cao cấp',
          iconKey: 'beer',
          accentHex: '0275D8',
          imageUrl: 'https://images.unsplash.com/photo-1608270586620-248524c67de9?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_coca_plus',
          category: 0,
          name: 'Coca Plus',
          subtitle: 'Lon FOS không đường',
          price: 35000,
          tag: 'Healthy',
          iconKey: 'bar',
          accentHex: 'D9534F',
          imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_coca_nilong',
          category: 0,
          name: 'Coca Nilong',
          subtitle: 'Lon truyền thống',
          price: 30000,
          tag: 'Giải khát',
          iconKey: 'bar',
          accentHex: 'D9534F',
          imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_sprite',
          category: 0,
          name: 'Sprite',
          subtitle: 'Lon chanh mát lạnh',
          price: 30000,
          tag: 'Giải khát',
          iconKey: 'bar',
          accentHex: '5CB85C',
          imageUrl: 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_monster',
          category: 0,
          name: 'Monster',
          subtitle: 'Nước tăng lực năng lượng',
          price: 60000,
          tag: 'Energy',
          iconKey: 'bar',
          accentHex: '5CB85C',
          imageUrl: 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_soda',
          category: 0,
          name: 'Soda Schweppes',
          subtitle: 'Soda không đường',
          price: 30000,
          tag: 'Mixer',
          iconKey: 'water',
          accentHex: 'F0AD4E',
          imageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_aquarius',
          category: 0,
          name: 'Aquarius',
          subtitle: 'Bù nước và khoáng chất',
          price: 30000,
          tag: 'Điện giải',
          iconKey: 'water',
          accentHex: '5BC0DE',
          imageUrl: 'https://images.unsplash.com/photo-1559839914-17aae19cec71?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_dasani_free',
          category: 0,
          name: 'Dasani - tặng',
          subtitle: 'Chai nước suối miễn phí tại phòng',
          price: 0,
          tag: 'Tặng kèm',
          iconKey: 'water',
          accentHex: '5BC0DE',
          imageUrl: 'https://images.unsplash.com/photo-1559839914-17aae19cec71?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_dasani',
          category: 0,
          name: 'Dasani',
          subtitle: 'Chai 500ml tinh khiết',
          price: 15000,
          tag: 'Nước suối',
          iconKey: 'water',
          accentHex: '5BC0DE',
          imageUrl: 'https://images.unsplash.com/photo-1559839914-17aae19cec71?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_espresso',
          category: 0,
          name: 'Espresso',
          subtitle: 'Đậm vị kiểu Ý truyền thống',
          price: 60000,
          tag: 'Cà phê',
          iconKey: 'coffee',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_lungo',
          category: 0,
          name: 'Lungo',
          subtitle: 'Espresso chiết xuất dài',
          price: 60000,
          tag: 'Cà phê',
          iconKey: 'coffee',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_caffe_au_lait',
          category: 0,
          name: 'Caffe Au Lait',
          subtitle: 'Cà phê sữa tươi kiểu Pháp',
          price: 65000,
          tag: 'Cà phê',
          iconKey: 'coffee',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1570968915860-54d5c301fa9f?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_latte',
          category: 0,
          name: 'Latte',
          subtitle: 'Sữa tươi đánh nóng bông mịn',
          price: 65000,
          tag: 'Cà phê',
          iconKey: 'coffee',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1570968915860-54d5c301fa9f?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_flat_white',
          category: 0,
          name: 'Flat White',
          subtitle: 'Double shot espresso sữa mịn',
          price: 65000,
          tag: 'Cà phê',
          iconKey: 'coffee',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1577968897966-3d4325b36b61?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_cappuchino',
          category: 0,
          name: 'Cappuchino',
          subtitle: 'Bọt sữa dày phủ bột cacao',
          price: 65000,
          tag: 'Cà phê',
          iconKey: 'coffee',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1534778101976-62847782c213?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_sapporo_thap_vang',
          category: 0,
          name: 'Bia Sapporo Tháp Vàng 2.5L',
          subtitle: 'Tháp bia vàng tươi mát',
          price: 400000,
          tag: 'Tháp bia',
          iconKey: 'beer',
          accentHex: 'F0AD4E',
          imageUrl: 'https://images.unsplash.com/photo-1538488881522-4328ca75ab60?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_sapporo_thap_den',
          category: 0,
          name: 'Bia Sapporo Tháp Đen 2.5L',
          subtitle: 'Tháp bia đen hảo hạng 2.5 lít',
          price: 450000,
          tag: 'Tháp bia',
          iconKey: 'beer',
          accentHex: '292B2C',
          imageUrl: 'https://images.unsplash.com/photo-1518176258769-f227c798150e?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_bia_ly',
          category: 0,
          name: 'Bia Ly',
          subtitle: 'Ly bia tươi Sapporo 500ml',
          price: 65000,
          tag: 'Bia ly',
          iconKey: 'beer',
          accentHex: '0275D8',
          imageUrl: 'https://images.unsplash.com/photo-1567696911980-2eed69a46042?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'drink_teddy_cam',
          category: 0,
          name: 'Teddy Cam',
          subtitle: 'Nước cam tươi Teddy nguyên chất',
          price: 27000,
          tag: 'Nước ép',
          iconKey: 'bar',
          accentHex: 'F0AD4E',
          imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'food_steak',
          category: 1,
          name: 'Bò Bít Tết Thăn Ngoại Úc',
          subtitle: 'Thịt bò Úc 250g sốt tiêu đen kèm măng tây',
          price: 280000,
          tag: 'Signature',
          iconKey: 'restaurant',
          accentHex: 'EF4444',
          imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'food_truffle_fries',
          category: 1,
          name: 'Khoai Tây Chiên Truffle & Phô Mai',
          subtitle: 'Khoai giòn rụm hương nấm Truffle & Parmesan',
          price: 95000,
          tag: 'Khai vị',
          iconKey: 'fastfood',
          accentHex: 'F97316',
          imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'food_1',
          category: 1,
          name: 'Gà Rán Sốt Cay Hàn Quốc',
          subtitle: 'Giòn rụm kèm củ cải muối chua ngọt',
          price: 165000,
          tag: 'Must Try',
          iconKey: 'restaurant',
          accentHex: 'EF4444',
          imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'food_2',
          category: 1,
          name: 'Xúc Xích Đức Nướng & Khoai Tây',
          subtitle: 'Phục vụ nóng kèm mù tạt vàng',
          price: 145000,
          tag: 'Nhanh gọn',
          iconKey: 'fastfood',
          accentHex: 'F97316',
          imageUrl: 'https://images.unsplash.com/photo-1525059696034-4967a8e1dca2?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'food_3',
          category: 1,
          name: 'Mì Udon Bò Mỹ Thượng Hạng',
          subtitle: 'Nước dùng Dashi truyền thống chuẩn Nhật',
          price: 155000,
          tag: 'Chuẩn Nhật',
          iconKey: 'ramen',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'food_4',
          category: 1,
          name: 'Đĩa Trái Cây Nhiệt Đới Theo Mùa',
          subtitle: 'Dưa lưới, nho mẫu đơn, táo Envy cắt sẵn',
          price: 180000,
          tag: 'Tươi mát',
          iconKey: 'fruit',
          accentHex: '10B981',
          imageUrl: 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'gear_1',
          category: 2,
          name: 'Fullset TaylorMade Qi10 (Nam/Nữ)',
          subtitle: '14 gậy Carbon thế hệ mới nhất',
          price: 200000,
          tag: 'Pro Tour',
          iconKey: 'golf',
          accentHex: '3B82F6',
          imageUrl: 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'gear_2',
          category: 2,
          name: 'Fullset Honma Beres 4 Sao',
          subtitle: 'Trợ lực cao cấp dành cho VIP Suite',
          price: 350000,
          tag: 'Luxury',
          iconKey: 'vip',
          accentHex: 'B69568',
          imageUrl: 'https://images.unsplash.com/photo-1593111774240-d529f12cf4bb?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'gear_3',
          category: 2,
          name: 'Thuê Giày Golf FootJoy & Tất Mới',
          subtitle: 'Đủ size 36 - 44, khử khuẩn UV',
          price: 80000,
          tag: 'Tiện lợi',
          iconKey: 'shoe',
          accentHex: 'A855F7',
          imageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'gear_4',
          category: 2,
          name: 'Găng Tay Da Cừu Titleist Players',
          subtitle: 'Cảm giác cầm nắm thật tay, chống trượt',
          price: 90000,
          tag: 'Phụ kiện',
          iconKey: 'glove',
          accentHex: '06B6D4',
          imageUrl: 'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'pro_1',
          category: 3,
          name: 'Caddie Riêng Phục Vụ Tại Phòng (1 Giờ)',
          subtitle: 'Chỉnh line green, đặt bóng & chăm sóc suốt trận',
          price: 150000,
          tag: 'Chu đáo',
          iconKey: 'caddie',
          accentHex: '10B981',
          imageUrl: 'https://images.unsplash.com/photo-1592919505780-303950717480?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'pro_2',
          category: 3,
          name: 'HLV PGA Chỉnh Swing Cấp Tốc (60 Phút)',
          subtitle: 'Phân tích video 2000fps & sửa lỗi Slice/Hook',
          price: 500000,
          tag: 'Chuyên gia',
          iconKey: 'coach',
          accentHex: 'F59E0B',
          imageUrl: 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&w=400&q=80',
        ),
        ServiceItemModel(
          id: 'pro_3',
          category: 3,
          name: 'Gói Chụp Ảnh & Quay Highlight Swing',
          subtitle: 'Xuất video 4K Slow-motion gửi ngay qua Zalo',
          price: 120000,
          tag: 'Kỷ niệm',
          iconKey: 'video',
          accentHex: 'EC4899',
          imageUrl: 'https://images.unsplash.com/photo-1593111774642-a164b3017a55?auto=format&fit=crop&w=400&q=80',
        ),
      ];

  static Future<List<ServiceItemModel>> loadServiceItems() async {
    final p = await prefs;
    final jsonStr = p.getString('okamura_service_items');
    if (jsonStr == null || jsonStr.isEmpty) {
      await saveServiceItems(initialServiceItems);
      return initialServiceItems.toList();
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list
          .map((e) => ServiceItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return initialServiceItems.toList();
    }
  }

  static Future<void> saveServiceItems(List<ServiceItemModel> items) async {
    final p = await prefs;
    await p.setString(
      'okamura_service_items',
      json.encode(items.map((e) => e.toMap()).toList()),
    );
  }

  static Future<List<ServiceOrderModel>> loadServiceOrders() async {
    final p = await prefs;
    final jsonStr = p.getString('okamura_service_orders');
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list
          .map((e) => ServiceOrderModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveServiceOrders(List<ServiceOrderModel> orders) async {
    final p = await prefs;
    await p.setString(
      'okamura_service_orders',
      json.encode(orders.map((e) => e.toMap()).toList()),
    );
  }

  /// Tải thông tin hồ sơ Golfer hiện tại
  static Future<GolferModel> loadGolferProfile() async {
    final p = await prefs;
    final jsonStr = p.getString('okamura_golfer_profile');
    if (jsonStr == null || jsonStr.isEmpty) {
      return GolferModel.defaultProfile;
    }
    try {
      final Map<String, dynamic> map = json.decode(jsonStr);
      return GolferModel.fromMap(map);
    } catch (_) {
      return GolferModel.defaultProfile;
    }
  }

  /// Lưu thông tin hồ sơ Golfer hiện tại
  static Future<void> saveGolferProfile(GolferModel golfer) async {
    final p = await prefs;
    await p.setString('okamura_golfer_profile', json.encode(golfer.toMap()));
  }

  /// Tải danh sách thể loại Golf từ bộ nhớ cục bộ
  static Future<List<GolfCategoryModel>> loadGolfCategories() async {
    final p = await prefs;
    final jsonStr = p.getString('okamura_golf_categories');
    if (jsonStr == null || jsonStr.isEmpty) {
      await saveGolfCategories(GolfCategoryModel.defaultCategories);
      return GolfCategoryModel.defaultCategories.toList();
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list
          .map((e) => GolfCategoryModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return GolfCategoryModel.defaultCategories.toList();
    }
  }

  /// Lưu danh sách thể loại Golf vào bộ nhớ cục bộ
  static Future<void> saveGolfCategories(List<GolfCategoryModel> categories) async {
    final p = await prefs;
    await p.setString(
      'okamura_golf_categories',
      json.encode(categories.map((e) => e.toMap()).toList()),
    );
  }

  /// Tải danh sách biên bản chốt ca thu ngân từ bộ nhớ cục bộ
  static Future<List<Map<String, dynamic>>> loadShiftHandovers() async {
    final p = await prefs;
    final jsonStr = p.getString('okamura_shift_handovers');
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Lưu biên bản chốt ca thu ngân vào bộ nhớ cục bộ
  static Future<void> saveShiftHandover(Map<String, dynamic> handover) async {
    final p = await prefs;
    final list = await loadShiftHandovers();
    list.insert(0, handover);
    await p.setString('okamura_shift_handovers', json.encode(list));
  }
}
