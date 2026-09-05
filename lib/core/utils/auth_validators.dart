class AuthValidators {
  /// Mobile must be exactly 11 digits (e.g. 017XXXXXXXX)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'মোবাইল নম্বর লিখুন';
    }
    final clean = value.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    if (clean.length != 11) {
      return 'মোবাইল নম্বর অবশ্যই ঠিক ১১ ডিজিটের হতে হবে (যেমন: 01XXXXXXXXX)';
    }
    if (!clean.startsWith('01')) {
      return 'মোবাইল নম্বর 01 দিয়ে শুরু হতে হবে';
    }
    if (!RegExp(r'^[0-9]{11}$').hasMatch(clean)) {
      return 'মোবাইল নম্বরে শুধুমাত্র সংখ্যা গ্রহণযোগ্য';
    }
    return null;
  }

  /// Password must contain at least 8 characters, 1 digit, 1 capital letter, 1 small letter
  static final RegExp passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'পাসওয়ার্ড প্রদান করুন';
    }
    if (value.length < 8) {
      return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
    }
    if (!passwordRegex.hasMatch(value)) {
      return 'পাসওয়ার্ডে অন্তত ১টি বড় হাতের (A-Z), ১টি ছোট হাতের (a-z) এবং ১টি সংখ্যা (0-9) থাকতে হবে';
    }
    return null;
  }
}
