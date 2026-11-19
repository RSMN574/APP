/// 台灣 22 縣市的統一目錄。
///
/// 專案內的城市識別有三種寫法：
/// - 中文名稱（`CityProvider` 與 UI 使用，例如 `臺中市`）
/// - TDX City 代碼（API 路徑使用，例如 `Taichung`、`HsinchuCounty`）
/// - AuthorityID / CityCode（資料庫使用，例如 `TXG`）
///
/// 所有轉換都應經過這個目錄，避免各頁面各自維護對照表而產生不一致。
class TaiwanCity {
  const TaiwanCity({
    required this.zhName,
    required this.tdxCode,
    required this.authorityCode,
    required this.enName,
    this.aliases = const [],
  });

  /// 中文名稱（以「臺」為正式寫法）。
  final String zhName;

  /// TDX API 使用的 City 代碼。
  final String tdxCode;

  /// TDX AuthorityID / CityCode 三碼。
  final String authorityCode;

  /// 顯示用英文名稱。
  final String enName;

  /// 其他常見寫法（例如「台中市」、`Hsinchu County`）。
  final List<String> aliases;

  /// 第一次使用、或保存資料無效時使用的預設城市。
  static const TaiwanCity defaultCity = taipei;

  static const taipei = TaiwanCity(
    zhName: '臺北市',
    tdxCode: 'Taipei',
    authorityCode: 'TPE',
    enName: 'Taipei',
  );

  static const all = <TaiwanCity>[
    taipei,
    TaiwanCity(
      zhName: '新北市',
      tdxCode: 'NewTaipei',
      authorityCode: 'NWT',
      enName: 'New Taipei',
    ),
    TaiwanCity(
      zhName: '桃園市',
      tdxCode: 'Taoyuan',
      authorityCode: 'TAO',
      enName: 'Taoyuan',
    ),
    TaiwanCity(
      zhName: '臺中市',
      tdxCode: 'Taichung',
      authorityCode: 'TXG',
      enName: 'Taichung',
    ),
    TaiwanCity(
      zhName: '臺南市',
      tdxCode: 'Tainan',
      authorityCode: 'TNN',
      enName: 'Tainan',
    ),
    TaiwanCity(
      zhName: '高雄市',
      tdxCode: 'Kaohsiung',
      authorityCode: 'KHH',
      enName: 'Kaohsiung',
    ),
    TaiwanCity(
      zhName: '基隆市',
      tdxCode: 'Keelung',
      authorityCode: 'KEE',
      enName: 'Keelung',
    ),
    TaiwanCity(
      zhName: '新竹市',
      tdxCode: 'Hsinchu',
      authorityCode: 'HSZ',
      enName: 'Hsinchu City',
      aliases: ['HsinchuCity'],
    ),
    TaiwanCity(
      zhName: '新竹縣',
      tdxCode: 'HsinchuCounty',
      authorityCode: 'HSQ',
      enName: 'Hsinchu County',
    ),
    TaiwanCity(
      zhName: '苗栗縣',
      tdxCode: 'MiaoliCounty',
      authorityCode: 'MIA',
      enName: 'Miaoli County',
      aliases: ['Miaoli'],
    ),
    TaiwanCity(
      zhName: '彰化縣',
      tdxCode: 'ChanghuaCounty',
      authorityCode: 'CHA',
      enName: 'Changhua County',
      aliases: ['Changhua'],
    ),
    TaiwanCity(
      zhName: '南投縣',
      tdxCode: 'NantouCounty',
      authorityCode: 'NAN',
      enName: 'Nantou County',
      aliases: ['Nantou'],
    ),
    TaiwanCity(
      zhName: '雲林縣',
      tdxCode: 'YunlinCounty',
      authorityCode: 'YUN',
      enName: 'Yunlin County',
      aliases: ['Yunlin'],
    ),
    TaiwanCity(
      zhName: '嘉義市',
      tdxCode: 'Chiayi',
      authorityCode: 'CYI',
      enName: 'Chiayi City',
      aliases: ['ChiayiCity'],
    ),
    TaiwanCity(
      zhName: '嘉義縣',
      tdxCode: 'ChiayiCounty',
      authorityCode: 'CYQ',
      enName: 'Chiayi County',
    ),
    TaiwanCity(
      zhName: '屏東縣',
      tdxCode: 'PingtungCounty',
      authorityCode: 'PIF',
      enName: 'Pingtung County',
      aliases: ['Pingtung'],
    ),
    TaiwanCity(
      zhName: '宜蘭縣',
      tdxCode: 'YilanCounty',
      authorityCode: 'ILA',
      enName: 'Yilan County',
      aliases: ['Yilan'],
    ),
    TaiwanCity(
      zhName: '花蓮縣',
      tdxCode: 'HualienCounty',
      authorityCode: 'HUA',
      enName: 'Hualien County',
      aliases: ['Hualien'],
    ),
    TaiwanCity(
      zhName: '臺東縣',
      tdxCode: 'TaitungCounty',
      authorityCode: 'TTT',
      enName: 'Taitung County',
      aliases: ['Taitung'],
    ),
    TaiwanCity(
      zhName: '澎湖縣',
      tdxCode: 'PenghuCounty',
      authorityCode: 'PEN',
      enName: 'Penghu County',
      aliases: ['Penghu'],
    ),
    TaiwanCity(
      zhName: '金門縣',
      tdxCode: 'KinmenCounty',
      authorityCode: 'KIN',
      enName: 'Kinmen County',
      aliases: ['Kinmen'],
    ),
    TaiwanCity(
      zhName: '連江縣',
      tdxCode: 'LienchiangCounty',
      authorityCode: 'LIE',
      enName: 'Lienchiang County',
      aliases: ['Lienchiang'],
    ),
  ];

  static final Map<String, TaiwanCity> _index = _buildIndex();

  static Map<String, TaiwanCity> _buildIndex() {
    final index = <String, TaiwanCity>{};
    for (final city in all) {
      for (final key in [
        city.zhName,
        city.zhName.replaceAll('臺', '台'),
        city.tdxCode,
        city.authorityCode,
        city.enName,
        ...city.aliases,
      ]) {
        index[_normalize(key)] = city;
      }
    }
    return index;
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();

  /// 依任何已知寫法（中文、TDX 代碼、AuthorityID、英文名）找出縣市。
  /// 找不到時回傳 `null`，呼叫端必須自行決定回退策略。
  static TaiwanCity? tryParse(String? value) {
    if (value == null) return null;
    final key = _normalize(value);
    if (key.isEmpty) return null;
    return _index[key];
  }

  /// 是否為目錄中的合法縣市。
  static bool isValid(String? value) => tryParse(value) != null;

  @override
  String toString() => 'TaiwanCity($zhName/$tdxCode)';
}
