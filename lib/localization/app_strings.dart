enum AppLanguage { english, kinyarwanda }

/// Looks up [key] in the given [language]. Falls back to the key
/// itself (i.e. the English text) if no translation exists yet —
/// extending coverage is just adding an entry below.
String t(String key, AppLanguage language) =>
    _translations[key]?[language] ?? key;

const _translations = <String, Map<AppLanguage, String>>{
  // Bottom nav
  'Dashboard': {AppLanguage.kinyarwanda: 'Ahabanza'},
  'Students': {AppLanguage.kinyarwanda: 'Abanyeshuri'},
  'Intervention': {AppLanguage.kinyarwanda: 'Ubufasha'},
  'Profile': {AppLanguage.kinyarwanda: 'Umwirondoro'},

  // Role select
  'Select Your Role': {AppLanguage.kinyarwanda: 'Hitamo Uruhare Rwawe'},
  'Teacher': {AppLanguage.kinyarwanda: 'Umwarimu'},
  'Log student issues quickly': {
    AppLanguage.kinyarwanda: 'Andika ibibazo by\'umunyeshuri vuba',
  },
  'Principal': {AppLanguage.kinyarwanda: 'Umuyobozi'},
  'Monitor and take action': {
    AppLanguage.kinyarwanda: 'Kurikirana kandi ufate ingamba',
  },

  // Common headers
  'IJISHO': {AppLanguage.kinyarwanda: 'IJISHO'},
  'Welcome back,': {AppLanguage.kinyarwanda: 'Ikaze kugaruka,'},
  'Select Student': {AppLanguage.kinyarwanda: 'Hitamo Umunyeshuri'},
  'Report Issues': {AppLanguage.kinyarwanda: 'Tanga Raporo y\'Ikibazo'},
  'View All': {AppLanguage.kinyarwanda: 'Reba Byose'},
  'Recent Submissions': {AppLanguage.kinyarwanda: 'Raporo Ziheruka'},
  'Flagging History': {AppLanguage.kinyarwanda: 'Amateka y\'Raporo'},
  'Search students...': {AppLanguage.kinyarwanda: 'Shakisha abanyeshuri...'},
  'Filter': {AppLanguage.kinyarwanda: 'Shungura'},
  'Analytics': {AppLanguage.kinyarwanda: 'Isesengura'},
  'Total Students': {AppLanguage.kinyarwanda: 'Abanyeshuri Bose'},
  'At Risk': {AppLanguage.kinyarwanda: 'Bari mu Kaga'},
  'Urgent': {AppLanguage.kinyarwanda: 'Byihutirwa'},
  'Attention Required': {AppLanguage.kinyarwanda: 'Bisaba Kwitabwaho'},
  'Case Details': {AppLanguage.kinyarwanda: 'Amakuru y\'Ikibazo'},
  'Select Intervention': {AppLanguage.kinyarwanda: 'Hitamo Ubufasha'},

  // Login / Signup
  'Login': {AppLanguage.kinyarwanda: 'Injira'},
  'Sign Up': {AppLanguage.kinyarwanda: 'Iyandikishe'},
  'Create your account': {AppLanguage.kinyarwanda: 'Fungura konti yawe'},
  'Full Name': {AppLanguage.kinyarwanda: 'Amazina Yombi'},
  'Password': {AppLanguage.kinyarwanda: 'Ijambo ry\'Ibanga'},
  'Support': {AppLanguage.kinyarwanda: 'Ubufasha'},
  'Kinyarwanda': {AppLanguage.kinyarwanda: 'English'},
};
