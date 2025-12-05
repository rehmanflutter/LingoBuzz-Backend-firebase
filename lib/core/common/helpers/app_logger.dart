class Log {
  static const bool _isInfoShow = true;
  static const bool _isWarnShow = true;
  static const bool _isErrShow = true;
  static const bool _isDebugShow = true;

  static void info(msg) {
    if (_isInfoShow) {
      print("\x1b[33m[INFO] $msg\x1b[0m");
    }
  }

  static void warn(msg) {
    if (_isWarnShow) {
      print("[WARN] $msg");
    }
  }

  static void err(msg) {
    if (_isErrShow) {
      print("\x1b[31m[ERR] $msg\x1b[0m");
    }
  }

  static void debug(msg) {
    if (_isDebugShow) {
      print("\x1B[32m[DEBUG] $msg\x1B[0m");
    }
  }
}
