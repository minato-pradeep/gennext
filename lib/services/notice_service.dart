import '../models/notice.dart';

class NoticeService {
  static final NoticeService _instance = NoticeService._internal();
  factory NoticeService() => _instance;
  NoticeService._internal();

  List<Notice> _notices = [];
  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Get all active notices (not expired)
  List<Notice> getAllNotices() {
    final now = DateTime.now();
    return _notices
        .where((notice) => notice.isActive && (notice.expiryDate == null || notice.expiryDate!.isAfter(now)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  // Get recent notices (last 30 days)
  List<Notice> getRecentNotices() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return getAllNotices()
        .where((notice) => notice.createdAt.isAfter(thirtyDaysAgo))
        .toList();
  }

  // Get notice by ID
  Notice? getNoticeById(String id) {
    try {
      return _notices.firstWhere((notice) => notice.id == id);
    } catch (e) {
      return null;
    }
  }

  // Create a new notice
  void createNotice({
    required String title,
    required String description,
    required String createdBy,
    required String createdByRole,
    DateTime? expiryDate,
    String? imageUrl,
    List<String>? tags,
  }) {
    final newNotice = Notice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdBy: createdBy,
      createdByRole: createdByRole,
      createdAt: DateTime.now(),
      expiryDate: expiryDate,
      imageUrl: imageUrl,
      isActive: true,
      tags: tags ?? [],
    );
    _notices.insert(0, newNotice); // Insert at beginning
    _notifyListeners();
  }

  // Update a notice
  void updateNotice(String id, {
    String? title,
    String? description,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isActive,
    List<String>? tags,
  }) {
    final index = _notices.indexWhere((notice) => notice.id == id);
    if (index != -1) {
      final oldNotice = _notices[index];
      _notices[index] = Notice(
        id: oldNotice.id,
        title: title ?? oldNotice.title,
        description: description ?? oldNotice.description,
        createdBy: oldNotice.createdBy,
        createdByRole: oldNotice.createdByRole,
        createdAt: oldNotice.createdAt,
        expiryDate: expiryDate ?? oldNotice.expiryDate,
        imageUrl: imageUrl ?? oldNotice.imageUrl,
        isActive: isActive ?? oldNotice.isActive,
        tags: tags ?? oldNotice.tags,
      );
      _notifyListeners();
    }
  }

  // Delete a notice
  void deleteNotice(String id) {
    _notices.removeWhere((notice) => notice.id == id);
    _notifyListeners();
  }

  // Archive a notice (soft delete)
  void archiveNotice(String id) {
    final index = _notices.indexWhere((notice) => notice.id == id);
    if (index != -1) {
      _notices[index] = Notice(
        id: _notices[index].id,
        title: _notices[index].title,
        description: _notices[index].description,
        createdBy: _notices[index].createdBy,
        createdByRole: _notices[index].createdByRole,
        createdAt: _notices[index].createdAt,
        expiryDate: _notices[index].expiryDate,
        imageUrl: _notices[index].imageUrl,
        isActive: false,
        tags: _notices[index].tags,
      );
      _notifyListeners();
    }
  }

  // Initialize mock data
  void initMockData() {
    _notices = [
      Notice(
        id: '1',
        title: 'Community Meeting - March 2024',
        description: 'Monthly community meeting will be held in the clubhouse. All residents are requested to attend.',
        createdBy: 'Admin',
        createdByRole: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiryDate: DateTime.now().add(const Duration(days: 28)),
        tags: ['event', 'important'],
      ),
      Notice(
        id: '2',
        title: 'Water Supply Maintenance',
        description: 'Water supply will be interrupted on Monday from 10 AM to 2 PM due to maintenance work.',
        createdBy: 'Admin',
        createdByRole: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        expiryDate: DateTime.now().add(const Duration(days: 10)),
        tags: ['urgent', 'important'],
      ),
      Notice(
        id: '3',
        title: 'Diwali Celebration',
        description: 'Join us for Diwali celebration on 12th November. Decoration, food, and cultural programs planned.',
        createdBy: 'Rajesh Kumar',
        createdByRole: 'owner',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 25)),
        tags: ['event'],
      ),
    ];
    _notifyListeners();
  }

  // Get next ID
  String getNextId() {
    if (_notices.isEmpty) return '1';
    final maxId = _notices.map((n) => int.parse(n.id)).reduce((a, b) => a > b ? a : b);
    return (maxId + 1).toString();
  }
}