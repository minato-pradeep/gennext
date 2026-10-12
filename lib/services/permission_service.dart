import '../models/user_permissions.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  UserPermissions? _currentUserPermissions;

  // Set current user's permissions after login
  void setCurrentUserPermissions(UserPermissions permissions) {
    _currentUserPermissions = permissions;
  }

  // Clear current user permissions on logout
  void clearCurrentUserPermissions() {
    _currentUserPermissions = null;
  }

  // Get current user permissions
  UserPermissions? getCurrentUserPermissions() {
    return _currentUserPermissions;
  }

  // Check if user has a specific permission
  bool hasPermission(String permissionKey) {
    if (_currentUserPermissions == null) return false;
    
    switch (permissionKey) {
      case 'emergency':
        return _currentUserPermissions!.emergency;
      case 'buySell':
        return _currentUserPermissions!.buySell;
      case 'raiseComplaint':
        return _currentUserPermissions!.raiseComplaint;
      case 'allComplaints':
        return _currentUserPermissions!.allComplaints;
      case 'events':
        return _currentUserPermissions!.events;
      case 'facilities':
        return _currentUserPermissions!.facilities;
      case 'payments':
        return _currentUserPermissions!.payments;
      case 'visitors':
        return _currentUserPermissions!.visitors;
      case 'visitorApproval':
        return _currentUserPermissions!.visitorApproval;
      case 'polls':
        return _currentUserPermissions!.polls;
      case 'documents':
        return _currentUserPermissions!.documents;
      case 'maintenance':
        return _currentUserPermissions!.maintenance;
      case 'noticeBoard':
        return _currentUserPermissions!.noticeBoard;
      case 'checkComplaint':
        return _currentUserPermissions!.checkComplaint;
      case 'profile':
        return _currentUserPermissions!.profile;
      default:
        return false;
    }
  }

  // Get list of enabled option IDs
  List<int> getEnabledOptionIds() {
    final enabledIds = <int>[];
    
    if (_currentUserPermissions?.emergency == true) enabledIds.add(1);
    if (_currentUserPermissions?.buySell == true) enabledIds.add(2);
    if (_currentUserPermissions?.raiseComplaint == true) enabledIds.add(3);
    if (_currentUserPermissions?.allComplaints == true) enabledIds.add(4);
    if (_currentUserPermissions?.events == true) enabledIds.add(5);
    if (_currentUserPermissions?.facilities == true) enabledIds.add(6);
    if (_currentUserPermissions?.payments == true) enabledIds.add(7);
    if (_currentUserPermissions?.visitors == true) enabledIds.add(8);
    if (_currentUserPermissions?.visitorApproval == true) enabledIds.add(9);
    if (_currentUserPermissions?.polls == true) enabledIds.add(10);
    if (_currentUserPermissions?.documents == true) enabledIds.add(11);
    if (_currentUserPermissions?.maintenance == true) enabledIds.add(12);
    if (_currentUserPermissions?.noticeBoard == true) enabledIds.add(13);
    if (_currentUserPermissions?.checkComplaint == true) enabledIds.add(14);
    
    return enabledIds;
  }

  // Check if user is App Master
  bool isAppMaster(String role) {
    return role.toLowerCase() == 'master';
  }
}