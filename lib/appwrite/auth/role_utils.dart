// lib/core/utils/role_utils.dart
class RoleUtils {
  static bool isAdmin(List<String> labels) => labels.contains('admin');
  
  static bool isFacilitator(List<String> labels) => 
      labels.contains('facilitator') || isAdmin(labels);
  
  static bool isMember(List<String> labels) =>
      labels.contains('member') || isFacilitator(labels);
      
  static String getRoleFromLabels(List<String> labels) {
    if (isAdmin(labels)) return 'admin';
    if (isFacilitator(labels)) return 'facilitator';
    if (isMember(labels)) return 'member';
    return 'nonmember';
  }
}