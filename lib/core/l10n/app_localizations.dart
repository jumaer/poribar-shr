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
      AppLanguage.bangla: 'বকেয়া পরিষদ',
      AppLanguage.english: 'Payments Due',
    },
    'highest_expenses': {
      AppLanguage.bangla: 'সর্বোচ্চ খরচ',
      AppLanguage.english: 'Highest Expenses',
    },
  };

  String translate(String key) {
    return _localizedValues[key]?[language] ?? key;
  }
}
