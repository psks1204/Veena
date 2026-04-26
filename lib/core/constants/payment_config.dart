class PaymentConfig {
  PaymentConfig._();

  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String _directKey = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  static const String _devKey = String.fromEnvironment(
    'RAZORPAY_KEY_DEV',
    defaultValue: '',
  );

  static const String _stagingKey = String.fromEnvironment(
    'RAZORPAY_KEY_STAGING',
    defaultValue: '',
  );

  static const String _prodKey = String.fromEnvironment(
    'RAZORPAY_KEY_PROD',
    defaultValue: '',
  );

  static String get razorpayKey {
    if (_directKey.isNotEmpty) {
      return _directKey;
    }

    switch (_env.toLowerCase()) {
      case 'prod':
      case 'production':
        return _prodKey;
      case 'stage':
      case 'staging':
        return _stagingKey;
      default:
        return _devKey;
    }
  }

  static bool get hasRazorpayKey => razorpayKey.isNotEmpty;
}
