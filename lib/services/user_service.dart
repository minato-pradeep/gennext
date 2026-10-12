import '../models/app_user.dart';
import '../models/user_permissions.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  List<AppUser> _users = [];
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

  // Get all users
  List<AppUser> getUsers() {
    return List.from(_users);
  }

  // Get user by username
  AppUser? getUserByUsername(String username) {
    try {
      return _users.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }

  // Authenticate user
  AppUser? authenticate(String username, String password) {
    try {
      final user = _users.firstWhere(
        (user) => user.username == username && user.password == password && user.isActive,
      );
      return user;
    } catch (e) {
      return null;
    }
  }

  // Create new user (by App Master)
  void createUser({
    required String username,
    required String password,
    required String role,
    required String name,
    required String apartment,
    required String phone,
    UserPermissions? permissions,
  }) {
    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
      role: role,
      name: name,
      apartment: apartment,
      phone: phone,
      createdAt: DateTime.now(),
      isActive: true,
      permissions: permissions ?? UserPermissions(),
    );
    _users.add(newUser);
    _notifyListeners();
  }

  // Update user permissions
  void updateUserPermissions(String userId, UserPermissions newPermissions) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users[index] = AppUser(
        id: _users[index].id,
        username: _users[index].username,
        password: _users[index].password,
        role: _users[index].role,
        name: _users[index].name,
        apartment: _users[index].apartment,
        phone: _users[index].phone,
        createdAt: _users[index].createdAt,
        isActive: _users[index].isActive,
        permissions: newPermissions,
      );
      _notifyListeners();
    }
  }

  // Update user basic info
  void updateUser(String userId, {
    String? name,
    String? apartment,
    String? phone,
    String? role,
    bool? isActive,
  }) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users[index] = AppUser(
        id: _users[index].id,
        username: _users[index].username,
        password: _users[index].password,
        role: role ?? _users[index].role,
        name: name ?? _users[index].name,
        apartment: apartment ?? _users[index].apartment,
        phone: phone ?? _users[index].phone,
        createdAt: _users[index].createdAt,
        isActive: isActive ?? _users[index].isActive,
        permissions: _users[index].permissions,
      );
      _notifyListeners();
    }
  }

  // Delete user
  void deleteUser(String userId) {
    _users.removeWhere((user) => user.id == userId);
    _notifyListeners();
  }

  // Reset user password
  void resetPassword(String userId, String newPassword) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users[index] = AppUser(
        id: _users[index].id,
        username: _users[index].username,
        password: newPassword,
        role: _users[index].role,
        name: _users[index].name,
        apartment: _users[index].apartment,
        phone: _users[index].phone,
        createdAt: _users[index].createdAt,
        isActive: _users[index].isActive,
        permissions: _users[index].permissions,
      );
      _notifyListeners();
    }
  }

  // Initialize mock data (including App Master)
  void initMockData() {
    // Create App Master user
    final masterPermissions = UserPermissions();
    masterPermissions.enableAll();
    
    _users = [
      AppUser(
        id: '1',
        username: 'admin',
        password: 'macs',
        role: 'master',
        name: 'App Master',
        apartment: 'Admin',
        phone: '+91 99999 99999',
        createdAt: DateTime.now(),
        isActive: true,
        permissions: masterPermissions,
      ),
      // Owner User - all 14 permissions enabled
      AppUser(
        id: '2',
        username: 'macs',
        password: 'macs',
        role: 'owner',
        name: 'Macs',
        apartment: 'B12',
        phone: '+91 98765 43210',
        createdAt: DateTime.now(),
        isActive: true,
        permissions: UserPermissions(
          emergency: true,
          buySell: true,
          raiseComplaint: true,
          allComplaints: true,
          events: true,
          facilities: true,
          payments: true,
          visitors: true,
          visitorApproval: true,
          polls: true,
          documents: true,
          maintenance: true,
          noticeBoard: true,
          checkComplaint: true,
          profile: true,
        ),
      ),
    ];
    _notifyListeners();
  }
}