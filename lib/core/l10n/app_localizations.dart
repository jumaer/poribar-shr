enum AppLanguage { bangla, english }

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static final Map<String, Map<AppLanguage, String>> _localizedValues = {
    'my_tab': {
      AppLanguage.bangla: 'আমার',
      AppLanguage.english: 'My Ledger',
    },
    'family_tab': {
      AppLanguage.bangla: 'পরিবারের হিসাব',
      AppLanguage.english: 'Family Ledger',
    },
    'annual_calendar': {
      AppLanguage.bangla: 'বার্ষিক কার্যপঞ্জি',
      AppLanguage.english: 'Annual Calendar',
    },
    'monthly_income_expense': {
      AppLanguage.bangla: 'মাসিক আয় ব্যয়',
      AppLanguage.english: 'Monthly Inc/Exp',
    },
    'monthly_savings': {
      AppLanguage.bangla: 'মাসিক জমা',
      AppLanguage.english: 'Monthly Savings',
    },
    'monthly_expense': {
      AppLanguage.bangla: 'মাসিক খরচ',
      AppLanguage.english: 'Monthly Expense',
    },
    'member_list': {
      AppLanguage.bangla: 'পরিবারের সদস্য তালিকা',
      AppLanguage.english: 'Member List',
    },
    'monthly_alarm': {
      AppLanguage.bangla: 'মাসিক এলার্ম',
      AppLanguage.english: 'Monthly Alarm',
    },
    'accounts': {
      AppLanguage.bangla: 'হিসাব',
      AppLanguage.english: 'Accounts',
    },
    'estimated_expense': {
      AppLanguage.bangla: 'আন্দাজ খরচ',
      AppLanguage.english: 'Estimated Budget',
    },
    'problem_list': {
      AppLanguage.bangla: 'পরিবারের সমস্যা তালিকা',
      AppLanguage.english: 'Problem List',
    },
    'graph_view': {
      AppLanguage.bangla: 'গ্রাফ ভিউ',
      AppLanguage.english: 'Graph View',
    },
    'add_expense': {
      AppLanguage.bangla: 'নতুন খরচ যোগ করুন',
      AppLanguage.english: 'Add Expense',
    },
    'date': {
      AppLanguage.bangla: 'তারিখ',
      AppLanguage.english: 'Date',
    },
    'amount': {
      AppLanguage.bangla: 'টাকার পরিমাণ',
      AppLanguage.english: 'Amount',
    },
    'purpose': {
      AppLanguage.bangla: 'উদ্দেশ্য',
      AppLanguage.english: 'Purpose',
    },
    'description': {
      AppLanguage.bangla: 'বিবরণ',
      AppLanguage.english: 'Description',
    },
    'submit': {
      AppLanguage.bangla: 'জমা দিন',
      AppLanguage.english: 'Submit',
    },
    'notification': {
      AppLanguage.bangla: 'নোটিফিকেশন',
      AppLanguage.english: 'Notifications',
    },
    'messages': {
      AppLanguage.bangla: 'মেসেজ',
      AppLanguage.english: 'Messages',
    },
    'offers': {
      AppLanguage.bangla: 'অফার',
      AppLanguage.english: 'Offers',
    },
    'payments_due': {
      AppLanguage.bangla: 'বকেয়া পরিশোধ',
      AppLanguage.english: 'Payments Due',
    },
    'highest_expenses': {
      AppLanguage.bangla: 'সর্বোচ্চ খরচ',
      AppLanguage.english: 'Highest Expenses',
    },
    'refresh': {
      AppLanguage.bangla: 'রিফ্রেশ',
      AppLanguage.english: 'Refresh',
    },
    'sync_success': {
      AppLanguage.bangla: 'সার্ভার থেকে সমস্ত তথ্য রিফ্রেশ ও সিঙ্ক করা হয়েছে!',
      AppLanguage.english: 'All data refreshed & synced from server!',
    },
    'logout': {
      AppLanguage.bangla: 'লগআউট',
      AppLanguage.english: 'Logout',
    },
    'logout_confirm': {
      AppLanguage.bangla: 'আপনি কি আপনার একাউন্ট থেকে লগআউট করতে চান?',
      AppLanguage.english: 'Do you want to logout from your account?',
    },
    'cancel': {
      AppLanguage.bangla: 'বাতিল',
      AppLanguage.english: 'Cancel',
    },
    'confirm': {
      AppLanguage.bangla: 'নিশ্চিত করুন',
      AppLanguage.english: 'Confirm',
    },
    'offline_warning': {
      AppLanguage.bangla: '⚠️ আপনি অফলাইনে আছেন। সংরক্ষিত ক্যাশ ডাটা দেখা যাচ্ছে। নতুন এন্ট্রি করতে ইন্টারনেট চালু করুন।',
      AppLanguage.english: '⚠️ You are offline. Showing cached local data. Turn on internet to add entries.',
    },
    'sos_banner_title': {
      AppLanguage.bangla: 'বিপদকালীন শেক এলার্ট সক্রিয়',
      AppLanguage.english: 'Emergency Shake Alert Active',
    },
    'sos_banner_desc': {
      AppLanguage.bangla: 'বিপদে ৩ বার দ্রুত ফোন ঝাঁকালে লাইভ অবস্থান পরিবারে যাবে',
      AppLanguage.english: 'Shake phone 3 times in danger to send live location to family',
    },
    'sos_test_btn': {
      AppLanguage.bangla: 'টেস্ট SOS',
      AppLanguage.english: 'Test SOS',
    },
    'namaj_alarm_title': {
      AppLanguage.bangla: 'নামাজের সময় ও অ্যালার্ম',
      AppLanguage.english: 'Prayer Times & Alarm',
    },
    'amol_tasbih_title': {
      AppLanguage.bangla: 'আমল ও তসবিহ',
      AppLanguage.english: 'Daily Amol & Tasbih',
    },
    'emergency_list_title': {
      AppLanguage.bangla: 'জরুরি তালিকা',
      AppLanguage.english: 'Emergency Need List',
    },
    'splash_img_title': {
      AppLanguage.bangla: 'স্প্ল্যাশ ছবি',
      AppLanguage.english: 'Splash Image',
    },
    'budget_distribution': {
      AppLanguage.bangla: 'বাজেট বণ্টন',
      AppLanguage.english: 'Distribute Budget',
    },
    'leave_family': {
      AppLanguage.bangla: 'পরিবার ত্যাগ করুন',
      AppLanguage.english: 'Leave Family',
    },
    'leave_family_confirm': {
      AppLanguage.bangla: 'আপনি কি নিশ্চিতভাবে এই পরিবার ত্যাগ করতে চান?',
      AppLanguage.english: 'Are you sure you want to leave this family?',
    },
    'admin_transfer_title': {
      AppLanguage.bangla: 'এডমিন হস্তান্তর ও ত্যাগ',
      AppLanguage.english: 'Transfer Admin & Leave',
    },
    'admin_panel': {
      AppLanguage.bangla: 'অ্যাডমিন প্যানেল',
      AppLanguage.english: 'Admin Panel',
    },
    'add_member': {
      AppLanguage.bangla: 'নতুন সদস্য যুক্ত করুন',
      AppLanguage.english: 'Add New Member',
    },
    'save': {
      AppLanguage.bangla: 'সংরক্ষণ করুন',
      AppLanguage.english: 'Save',
    },
    'delete': {
      AppLanguage.bangla: 'বাদ দিন',
      AppLanguage.english: 'Delete',
    },
    'receipt_camera': {
      AppLanguage.bangla: 'রসিদ ক্যামেরা',
      AppLanguage.english: 'Receipt Camera',
    },
    'analytics': {
      AppLanguage.bangla: 'হিসাব বিশ্লেষণ',
      AppLanguage.english: 'Analytics',
    },
    'private_vault': {
      AppLanguage.bangla: 'গোপন ভল্ট',
      AppLanguage.english: 'Private Vault',
    },
    'alarm_permission_denied': {
      AppLanguage.bangla: 'আপনার মাসিক অ্যালার্ম সেট করার অনুমতি বন্ধ রয়েছে। পরিবারের অ্যাডমিনের সাথে যোগাযোগ করুন।',
      AppLanguage.english: 'You do not have permission to set monthly alarms. Contact family admin.',
    },
    'total_savings_remaining': {
      AppLanguage.bangla: 'মোট সঞ্চয় / অবশিষ্ট ব্যালেন্স',
      AppLanguage.english: 'Total Savings / Balance',
    },
    'spent_percentage': {
      AppLanguage.bangla: 'খরচ',
      AppLanguage.english: 'Spent',
    },
    'total_income': {
      AppLanguage.bangla: 'মোট আয়',
      AppLanguage.english: 'Total Income',
    },
    'total_expense': {
      AppLanguage.bangla: 'মোট খরচ',
      AppLanguage.english: 'Total Expense',
    },
    'salary_received': {
      AppLanguage.bangla: '🎉 বেতন প্রাপ্তি!',
      AppLanguage.english: '🎉 Salary Received!',
    },
    'current_month': {
      AppLanguage.bangla: 'চলতি মাস',
      AppLanguage.english: 'Current Month',
    },
    'family_label': {
      AppLanguage.bangla: 'পরিবার',
      AppLanguage.english: 'Family',
    },
    'our_family': {
      AppLanguage.bangla: 'আমাদের পরিবার',
      AppLanguage.english: 'Our Family',
    },
    'online': {
      AppLanguage.bangla: 'অনলাইন',
      AppLanguage.english: 'Online',
    },
    'offline': {
      AppLanguage.bangla: 'অফলাইন',
      AppLanguage.english: 'Offline',
    },
    'no_entries_found': {
      AppLanguage.bangla: 'কোনো এন্ট্রি পাওয়া যায়নি',
      AppLanguage.english: 'No entries found',
    },
    'welcome_family_banner': {
      AppLanguage.bangla: 'পরিবারে স্বাগতম! হিসাব সংরক্ষণ শুরু করতে নিচে + চাপুন',
      AppLanguage.english: 'Welcome to family! Tap + below to add expenses',
    },
    'recent_prefix': {
      AppLanguage.bangla: 'সর্বশেষ',
      AppLanguage.english: 'Latest',
    },
    'add_expense_fab': {
      AppLanguage.bangla: 'খরচ যুক্ত করুন',
      AppLanguage.english: 'Add Expense',
    },
    'offline_fab_disabled': {
      AppLanguage.bangla: 'অফলাইনে এন্ট্রি বন্ধ',
      AppLanguage.english: 'Offline entry disabled',
    },
    'recent_transactions': {
      AppLanguage.bangla: 'সাম্প্রতিক লেনদেন',
      AppLanguage.english: 'Recent Transactions',
    },
    'delete_transaction_title': {
      AppLanguage.bangla: 'লেনদেন মুছে ফেলা নিশ্চিত করুন',
      AppLanguage.english: 'Confirm Delete Transaction',
    },
    'delete_transaction_msg': {
      AppLanguage.bangla: 'আপনি কি নিশ্চিতভাবে এই লেনদেনটি মুছে ফেলতে চান?',
      AppLanguage.english: 'Are you sure you want to delete this transaction?',
    },
    'personal': {
      AppLanguage.bangla: 'ব্যক্তিগত',
      AppLanguage.english: 'Personal',
    },
    'family': {
      AppLanguage.bangla: 'পারিবারিক',
      AppLanguage.english: 'Family',
    },
    // Private Vault
    'private_vault_appbar': {
      AppLanguage.bangla: 'আমার গোপন ভল্ট',
      AppLanguage.english: 'My Private Vault',
    },
    'direct_msg_tooltip': {
      AppLanguage.bangla: 'সরাসরি বার্তা পাঠান (৩টি/দিন)',
      AppLanguage.english: 'Send Direct Message (3/day)',
    },
    'zero_knowledge_vault': {
      AppLanguage.bangla: 'জিরো-নলেজ ব্যক্তিগত ভল্ট',
      AppLanguage.english: 'Zero-Knowledge Private Vault',
    },
    'zero_knowledge_desc': {
      AppLanguage.bangla: 'এই তথ্য সম্পূর্ণ এনক্রিপ্টেড। পরিবারের এডমিন বা অন্য কোনো সদস্যের এই সেকশনে কোনো অ্যাক্সেস নেই।',
      AppLanguage.english: 'This data is fully encrypted. Family admin or members have zero access to this section.',
    },
    'vault_add_note_title': {
      AppLanguage.bangla: 'ব্যক্তিগত ভল্টে নোট যোগ করুন',
      AppLanguage.english: 'Add Note to Private Vault',
    },
    'vault_note_title_label': {
      AppLanguage.bangla: 'নোটের শিরোনাম',
      AppLanguage.english: 'Note Title',
    },
    'vault_note_title_hint': {
      AppLanguage.bangla: 'যেমন: টাকার অবস্থান বা চাবি',
      AppLanguage.english: 'e.g., Cash location or key',
    },
    'vault_note_desc_label': {
      AppLanguage.bangla: 'গোপন বিবরণ',
      AppLanguage.english: 'Secret Description',
    },
    'vault_note_desc_hint': {
      AppLanguage.bangla: 'বিস্তারিত বিবরণ লিখুন...',
      AppLanguage.english: 'Write detailed description...',
    },
    'vault_save_btn': {
      AppLanguage.bangla: 'নিরাপদে সংরক্ষণ করুন',
      AppLanguage.english: 'Save Securely',
    },
    'vault_hidden_items': {
      AppLanguage.bangla: 'লুকানো জিনিস',
      AppLanguage.english: 'Hidden Items',
    },
    'vault_guest_items': {
      AppLanguage.bangla: 'ব্যক্তিগত মেহমান',
      AppLanguage.english: 'Personal Guests',
    },
    'vault_no_hidden_items': {
      AppLanguage.bangla: 'কোনো গোপন জিনিস সংরক্ষিত নেই',
      AppLanguage.english: 'No secret items saved',
    },
    'vault_no_guest_items': {
      AppLanguage.bangla: 'কোনো ব্যক্তিগত মেহমানের নোট নেই',
      AppLanguage.english: 'No personal guest notes',
    },
    // Splash Dialog
    'splash_change_title': {
      AppLanguage.bangla: 'স্প্ল্যাশ স্ক্রিন ছবি পরিবর্তন',
      AppLanguage.english: 'Change Splash Screen Image',
    },
    'splash_change_desc': {
      AppLanguage.bangla: 'ব্যবহারকারী বা এডমিন হিসেবে পরিবারের অ্যাপ চালু হওয়ার স্প্ল্যাশ স্ক্রিনের ছবি কাস্টমাইজ করুন:',
      AppLanguage.english: 'Customize the splash image displayed when launching the app:',
    },
    'splash_new_selected': {
      AppLanguage.bangla: '✓ নতুন ছবি নির্বাচিত হয়েছে (প্রিভিউ)',
      AppLanguage.english: '✓ New image selected (Preview)',
    },
    'splash_current_custom': {
      AppLanguage.bangla: 'বর্তমান কাস্টম স্প্ল্যাশ ছবি',
      AppLanguage.english: 'Current custom splash image',
    },
    'splash_default_active': {
      AppLanguage.bangla: 'ডিফল্ট অ্যাপ লোগো সক্রিয়',
      AppLanguage.english: 'Default app logo active',
    },
    'camera': {
      AppLanguage.bangla: 'ক্যামেরা',
      AppLanguage.english: 'Camera',
    },
    'gallery': {
      AppLanguage.bangla: 'গ্যালারি',
      AppLanguage.english: 'Gallery',
    },
    'splash_save_btn': {
      AppLanguage.bangla: 'স্প্ল্যাশ ছবি সংরক্ষণ করুন',
      AppLanguage.english: 'Save Splash Image',
    },
    'splash_reset_btn': {
      AppLanguage.bangla: 'ডিফল্ট লোগোতে রিসেট করুন',
      AppLanguage.english: 'Reset to Default Logo',
    },
    'splash_image_pick_error': {
      AppLanguage.bangla: 'ছবি নির্বাচন করতে সমস্যা হয়েছে',
      AppLanguage.english: 'Failed to select image',
    },
    'splash_save_success': {
      AppLanguage.bangla: '🎉 স্প্ল্যাশ স্ক্রিনের ছবি সফলভাবে ফায়ারবেসে সংরক্ষিত হয়েছে!',
      AppLanguage.english: '🎉 Splash screen image saved to Firebase successfully!',
    },
    'splash_save_failed': {
      AppLanguage.bangla: 'সংরক্ষণ ব্যর্থ হয়েছে',
      AppLanguage.english: 'Failed to save',
    },
    'splash_reset_success': {
      AppLanguage.bangla: 'ডিফল্ট পরিবার লোগো সফলভাবে রিসেট করা হয়েছে।',
      AppLanguage.english: 'Default family logo reset successfully.',
    },
    'splash_reset_failed': {
      AppLanguage.bangla: 'রিসেট ব্যর্থ হয়েছে',
      AppLanguage.english: 'Failed to reset',
    },
    // OTP Verification Sheet
    'otp_sheet_title': {
      AppLanguage.bangla: 'মোবাইল নম্বর ওটিপি যাচাইকরণ',
      AppLanguage.english: 'Mobile OTP Verification',
    },
    'otp_info_prefix': {
      AppLanguage.bangla: 'নম্বরে ফায়ারবেস থেকে ৬ ডিজিটের এসএমএস ওটিপি পাঠানো হয়েছে',
      AppLanguage.english: 'A 6-digit SMS OTP has been sent from Firebase to',
    },
    'otp_sending_status': {
      AppLanguage.bangla: 'গুগল ফায়ারবেস থেকে এসএমএস ওটিপি পাঠানো হচ্ছে...',
      AppLanguage.english: 'Sending SMS OTP from Google Firebase...',
    },
    'otp_sent_status': {
      AppLanguage.bangla: 'নম্বরে ৬ ডিজিটের এসএমএস কোড পাঠানো হয়েছে।',
      AppLanguage.english: '6-digit SMS code sent to',
    },
    'otp_code_label': {
      AppLanguage.bangla: '৬ ডিজিটের এসএমএস কোড',
      AppLanguage.english: '6-Digit SMS Code',
    },
    'otp_wait_seconds': {
      AppLanguage.bangla: 'অপেক্ষা',
      AppLanguage.english: 'Wait',
    },
    'otp_seconds_unit': {
      AppLanguage.bangla: 'সে.',
      AppLanguage.english: 's',
    },
    'otp_didnt_get_code': {
      AppLanguage.bangla: 'কোড পাননি?',
      AppLanguage.english: "Didn't receive code?",
    },
    'otp_resend': {
      AppLanguage.bangla: 'পুনরায় পাঠান',
      AppLanguage.english: 'Resend',
    },
    'otp_verifying': {
      AppLanguage.bangla: 'যাচাই করা হচ্ছে...',
      AppLanguage.english: 'Verifying...',
    },
    'otp_verify_btn': {
      AppLanguage.bangla: 'ওটিপি যাচাই সম্পন্ন করুন',
      AppLanguage.english: 'Complete OTP Verification',
    },
    'otp_enter_6_digits': {
      AppLanguage.bangla: 'আপনার মোবাইলে আসা ৬ ডিজিটের ওটিপি কোডটি লিখুন',
      AppLanguage.english: 'Enter the 6-digit OTP code received on your phone',
    },
    'otp_code_not_sent_yet': {
      AppLanguage.bangla: 'এসএমএস কোড এখনও পাঠানো সম্পন্ন হয়নি, কিছুক্ষণ অপেক্ষা করুন',
      AppLanguage.english: 'SMS code has not finished sending yet, please wait a moment',
    },
    'otp_invalid_code': {
      AppLanguage.bangla: 'ভুল ওটিপি কোড! মোবাইলে আসা সঠিক এসএমএস কোডটি দিন।',
      AppLanguage.english: 'Invalid OTP code! Please enter the code from your SMS.',
    },
    'otp_session_expired': {
      AppLanguage.bangla: 'ওটিপি কোডের মেয়াদ শেষ হয়ে গেছে। পুনরায় কোড পাঠান।',
      AppLanguage.english: 'OTP code expired. Please resend code.',
    },
    'otp_verification_failed': {
      AppLanguage.bangla: 'যাচাইকরণ ব্যর্থ হয়েছে',
      AppLanguage.english: 'Verification failed',
    },
    // Invitation Banner
    'invitation_new_title': {
      AppLanguage.bangla: 'পরিবারে যোগদানের নতুন আমন্ত্রণ!',
      AppLanguage.english: 'New Family Invitation!',
    },
    'invitation_default_family': {
      AppLanguage.bangla: 'একটি পরিবার',
      AppLanguage.english: 'A Family',
    },
    'invitation_default_admin': {
      AppLanguage.bangla: 'পরিবার এডমিন',
      AppLanguage.english: 'Family Admin',
    },
    'invitation_default_role': {
      AppLanguage.bangla: 'সদস্য',
      AppLanguage.english: 'Member',
    },
    'invitation_accept': {
      AppLanguage.bangla: 'গ্রহণ করুন',
      AppLanguage.english: 'Accept',
    },
    'invitation_reject': {
      AppLanguage.bangla: 'প্রত্যাখ্যান করুন',
      AppLanguage.english: 'Decline',
    },
    'invitation_joined_success': {
      AppLanguage.bangla: 'আপনি সফলভাবে পরিবারে যুক্ত হয়েছেন!',
      AppLanguage.english: 'You have joined the family successfully!',
    },
    'invitation_accept_failed': {
      AppLanguage.bangla: 'আমন্ত্রণ গ্রহণ করা সম্ভব হয়নি',
      AppLanguage.english: 'Could not accept invitation',
    },
    'invitation_rejected_msg': {
      AppLanguage.bangla: 'আমন্ত্রণ প্রত্যাখ্যান করা হয়েছে।',
      AppLanguage.english: 'Invitation was declined.',
    },
    // Namaj Alarm Screen
    'namaj_alarm_screen_title': {
      AppLanguage.bangla: 'নামাজের সময়সূচি ও অ্যালার্ম',
      AppLanguage.english: 'Prayer Times & Alarm',
    },
    'today_waqt': {
      AppLanguage.bangla: 'আজকের ওয়াক্ত',
      AppLanguage.english: "Today's Waqt",
    },
    'live_update': {
      AppLanguage.bangla: 'লাইভ আপডেট',
      AppLanguage.english: 'Live Update',
    },
    'currently_running': {
      AppLanguage.bangla: 'এখন চলছে',
      AppLanguage.english: 'Current Waqt',
    },
    'time_duration': {
      AppLanguage.bangla: 'সময়কাল',
      AppLanguage.english: 'Duration',
    },
    'sahri_iftar_header': {
      AppLanguage.bangla: 'সাহরি ও ইফতার:',
      AppLanguage.english: 'Sahri & Iftar:',
    },
    'sahri_ends': {
      AppLanguage.bangla: 'সাহরি শেষ',
      AppLanguage.english: 'Sahri Ends',
    },
    'iftar_starts': {
      AppLanguage.bangla: 'ইফতার',
      AppLanguage.english: 'Iftar',
    },
    'offset_start': {
      AppLanguage.bangla: 'ওয়াক্তের শুরুতে',
      AppLanguage.english: 'At start of waqt',
    },
    'offset_5_mins': {
      AppLanguage.bangla: '৫ মিনিট আগে',
      AppLanguage.english: '5 minutes before',
    },
    'offset_10_mins': {
      AppLanguage.bangla: '১০ মিনিট আগে',
      AppLanguage.english: '10 minutes before',
    },
    'offset_15_mins': {
      AppLanguage.bangla: '১৫ মিনিট আগে',
      AppLanguage.english: '15 minutes before',
    },
    'sound_adhan': {
      AppLanguage.bangla: 'আযান সাউন্ড',
      AppLanguage.english: 'Adhan Sound',
    },
    'sound_gentle': {
      AppLanguage.bangla: 'মধুর অ্যালার্ম',
      AppLanguage.english: 'Gentle Alarm',
    },
    'sound_vibrate': {
      AppLanguage.bangla: 'শুধু ভাইব্রেশন',
      AppLanguage.english: 'Vibration Only',
    },
    // Rate Limited Direct Ping
    'ping_sheet_title': {
      AppLanguage.bangla: '১-টু-১ ডিরেক্ট পিং পাঠান (দৈনিক ৩টি)',
      AppLanguage.english: 'Send 1-to-1 Direct Ping (Max 3/day)',
    },
    'ping_permission_blocked': {
      AppLanguage.bangla: 'আপনার পুশ বা বার্তা পাঠানোর অনুমতি বন্ধ রয়েছে। পরিবারের অ্যাডমিনের সাথে যোগাযোগ করুন।',
      AppLanguage.english: 'Your push message permission is disabled. Contact your family admin.',
    },
    'ping_daily_quota_title': {
      AppLanguage.bangla: 'দৈনিক পিং লিমিট',
      AppLanguage.english: 'Daily Ping Limit',
    },
    'ping_used_text': {
      AppLanguage.bangla: 'টি ব্যবহৃত',
      AppLanguage.english: 'used',
    },
    'ping_limit_over': {
      AppLanguage.bangla: 'লিমিট শেষ',
      AppLanguage.english: 'Limit Reached',
    },
    'ping_left_text': {
      AppLanguage.bangla: 'টি অবশিষ্ট',
      AppLanguage.english: 'remaining',
    },
    'ping_limit_over_desc': {
      AppLanguage.bangla: 'আপনি আজকের সর্বোচ্চ ৩টি ডিরেক্ট পিং কোটা সম্পন্ন করেছেন। রাত ১২টার পর কোটা স্বয়ংক্রিয়ভাবে রিসেট হবে।',
      AppLanguage.english: 'You have reached today’s limit of 3 direct pings. It will reset after midnight.',
    },
    'ping_no_other_members': {
      AppLanguage.bangla: 'পরিবারে এখনও অন্য কোনো সদস্য যুক্ত হননি।',
      AppLanguage.english: 'No other members in this family yet.',
    },
    'ping_no_members_hint': {
      AppLanguage.bangla: 'সদস্য যুক্ত করতে মেনু থেকে "পরিবারের সদস্য" তালিকায় যান।',
      AppLanguage.english: 'Go to Member List from menu to add members.',
    },
    'ping_msg_label': {
      AppLanguage.bangla: 'সরাসরি জরুরি বার্তা',
      AppLanguage.english: 'Direct Urgent Message',
    },
    'ping_msg_hint': {
      AppLanguage.bangla: 'যেমন: টাকা কি পেয়েছ? ৫০০ টাকা...',
      AppLanguage.english: 'e.g., Did you receive the money?',
    },
    'ping_btn_no_perm': {
      AppLanguage.bangla: 'অনুমতি বন্ধ আছে',
      AppLanguage.english: 'Permission Disabled',
    },
    'ping_btn_limit_over': {
      AppLanguage.bangla: 'আজকের লিমিট শেষ',
      AppLanguage.english: 'Today’s Limit Reached',
    },
    'ping_btn_send': {
      AppLanguage.bangla: 'সরাসরি বার্তা পাঠান',
      AppLanguage.english: 'Send Direct Ping',
    },
    'ping_sent_success': {
      AppLanguage.bangla: 'ডিরেক্ট মেসেজ পাঠানো হয়েছে!',
      AppLanguage.english: 'Direct message sent!',
    },
    // Custom Camera Screen
    'camera_scanner_title': {
      AppLanguage.bangla: 'রসিদ ক্যামেরা স্ক্যানার',
      AppLanguage.english: 'Receipt Camera Scanner',
    },
    'camera_box_title': {
      AppLanguage.bangla: 'রসিদ বা ভাউচারের ছবি তুলুন',
      AppLanguage.english: 'Capture Receipt or Voucher',
    },
    'camera_box_subtitle': {
      AppLanguage.bangla: 'ক্যামেরা বা গ্যালারি থেকে ছবি নির্বাচন করুন',
      AppLanguage.english: 'Select image from Camera or Gallery',
    },
    'camera_open_error': {
      AppLanguage.bangla: 'ক্যামেরা খুলতে সমস্যা হয়েছে',
      AppLanguage.english: 'Failed to open camera',
    },
    'gallery_open_error': {
      AppLanguage.bangla: 'গ্যালারি খুলতে সমস্যা হয়েছে',
      AppLanguage.english: 'Failed to open gallery',
    },
    'camera_retake': {
      AppLanguage.bangla: 'পুনরায় তুলুন',
      AppLanguage.english: 'Retake',
    },
    'camera_save': {
      AppLanguage.bangla: 'সংরক্ষণ করুন',
      AppLanguage.english: 'Save',
    },
    // Advanced Expense Graphs
    'month_1': { AppLanguage.bangla: 'জানুয়ারি', AppLanguage.english: 'January' },
    'month_2': { AppLanguage.bangla: 'ফেব্রুয়ারি', AppLanguage.english: 'February' },
    'month_3': { AppLanguage.bangla: 'মার্চ', AppLanguage.english: 'March' },
    'month_4': { AppLanguage.bangla: 'এপ্রিল', AppLanguage.english: 'April' },
    'month_5': { AppLanguage.bangla: 'মে', AppLanguage.english: 'May' },
    'month_6': { AppLanguage.bangla: 'জুন', AppLanguage.english: 'June' },
    'month_7': { AppLanguage.bangla: 'জুলাই', AppLanguage.english: 'July' },
    'month_8': { AppLanguage.bangla: 'আগস্ট', AppLanguage.english: 'August' },
    'month_9': { AppLanguage.bangla: 'সেপ্টেম্বর', AppLanguage.english: 'September' },
    'month_10': { AppLanguage.bangla: 'অক্টোবর', AppLanguage.english: 'October' },
    'month_11': { AppLanguage.bangla: 'নভেম্বর', AppLanguage.english: 'November' },
    'month_12': { AppLanguage.bangla: 'ডিসেম্বর', AppLanguage.english: 'December' },
    'monthly_trend': {
      AppLanguage.bangla: 'মাসিক ট্রেন্ড',
      AppLanguage.english: 'Monthly Trend',
    },
    'category_distribution': {
      AppLanguage.bangla: 'খাতওয়ারি বন্টন',
      AppLanguage.english: 'Category Breakdown',
    },
    'no_transactions_recorded': {
      AppLanguage.bangla: 'কোন লেনদেন রেকর্ড করা হয়নি',
      AppLanguage.english: 'No transactions recorded yet',
    },
    'add_transaction_hint': {
      AppLanguage.bangla: 'নিচের + বাটনে চেপে আয় বা খরচ যোগ করুন',
      AppLanguage.english: 'Tap + button below to add income or expense',
    },
    'income_legend': {
      AppLanguage.bangla: 'আয়',
      AppLanguage.english: 'Income',
    },
    'expense_legend': {
      AppLanguage.bangla: 'খরচ',
      AppLanguage.english: 'Expense',
    },
    'date_suffix': {
      AppLanguage.bangla: 'তারিখ',
      AppLanguage.english: 'Date',
    },
    'no_category_expense': {
      AppLanguage.bangla: 'কোন ক্যাটাগরি খরচ পাওয়া যায়নি',
      AppLanguage.english: 'No category expenses found',
    },
    // Salary Celebration Dialog
    'salary_alhamdulillah': {
      AppLanguage.bangla: '🎉 আলহামদুলিল্লাহ!',
      AppLanguage.english: '🎉 Alhamdulillah!',
    },
    'salary_celebration_subtitle': {
      AppLanguage.bangla: 'পরিবারে নতুন বেতন জমা হয়েছে',
      AppLanguage.english: 'New salary deposited into family',
    },
    'deposited_by': {
      AppLanguage.bangla: 'জমা করেছেন',
      AppLanguage.english: 'Deposited by',
    },
    'salary_slip_attached': {
      AppLanguage.bangla: 'বেতনের রসিদ / স্টেটমেন্ট ছবি সংযুক্ত',
      AppLanguage.english: 'Salary slip / statement photo attached',
    },
    'smart_budget_advice': {
      AppLanguage.bangla: 'স্মার্ট পারিবারিক বাজেট বণ্টন পরামর্শ:',
      AppLanguage.english: 'Smart Family Budget Allocation Guide:',
    },
    'budget_50_essential': {
      AppLanguage.bangla: '৫০% নিত্যপ্রয়োজনীয় (বাজার, বিল, ভাড়া)',
      AppLanguage.english: '50% Essentials (Groceries, Bills, Rent)',
    },
    'budget_30_lifestyle': {
      AppLanguage.bangla: '৩০% পারিবারিক চাহিদা ও পোশাক',
      AppLanguage.english: '30% Wants & Lifestyle',
    },
    'budget_20_savings': {
      AppLanguage.bangla: '২০% জরুরি সঞ্চয় ও ডিপিএস ফান্ড',
      AppLanguage.english: '20% Emergency Savings & DPS',
    },
    'salary_done_btn': {
      AppLanguage.bangla: 'আলহামদুলিল্লাহ, সম্পন্ন করুন',
      AppLanguage.english: 'Alhamdulillah, Done',
    },
    // Amol & Dropdown Dynamic Option Add
    'add_new_amol': {
      AppLanguage.bangla: 'নতুন আমল / জিকির যুক্ত করুন',
      AppLanguage.english: 'Add New Amol / Dhikr',
    },
    'amol_name_bn': {
      AppLanguage.bangla: 'জিকির / দোয়ার নাম (বাংলা)',
      AppLanguage.english: 'Dhikr Name (Bengali)',
    },
    'amol_name_ar': {
      AppLanguage.bangla: 'আরবি উচ্চারণ (ঐচ্ছিক)',
      AppLanguage.english: 'Arabic Pronunciation (Optional)',
    },
    'amol_virtue': {
      AppLanguage.bangla: 'ফজিলত / তাৎপর্য',
      AppLanguage.english: 'Virtue / Meaning',
    },
    'amol_target': {
      AppLanguage.bangla: 'দৈনিক লক্ষ্য (টার্গেট সংখ্যা)',
      AppLanguage.english: 'Daily Target Count',
    },
    'add_new_dropdown_option': {
      AppLanguage.bangla: 'নতুন অপশন যোগ করুন',
      AppLanguage.english: 'Add New Option',
    },
    'dropdown_option_label': {
      AppLanguage.bangla: 'নতুন অপশনের নাম',
      AppLanguage.english: 'Option Name',
    },
    'save_option_btn': {
      AppLanguage.bangla: 'সংরক্ষণ করুন',
      AppLanguage.english: 'Save',
    },
    'save_amol_success': {
      AppLanguage.bangla: 'নতুন আমল সফলভাবে ফায়ারবেসে সংরক্ষিত হয়েছে!',
      AppLanguage.english: 'New Amol saved to Firebase successfully!',
    },
    'app_name': {
      AppLanguage.bangla: 'SRH',
      AppLanguage.english: 'SRH',
    },
    'app_tagline': {
      AppLanguage.bangla: 'স্মার্ট পারিবারিক হিসাব ও বাজেট নিয়ন্ত্রণ',
      AppLanguage.english: 'Smart Family Accounts & Budget Management',
    },
    'drawer_dashboard': {
      AppLanguage.bangla: 'ড্যাশবোর্ড ও খতিয়ান',
      AppLanguage.english: 'Dashboard & Ledger',
    },
    'drawer_members': {
      AppLanguage.bangla: 'সদস্য ও পারমিশন',
      AppLanguage.english: 'Members & Permissions',
    },
    'drawer_loans': {
      AppLanguage.bangla: 'ধার-দেনা ও পাওনা হিসাব',
      AppLanguage.english: 'Loans & Receivables',
    },
    'drawer_savings': {
      AppLanguage.bangla: 'পারিবারিক সঞ্চয় ও তহবিল',
      AppLanguage.english: 'Savings & Funds',
    },
    'drawer_namaz': {
      AppLanguage.bangla: 'নামাজের সময় ও অ্যালার্ম',
      AppLanguage.english: 'Prayer Times & Alarm',
    },
    'drawer_amol': {
      AppLanguage.bangla: 'ডিজিটাল তাসবিহ ও আয়াতুল কুরসি',
      AppLanguage.english: 'Digital Tasbih & Ayatul Kursi',
    },
    'drawer_notifications': {
      AppLanguage.bangla: 'নোটিফিকেশন সেন্টার',
      AppLanguage.english: 'Notification Center',
    },
    'drawer_vault': {
      AppLanguage.bangla: 'প্রাইভেট ভল্ট',
      AppLanguage.english: 'Private Vault',
    },
    'drawer_splash': {
      AppLanguage.bangla: 'স্প্ল্যাশ স্ক্রিন পরিবর্তন',
      AppLanguage.english: 'Customize Splash',
    },
    'drawer_language': {
      AppLanguage.bangla: 'ভাষা (Language)',
      AppLanguage.english: 'Language',
    },
    'drawer_logout': {
      AppLanguage.bangla: 'লগআউট',
      AppLanguage.english: 'Logout',
    },
    'loan_given_label': {
      AppLanguage.bangla: 'পাওনা টাকা (দিয়েছি)',
      AppLanguage.english: 'Receivable (Lent)',
    },
    'loan_taken_label': {
      AppLanguage.bangla: 'দেনা টাকা (নিয়েছি)',
      AppLanguage.english: 'Payable (Borrowed)',
    },
    'total_savings_label': {
      AppLanguage.bangla: 'মোট সঞ্চয়',
      AppLanguage.english: 'Total Savings',
    },
    'all_combined': {
      AppLanguage.bangla: 'সম্মিলিত',
      AppLanguage.english: 'Combined',
    },
    'ayatul_kursi_title': {
      AppLanguage.bangla: 'আয়াতুল কুরসি',
      AppLanguage.english: 'Ayatul Kursi',
    },
    'ayatul_kursi_desc': {
      AppLanguage.bangla: 'কুরআনের সর্বশ্রেষ্ঠ আয়াত, হেফাজত ও বরকতের অমূল্য ঢাল',
      AppLanguage.english: 'The greatest verse of Quran, ultimate protection & blessing',
    },
    'ayatul_kursi_arabic': {
      AppLanguage.bangla: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      AppLanguage.english: 'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta\'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-\'ard. Man dhal-ladhi yashfa\'u \'indahu illa bi-idhnihi? Ya\'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bishay\'im-min \'ilmihi illa bima sha\'a. Wasi\'a kursiyyuhus-samawati wal-\'ard, wa la ya\'uduhu hifdhuhuma wa Huwal-\'Aliyyul-\'Adheem.',
    },
    'ayatul_kursi_bangla_pronunciation': {
      AppLanguage.bangla: 'উচ্চারণ: আল্লা-হু লা- ইলা-হা ইল্লা- হুওয়াল হাইয়্যুল ক্বাইয়্যূম। লা- তা’খুযুহু ছিনাতুঁও ওয়ালা- নাওম। লাহূ মা- ফিসসামা-ওয়া-তি ওয়ামা- ফিল আরদ্ব। মান যাল্লাযী ইয়াশফা‘উ ‘ইনদাহূ ইল্লা- বিইযনিহী। ইয়া‘লামু মা- বাইনা আইদীহিম ওয়ামা- খালফাহুম, ওয়ালা- ইউহীতূনা বিশাইইম মিন ‘ইলমিহী ইল্লা- বিমা- শা-আ। ওয়াসি‘আ কুরসিয়্যুহুস সামা-ওয়া-তি ওয়াল আরদ্ব, ওয়ালা- ইয়াউদুহু হিফযুহুমা- ওয়াহুওয়াল ‘আলিয়্যুল ‘আযীম।',
      AppLanguage.english: 'Pronunciation: Allahu la ilaha illa Huwal Hayyul Qayyum...',
    },
    'ayatul_kursi_bangla_meaning': {
      AppLanguage.bangla: 'অর্থ: আল্লাহ, তিনি ছাড়া কোনো সত্য উপাস্য নেই। তিনি চিরঞ্জীব, সবকিছুর ধারক। তন্দ্রা বা নিদ্রা তাঁকে স্পর্শ করে না। আসমান ও জমিনে যা কিছু আছে সব তাঁরই। কে সেই ব্যক্তি যে তাঁর অনুমতি ছাড়া তাঁর কাছে সুপারিশ করবে? তাদের সামনে ও পেছনে যা কিছু আছে তা তিনি জানেন। তিনি যা ইচ্ছা করেন তা ছাড়া তাঁর জ্ঞানের কিছুই তারা আয়ত্ত করতে পারে না। তাঁর কুরসি সমস্ত আসমান ও জমিন পরিব্যাপ্ত করে আছে। আর এই দুইয়ের রক্ষণাবেক্ষণ তাঁকে ক্লান্ত করে না। তিনি সর্বোচ্চ, মহান।',
      AppLanguage.english: 'Meaning: Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep...',
    },
    'filter_all': {
      AppLanguage.bangla: 'সব লেনদেন',
      AppLanguage.english: 'All Transactions',
    },
    'filter_expense': {
      AppLanguage.bangla: 'ব্যয়',
      AppLanguage.english: 'Expense',
    },
    'filter_income': {
      AppLanguage.bangla: 'আয়',
      AppLanguage.english: 'Income',
    },
    'filter_loan': {
      AppLanguage.bangla: 'ধার-দেনা',
      AppLanguage.english: 'Loans',
    },
    // Core financial categories & types
    'emi_installment': {
      AppLanguage.bangla: 'ইএমআই ও কিস্তি',
      AppLanguage.english: 'EMI & Installment',
    },
    'rent': {
      AppLanguage.bangla: 'বাড়ি ভাড়া',
      AppLanguage.english: 'House Rent',
    },
    'electricity_bill': {
      AppLanguage.bangla: 'বিদ্যুৎ বিল',
      AppLanguage.english: 'Electricity Bill',
    },
    'net_bill': {
      AppLanguage.bangla: 'ইন্টারনেট ও নেট বিল',
      AppLanguage.english: 'Internet / Net Bill',
    },
    'pay_to_someone': {
      AppLanguage.bangla: 'কাউকে পরিশোধ (দেনা)',
      AppLanguage.english: 'Pay to Someone (Payable)',
    },
    'get_by_someone': {
      AppLanguage.bangla: 'কারও থেকে গ্রহণ (পাওনা)',
      AppLanguage.english: 'Received from Someone (Receivable)',
    },
    'custom_category': {
      AppLanguage.bangla: 'কাস্টম খাত',
      AppLanguage.english: 'Custom Category',
    },
    'add_custom_category': {
      AppLanguage.bangla: 'নতুন কাস্টম খাত যোগ করুন',
      AppLanguage.english: 'Add Custom Category',
    },
    'category_name_bn': {
      AppLanguage.bangla: 'খাতের নাম (বাংলা)',
      AppLanguage.english: 'Category Name (Bangla)',
    },
    'category_name_en': {
      AppLanguage.bangla: 'খাতের নাম (ইংরেজি)',
      AppLanguage.english: 'Category Name (English)',
    },
    'choose_color': {
      AppLanguage.bangla: 'রং নির্বাচন করুন',
      AppLanguage.english: 'Select Color',
    },
    'edit_transaction': {
      AppLanguage.bangla: 'লেনদেন সম্পাদনা',
      AppLanguage.english: 'Edit Transaction',
    },
    'delete_transaction': {
      AppLanguage.bangla: 'লেনদেন মুছে ফেলুন',
      AppLanguage.english: 'Delete Transaction',
    },
    'delete_confirm': {
      AppLanguage.bangla: 'আপনি কি নিশ্চিতভাবে এই লেনদেনটি মুছে ফেলতে চান?',
      AppLanguage.english: 'Are you sure you want to delete this transaction?',
    },
    'personal_ledger_scope': {
      AppLanguage.bangla: 'আমার ব্যক্তিগত খতিয়ান',
      AppLanguage.english: 'My Personal Ledger',
    },
    'family_ledger_scope': {
      AppLanguage.bangla: 'পারিবারিক যৌথ খতিয়ান',
      AppLanguage.english: 'Family Joint Ledger',
    },
    'due_date_label': {
      AppLanguage.bangla: 'পরিশোধের শেষ তারিখ (অ্যালার্ম)',
      AppLanguage.english: 'Due Date (Payment Alarm)',
    },
    'due_date_hint': {
      AppLanguage.bangla: 'নির্ধারিত দিনে সকাল ৭টা, ৮টা এবং দুপুর ১২টায় অ্যালার্ম বাজবে',
      AppLanguage.english: 'Alarms will alert at 7:00 AM, 8:00 AM and 12:00 on due date',
    },
    'attach_receipt': {
      AppLanguage.bangla: 'রসিদ / ভাউচার সংযুক্ত করুন',
      AppLanguage.english: 'Attach Receipt / Voucher',
    },
    'quick_amount': {
      AppLanguage.bangla: 'দ্রুত পরিমাণ',
      AppLanguage.english: 'Quick Amount',
    },
    // Push notifications (8 cases)
    'push_custom_title': {
      AppLanguage.bangla: 'পারিবারিক বিজ্ঞপ্তি',
      AppLanguage.english: 'Family Notice',
    },
    'push_chat_title': {
      AppLanguage.bangla: 'নতুন চ্যাট বার্তা',
      AppLanguage.english: 'New Chat Message',
    },
    'push_entry_created': {
      AppLanguage.bangla: 'নতুন লেনদেন এন্ট্রি',
      AppLanguage.english: 'New Transaction Entry',
    },
    'push_entry_updated': {
      AppLanguage.bangla: 'লেনদেন হালনাগাদ',
      AppLanguage.english: 'Transaction Updated',
    },
    'push_invite_received': {
      AppLanguage.bangla: 'পারিবারিক আমন্ত্রণ',
      AppLanguage.english: 'Family Invitation',
    },
    'push_member_added': {
      AppLanguage.bangla: 'নতুন সদস্য যুক্ত হয়েছেন 🎉',
      AppLanguage.english: 'New Member Joined 🎉',
    },
    'push_member_removed': {
      AppLanguage.bangla: 'পারিবারিক সদস্যপদ আপডেট',
      AppLanguage.english: 'Family Membership Update',
    },
    'push_payment_due_alarm': {
      AppLanguage.bangla: 'পরিশোধ অনুস্মারক (জরুরি)',
      AppLanguage.english: 'Payment Due Reminder (Urgent)',
    },
    'push_category_updated': {
      AppLanguage.bangla: 'পারিবারিক হিসাবের খাত আপডেট',
      AppLanguage.english: 'Expense Category Updated',
    },
    // Prayer & Azan
    'fajr_name': {
      AppLanguage.bangla: 'ফজর',
      AppLanguage.english: 'Fajr',
    },
    'dhuhr_name': {
      AppLanguage.bangla: 'যোহর',
      AppLanguage.english: 'Dhuhr',
    },
    'asr_name': {
      AppLanguage.bangla: 'আসর',
      AppLanguage.english: 'Asr',
    },
    'maghrib_name': {
      AppLanguage.bangla: 'মাগরিব',
      AppLanguage.english: 'Maghrib',
    },
    'isha_name': {
      AppLanguage.bangla: 'এশা ও তারাবীহ',
      AppLanguage.english: 'Isha',
    },
    'azan_alarm_enabled': {
      AppLanguage.bangla: 'আযান ও ওয়াক্ত অ্যালার্ম চালু',
      AppLanguage.english: 'Adhan & Waqt Alarm Active',
    },
    'azan_alarm_disabled': {
      AppLanguage.bangla: 'অ্যালার্ম বন্ধ',
      AppLanguage.english: 'Alarm Off',
    },
    'sound_high': {
      AppLanguage.bangla: 'উচ্চ শব্দ ও ভাইব্রেশন',
      AppLanguage.english: 'High Sound & Vibration',
    },
    'alarm_time_offset': {
      AppLanguage.bangla: 'ওয়াক্তের কতক্ষণ আগে অ্যালার্ম',
      AppLanguage.english: 'Reminder Before Waqt',
    },
    'on_time': {
      AppLanguage.bangla: 'ওয়াক্তের সঠিক সময়ে',
      AppLanguage.english: 'Exact on time',
    },
    'minutes_before': {
      AppLanguage.bangla: 'মিনিট আগে',
      AppLanguage.english: 'minutes before',
    },
    // Quranic Surahs & Duas
    'surahs_duas_tab': {
      AppLanguage.bangla: 'সূরা ও দুআ',
      AppLanguage.english: 'Surahs & Duas',
    },
    'dua_qunut_title': {
      AppLanguage.bangla: 'দুআ কুনুত (বিতর নামাজ)',
      AppLanguage.english: 'Dua Qunut (Witr Prayer)',
    },
    'sura_ar_rahman_title': {
      AppLanguage.bangla: 'সূরা আর-রহমান',
      AppLanguage.english: 'Surah Ar-Rahman',
    },
    'sura_yasin_title': {
      AppLanguage.bangla: 'সূরা ইয়াসিন (কুরআনের হৃৎপিণ্ড)',
      AppLanguage.english: 'Surah Yasin (Heart of Quran)',
    },
    'sura_mulk_title': {
      AppLanguage.bangla: 'সূরা আল-মুলক (কবরের আজাব মুক্তি)',
      AppLanguage.english: 'Surah Al-Mulk',
    },
    'sura_kahaf_title': {
      AppLanguage.bangla: 'সূরা আল-কাহাফ (জুমার বিশেষ আমল)',
      AppLanguage.english: 'Surah Al-Kahf',
    },
    'arabic_script': {
      AppLanguage.bangla: 'মূল আরবি তিলাওয়াত',
      AppLanguage.english: 'Arabic Recitation',
    },
    'bangla_pronunciation': {
      AppLanguage.bangla: 'উচ্চারণ',
      AppLanguage.english: 'Pronunciation',
    },
    'bangla_meaning': {
      AppLanguage.bangla: 'বাংলা অনুবাদ ও অর্থ',
      AppLanguage.english: 'Meaning & Translation',
    },
    'virtues_and_benefits': {
      AppLanguage.bangla: 'ফজিলত ও বরকত',
      AppLanguage.english: 'Virtues & Benefits',
    },
    'copy_success': {
      AppLanguage.bangla: 'ক্লিপবোর্ডে কপি করা হয়েছে!',
      AppLanguage.english: 'Copied to clipboard!',
    },
    'server_synced': {
      AppLanguage.bangla: 'সার্ভার থেকে সংগৃহীত',
      AppLanguage.english: 'Synced from Server',
    },
    // Custom Camera
    'camera_viewfinder_title': {
      AppLanguage.bangla: 'স্বচ্ছ রসিদ স্ক্যানার',
      AppLanguage.english: 'Transparent Receipt Scanner',
    },
    'camera_scan_hint': {
      AppLanguage.bangla: 'রসিদ বা ভাউচারটি স্বচ্ছ ফ্রেমের মাঝে রাখুন',
      AppLanguage.english: 'Align receipt or voucher within the frame',
    },
    'capture_photo': {
      AppLanguage.bangla: 'ছবি তুলুন',
      AppLanguage.english: 'Take Photo',
    },
    'retake_photo': {
      AppLanguage.bangla: 'পুনরায় তুলুন',
      AppLanguage.english: 'Retake',
    },
    'use_photo': {
      AppLanguage.bangla: 'এই ছবি ব্যবহার করুন',
      AppLanguage.english: 'Use Photo',
    },
    'camera_permission_needed': {
      AppLanguage.bangla: 'ক্যামেরা ব্যবহারের অনুমতি প্রয়োজন',
      AppLanguage.english: 'Camera permission required',
    },
    'camera_initialize_error': {
      AppLanguage.bangla: 'ক্যামেরা চালু করা সম্ভব হয়নি',
      AppLanguage.english: 'Failed to initialize camera',
    },
    'digital_tasbih': {
      AppLanguage.bangla: 'ডিজিটাল তসবিহ',
      AppLanguage.english: 'Digital Tasbih',
    },
    'surahs_and_duas': {
      AppLanguage.bangla: 'সূরা ও দুআ সমূহ',
      AppLanguage.english: 'Surahs & Duas',
    },
    'family_amol_board': {
      AppLanguage.bangla: 'পরিবারের আমল বোর্ড',
      AppLanguage.english: 'Family Amol Board',
    },
    'personal_scope': {
      AppLanguage.bangla: 'ব্যক্তিগত',
      AppLanguage.english: 'Personal',
    },
    'family_scope': {
      AppLanguage.bangla: 'পারিবারিক',
      AppLanguage.english: 'Family',
    },
    'tab_expense': {
      AppLanguage.bangla: 'খরচ',
      AppLanguage.english: 'Expense',
    },
    'tab_income': {
      AppLanguage.bangla: 'আয়',
      AppLanguage.english: 'Income',
    },
    'tab_savings': {
      AppLanguage.bangla: 'সঞ্চয়',
      AppLanguage.english: 'Savings',
    },
    'loan_given': {
      AppLanguage.bangla: 'ধার প্রদান',
      AppLanguage.english: 'Loan Given',
    },
    'loan_taken': {
      AppLanguage.bangla: 'ধার গ্রহণ',
      AppLanguage.english: 'Loan Taken',
    },
    'empty_data': {
      AppLanguage.bangla: 'কোনো বার্তা বা তথ্য নেই',
      AppLanguage.english: 'No data available',
    },
    'no_data': {
      AppLanguage.bangla: 'কোনো তথ্য নেই',
      AppLanguage.english: 'No data',
    },
    'dashboard': {
      AppLanguage.bangla: 'ড্যাশবোর্ড',
      AppLanguage.english: 'Dashboard',
    },
    'expense': {
      AppLanguage.bangla: 'খরচ',
      AppLanguage.english: 'Expense',
    },
    'income': {
      AppLanguage.bangla: 'আয়',
      AppLanguage.english: 'Income',
    },
    'savings': {
      AppLanguage.bangla: 'সঞ্চয়',
      AppLanguage.english: 'Savings',
    },
  };

  String translate(String key, [Map<String, String>? params]) {
    String val = _localizedValues[key]?[language] ?? key;
    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramVal) {
        val = val.replaceAll('{$paramKey}', paramVal);
      });
    }
    return val;
  }

  String t(String key, [Map<String, String>? params]) => translate(key, params);
}

