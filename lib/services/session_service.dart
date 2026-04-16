class SessionService {
  static String? authToken;
  static String? username;
  static String? displayPhoneNumber;
  static String? userId;
  static String? role;
  static bool isAdmin = false;

  static bool get isLoggedIn => authToken != null && authToken!.isNotEmpty;

  static void setSession({
    required String token,
    required String sessionUsername,
    required String sessionDisplayPhoneNumber,
    String? sessionUserId,
    String? sessionRole,
    bool sessionIsAdmin = false,
  }) {
    authToken = token;
    username = sessionUsername;
    displayPhoneNumber = sessionDisplayPhoneNumber;
    userId = sessionUserId;
    role = sessionRole;
    isAdmin = sessionIsAdmin;
  }

  static void clear() {
    authToken = null;
    username = null;
    displayPhoneNumber = null;
    userId = null;
    role = null;
    isAdmin = false;
  }
}
