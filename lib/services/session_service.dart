class SessionService {
  static String? authToken;
  static String? username;
  static String? displayPhoneNumber;
  static String? userId;
  static String? role;
  static String? referralCode;
  static bool isAdmin = false;

  static bool get isLoggedIn => authToken != null && authToken!.isNotEmpty;

  static void setSession({
    required String token,
    required String sessionUsername,
    required String sessionDisplayPhoneNumber,
    String? sessionUserId,
    String? sessionRole,
    String? sessionReferralCode,
    bool sessionIsAdmin = false,
  }) {
    authToken = token;
    username = sessionUsername;
    displayPhoneNumber = sessionDisplayPhoneNumber;
    userId = sessionUserId;
    role = sessionRole;
    referralCode = sessionReferralCode;
    isAdmin = sessionIsAdmin;
  }

  static void clear() {
    authToken = null;
    username = null;
    displayPhoneNumber = null;
    userId = null;
    role = null;
    referralCode = null;
    isAdmin = false;
  }
}
