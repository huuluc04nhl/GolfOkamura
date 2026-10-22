import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golf_booking/core/utils/formatters.dart';
import 'package:golf_booking/shared/models/room_model.dart';
import 'package:golf_booking/shared/models/service_order_model.dart';
import 'package:golf_booking/shared/providers/booking_provider.dart';

/// Tab Lưới Thực Đơn Gọi Món (F&B) & Quản lý CRUD Món Ăn / Đồ Uống
class FnbMenuGrid extends StatefulWidget {
  final RoomModel selectedRoom;

  const FnbMenuGrid({super.key, required this.selectedRoom});

  @override
  State<FnbMenuGrid> createState() => _FnbMenuGridState();
}

class _FnbMenuGridState extends State<FnbMenuGrid> {
  int _fnbFilterCategory = -1; // -1: Tất cả, 0: Nước & Đồ uống, 1: Ẩm thực Lounge
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    // Chỉ lấy sản phẩm F&B (category 0 và 1)
    final fnbList = provider.serviceItems.where((i) {
      if (i.category != 0 && i.category != 1) return false;
      if (_fnbFilterCategory != -1 && i.category != _fnbFilterCategory) return false;
      if (_searchText.isNotEmpty) {
        final query = _searchText.toLowerCase();
        return i.name.toLowerCase().contains(query) ||
            i.subtitle.toLowerCase().contains(query) ||
            i.tag.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Thanh công cụ: Pills danh mục F&B, Ô tìm kiếm và Nút Thêm Món
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildCategoryPill(-1, 'Tất cả F&B'),
                  const SizedBox(width: 6),
                  _buildCategoryPill(0, 'Nước & Đồ uống'),
                  const SizedBox(width: 6),
                  _buildCategoryPill(1, 'Ẩm thực Lounge'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchText = val.trim()),
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm trà đào, bia, steak, mì udon...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                          suffixIcon: _searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchText = '');
                                  },
                                )
                              : null,
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showAddEditFnbItemDialog(context, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB69568),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text(
                      'Thêm Món',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lưới hiển thị các món F&B
        Expanded(
          child: fnbList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'Không tìm thấy món ăn hoặc đồ uống phù hợp',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.88,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: fnbList.length,
                  itemBuilder: (itemCtx, index) {
                    final item = fnbList[index];
                    return _buildFnbCard(provider, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill(int catIndex, String label) {
    final isSelected = _fnbFilterCategory == catIndex;
    return InkWell(
      onTap: () => setState(() => _fnbFilterCategory = catIndex),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFFB69568) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildFnbCard(BookingProvider provider, ServiceItemModel item) {
    return InkWell(
      onTap: () async {
        await provider.quickAddServiceItem(
          roomName: widget.selectedRoom.name,
          item: item,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm 1 ${item.name} (${item.unit}) vào ${widget.selectedRoom.posName}!'),
            duration: const Duration(milliseconds: 700),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.resolvedImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1E293B),
                      child: Center(child: Icon(item.iconData, color: Colors.white70, size: 26)),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black45],
                        ),
                      ),
                    ),
                  ),
                  if (item.tag.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item.tag,
                          style: const TextStyle(color: Color(0xFFB69568), fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      tooltip: 'Tùy chọn món F&B',
                      icon: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.more_vert, size: 14, color: Colors.white),
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showAddEditFnbItemDialog(context, provider, item: item);
                        } else if (val == 'delete') {
                          _showDeleteDialog(context, provider, item);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 14, color: Color(0xFFB69568)),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa món', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Xóa khỏi thực đơn', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.currency(item.price),
                        style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditFnbItemDialog(BuildContext context, BookingProvider provider, {ServiceItemModel? item}) {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final subtitleCtrl = TextEditingController(text: item?.subtitle ?? '');
    final priceCtrl = TextEditingController(text: item != null ? item.price.toInt().toString() : '50000');
    final tagCtrl = TextEditingController(text: item?.tag ?? 'F&B');
    final imageUrlCtrl = TextEditingController(text: item?.imageUrl ?? '');
    int selectedCategory = item?.category ?? (_fnbFilterCategory == -1 ? 0 : _fnbFilterCategory);
    if (selectedCategory != 0 && selectedCategory != 1) selectedCategory = 0;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF131C31),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF1E293B))),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.restaurant_rounded, color: const Color(0xFFB69568)),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Sửa Món F&B' : 'Thêm Món F&B Mới',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tên món ăn / Đồ uống:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDialogDecoration('VD: Trà Đào Cam Sả / Steak Bò Úc'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phân loại F&B:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF26354D)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: (selectedCategory == 0 || selectedCategory == 1)
                                      ? selectedCategory
                                      : 0,
                                  dropdownColor: const Color(0xFF131C31),
                                  isExpanded: true,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  items: const [
                                    DropdownMenuItem(value: 0, child: Text('0: Nước & Đồ uống')),
                                    DropdownMenuItem(value: 1, child: Text('1: Ẩm thực Lounge')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedCategory = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Đơn giá (VNĐ):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Color(0xFFB69568), fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: _inputDialogDecoration('Đơn giá', suffix: 'đ'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Mô tả ngắn:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: subtitleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _inputDialogDecoration('VD: Hương vị thanh mát, giải nhiệt'),
                  ),
                  const SizedBox(height: 10),
                  const Text('Link hình ảnh URL:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: imageUrlCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: _inputDialogDecoration('https://...'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final price = double.tryParse(priceCtrl.text.trim()) ?? 50000;
                final img = imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim();

                if (isEditing) {
                  final updated = item.copyWith(
                    name: name,
                    subtitle: subtitleCtrl.text.trim(),
                    price: price,
                    category: selectedCategory,
                    tag: tagCtrl.text.trim().isEmpty ? 'F&B' : tagCtrl.text.trim(),
                    imageUrl: img,
                  );
                  await provider.updateServiceItem(updated);
                } else {
                  final newId = 'fnb_${DateTime.now().millisecondsSinceEpoch % 100000}';
                  final newItem = ServiceItemModel(
                    id: newId,
                    category: selectedCategory,
                    name: name,
                    subtitle: subtitleCtrl.text.trim(),
                    price: price,
                    tag: tagCtrl.text.trim().isEmpty ? 'NEW' : tagCtrl.text.trim(),
                    iconKey: selectedCategory == 0 ? 'coffee' : 'restaurant',
                    imageUrl: img,
                  );
                  await provider.addServiceItem(newItem);
                }

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Đã cập nhật món "$name"!' : 'Đã thêm món "$name" vào thực đơn!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB69568),
                foregroundColor: Colors.black,
              ),
              child: Text(isEditing ? 'Lưu' : 'Thêm Món', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BookingProvider provider, ServiceItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF1E293B))),
        title: const Text('Xác nhận xóa món', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa "${item.name}" khỏi thực đơn F&B?', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteServiceItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa món "${item.name}" khỏi thực đơn F&B!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xóa Món'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDialogDecoration(String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: Color(0xFFB69568)),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF26354D))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF26354D))),
    );
  }
}
