import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en')
  ];

  /// No description provided for @text_1.
  ///
  /// In zh, this message translates to:
  /// **'收藏路線'**
  String get text_1;

  /// No description provided for @text_2.
  ///
  /// In zh, this message translates to:
  /// **'收藏站牌'**
  String get text_2;

  /// No description provided for @text_3.
  ///
  /// In zh, this message translates to:
  /// **'規劃'**
  String get text_3;

  /// No description provided for @text_4.
  ///
  /// In zh, this message translates to:
  /// **'接駁車'**
  String get text_4;

  /// No description provided for @text_5.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get text_5;

  /// No description provided for @text_6.
  ///
  /// In zh, this message translates to:
  /// **'臺中市'**
  String get text_6;

  /// No description provided for @text_7.
  ///
  /// In zh, this message translates to:
  /// **'臺北市'**
  String get text_7;

  /// No description provided for @text_8.
  ///
  /// In zh, this message translates to:
  /// **'新北市'**
  String get text_8;

  /// No description provided for @text_9.
  ///
  /// In zh, this message translates to:
  /// **'桃園市'**
  String get text_9;

  /// No description provided for @text_10.
  ///
  /// In zh, this message translates to:
  /// **'臺南市'**
  String get text_10;

  /// No description provided for @text_11.
  ///
  /// In zh, this message translates to:
  /// **'高雄市'**
  String get text_11;

  /// No description provided for @text_12.
  ///
  /// In zh, this message translates to:
  /// **'基隆市'**
  String get text_12;

  /// No description provided for @text_13.
  ///
  /// In zh, this message translates to:
  /// **'新竹市'**
  String get text_13;

  /// No description provided for @text_14.
  ///
  /// In zh, this message translates to:
  /// **'公路客運'**
  String get text_14;

  /// No description provided for @text_15.
  ///
  /// In zh, this message translates to:
  /// **'路線'**
  String get text_15;

  /// No description provided for @text_16.
  ///
  /// In zh, this message translates to:
  /// **'公車資訊'**
  String get text_16;

  /// No description provided for @text_17.
  ///
  /// In zh, this message translates to:
  /// **'票價說明'**
  String get text_17;

  /// No description provided for @text_18.
  ///
  /// In zh, this message translates to:
  /// **'查看公車票價資訊'**
  String get text_18;

  /// No description provided for @text_19.
  ///
  /// In zh, this message translates to:
  /// **'通阻消息'**
  String get text_19;

  /// No description provided for @text_20.
  ///
  /// In zh, this message translates to:
  /// **'查看交通中斷資訊'**
  String get text_20;

  /// No description provided for @text_21.
  ///
  /// In zh, this message translates to:
  /// **'票價細則'**
  String get text_21;

  /// No description provided for @text_22.
  ///
  /// In zh, this message translates to:
  /// **'1. 臺中市民、市民的新住民配偶及臺中就學的外縣市學生，使用綁定市民限定乘車優惠的電子票證可享「10公里免費＋超過10公里車資上限10元」的雙十優惠。'**
  String get text_22;

  /// No description provided for @text_23.
  ///
  /// In zh, this message translates to:
  /// **'2. 非市民搭乘依里程計費，投現上車應付車資全票20元、半票11元，超過基本里程再依實際搭乘距離計算下車應付車資；另使用電子票證，刷卡上車應付車資全票僅扣15元(享有5元的優惠)、半票11元，超過基本里程再依實際搭乘距離計算下車應付車資。'**
  String get text_23;

  /// No description provided for @text_24.
  ///
  /// In zh, this message translates to:
  /// **'3. 臺中市委託發行敬老愛心卡先享有雙十乘車優惠，即搭乘距離在10公里內不會扣點，搭乘超過10公里最多扣10點。'**
  String get text_24;

  /// No description provided for @text_25.
  ///
  /// In zh, this message translates to:
  /// **'無標題'**
  String get text_25;

  /// No description provided for @text_26.
  ///
  /// In zh, this message translates to:
  /// **'無描述'**
  String get text_26;

  /// No description provided for @text_27.
  ///
  /// In zh, this message translates to:
  /// **'暫無通阻消息'**
  String get text_27;

  /// No description provided for @text_28.
  ///
  /// In zh, this message translates to:
  /// **'選擇城市'**
  String get text_28;

  /// No description provided for @text_29.
  ///
  /// In zh, this message translates to:
  /// **'站牌'**
  String get text_29;

  /// No description provided for @text_30.
  ///
  /// In zh, this message translates to:
  /// **'搜尋公車路線或站牌...'**
  String get text_30;

  /// No description provided for @text_31.
  ///
  /// In zh, this message translates to:
  /// **'快去添加一些喜歡的吧！'**
  String get text_31;

  /// No description provided for @text_32.
  ///
  /// In zh, this message translates to:
  /// **'功能開發中'**
  String get text_32;

  /// No description provided for @text_33.
  ///
  /// In zh, this message translates to:
  /// **'沒有找到結果'**
  String get text_33;

  /// No description provided for @text_34.
  ///
  /// In zh, this message translates to:
  /// **'確定取消收藏嗎'**
  String get text_34;

  /// No description provided for @text_35.
  ///
  /// In zh, this message translates to:
  /// **'確認'**
  String get text_35;

  /// No description provided for @text_36.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get text_36;

  /// No description provided for @text_37.
  ///
  /// In zh, this message translates to:
  /// **'還沒有規劃的行程'**
  String get text_37;

  /// No description provided for @text_38.
  ///
  /// In zh, this message translates to:
  /// **'點擊下方按鈕來新增你的第一個行程吧！'**
  String get text_38;

  /// No description provided for @text_39.
  ///
  /// In zh, this message translates to:
  /// **'新增行程'**
  String get text_39;

  /// No description provided for @text_40.
  ///
  /// In zh, this message translates to:
  /// **'行程選項'**
  String get text_40;

  /// No description provided for @text_41.
  ///
  /// In zh, this message translates to:
  /// **'查看行程資訊'**
  String get text_41;

  /// No description provided for @text_42.
  ///
  /// In zh, this message translates to:
  /// **'編輯行程'**
  String get text_42;

  /// No description provided for @text_43.
  ///
  /// In zh, this message translates to:
  /// **'移除行程'**
  String get text_43;

  /// No description provided for @text_44.
  ///
  /// In zh, this message translates to:
  /// **'關閉'**
  String get text_44;

  /// No description provided for @text_45.
  ///
  /// In zh, this message translates to:
  /// **'行程錯誤！'**
  String get text_45;

  /// No description provided for @text_46.
  ///
  /// In zh, this message translates to:
  /// **'行程刪除成功！'**
  String get text_46;

  /// No description provided for @text_47.
  ///
  /// In zh, this message translates to:
  /// **'行程刪除失败。'**
  String get text_47;

  /// No description provided for @text_48.
  ///
  /// In zh, this message translates to:
  /// **'路線資訊'**
  String get text_48;

  /// No description provided for @text_49.
  ///
  /// In zh, this message translates to:
  /// **'路線起點'**
  String get text_49;

  /// No description provided for @text_50.
  ///
  /// In zh, this message translates to:
  /// **'路線終點'**
  String get text_50;

  /// No description provided for @text_51.
  ///
  /// In zh, this message translates to:
  /// **'用戶上車站'**
  String get text_51;

  /// No description provided for @text_52.
  ///
  /// In zh, this message translates to:
  /// **'用戶下車站'**
  String get text_52;

  /// No description provided for @text_53.
  ///
  /// In zh, this message translates to:
  /// **'未知路線'**
  String get text_53;

  /// No description provided for @text_54.
  ///
  /// In zh, this message translates to:
  /// **'城市'**
  String get text_54;

  /// No description provided for @text_55.
  ///
  /// In zh, this message translates to:
  /// **'起點'**
  String get text_55;

  /// No description provided for @text_56.
  ///
  /// In zh, this message translates to:
  /// **'未設定'**
  String get text_56;

  /// No description provided for @text_57.
  ///
  /// In zh, this message translates to:
  /// **'終點'**
  String get text_57;

  /// No description provided for @text_58.
  ///
  /// In zh, this message translates to:
  /// **'市區公車服務'**
  String get text_58;

  /// No description provided for @text_59.
  ///
  /// In zh, this message translates to:
  /// **'輸入座位號'**
  String get text_59;

  /// No description provided for @text_60.
  ///
  /// In zh, this message translates to:
  /// **'請輸入座位號'**
  String get text_60;

  /// No description provided for @text_61.
  ///
  /// In zh, this message translates to:
  /// **'更新失敗。'**
  String get text_61;

  /// No description provided for @text_62.
  ///
  /// In zh, this message translates to:
  /// **'更新成功！'**
  String get text_62;

  /// No description provided for @text_63.
  ///
  /// In zh, this message translates to:
  /// **'出發站'**
  String get text_63;

  /// No description provided for @text_64.
  ///
  /// In zh, this message translates to:
  /// **'抵達站'**
  String get text_64;

  /// No description provided for @text_65.
  ///
  /// In zh, this message translates to:
  /// **'區間車'**
  String get text_65;

  /// No description provided for @text_66.
  ///
  /// In zh, this message translates to:
  /// **'區間快'**
  String get text_66;

  /// No description provided for @text_67.
  ///
  /// In zh, this message translates to:
  /// **'出發'**
  String get text_67;

  /// No description provided for @text_68.
  ///
  /// In zh, this message translates to:
  /// **'抵達'**
  String get text_68;

  /// No description provided for @text_69.
  ///
  /// In zh, this message translates to:
  /// **'填寫座位'**
  String get text_69;

  /// No description provided for @text_70.
  ///
  /// In zh, this message translates to:
  /// **'上班通勤'**
  String get text_70;

  /// No description provided for @text_71.
  ///
  /// In zh, this message translates to:
  /// **'旅行'**
  String get text_71;

  /// No description provided for @text_72.
  ///
  /// In zh, this message translates to:
  /// **'繁體中文'**
  String get text_72;

  /// No description provided for @text_73.
  ///
  /// In zh, this message translates to:
  /// **'宜蘭'**
  String get text_73;

  /// No description provided for @text_74.
  ///
  /// In zh, this message translates to:
  /// **'宜蘭縣'**
  String get text_74;

  /// No description provided for @text_75.
  ///
  /// In zh, this message translates to:
  /// **'花蓮'**
  String get text_75;

  /// No description provided for @text_76.
  ///
  /// In zh, this message translates to:
  /// **'花蓮縣'**
  String get text_76;

  /// No description provided for @text_77.
  ///
  /// In zh, this message translates to:
  /// **'台東'**
  String get text_77;

  /// No description provided for @text_78.
  ///
  /// In zh, this message translates to:
  /// **'臺東縣'**
  String get text_78;

  /// No description provided for @text_79.
  ///
  /// In zh, this message translates to:
  /// **'澎湖'**
  String get text_79;

  /// No description provided for @text_80.
  ///
  /// In zh, this message translates to:
  /// **'澎湖縣'**
  String get text_80;

  /// No description provided for @text_81.
  ///
  /// In zh, this message translates to:
  /// **'金門'**
  String get text_81;

  /// No description provided for @text_82.
  ///
  /// In zh, this message translates to:
  /// **'金門縣'**
  String get text_82;

  /// No description provided for @text_83.
  ///
  /// In zh, this message translates to:
  /// **'連江'**
  String get text_83;

  /// No description provided for @text_84.
  ///
  /// In zh, this message translates to:
  /// **'連江縣'**
  String get text_84;

  /// No description provided for @text_85.
  ///
  /// In zh, this message translates to:
  /// **'台北'**
  String get text_85;

  /// No description provided for @text_86.
  ///
  /// In zh, this message translates to:
  /// **'新北'**
  String get text_86;

  /// No description provided for @text_87.
  ///
  /// In zh, this message translates to:
  /// **'桃園'**
  String get text_87;

  /// No description provided for @text_88.
  ///
  /// In zh, this message translates to:
  /// **'台中'**
  String get text_88;

  /// No description provided for @text_89.
  ///
  /// In zh, this message translates to:
  /// **'台南'**
  String get text_89;

  /// No description provided for @text_90.
  ///
  /// In zh, this message translates to:
  /// **'高雄'**
  String get text_90;

  /// No description provided for @text_91.
  ///
  /// In zh, this message translates to:
  /// **'基隆'**
  String get text_91;

  /// No description provided for @text_92.
  ///
  /// In zh, this message translates to:
  /// **'新竹縣'**
  String get text_92;

  /// No description provided for @text_93.
  ///
  /// In zh, this message translates to:
  /// **'苗栗'**
  String get text_93;

  /// No description provided for @text_94.
  ///
  /// In zh, this message translates to:
  /// **'苗栗縣'**
  String get text_94;

  /// No description provided for @text_95.
  ///
  /// In zh, this message translates to:
  /// **'彰化'**
  String get text_95;

  /// No description provided for @text_96.
  ///
  /// In zh, this message translates to:
  /// **'彰化縣'**
  String get text_96;

  /// No description provided for @text_97.
  ///
  /// In zh, this message translates to:
  /// **'南投'**
  String get text_97;

  /// No description provided for @text_98.
  ///
  /// In zh, this message translates to:
  /// **'南投縣'**
  String get text_98;

  /// No description provided for @text_99.
  ///
  /// In zh, this message translates to:
  /// **'雲林'**
  String get text_99;

  /// No description provided for @text_100.
  ///
  /// In zh, this message translates to:
  /// **'雲林縣'**
  String get text_100;

  /// No description provided for @text_101.
  ///
  /// In zh, this message translates to:
  /// **'嘉義縣'**
  String get text_101;

  /// No description provided for @text_102.
  ///
  /// In zh, this message translates to:
  /// **'嘉義市'**
  String get text_102;

  /// No description provided for @text_103.
  ///
  /// In zh, this message translates to:
  /// **'屏東'**
  String get text_103;

  /// No description provided for @text_104.
  ///
  /// In zh, this message translates to:
  /// **'屏東縣'**
  String get text_104;

  /// No description provided for @text_105.
  ///
  /// In zh, this message translates to:
  /// **'連接失敗: \$e'**
  String get text_105;

  /// No description provided for @text_106.
  ///
  /// In zh, this message translates to:
  /// **'查詢失敗，請稍後再試'**
  String get text_106;

  /// No description provided for @text_107.
  ///
  /// In zh, this message translates to:
  /// **'獲取公車資料失敗，請稍後再試'**
  String get text_107;

  /// No description provided for @text_108.
  ///
  /// In zh, this message translates to:
  /// **'獲取公車路線資料失敗，請稍後再試'**
  String get text_108;

  /// No description provided for @text_109.
  ///
  /// In zh, this message translates to:
  /// **'沒有符合的行車方向'**
  String get text_109;

  /// No description provided for @text_110.
  ///
  /// In zh, this message translates to:
  /// **'多個方向符合路線'**
  String get text_110;

  /// No description provided for @text_111.
  ///
  /// In zh, this message translates to:
  /// **'晴'**
  String get text_111;

  /// No description provided for @text_112.
  ///
  /// In zh, this message translates to:
  /// **'雨'**
  String get text_112;

  /// No description provided for @text_113.
  ///
  /// In zh, this message translates to:
  /// **'雲'**
  String get text_113;

  /// No description provided for @text_114.
  ///
  /// In zh, this message translates to:
  /// **'臺北捷運'**
  String get text_114;

  /// No description provided for @text_115.
  ///
  /// In zh, this message translates to:
  /// **'桃園捷運'**
  String get text_115;

  /// No description provided for @text_116.
  ///
  /// In zh, this message translates to:
  /// **'臺中捷運'**
  String get text_116;

  /// No description provided for @text_117.
  ///
  /// In zh, this message translates to:
  /// **'新北捷運'**
  String get text_117;

  /// No description provided for @text_118.
  ///
  /// In zh, this message translates to:
  /// **'項目'**
  String get text_118;

  /// No description provided for @text_119.
  ///
  /// In zh, this message translates to:
  /// **'已存在於列表中，不會重複添加。'**
  String get text_119;

  /// No description provided for @text_120.
  ///
  /// In zh, this message translates to:
  /// **'儲存項目時發生錯誤: \$e'**
  String get text_120;

  /// No description provided for @text_121.
  ///
  /// In zh, this message translates to:
  /// **'載入項目時發生錯誤: \$e'**
  String get text_121;

  /// No description provided for @text_122.
  ///
  /// In zh, this message translates to:
  /// **'移除項目時發生錯誤: \$e'**
  String get text_122;

  /// No description provided for @text_123.
  ///
  /// In zh, this message translates to:
  /// **'時間在前後 30 分鐘內，載入即時列車資訊'**
  String get text_123;

  /// No description provided for @text_124.
  ///
  /// In zh, this message translates to:
  /// **'時間超出範圍，僅載入時刻表'**
  String get text_124;

  /// No description provided for @text_125.
  ///
  /// In zh, this message translates to:
  /// **'使用快取資料'**
  String get text_125;

  /// No description provided for @text_126.
  ///
  /// In zh, this message translates to:
  /// **'發生錯誤: \$e'**
  String get text_126;

  /// No description provided for @text_127.
  ///
  /// In zh, this message translates to:
  /// **'前台消息处理已启动'**
  String get text_127;

  /// No description provided for @text_128.
  ///
  /// In zh, this message translates to:
  /// **'無内容'**
  String get text_128;

  /// No description provided for @text_129.
  ///
  /// In zh, this message translates to:
  /// **'无法获取当前位置: \$e'**
  String get text_129;

  /// No description provided for @text_130.
  ///
  /// In zh, this message translates to:
  /// **'請選擇站點'**
  String get text_130;

  /// No description provided for @text_131.
  ///
  /// In zh, this message translates to:
  /// **'資料載入失敗'**
  String get text_131;

  /// No description provided for @text_132.
  ///
  /// In zh, this message translates to:
  /// **'暫無可用資料'**
  String get text_132;

  /// No description provided for @text_133.
  ///
  /// In zh, this message translates to:
  /// **'載入中...'**
  String get text_133;

  /// No description provided for @text_134.
  ///
  /// In zh, this message translates to:
  /// **'可租借'**
  String get text_134;

  /// No description provided for @text_135.
  ///
  /// In zh, this message translates to:
  /// **'可歸還'**
  String get text_135;

  /// No description provided for @text_136.
  ///
  /// In zh, this message translates to:
  /// **'車輛類型'**
  String get text_136;

  /// No description provided for @text_137.
  ///
  /// In zh, this message translates to:
  /// **'普通車'**
  String get text_137;

  /// No description provided for @text_138.
  ///
  /// In zh, this message translates to:
  /// **'電輔車'**
  String get text_138;

  /// No description provided for @text_139.
  ///
  /// In zh, this message translates to:
  /// **'搜尋站點名稱或地址'**
  String get text_139;

  /// No description provided for @text_140.
  ///
  /// In zh, this message translates to:
  /// **'可借'**
  String get text_140;

  /// No description provided for @text_141.
  ///
  /// In zh, this message translates to:
  /// **'加載站點失敗: \$e'**
  String get text_141;

  /// No description provided for @text_142.
  ///
  /// In zh, this message translates to:
  /// **'最近搜尋'**
  String get text_142;

  /// No description provided for @text_143.
  ///
  /// In zh, this message translates to:
  /// **'搜尋站點...'**
  String get text_143;

  /// No description provided for @text_144.
  ///
  /// In zh, this message translates to:
  /// **'高鐵查詢系統'**
  String get text_144;

  /// No description provided for @text_145.
  ///
  /// In zh, this message translates to:
  /// **'按車次查詢'**
  String get text_145;

  /// No description provided for @text_146.
  ///
  /// In zh, this message translates to:
  /// **'按出發地和目的地查詢'**
  String get text_146;

  /// No description provided for @text_147.
  ///
  /// In zh, this message translates to:
  /// **'按車站查詢'**
  String get text_147;

  /// No description provided for @text_148.
  ///
  /// In zh, this message translates to:
  /// **'高鐵車次查詢'**
  String get text_148;

  /// No description provided for @text_149.
  ///
  /// In zh, this message translates to:
  /// **'輸入高鐵車次號碼查詢時刻表'**
  String get text_149;

  /// No description provided for @text_150.
  ///
  /// In zh, this message translates to:
  /// **'輸入高鐵車次，例如：1110'**
  String get text_150;

  /// No description provided for @text_151.
  ///
  /// In zh, this message translates to:
  /// **'查無此車次'**
  String get text_151;

  /// No description provided for @text_152.
  ///
  /// In zh, this message translates to:
  /// **'查詢失敗: \$e'**
  String get text_152;

  /// No description provided for @text_153.
  ///
  /// In zh, this message translates to:
  /// **'立即查詢'**
  String get text_153;

  /// No description provided for @text_154.
  ///
  /// In zh, this message translates to:
  /// **'查詢提示'**
  String get text_154;

  /// No description provided for @text_155.
  ///
  /// In zh, this message translates to:
  /// **'請輸入完整的4碼高鐵車次號碼'**
  String get text_155;

  /// No description provided for @text_156.
  ///
  /// In zh, this message translates to:
  /// **'常見車次'**
  String get text_156;

  /// No description provided for @text_157.
  ///
  /// In zh, this message translates to:
  /// **'出發地和目的地不能相同'**
  String get text_157;

  /// No description provided for @text_158.
  ///
  /// In zh, this message translates to:
  /// **'高鐵站站查詢'**
  String get text_158;

  /// No description provided for @text_159.
  ///
  /// In zh, this message translates to:
  /// **'選擇出發站、到達站與出發時間'**
  String get text_159;

  /// No description provided for @text_160.
  ///
  /// In zh, this message translates to:
  /// **'未知車站'**
  String get text_160;

  /// No description provided for @text_161.
  ///
  /// In zh, this message translates to:
  /// **'請選擇出發站'**
  String get text_161;

  /// No description provided for @text_162.
  ///
  /// In zh, this message translates to:
  /// **'到達站'**
  String get text_162;

  /// No description provided for @text_163.
  ///
  /// In zh, this message translates to:
  /// **'請選擇到達站'**
  String get text_163;

  /// No description provided for @text_164.
  ///
  /// In zh, this message translates to:
  /// **'出發時間'**
  String get text_164;

  /// No description provided for @text_165.
  ///
  /// In zh, this message translates to:
  /// **'現在時間'**
  String get text_165;

  /// No description provided for @text_166.
  ///
  /// In zh, this message translates to:
  /// **'查詢班次'**
  String get text_166;

  /// No description provided for @text_167.
  ///
  /// In zh, this message translates to:
  /// **'高鐵可查詢未來90天內的班次'**
  String get text_167;

  /// No description provided for @text_168.
  ///
  /// In zh, this message translates to:
  /// **'熱門路線'**
  String get text_168;

  /// No description provided for @text_169.
  ///
  /// In zh, this message translates to:
  /// **'台北→左營'**
  String get text_169;

  /// No description provided for @text_170.
  ///
  /// In zh, this message translates to:
  /// **'台北→台中'**
  String get text_170;

  /// No description provided for @text_171.
  ///
  /// In zh, this message translates to:
  /// **'台中→左營'**
  String get text_171;

  /// No description provided for @text_172.
  ///
  /// In zh, this message translates to:
  /// **'左營→台北'**
  String get text_172;

  /// No description provided for @text_173.
  ///
  /// In zh, this message translates to:
  /// **'台中→台北'**
  String get text_173;

  /// No description provided for @text_174.
  ///
  /// In zh, this message translates to:
  /// **'台北市'**
  String get text_174;

  /// No description provided for @text_175.
  ///
  /// In zh, this message translates to:
  /// **'台北車站'**
  String get text_175;

  /// No description provided for @text_176.
  ///
  /// In zh, this message translates to:
  /// **'大安站'**
  String get text_176;

  /// No description provided for @text_177.
  ///
  /// In zh, this message translates to:
  /// **'松山站'**
  String get text_177;

  /// No description provided for @text_178.
  ///
  /// In zh, this message translates to:
  /// **'板橋車站'**
  String get text_178;

  /// No description provided for @text_179.
  ///
  /// In zh, this message translates to:
  /// **'新店站'**
  String get text_179;

  /// No description provided for @text_180.
  ///
  /// In zh, this message translates to:
  /// **'淡水站'**
  String get text_180;

  /// No description provided for @text_181.
  ///
  /// In zh, this message translates to:
  /// **'桃園車站'**
  String get text_181;

  /// No description provided for @text_182.
  ///
  /// In zh, this message translates to:
  /// **'中壢站'**
  String get text_182;

  /// No description provided for @text_183.
  ///
  /// In zh, this message translates to:
  /// **'機場站'**
  String get text_183;

  /// No description provided for @text_184.
  ///
  /// In zh, this message translates to:
  /// **'台中市'**
  String get text_184;

  /// No description provided for @text_185.
  ///
  /// In zh, this message translates to:
  /// **'台中車站'**
  String get text_185;

  /// No description provided for @text_186.
  ///
  /// In zh, this message translates to:
  /// **'豐原站'**
  String get text_186;

  /// No description provided for @text_187.
  ///
  /// In zh, this message translates to:
  /// **'后里站'**
  String get text_187;

  /// No description provided for @text_188.
  ///
  /// In zh, this message translates to:
  /// **'台南市'**
  String get text_188;

  /// No description provided for @text_189.
  ///
  /// In zh, this message translates to:
  /// **'台南車站'**
  String get text_189;

  /// No description provided for @text_190.
  ///
  /// In zh, this message translates to:
  /// **'新營站'**
  String get text_190;

  /// No description provided for @text_191.
  ///
  /// In zh, this message translates to:
  /// **'善化站'**
  String get text_191;

  /// No description provided for @text_192.
  ///
  /// In zh, this message translates to:
  /// **'高雄車站'**
  String get text_192;

  /// No description provided for @text_193.
  ///
  /// In zh, this message translates to:
  /// **'左營站'**
  String get text_193;

  /// No description provided for @text_194.
  ///
  /// In zh, this message translates to:
  /// **'楠梓站'**
  String get text_194;

  /// No description provided for @text_195.
  ///
  /// In zh, this message translates to:
  /// **'無法打開連結'**
  String get text_195;

  /// No description provided for @text_196.
  ///
  /// In zh, this message translates to:
  /// **'開啟連結失敗: \$e'**
  String get text_196;

  /// No description provided for @text_197.
  ///
  /// In zh, this message translates to:
  /// **'高鐵車站查詢'**
  String get text_197;

  /// No description provided for @text_198.
  ///
  /// In zh, this message translates to:
  /// **'選擇高鐵車站查詢相關資訊'**
  String get text_198;

  /// No description provided for @text_199.
  ///
  /// In zh, this message translates to:
  /// **'高鐵車站'**
  String get text_199;

  /// No description provided for @text_200.
  ///
  /// In zh, this message translates to:
  /// **'請選擇車站'**
  String get text_200;

  /// No description provided for @text_201.
  ///
  /// In zh, this message translates to:
  /// **'查詢車站'**
  String get text_201;

  /// No description provided for @text_202.
  ///
  /// In zh, this message translates to:
  /// **'選擇車站後可查詢該站的詳細資訊'**
  String get text_202;

  /// No description provided for @text_203.
  ///
  /// In zh, this message translates to:
  /// **'熱門車站'**
  String get text_203;

  /// No description provided for @text_204.
  ///
  /// In zh, this message translates to:
  /// **'查詢高鐵班次中...'**
  String get text_204;

  /// No description provided for @text_205.
  ///
  /// In zh, this message translates to:
  /// **'載入失敗'**
  String get text_205;

  /// No description provided for @text_206.
  ///
  /// In zh, this message translates to:
  /// **'請檢查網路連線後重試'**
  String get text_206;

  /// No description provided for @text_207.
  ///
  /// In zh, this message translates to:
  /// **'無符合條件的列車'**
  String get text_207;

  /// No description provided for @text_208.
  ///
  /// In zh, this message translates to:
  /// **'請調整查詢條件後重新搜尋'**
  String get text_208;

  /// No description provided for @text_209.
  ///
  /// In zh, this message translates to:
  /// **'標準車廂'**
  String get text_209;

  /// No description provided for @text_210.
  ///
  /// In zh, this message translates to:
  /// **'標準'**
  String get text_210;

  /// No description provided for @text_211.
  ///
  /// In zh, this message translates to:
  /// **'商務'**
  String get text_211;

  /// No description provided for @text_212.
  ///
  /// In zh, this message translates to:
  /// **'獲取座位狀態失敗: \$e'**
  String get text_212;

  /// No description provided for @text_213.
  ///
  /// In zh, this message translates to:
  /// **'標準座艙'**
  String get text_213;

  /// No description provided for @text_214.
  ///
  /// In zh, this message translates to:
  /// **'有座'**
  String get text_214;

  /// No description provided for @text_215.
  ///
  /// In zh, this message translates to:
  /// **'無座'**
  String get text_215;

  /// No description provided for @text_216.
  ///
  /// In zh, this message translates to:
  /// **'商務座艙'**
  String get text_216;

  /// No description provided for @text_217.
  ///
  /// In zh, this message translates to:
  /// **'獲取運輸資訊失敗: \$e'**
  String get text_217;

  /// No description provided for @text_218.
  ///
  /// In zh, this message translates to:
  /// **'台灣好行資訊'**
  String get text_218;

  /// No description provided for @text_219.
  ///
  /// In zh, this message translates to:
  /// **'應用程式啟動'**
  String get text_219;

  /// No description provided for @text_220.
  ///
  /// In zh, this message translates to:
  /// **'台灣通'**
  String get text_220;

  /// No description provided for @text_221.
  ///
  /// In zh, this message translates to:
  /// **'選擇地區'**
  String get text_221;

  /// No description provided for @text_222.
  ///
  /// In zh, this message translates to:
  /// **'首頁'**
  String get text_222;

  /// No description provided for @text_223.
  ///
  /// In zh, this message translates to:
  /// **'行程'**
  String get text_223;

  /// No description provided for @text_224.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get text_224;

  /// No description provided for @text_225.
  ///
  /// In zh, this message translates to:
  /// **'臺中市測試'**
  String get text_225;

  /// No description provided for @text_226.
  ///
  /// In zh, this message translates to:
  /// **'車站'**
  String get text_226;

  /// No description provided for @text_227.
  ///
  /// In zh, this message translates to:
  /// **'路線圖'**
  String get text_227;

  /// No description provided for @text_228.
  ///
  /// In zh, this message translates to:
  /// **'捷運資訊'**
  String get text_228;

  /// No description provided for @text_229.
  ///
  /// In zh, this message translates to:
  /// **'選擇縣市'**
  String get text_229;

  /// No description provided for @text_230.
  ///
  /// In zh, this message translates to:
  /// **'查看捷運路線與資訊'**
  String get text_230;

  /// No description provided for @text_231.
  ///
  /// In zh, this message translates to:
  /// **'車票資訊'**
  String get text_231;

  /// No description provided for @text_232.
  ///
  /// In zh, this message translates to:
  /// **'票價與購票說明'**
  String get text_232;

  /// No description provided for @text_233.
  ///
  /// In zh, this message translates to:
  /// **'發車班距'**
  String get text_233;

  /// No description provided for @text_234.
  ///
  /// In zh, this message translates to:
  /// **'查看列車發車班距頻率'**
  String get text_234;

  /// No description provided for @text_235.
  ///
  /// In zh, this message translates to:
  /// **'發車時刻表'**
  String get text_235;

  /// No description provided for @text_236.
  ///
  /// In zh, this message translates to:
  /// **'查看列車發車時間'**
  String get text_236;

  /// No description provided for @text_237.
  ///
  /// In zh, this message translates to:
  /// **'導航到捷運資訊'**
  String get text_237;

  /// No description provided for @text_238.
  ///
  /// In zh, this message translates to:
  /// **'導航到車票資訊'**
  String get text_238;

  /// No description provided for @text_239.
  ///
  /// In zh, this message translates to:
  /// **'導航到發車時刻表'**
  String get text_239;

  /// No description provided for @text_240.
  ///
  /// In zh, this message translates to:
  /// **'導航到使用說明'**
  String get text_240;

  /// No description provided for @text_241.
  ///
  /// In zh, this message translates to:
  /// **'車站資訊'**
  String get text_241;

  /// No description provided for @text_242.
  ///
  /// In zh, this message translates to:
  /// **'轉乘資訊'**
  String get text_242;

  /// No description provided for @text_243.
  ///
  /// In zh, this message translates to:
  /// **'未知的城市'**
  String get text_243;

  /// No description provided for @text_244.
  ///
  /// In zh, this message translates to:
  /// **'這裡顯示車站的轉乘資訊，包括可以轉乘的其他交通工具或路線。'**
  String get text_244;

  /// No description provided for @text_245.
  ///
  /// In zh, this message translates to:
  /// **'載入車站資訊中...'**
  String get text_245;

  /// No description provided for @text_246.
  ///
  /// In zh, this message translates to:
  /// **'無法載入車站資訊'**
  String get text_246;

  /// No description provided for @text_247.
  ///
  /// In zh, this message translates to:
  /// **'車站出口資訊'**
  String get text_247;

  /// No description provided for @text_248.
  ///
  /// In zh, this message translates to:
  /// **'車站設施'**
  String get text_248;

  /// No description provided for @text_249.
  ///
  /// In zh, this message translates to:
  /// **'未找到車站資訊'**
  String get text_249;

  /// No description provided for @text_250.
  ///
  /// In zh, this message translates to:
  /// **'車站地圖'**
  String get text_250;

  /// No description provided for @text_251.
  ///
  /// In zh, this message translates to:
  /// **'圖片預覽'**
  String get text_251;

  /// No description provided for @text_252.
  ///
  /// In zh, this message translates to:
  /// **'無法載入圖片'**
  String get text_252;

  /// No description provided for @text_253.
  ///
  /// In zh, this message translates to:
  /// **'未命名地圖'**
  String get text_253;

  /// No description provided for @text_254.
  ///
  /// In zh, this message translates to:
  /// **'樓梯'**
  String get text_254;

  /// No description provided for @text_255.
  ///
  /// In zh, this message translates to:
  /// **'電梯'**
  String get text_255;

  /// No description provided for @text_256.
  ///
  /// In zh, this message translates to:
  /// **'手扶梯'**
  String get text_256;

  /// No description provided for @text_257.
  ///
  /// In zh, this message translates to:
  /// **'北屯總站'**
  String get text_257;

  /// No description provided for @text_258.
  ///
  /// In zh, this message translates to:
  /// **'舊社'**
  String get text_258;

  /// No description provided for @text_259.
  ///
  /// In zh, this message translates to:
  /// **'松竹'**
  String get text_259;

  /// No description provided for @text_260.
  ///
  /// In zh, this message translates to:
  /// **'四維國小'**
  String get text_260;

  /// No description provided for @text_261.
  ///
  /// In zh, this message translates to:
  /// **'文心崇德'**
  String get text_261;

  /// No description provided for @text_262.
  ///
  /// In zh, this message translates to:
  /// **'文心中清'**
  String get text_262;

  /// No description provided for @text_263.
  ///
  /// In zh, this message translates to:
  /// **'文華高中'**
  String get text_263;

  /// No description provided for @text_264.
  ///
  /// In zh, this message translates to:
  /// **'文心櫻花'**
  String get text_264;

  /// No description provided for @text_265.
  ///
  /// In zh, this message translates to:
  /// **'市政府'**
  String get text_265;

  /// No description provided for @text_266.
  ///
  /// In zh, this message translates to:
  /// **'水安宮'**
  String get text_266;

  /// No description provided for @text_267.
  ///
  /// In zh, this message translates to:
  /// **'文心森林公園'**
  String get text_267;

  /// No description provided for @text_268.
  ///
  /// In zh, this message translates to:
  /// **'南屯'**
  String get text_268;

  /// No description provided for @text_269.
  ///
  /// In zh, this message translates to:
  /// **'豐樂公園'**
  String get text_269;

  /// No description provided for @text_270.
  ///
  /// In zh, this message translates to:
  /// **'大慶'**
  String get text_270;

  /// No description provided for @text_271.
  ///
  /// In zh, this message translates to:
  /// **'九張犁'**
  String get text_271;

  /// No description provided for @text_272.
  ///
  /// In zh, this message translates to:
  /// **'九德'**
  String get text_272;

  /// No description provided for @text_273.
  ///
  /// In zh, this message translates to:
  /// **'烏日'**
  String get text_273;

  /// No description provided for @text_274.
  ///
  /// In zh, this message translates to:
  /// **'高鐵臺中站'**
  String get text_274;

  /// No description provided for @text_275.
  ///
  /// In zh, this message translates to:
  /// **'淡水'**
  String get text_275;

  /// No description provided for @text_276.
  ///
  /// In zh, this message translates to:
  /// **'北投'**
  String get text_276;

  /// No description provided for @text_277.
  ///
  /// In zh, this message translates to:
  /// **'劍潭'**
  String get text_277;

  /// No description provided for @text_278.
  ///
  /// In zh, this message translates to:
  /// **'大安'**
  String get text_278;

  /// No description provided for @text_279.
  ///
  /// In zh, this message translates to:
  /// **'象山'**
  String get text_279;

  /// No description provided for @text_280.
  ///
  /// In zh, this message translates to:
  /// **'松山'**
  String get text_280;

  /// No description provided for @text_281.
  ///
  /// In zh, this message translates to:
  /// **'南京復興'**
  String get text_281;

  /// No description provided for @text_282.
  ///
  /// In zh, this message translates to:
  /// **'古亭'**
  String get text_282;

  /// No description provided for @text_283.
  ///
  /// In zh, this message translates to:
  /// **'公館'**
  String get text_283;

  /// No description provided for @text_284.
  ///
  /// In zh, this message translates to:
  /// **'新店'**
  String get text_284;

  /// No description provided for @text_285.
  ///
  /// In zh, this message translates to:
  /// **'南港展覽館'**
  String get text_285;

  /// No description provided for @text_286.
  ///
  /// In zh, this message translates to:
  /// **'龍山寺'**
  String get text_286;

  /// No description provided for @text_287.
  ///
  /// In zh, this message translates to:
  /// **'板橋'**
  String get text_287;

  /// No description provided for @text_288.
  ///
  /// In zh, this message translates to:
  /// **'紅線'**
  String get text_288;

  /// No description provided for @text_289.
  ///
  /// In zh, this message translates to:
  /// **'綠線'**
  String get text_289;

  /// No description provided for @text_290.
  ///
  /// In zh, this message translates to:
  /// **'其他路線'**
  String get text_290;

  /// No description provided for @text_291.
  ///
  /// In zh, this message translates to:
  /// **'可能匹配'**
  String get text_291;

  /// No description provided for @text_292.
  ///
  /// In zh, this message translates to:
  /// **'\\n初始化距離:'**
  String get text_292;

  /// No description provided for @text_293.
  ///
  /// In zh, this message translates to:
  /// **'⚠️ 找不到更多可到達的節點，停止計算'**
  String get text_293;

  /// No description provided for @text_294.
  ///
  /// In zh, this message translates to:
  /// **'起始站自己: 1 個'**
  String get text_294;

  /// No description provided for @text_295.
  ///
  /// In zh, this message translates to:
  /// **'\\n前10個車站結果:'**
  String get text_295;

  /// No description provided for @text_296.
  ///
  /// In zh, this message translates to:
  /// **'無法到達'**
  String get text_296;

  /// No description provided for @text_297.
  ///
  /// In zh, this message translates to:
  /// **'發車時刻 / 班距'**
  String get text_297;

  /// No description provided for @text_298.
  ///
  /// In zh, this message translates to:
  /// **'載入時刻表中...'**
  String get text_298;

  /// No description provided for @text_299.
  ///
  /// In zh, this message translates to:
  /// **'請稍後再試'**
  String get text_299;

  /// No description provided for @text_300.
  ///
  /// In zh, this message translates to:
  /// **'暫無時刻表資料'**
  String get text_300;

  /// No description provided for @text_301.
  ///
  /// In zh, this message translates to:
  /// **'該城市目前沒有可用的時刻表'**
  String get text_301;

  /// No description provided for @text_302.
  ///
  /// In zh, this message translates to:
  /// **'營運中'**
  String get text_302;

  /// No description provided for @text_303.
  ///
  /// In zh, this message translates to:
  /// **'未營運'**
  String get text_303;

  /// No description provided for @text_304.
  ///
  /// In zh, this message translates to:
  /// **'營運時間'**
  String get text_304;

  /// No description provided for @text_305.
  ///
  /// In zh, this message translates to:
  /// **'班距時段'**
  String get text_305;

  /// No description provided for @text_306.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get text_306;

  /// No description provided for @text_307.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get text_307;

  /// No description provided for @text_308.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get text_308;

  /// No description provided for @text_309.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get text_309;

  /// No description provided for @text_310.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get text_310;

  /// No description provided for @text_311.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get text_311;

  /// No description provided for @text_312.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get text_312;

  /// No description provided for @text_313.
  ///
  /// In zh, this message translates to:
  /// **'尖峰'**
  String get text_313;

  /// No description provided for @text_314.
  ///
  /// In zh, this message translates to:
  /// **'離峰'**
  String get text_314;

  /// No description provided for @text_315.
  ///
  /// In zh, this message translates to:
  /// **'現在'**
  String get text_315;

  /// No description provided for @text_316.
  ///
  /// In zh, this message translates to:
  /// **'即將到站'**
  String get text_316;

  /// No description provided for @text_317.
  ///
  /// In zh, this message translates to:
  /// **'班次結束'**
  String get text_317;

  /// No description provided for @text_318.
  ///
  /// In zh, this message translates to:
  /// **'選擇排序方式'**
  String get text_318;

  /// No description provided for @text_319.
  ///
  /// In zh, this message translates to:
  /// **'時間 早→晚'**
  String get text_319;

  /// No description provided for @text_320.
  ///
  /// In zh, this message translates to:
  /// **'時間 晚→早'**
  String get text_320;

  /// No description provided for @text_321.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get text_321;

  /// No description provided for @text_322.
  ///
  /// In zh, this message translates to:
  /// **'未知站名'**
  String get text_322;

  /// No description provided for @text_323.
  ///
  /// In zh, this message translates to:
  /// **'未知方向'**
  String get text_323;

  /// No description provided for @text_324.
  ///
  /// In zh, this message translates to:
  /// **'批次查詢失敗: \$e, 啟動併發降級查詢'**
  String get text_324;

  /// No description provided for @text_325.
  ///
  /// In zh, this message translates to:
  /// **'未知出發站'**
  String get text_325;

  /// No description provided for @text_326.
  ///
  /// In zh, this message translates to:
  /// **'未知目的站'**
  String get text_326;

  /// No description provided for @text_327.
  ///
  /// In zh, this message translates to:
  /// **'處理資料失敗: \$e'**
  String get text_327;

  /// No description provided for @text_328.
  ///
  /// In zh, this message translates to:
  /// **'測試資料庫查詢...'**
  String get text_328;

  /// No description provided for @text_329.
  ///
  /// In zh, this message translates to:
  /// **'第一筆結果:'**
  String get text_329;

  /// No description provided for @text_330.
  ///
  /// In zh, this message translates to:
  /// **'測試失敗: \$e'**
  String get text_330;

  /// No description provided for @text_331.
  ///
  /// In zh, this message translates to:
  /// **'X 分鐘'**
  String get text_331;

  /// No description provided for @text_332.
  ///
  /// In zh, this message translates to:
  /// **'分鐘'**
  String get text_332;

  /// No description provided for @text_333.
  ///
  /// In zh, this message translates to:
  /// **'站牌資訊'**
  String get text_333;

  /// No description provided for @text_334.
  ///
  /// In zh, this message translates to:
  /// **'加入收藏'**
  String get text_334;

  /// No description provided for @text_335.
  ///
  /// In zh, this message translates to:
  /// **'排序方式'**
  String get text_335;

  /// No description provided for @text_336.
  ///
  /// In zh, this message translates to:
  /// **'儲存項目時發生錯誤'**
  String get text_336;

  /// No description provided for @text_337.
  ///
  /// In zh, this message translates to:
  /// **'載入路線形狀失敗: \$e'**
  String get text_337;

  /// No description provided for @text_338.
  ///
  /// In zh, this message translates to:
  /// **'載入路線失敗: \$e'**
  String get text_338;

  /// No description provided for @text_339.
  ///
  /// In zh, this message translates to:
  /// **'無資料'**
  String get text_339;

  /// No description provided for @text_340.
  ///
  /// In zh, this message translates to:
  /// **'已過站'**
  String get text_340;

  /// No description provided for @text_341.
  ///
  /// In zh, this message translates to:
  /// **'收藏成功'**
  String get text_341;

  /// No description provided for @text_342.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get text_342;

  /// No description provided for @text_343.
  ///
  /// In zh, this message translates to:
  /// **'收藏失敗'**
  String get text_343;

  /// No description provided for @text_344.
  ///
  /// In zh, this message translates to:
  /// **'查看詳細資訊'**
  String get text_344;

  /// No description provided for @text_345.
  ///
  /// In zh, this message translates to:
  /// **'收藏此路線'**
  String get text_345;

  /// No description provided for @text_346.
  ///
  /// In zh, this message translates to:
  /// **'查看路線地圖'**
  String get text_346;

  /// No description provided for @text_347.
  ///
  /// In zh, this message translates to:
  /// **'歷史時間'**
  String get text_347;

  /// No description provided for @text_348.
  ///
  /// In zh, this message translates to:
  /// **'查看歷史班次'**
  String get text_348;

  /// No description provided for @text_349.
  ///
  /// In zh, this message translates to:
  /// **'已停止自動更新'**
  String get text_349;

  /// No description provided for @text_350.
  ///
  /// In zh, this message translates to:
  /// **'最近'**
  String get text_350;

  /// No description provided for @text_351.
  ///
  /// In zh, this message translates to:
  /// **'公車站牌選項'**
  String get text_351;

  /// No description provided for @text_352.
  ///
  /// In zh, this message translates to:
  /// **'下班車資訊'**
  String get text_352;

  /// No description provided for @text_353.
  ///
  /// In zh, this message translates to:
  /// **'查看預計到站時間'**
  String get text_353;

  /// No description provided for @text_354.
  ///
  /// In zh, this message translates to:
  /// **'站牌查詢'**
  String get text_354;

  /// No description provided for @text_355.
  ///
  /// In zh, this message translates to:
  /// **'查看詳細站牌資訊'**
  String get text_355;

  /// No description provided for @text_356.
  ///
  /// In zh, this message translates to:
  /// **'到站通知'**
  String get text_356;

  /// No description provided for @text_357.
  ///
  /// In zh, this message translates to:
  /// **'設定公車到站提醒'**
  String get text_357;

  /// No description provided for @text_358.
  ///
  /// In zh, this message translates to:
  /// **'收藏此站牌'**
  String get text_358;

  /// No description provided for @text_359.
  ///
  /// In zh, this message translates to:
  /// **'路線規劃'**
  String get text_359;

  /// No description provided for @text_360.
  ///
  /// In zh, this message translates to:
  /// **'規劃乘車路線'**
  String get text_360;

  /// No description provided for @text_361.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有公車預估時間'**
  String get text_361;

  /// No description provided for @text_362.
  ///
  /// In zh, this message translates to:
  /// **'時間格式錯誤'**
  String get text_362;

  /// No description provided for @text_363.
  ///
  /// In zh, this message translates to:
  /// **'公車歷史資料'**
  String get text_363;

  /// No description provided for @text_364.
  ///
  /// In zh, this message translates to:
  /// **'搜尋站點名稱'**
  String get text_364;

  /// No description provided for @text_365.
  ///
  /// In zh, this message translates to:
  /// **'沒有符合的資料'**
  String get text_365;

  /// No description provided for @text_366.
  ///
  /// In zh, this message translates to:
  /// **'去程'**
  String get text_366;

  /// No description provided for @text_367.
  ///
  /// In zh, this message translates to:
  /// **'回程'**
  String get text_367;

  /// No description provided for @text_368.
  ///
  /// In zh, this message translates to:
  /// **'探索台灣城市'**
  String get text_368;

  /// No description provided for @text_369.
  ///
  /// In zh, this message translates to:
  /// **'充電樁資訊'**
  String get text_369;

  /// No description provided for @text_370.
  ///
  /// In zh, this message translates to:
  /// **'載入充電站資訊中...'**
  String get text_370;

  /// No description provided for @text_371.
  ///
  /// In zh, this message translates to:
  /// **'找不到符合的充電站'**
  String get text_371;

  /// No description provided for @text_372.
  ///
  /// In zh, this message translates to:
  /// **'請嘗試不同的搜尋關鍵字'**
  String get text_372;

  /// No description provided for @text_373.
  ///
  /// In zh, this message translates to:
  /// **'未命名充電站'**
  String get text_373;

  /// No description provided for @text_374.
  ///
  /// In zh, this message translates to:
  /// **'充電費率'**
  String get text_374;

  /// No description provided for @text_375.
  ///
  /// In zh, this message translates to:
  /// **'詳情見App'**
  String get text_375;

  /// No description provided for @text_376.
  ///
  /// In zh, this message translates to:
  /// **'停車費率'**
  String get text_376;

  /// No description provided for @text_377.
  ///
  /// In zh, this message translates to:
  /// **'依現場為準'**
  String get text_377;

  /// No description provided for @text_378.
  ///
  /// In zh, this message translates to:
  /// **'聯絡'**
  String get text_378;

  /// No description provided for @text_379.
  ///
  /// In zh, this message translates to:
  /// **'導航'**
  String get text_379;

  /// No description provided for @text_380.
  ///
  /// In zh, this message translates to:
  /// **'充電站'**
  String get text_380;

  /// No description provided for @text_381.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get text_381;

  /// No description provided for @text_382.
  ///
  /// In zh, this message translates to:
  /// **'充電站詳情'**
  String get text_382;

  /// No description provided for @text_383.
  ///
  /// In zh, this message translates to:
  /// **'最大功率'**
  String get text_383;

  /// No description provided for @text_384.
  ///
  /// In zh, this message translates to:
  /// **'可用接口'**
  String get text_384;

  /// No description provided for @text_385.
  ///
  /// In zh, this message translates to:
  /// **'分佈位置'**
  String get text_385;

  /// No description provided for @text_386.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get text_386;

  /// No description provided for @text_387.
  ///
  /// In zh, this message translates to:
  /// **'已滿'**
  String get text_387;

  /// No description provided for @text_388.
  ///
  /// In zh, this message translates to:
  /// **'維護中'**
  String get text_388;

  /// No description provided for @text_389.
  ///
  /// In zh, this message translates to:
  /// **'特斯拉'**
  String get text_389;

  /// No description provided for @text_390.
  ///
  /// In zh, this message translates to:
  /// **'未知類型'**
  String get text_390;

  /// No description provided for @text_391.
  ///
  /// In zh, this message translates to:
  /// **'沒有可用的充電接口'**
  String get text_391;

  /// No description provided for @text_392.
  ///
  /// In zh, this message translates to:
  /// **'此站點目前沒有提供充電服務'**
  String get text_392;

  /// No description provided for @text_393.
  ///
  /// In zh, this message translates to:
  /// **'高鐵列車時刻表'**
  String get text_393;

  /// No description provided for @text_394.
  ///
  /// In zh, this message translates to:
  /// **'台灣高鐵700T'**
  String get text_394;

  /// No description provided for @text_395.
  ///
  /// In zh, this message translates to:
  /// **'該行程已經存在'**
  String get text_395;

  /// No description provided for @text_396.
  ///
  /// In zh, this message translates to:
  /// **'行程添加成功'**
  String get text_396;

  /// No description provided for @text_397.
  ///
  /// In zh, this message translates to:
  /// **'添加行程失敗'**
  String get text_397;

  /// No description provided for @text_398.
  ///
  /// In zh, this message translates to:
  /// **'停靠站資訊'**
  String get text_398;

  /// No description provided for @text_399.
  ///
  /// In zh, this message translates to:
  /// **'列車編組'**
  String get text_399;

  /// No description provided for @text_400.
  ///
  /// In zh, this message translates to:
  /// **'列車長度'**
  String get text_400;

  /// No description provided for @text_401.
  ///
  /// In zh, this message translates to:
  /// **'最高時速'**
  String get text_401;

  /// No description provided for @text_402.
  ///
  /// In zh, this message translates to:
  /// **'營運速度'**
  String get text_402;

  /// No description provided for @text_403.
  ///
  /// In zh, this message translates to:
  /// **'座位配置'**
  String get text_403;

  /// No description provided for @text_404.
  ///
  /// In zh, this message translates to:
  /// **'標準座艙 + 商務座艙'**
  String get text_404;

  /// No description provided for @text_405.
  ///
  /// In zh, this message translates to:
  /// **'無障礙設施'**
  String get text_405;

  /// No description provided for @text_406.
  ///
  /// In zh, this message translates to:
  /// **'第5車廂'**
  String get text_406;

  /// No description provided for @text_407.
  ///
  /// In zh, this message translates to:
  /// **'哺集乳室'**
  String get text_407;

  /// No description provided for @text_408.
  ///
  /// In zh, this message translates to:
  /// **'台灣高鐵'**
  String get text_408;

  /// No description provided for @text_409.
  ///
  /// In zh, this message translates to:
  /// **'起站'**
  String get text_409;

  /// No description provided for @text_410.
  ///
  /// In zh, this message translates to:
  /// **'終站'**
  String get text_410;

  /// No description provided for @text_411.
  ///
  /// In zh, this message translates to:
  /// **'正常停靠'**
  String get text_411;

  /// No description provided for @text_412.
  ///
  /// In zh, this message translates to:
  /// **'北高時間'**
  String get text_412;

  /// No description provided for @text_413.
  ///
  /// In zh, this message translates to:
  /// **'座位數'**
  String get text_413;

  /// No description provided for @text_414.
  ///
  /// In zh, this message translates to:
  /// **'取得站點資料失敗: \$e'**
  String get text_414;

  /// No description provided for @text_415.
  ///
  /// In zh, this message translates to:
  /// **'公車站'**
  String get text_415;

  /// No description provided for @text_416.
  ///
  /// In zh, this message translates to:
  /// **'捷運站'**
  String get text_416;

  /// No description provided for @text_417.
  ///
  /// In zh, this message translates to:
  /// **'火車站'**
  String get text_417;

  /// No description provided for @text_418.
  ///
  /// In zh, this message translates to:
  /// **'高鐵站'**
  String get text_418;

  /// No description provided for @text_419.
  ///
  /// In zh, this message translates to:
  /// **'找不到附近的站牌'**
  String get text_419;

  /// No description provided for @text_420.
  ///
  /// In zh, this message translates to:
  /// **'重試'**
  String get text_420;

  /// No description provided for @text_421.
  ///
  /// In zh, this message translates to:
  /// **'這是高鐵站的內容'**
  String get text_421;

  /// No description provided for @text_422.
  ///
  /// In zh, this message translates to:
  /// **'開發中'**
  String get text_422;

  /// No description provided for @text_423.
  ///
  /// In zh, this message translates to:
  /// **'無數據，返回空列表'**
  String get text_423;

  /// No description provided for @text_424.
  ///
  /// In zh, this message translates to:
  /// **'批次查詢失敗: \$e'**
  String get text_424;

  /// No description provided for @text_425.
  ///
  /// In zh, this message translates to:
  /// **'開始逐個查詢...'**
  String get text_425;

  /// No description provided for @text_426.
  ///
  /// In zh, this message translates to:
  /// **'開始合併路線資訊...'**
  String get text_426;

  /// No description provided for @text_427.
  ///
  /// In zh, this message translates to:
  /// **'和'**
  String get text_427;

  /// No description provided for @text_428.
  ///
  /// In zh, this message translates to:
  /// **'未知目的地'**
  String get text_428;

  /// No description provided for @text_429.
  ///
  /// In zh, this message translates to:
  /// **'未知出發地'**
  String get text_429;

  /// No description provided for @text_430.
  ///
  /// In zh, this message translates to:
  /// **'沒有資料'**
  String get text_430;

  /// No description provided for @text_431.
  ///
  /// In zh, this message translates to:
  /// **'城市_站點名'**
  String get text_431;

  /// No description provided for @text_432.
  ///
  /// In zh, this message translates to:
  /// **'[Cache] 快取未命中或過期，請求遠端資料 \$key'**
  String get text_432;

  /// No description provided for @text_433.
  ///
  /// In zh, this message translates to:
  /// **'無內容'**
  String get text_433;

  /// No description provided for @text_434.
  ///
  /// In zh, this message translates to:
  /// **'用戶拒絕通知'**
  String get text_434;

  /// No description provided for @text_435.
  ///
  /// In zh, this message translates to:
  /// **'通知中心'**
  String get text_435;

  /// No description provided for @text_436.
  ///
  /// In zh, this message translates to:
  /// **'暫無新通知'**
  String get text_436;

  /// No description provided for @text_437.
  ///
  /// In zh, this message translates to:
  /// **'所有重要資訊都會在這裡顯示'**
  String get text_437;

  /// No description provided for @text_438.
  ///
  /// In zh, this message translates to:
  /// **'重新整理'**
  String get text_438;

  /// No description provided for @text_439.
  ///
  /// In zh, this message translates to:
  /// **'全部通知'**
  String get text_439;

  /// No description provided for @text_440.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get text_440;

  /// No description provided for @text_441.
  ///
  /// In zh, this message translates to:
  /// **'錯誤'**
  String get text_441;

  /// No description provided for @text_442.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get text_442;

  /// No description provided for @text_443.
  ///
  /// In zh, this message translates to:
  /// **'優惠'**
  String get text_443;

  /// No description provided for @text_444.
  ///
  /// In zh, this message translates to:
  /// **'資訊'**
  String get text_444;

  /// No description provided for @text_445.
  ///
  /// In zh, this message translates to:
  /// **'交通助手'**
  String get text_445;

  /// No description provided for @text_446.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get text_446;

  /// No description provided for @text_447.
  ///
  /// In zh, this message translates to:
  /// **'系統設定'**
  String get text_447;

  /// No description provided for @text_448.
  ///
  /// In zh, this message translates to:
  /// **'啟用即時通知'**
  String get text_448;

  /// No description provided for @text_449.
  ///
  /// In zh, this message translates to:
  /// **'接收公車到站與天氣警報'**
  String get text_449;

  /// No description provided for @text_450.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get text_450;

  /// No description provided for @text_451.
  ///
  /// In zh, this message translates to:
  /// **'語言設定'**
  String get text_451;

  /// No description provided for @text_452.
  ///
  /// In zh, this message translates to:
  /// **'資料管理'**
  String get text_452;

  /// No description provided for @text_453.
  ///
  /// In zh, this message translates to:
  /// **'資料來源說明'**
  String get text_453;

  /// No description provided for @text_454.
  ///
  /// In zh, this message translates to:
  /// **'清除數據庫'**
  String get text_454;

  /// No description provided for @text_455.
  ///
  /// In zh, this message translates to:
  /// **'刪除所有儲存的常用行程與快取'**
  String get text_455;

  /// No description provided for @text_456.
  ///
  /// In zh, this message translates to:
  /// **'支援與關於'**
  String get text_456;

  /// No description provided for @text_457.
  ///
  /// In zh, this message translates to:
  /// **'評分我們'**
  String get text_457;

  /// No description provided for @text_458.
  ///
  /// In zh, this message translates to:
  /// **'問題回饋'**
  String get text_458;

  /// No description provided for @text_459.
  ///
  /// In zh, this message translates to:
  /// **'關於我們'**
  String get text_459;

  /// No description provided for @text_460.
  ///
  /// In zh, this message translates to:
  /// **'開發者設定'**
  String get text_460;

  /// No description provided for @text_461.
  ///
  /// In zh, this message translates to:
  /// **'選擇語言'**
  String get text_461;

  /// No description provided for @text_462.
  ///
  /// In zh, this message translates to:
  /// **'確認清除？'**
  String get text_462;

  /// No description provided for @text_463.
  ///
  /// In zh, this message translates to:
  /// **'這將刪除所有儲存的資料，且無法復原。是否繼續？'**
  String get text_463;

  /// No description provided for @text_464.
  ///
  /// In zh, this message translates to:
  /// **'✅ 數據庫已清除'**
  String get text_464;

  /// No description provided for @text_465.
  ///
  /// In zh, this message translates to:
  /// **'確定清除'**
  String get text_465;

  /// No description provided for @text_466.
  ///
  /// In zh, this message translates to:
  /// **'資料來源'**
  String get text_466;

  /// No description provided for @text_467.
  ///
  /// In zh, this message translates to:
  /// **'本應用的數據來源於以下平台：'**
  String get text_467;

  /// No description provided for @text_468.
  ///
  /// In zh, this message translates to:
  /// **'• TDX 交通部運輸資料流通服務平臺'**
  String get text_468;

  /// No description provided for @text_469.
  ///
  /// In zh, this message translates to:
  /// **'• CWA 中央氣象署開放資料平臺'**
  String get text_469;

  /// No description provided for @text_470.
  ///
  /// In zh, this message translates to:
  /// **'所有即時資訊以各平臺官方發佈為準。'**
  String get text_470;

  /// No description provided for @text_471.
  ///
  /// In zh, this message translates to:
  /// **'確定'**
  String get text_471;

  /// No description provided for @text_472.
  ///
  /// In zh, this message translates to:
  /// **'最高速度'**
  String get text_472;

  /// No description provided for @text_473.
  ///
  /// In zh, this message translates to:
  /// **'平均速度'**
  String get text_473;

  /// No description provided for @text_474.
  ///
  /// In zh, this message translates to:
  /// **'累計里程'**
  String get text_474;

  /// No description provided for @text_475.
  ///
  /// In zh, this message translates to:
  /// **'行程時間'**
  String get text_475;

  /// No description provided for @text_476.
  ///
  /// In zh, this message translates to:
  /// **'海拔'**
  String get text_476;

  /// No description provided for @text_477.
  ///
  /// In zh, this message translates to:
  /// **'定位精度'**
  String get text_477;

  /// No description provided for @text_478.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get text_478;

  /// No description provided for @text_479.
  ///
  /// In zh, this message translates to:
  /// **'校準'**
  String get text_479;

  /// No description provided for @text_480.
  ///
  /// In zh, this message translates to:
  /// **'記錄'**
  String get text_480;

  /// No description provided for @text_481.
  ///
  /// In zh, this message translates to:
  /// **'速度記錄已保存'**
  String get text_481;

  /// No description provided for @text_482.
  ///
  /// In zh, this message translates to:
  /// **'設置'**
  String get text_482;

  /// No description provided for @text_483.
  ///
  /// In zh, this message translates to:
  /// **'速度單位'**
  String get text_483;

  /// No description provided for @text_484.
  ///
  /// In zh, this message translates to:
  /// **'小數位數'**
  String get text_484;

  /// No description provided for @text_485.
  ///
  /// In zh, this message translates to:
  /// **'主題顏色'**
  String get text_485;

  /// No description provided for @text_486.
  ///
  /// In zh, this message translates to:
  /// **'顯示選項'**
  String get text_486;

  /// No description provided for @text_487.
  ///
  /// In zh, this message translates to:
  /// **'數位顯示'**
  String get text_487;

  /// No description provided for @text_488.
  ///
  /// In zh, this message translates to:
  /// **'指針顯示'**
  String get text_488;

  /// No description provided for @text_489.
  ///
  /// In zh, this message translates to:
  /// **'速度記錄'**
  String get text_489;

  /// No description provided for @text_490.
  ///
  /// In zh, this message translates to:
  /// **'無記錄'**
  String get text_490;

  /// No description provided for @text_491.
  ///
  /// In zh, this message translates to:
  /// **'清除記錄'**
  String get text_491;

  /// No description provided for @text_492.
  ///
  /// In zh, this message translates to:
  /// **'重置確認'**
  String get text_492;

  /// No description provided for @text_493.
  ///
  /// In zh, this message translates to:
  /// **'確定要重置所有行程數據嗎？\\n（最高速度記錄將保留）'**
  String get text_493;

  /// No description provided for @text_494.
  ///
  /// In zh, this message translates to:
  /// **'行程數據已重置'**
  String get text_494;

  /// No description provided for @text_495.
  ///
  /// In zh, this message translates to:
  /// **'速度計校準'**
  String get text_495;

  /// No description provided for @text_496.
  ///
  /// In zh, this message translates to:
  /// **'輸入參考速度以校準儀表：'**
  String get text_496;

  /// No description provided for @text_497.
  ///
  /// In zh, this message translates to:
  /// **'停車資訊'**
  String get text_497;

  /// No description provided for @text_498.
  ///
  /// In zh, this message translates to:
  /// **'找不到停車場'**
  String get text_498;

  /// No description provided for @text_499.
  ///
  /// In zh, this message translates to:
  /// **'請嘗試不同的搜尋條件'**
  String get text_499;

  /// No description provided for @text_500.
  ///
  /// In zh, this message translates to:
  /// **'未命名停車場'**
  String get text_500;

  /// No description provided for @text_501.
  ///
  /// In zh, this message translates to:
  /// **'無地址資訊'**
  String get text_501;

  /// No description provided for @text_502.
  ///
  /// In zh, this message translates to:
  /// **'未知名稱'**
  String get text_502;

  /// No description provided for @text_503.
  ///
  /// In zh, this message translates to:
  /// **'充足'**
  String get text_503;

  /// No description provided for @text_504.
  ///
  /// In zh, this message translates to:
  /// **'普通'**
  String get text_504;

  /// No description provided for @text_505.
  ///
  /// In zh, this message translates to:
  /// **'緊張'**
  String get text_505;

  /// No description provided for @text_506.
  ///
  /// In zh, this message translates to:
  /// **'無車位資訊'**
  String get text_506;

  /// No description provided for @text_507.
  ///
  /// In zh, this message translates to:
  /// **'費用'**
  String get text_507;

  /// No description provided for @text_508.
  ///
  /// In zh, this message translates to:
  /// **'無資訊'**
  String get text_508;

  /// No description provided for @text_509.
  ///
  /// In zh, this message translates to:
  /// **'無法開啟地圖'**
  String get text_509;

  /// No description provided for @text_510.
  ///
  /// In zh, this message translates to:
  /// **'停車場詳情'**
  String get text_510;

  /// No description provided for @text_511.
  ///
  /// In zh, this message translates to:
  /// **'基本資訊'**
  String get text_511;

  /// No description provided for @text_512.
  ///
  /// In zh, this message translates to:
  /// **'停車場 ID'**
  String get text_512;

  /// No description provided for @text_513.
  ///
  /// In zh, this message translates to:
  /// **'地址'**
  String get text_513;

  /// No description provided for @text_514.
  ///
  /// In zh, this message translates to:
  /// **'聯絡電話'**
  String get text_514;

  /// No description provided for @text_515.
  ///
  /// In zh, this message translates to:
  /// **'費用資訊'**
  String get text_515;

  /// No description provided for @text_516.
  ///
  /// In zh, this message translates to:
  /// **'收費方式'**
  String get text_516;

  /// No description provided for @text_517.
  ///
  /// In zh, this message translates to:
  /// **'收費種類'**
  String get text_517;

  /// No description provided for @text_518.
  ///
  /// In zh, this message translates to:
  /// **'設施服務'**
  String get text_518;

  /// No description provided for @text_519.
  ///
  /// In zh, this message translates to:
  /// **'停車種類'**
  String get text_519;

  /// No description provided for @text_520.
  ///
  /// In zh, this message translates to:
  /// **'營運描述'**
  String get text_520;

  /// No description provided for @text_521.
  ///
  /// In zh, this message translates to:
  /// **'其他資訊'**
  String get text_521;

  /// No description provided for @text_522.
  ///
  /// In zh, this message translates to:
  /// **'全年無休'**
  String get text_522;

  /// No description provided for @text_523.
  ///
  /// In zh, this message translates to:
  /// **'充電樁'**
  String get text_523;

  /// No description provided for @text_524.
  ///
  /// In zh, this message translates to:
  /// **'可過夜'**
  String get text_524;

  /// No description provided for @text_525.
  ///
  /// In zh, this message translates to:
  /// **'車輛偵測'**
  String get text_525;

  /// No description provided for @text_526.
  ///
  /// In zh, this message translates to:
  /// **'無障礙車位'**
  String get text_526;

  /// No description provided for @text_527.
  ///
  /// In zh, this message translates to:
  /// **'位置資訊'**
  String get text_527;

  /// No description provided for @text_528.
  ///
  /// In zh, this message translates to:
  /// **'停車場'**
  String get text_528;

  /// No description provided for @text_529.
  ///
  /// In zh, this message translates to:
  /// **'無即時車位資訊'**
  String get text_529;

  /// No description provided for @text_530.
  ///
  /// In zh, this message translates to:
  /// **'剩餘車位'**
  String get text_530;

  /// No description provided for @text_531.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get text_531;

  /// No description provided for @text_532.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get text_532;

  /// No description provided for @text_533.
  ///
  /// In zh, this message translates to:
  /// **'地理位置'**
  String get text_533;

  /// No description provided for @text_534.
  ///
  /// In zh, this message translates to:
  /// **'撥打電話'**
  String get text_534;

  /// No description provided for @text_535.
  ///
  /// In zh, this message translates to:
  /// **'開始導航'**
  String get text_535;

  /// No description provided for @text_536.
  ///
  /// In zh, this message translates to:
  /// **'平面'**
  String get text_536;

  /// No description provided for @text_537.
  ///
  /// In zh, this message translates to:
  /// **'立體'**
  String get text_537;

  /// No description provided for @text_538.
  ///
  /// In zh, this message translates to:
  /// **'地下'**
  String get text_538;

  /// No description provided for @text_539.
  ///
  /// In zh, this message translates to:
  /// **'立體停車塔'**
  String get text_539;

  /// No description provided for @text_540.
  ///
  /// In zh, this message translates to:
  /// **'立體機械式'**
  String get text_540;

  /// No description provided for @text_541.
  ///
  /// In zh, this message translates to:
  /// **'同時涵蓋2種以上'**
  String get text_541;

  /// No description provided for @text_542.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get text_542;

  /// No description provided for @text_543.
  ///
  /// In zh, this message translates to:
  /// **'計時'**
  String get text_543;

  /// No description provided for @text_544.
  ///
  /// In zh, this message translates to:
  /// **'計次'**
  String get text_544;

  /// No description provided for @text_545.
  ///
  /// In zh, this message translates to:
  /// **'月租'**
  String get text_545;

  /// No description provided for @text_546.
  ///
  /// In zh, this message translates to:
  /// **'免費'**
  String get text_546;

  /// No description provided for @text_547.
  ///
  /// In zh, this message translates to:
  /// **'自行找尋停車位'**
  String get text_547;

  /// No description provided for @text_548.
  ///
  /// In zh, this message translates to:
  /// **'有導引輔助設施協助尋找停車位'**
  String get text_548;

  /// No description provided for @text_549.
  ///
  /// In zh, this message translates to:
  /// **'人工導引停找車位'**
  String get text_549;

  /// No description provided for @text_550.
  ///
  /// In zh, this message translates to:
  /// **'代客泊車'**
  String get text_550;

  /// No description provided for @text_551.
  ///
  /// In zh, this message translates to:
  /// **'混合型'**
  String get text_551;

  /// No description provided for @text_552.
  ///
  /// In zh, this message translates to:
  /// **'停車轉乘公共運輸'**
  String get text_552;

  /// No description provided for @text_553.
  ///
  /// In zh, this message translates to:
  /// **'臨時停車接送'**
  String get text_553;

  /// No description provided for @text_554.
  ///
  /// In zh, this message translates to:
  /// **'停車後轉使用公共自行車'**
  String get text_554;

  /// No description provided for @text_555.
  ///
  /// In zh, this message translates to:
  /// **'停車後步行'**
  String get text_555;

  /// No description provided for @text_556.
  ///
  /// In zh, this message translates to:
  /// **'活動專用停車場'**
  String get text_556;

  /// No description provided for @text_557.
  ///
  /// In zh, this message translates to:
  /// **'休息站專用停車場'**
  String get text_557;

  /// No description provided for @text_558.
  ///
  /// In zh, this message translates to:
  /// **'服務區專用停車場'**
  String get text_558;

  /// No description provided for @text_559.
  ///
  /// In zh, this message translates to:
  /// **'貨車及大型車停車場'**
  String get text_559;

  /// No description provided for @text_560.
  ///
  /// In zh, this message translates to:
  /// **'共享汽車租用服務停車場'**
  String get text_560;

  /// No description provided for @text_561.
  ///
  /// In zh, this message translates to:
  /// **'共乘服務停車場'**
  String get text_561;

  /// No description provided for @text_562.
  ///
  /// In zh, this message translates to:
  /// **'軌道場站'**
  String get text_562;

  /// No description provided for @text_563.
  ///
  /// In zh, this message translates to:
  /// **'機場場站'**
  String get text_563;

  /// No description provided for @text_564.
  ///
  /// In zh, this message translates to:
  /// **'船舶場站'**
  String get text_564;

  /// No description provided for @text_565.
  ///
  /// In zh, this message translates to:
  /// **'商圈'**
  String get text_565;

  /// No description provided for @text_566.
  ///
  /// In zh, this message translates to:
  /// **'餐廳'**
  String get text_566;

  /// No description provided for @text_567.
  ///
  /// In zh, this message translates to:
  /// **'運動場'**
  String get text_567;

  /// No description provided for @text_568.
  ///
  /// In zh, this message translates to:
  /// **'飯店'**
  String get text_568;

  /// No description provided for @text_569.
  ///
  /// In zh, this message translates to:
  /// **'觀光地標'**
  String get text_569;

  /// No description provided for @text_570.
  ///
  /// In zh, this message translates to:
  /// **'電影院'**
  String get text_570;

  /// No description provided for @text_571.
  ///
  /// In zh, this message translates to:
  /// **'觀光景點'**
  String get text_571;

  /// No description provided for @text_572.
  ///
  /// In zh, this message translates to:
  /// **'學校'**
  String get text_572;

  /// No description provided for @text_573.
  ///
  /// In zh, this message translates to:
  /// **'美術博物館'**
  String get text_573;

  /// No description provided for @text_574.
  ///
  /// In zh, this message translates to:
  /// **'展覽中心'**
  String get text_574;

  /// No description provided for @text_575.
  ///
  /// In zh, this message translates to:
  /// **'會議中心'**
  String get text_575;

  /// No description provided for @text_576.
  ///
  /// In zh, this message translates to:
  /// **'宗教機構'**
  String get text_576;

  /// No description provided for @text_577.
  ///
  /// In zh, this message translates to:
  /// **'賣場'**
  String get text_577;

  /// No description provided for @text_578.
  ///
  /// In zh, this message translates to:
  /// **'動物園'**
  String get text_578;

  /// No description provided for @text_579.
  ///
  /// In zh, this message translates to:
  /// **'高速公路'**
  String get text_579;

  /// No description provided for @text_580.
  ///
  /// In zh, this message translates to:
  /// **'政府部門'**
  String get text_580;

  /// No description provided for @text_581.
  ///
  /// In zh, this message translates to:
  /// **'住宅區'**
  String get text_581;

  /// No description provided for @text_582.
  ///
  /// In zh, this message translates to:
  /// **'夜市'**
  String get text_582;

  /// No description provided for @text_583.
  ///
  /// In zh, this message translates to:
  /// **'市場'**
  String get text_583;

  /// No description provided for @text_584.
  ///
  /// In zh, this message translates to:
  /// **'公園'**
  String get text_584;

  /// No description provided for @text_585.
  ///
  /// In zh, this message translates to:
  /// **'火車'**
  String get text_585;

  /// No description provided for @text_586.
  ///
  /// In zh, this message translates to:
  /// **'高鐵'**
  String get text_586;

  /// No description provided for @text_587.
  ///
  /// In zh, this message translates to:
  /// **'捷運'**
  String get text_587;

  /// No description provided for @text_588.
  ///
  /// In zh, this message translates to:
  /// **'公車'**
  String get text_588;

  /// No description provided for @text_589.
  ///
  /// In zh, this message translates to:
  /// **'飛機'**
  String get text_589;

  /// No description provided for @text_590.
  ///
  /// In zh, this message translates to:
  /// **'客運'**
  String get text_590;

  /// No description provided for @text_591.
  ///
  /// In zh, this message translates to:
  /// **'市政府站'**
  String get text_591;

  /// No description provided for @text_592.
  ///
  /// In zh, this message translates to:
  /// **'信義安和'**
  String get text_592;

  /// No description provided for @text_593.
  ///
  /// In zh, this message translates to:
  /// **'士林夜市'**
  String get text_593;

  /// No description provided for @text_594.
  ///
  /// In zh, this message translates to:
  /// **'劍潭站'**
  String get text_594;

  /// No description provided for @text_595.
  ///
  /// In zh, this message translates to:
  /// **'中山國中'**
  String get text_595;

  /// No description provided for @text_596.
  ///
  /// In zh, this message translates to:
  /// **'松山機場'**
  String get text_596;

  /// No description provided for @text_597.
  ///
  /// In zh, this message translates to:
  /// **'圓山飯店'**
  String get text_597;

  /// No description provided for @text_598.
  ///
  /// In zh, this message translates to:
  /// **'選擇站牌'**
  String get text_598;

  /// No description provided for @text_599.
  ///
  /// In zh, this message translates to:
  /// **'搜尋站牌'**
  String get text_599;

  /// No description provided for @text_600.
  ///
  /// In zh, this message translates to:
  /// **'正在載入路線數據...'**
  String get text_600;

  /// No description provided for @text_601.
  ///
  /// In zh, this message translates to:
  /// **'選擇路線'**
  String get text_601;

  /// No description provided for @text_602.
  ///
  /// In zh, this message translates to:
  /// **'請選擇路線'**
  String get text_602;

  /// No description provided for @text_603.
  ///
  /// In zh, this message translates to:
  /// **'確認行程'**
  String get text_603;

  /// No description provided for @text_604.
  ///
  /// In zh, this message translates to:
  /// **'行程規畫'**
  String get text_604;

  /// No description provided for @text_605.
  ///
  /// In zh, this message translates to:
  /// **'請選擇'**
  String get text_605;

  /// No description provided for @text_606.
  ///
  /// In zh, this message translates to:
  /// **'選擇到達站'**
  String get text_606;

  /// No description provided for @text_607.
  ///
  /// In zh, this message translates to:
  /// **'搜尋站點'**
  String get text_607;

  /// No description provided for @text_608.
  ///
  /// In zh, this message translates to:
  /// **'搜尋路線'**
  String get text_608;

  /// No description provided for @text_609.
  ///
  /// In zh, this message translates to:
  /// **'選擇類別'**
  String get text_609;

  /// No description provided for @text_610.
  ///
  /// In zh, this message translates to:
  /// **'將路線 \$route 添加到以下類別:'**
  String get text_610;

  /// No description provided for @text_611.
  ///
  /// In zh, this message translates to:
  /// **'該行程已經存在。'**
  String get text_611;

  /// No description provided for @text_612.
  ///
  /// In zh, this message translates to:
  /// **'行程添加成功！'**
  String get text_612;

  /// No description provided for @text_613.
  ///
  /// In zh, this message translates to:
  /// **'添加行程失敗。'**
  String get text_613;

  /// No description provided for @text_614.
  ///
  /// In zh, this message translates to:
  /// **'添加到旅行'**
  String get text_614;

  /// No description provided for @text_615.
  ///
  /// In zh, this message translates to:
  /// **'添加到上班通勤'**
  String get text_615;

  /// No description provided for @text_616.
  ///
  /// In zh, this message translates to:
  /// **'選擇站點'**
  String get text_616;

  /// No description provided for @text_617.
  ///
  /// In zh, this message translates to:
  /// **'輸入站名搜尋...'**
  String get text_617;

  /// No description provided for @text_618.
  ///
  /// In zh, this message translates to:
  /// **'找不到相關站點'**
  String get text_618;

  /// No description provided for @text_619.
  ///
  /// In zh, this message translates to:
  /// **'確認選擇'**
  String get text_619;

  /// No description provided for @text_620.
  ///
  /// In zh, this message translates to:
  /// **'搜尋'**
  String get text_620;

  /// No description provided for @text_621.
  ///
  /// In zh, this message translates to:
  /// **'尚未取得'**
  String get text_621;

  /// No description provided for @text_622.
  ///
  /// In zh, this message translates to:
  /// **'圓山交流道'**
  String get text_622;

  /// No description provided for @text_623.
  ///
  /// In zh, this message translates to:
  /// **'前方道路施工 請減速慢行'**
  String get text_623;

  /// No description provided for @text_624.
  ///
  /// In zh, this message translates to:
  /// **'施工'**
  String get text_624;

  /// No description provided for @text_625.
  ///
  /// In zh, this message translates to:
  /// **'定位未授權'**
  String get text_625;

  /// No description provided for @text_626.
  ///
  /// In zh, this message translates to:
  /// **'事故'**
  String get text_626;

  /// No description provided for @text_627.
  ///
  /// In zh, this message translates to:
  /// **'國道1號 25.2k 小客車追撞'**
  String get text_627;

  /// No description provided for @text_628.
  ///
  /// In zh, this message translates to:
  /// **'北'**
  String get text_628;

  /// No description provided for @text_629.
  ///
  /// In zh, this message translates to:
  /// **'東北'**
  String get text_629;

  /// No description provided for @text_630.
  ///
  /// In zh, this message translates to:
  /// **'東'**
  String get text_630;

  /// No description provided for @text_631.
  ///
  /// In zh, this message translates to:
  /// **'東南'**
  String get text_631;

  /// No description provided for @text_632.
  ///
  /// In zh, this message translates to:
  /// **'南'**
  String get text_632;

  /// No description provided for @text_633.
  ///
  /// In zh, this message translates to:
  /// **'西南'**
  String get text_633;

  /// No description provided for @text_634.
  ///
  /// In zh, this message translates to:
  /// **'西'**
  String get text_634;

  /// No description provided for @text_635.
  ///
  /// In zh, this message translates to:
  /// **'西北'**
  String get text_635;

  /// No description provided for @text_636.
  ///
  /// In zh, this message translates to:
  /// **'高速公路行車助理系統 (範例)'**
  String get text_636;

  /// No description provided for @text_637.
  ///
  /// In zh, this message translates to:
  /// **'目前位置'**
  String get text_637;

  /// No description provided for @text_638.
  ///
  /// In zh, this message translates to:
  /// **'最近交流道'**
  String get text_638;

  /// No description provided for @text_639.
  ///
  /// In zh, this message translates to:
  /// **'可變標誌 CMS'**
  String get text_639;

  /// No description provided for @text_640.
  ///
  /// In zh, this message translates to:
  /// **'前方 3 公里內事件'**
  String get text_640;

  /// No description provided for @text_641.
  ///
  /// In zh, this message translates to:
  /// **'無事故 / 無施工'**
  String get text_641;

  /// No description provided for @text_642.
  ///
  /// In zh, this message translates to:
  /// **'重新整理（示範）'**
  String get text_642;

  /// No description provided for @text_643.
  ///
  /// In zh, this message translates to:
  /// **'高速公路道路事件資訊'**
  String get text_643;

  /// No description provided for @text_644.
  ///
  /// In zh, this message translates to:
  /// **'查看高速公路道路事件資訊'**
  String get text_644;

  /// No description provided for @text_645.
  ///
  /// In zh, this message translates to:
  /// **'沒有事件資料'**
  String get text_645;

  /// No description provided for @text_646.
  ///
  /// In zh, this message translates to:
  /// **'事件'**
  String get text_646;

  /// No description provided for @text_647.
  ///
  /// In zh, this message translates to:
  /// **'未知位置'**
  String get text_647;

  /// No description provided for @text_648.
  ///
  /// In zh, this message translates to:
  /// **'無'**
  String get text_648;

  /// No description provided for @text_649.
  ///
  /// In zh, this message translates to:
  /// **'電力機車頭，最高時速130km/h'**
  String get text_649;

  /// No description provided for @text_650.
  ///
  /// In zh, this message translates to:
  /// **'城際電聯車，最高時速130km/h，12節編組'**
  String get text_650;

  /// No description provided for @text_651.
  ///
  /// In zh, this message translates to:
  /// **'區間通勤電聯車，最高時速130km/h，10節編組'**
  String get text_651;

  /// No description provided for @text_652.
  ///
  /// In zh, this message translates to:
  /// **'推拉式自強號'**
  String get text_652;

  /// No description provided for @text_653.
  ///
  /// In zh, this message translates to:
  /// **'推拉式電聯車，最高時速130km/h，12節編組'**
  String get text_653;

  /// No description provided for @text_654.
  ///
  /// In zh, this message translates to:
  /// **'列車時刻表'**
  String get text_654;

  /// No description provided for @text_655.
  ///
  /// In zh, this message translates to:
  /// **'列車資訊'**
  String get text_655;

  /// No description provided for @text_656.
  ///
  /// In zh, this message translates to:
  /// **'行李服務'**
  String get text_656;

  /// No description provided for @text_657.
  ///
  /// In zh, this message translates to:
  /// **'餐飲服務'**
  String get text_657;

  /// No description provided for @text_658.
  ///
  /// In zh, this message translates to:
  /// **'自行車車廂'**
  String get text_658;

  /// No description provided for @text_659.
  ///
  /// In zh, this message translates to:
  /// **'哺乳設施'**
  String get text_659;

  /// No description provided for @text_660.
  ///
  /// In zh, this message translates to:
  /// **'每日行駛'**
  String get text_660;

  /// No description provided for @text_661.
  ///
  /// In zh, this message translates to:
  /// **'加班列車'**
  String get text_661;

  /// No description provided for @text_662.
  ///
  /// In zh, this message translates to:
  /// **'停駛'**
  String get text_662;

  /// No description provided for @text_663.
  ///
  /// In zh, this message translates to:
  /// **'提供'**
  String get text_663;

  /// No description provided for @text_664.
  ///
  /// In zh, this message translates to:
  /// **'跨日行駛'**
  String get text_664;

  /// No description provided for @text_665.
  ///
  /// In zh, this message translates to:
  /// **'準點運行'**
  String get text_665;

  /// No description provided for @text_666.
  ///
  /// In zh, this message translates to:
  /// **'即時資訊'**
  String get text_666;

  /// No description provided for @text_667.
  ///
  /// In zh, this message translates to:
  /// **'自強(推拉式自強號且無自行車車廂)'**
  String get text_667;

  /// No description provided for @text_668.
  ///
  /// In zh, this message translates to:
  /// **'自強(推拉式自強號且有自行車車廂)'**
  String get text_668;

  /// No description provided for @text_669.
  ///
  /// In zh, this message translates to:
  /// **'太魯閣(太魯閣)'**
  String get text_669;

  /// No description provided for @text_670.
  ///
  /// In zh, this message translates to:
  /// **'普悠瑪(普悠瑪)'**
  String get text_670;

  /// No description provided for @text_671.
  ///
  /// In zh, this message translates to:
  /// **'列車編組資訊'**
  String get text_671;

  /// No description provided for @text_672.
  ///
  /// In zh, this message translates to:
  /// **'列車型號'**
  String get text_672;

  /// No description provided for @text_673.
  ///
  /// In zh, this message translates to:
  /// **'無障礙車廂'**
  String get text_673;

  /// No description provided for @text_674.
  ///
  /// In zh, this message translates to:
  /// **'車長室'**
  String get text_674;

  /// No description provided for @text_675.
  ///
  /// In zh, this message translates to:
  /// **'親子車廂'**
  String get text_675;

  /// No description provided for @text_676.
  ///
  /// In zh, this message translates to:
  /// **'測試BETA人員'**
  String get text_676;

  /// No description provided for @text_677.
  ///
  /// In zh, this message translates to:
  /// **'歷史行程'**
  String get text_677;

  /// No description provided for @text_678.
  ///
  /// In zh, this message translates to:
  /// **'里程'**
  String get text_678;

  /// No description provided for @text_679.
  ///
  /// In zh, this message translates to:
  /// **'版本資訊'**
  String get text_679;

  /// No description provided for @text_680.
  ///
  /// In zh, this message translates to:
  /// **'查看應用版本與詳細資訊'**
  String get text_680;

  /// No description provided for @text_681.
  ///
  /// In zh, this message translates to:
  /// **'Token 複製到剪貼簿'**
  String get text_681;

  /// No description provided for @text_682.
  ///
  /// In zh, this message translates to:
  /// **'回報BUG 和建議'**
  String get text_682;

  /// No description provided for @text_683.
  ///
  /// In zh, this message translates to:
  /// **'協助我們改進應用程式'**
  String get text_683;

  /// No description provided for @text_684.
  ///
  /// In zh, this message translates to:
  /// **'觸發通知'**
  String get text_684;

  /// No description provided for @text_685.
  ///
  /// In zh, this message translates to:
  /// **'測試推播通知功能'**
  String get text_685;

  /// No description provided for @text_686.
  ///
  /// In zh, this message translates to:
  /// **'桃園國際機場'**
  String get text_686;

  /// No description provided for @text_687.
  ///
  /// In zh, this message translates to:
  /// **'機場捷運'**
  String get text_687;

  /// No description provided for @text_688.
  ///
  /// In zh, this message translates to:
  /// **'直達台北車站，約35分鐘'**
  String get text_688;

  /// No description provided for @text_689.
  ///
  /// In zh, this message translates to:
  /// **'客運巴士'**
  String get text_689;

  /// No description provided for @text_690.
  ///
  /// In zh, this message translates to:
  /// **'多條路線通往全台各地'**
  String get text_690;

  /// No description provided for @text_691.
  ///
  /// In zh, this message translates to:
  /// **'計程車'**
  String get text_691;

  /// No description provided for @text_692.
  ///
  /// In zh, this message translates to:
  /// **'24小時排班服務'**
  String get text_692;

  /// No description provided for @text_693.
  ///
  /// In zh, this message translates to:
  /// **'租車服務'**
  String get text_693;

  /// No description provided for @text_694.
  ///
  /// In zh, this message translates to:
  /// **'各大租車公司進駐'**
  String get text_694;

  /// No description provided for @text_695.
  ///
  /// In zh, this message translates to:
  /// **'免稅商店'**
  String get text_695;

  /// No description provided for @text_696.
  ///
  /// In zh, this message translates to:
  /// **'貴賓室'**
  String get text_696;

  /// No description provided for @text_697.
  ///
  /// In zh, this message translates to:
  /// **'貨幣兌換'**
  String get text_697;

  /// No description provided for @text_698.
  ///
  /// In zh, this message translates to:
  /// **'行李寄存'**
  String get text_698;

  /// No description provided for @text_699.
  ///
  /// In zh, this message translates to:
  /// **'祈禱室'**
  String get text_699;

  /// No description provided for @text_700.
  ///
  /// In zh, this message translates to:
  /// **'育嬰室'**
  String get text_700;

  /// No description provided for @text_701.
  ///
  /// In zh, this message translates to:
  /// **'機場警察'**
  String get text_701;

  /// No description provided for @text_702.
  ///
  /// In zh, this message translates to:
  /// **'醫療中心'**
  String get text_702;

  /// No description provided for @text_703.
  ///
  /// In zh, this message translates to:
  /// **'遺失物協尋'**
  String get text_703;

  /// No description provided for @text_704.
  ///
  /// In zh, this message translates to:
  /// **'台北松山機場'**
  String get text_704;

  /// No description provided for @text_705.
  ///
  /// In zh, this message translates to:
  /// **'捷運文湖線'**
  String get text_705;

  /// No description provided for @text_706.
  ///
  /// In zh, this message translates to:
  /// **'松山機場站，直達市區'**
  String get text_706;

  /// No description provided for @text_707.
  ///
  /// In zh, this message translates to:
  /// **'多線公車可達'**
  String get text_707;

  /// No description provided for @text_708.
  ///
  /// In zh, this message translates to:
  /// **'排班服務'**
  String get text_708;

  /// No description provided for @text_709.
  ///
  /// In zh, this message translates to:
  /// **'機場外有站點'**
  String get text_709;

  /// No description provided for @text_710.
  ///
  /// In zh, this message translates to:
  /// **'便利商店'**
  String get text_710;

  /// No description provided for @text_711.
  ///
  /// In zh, this message translates to:
  /// **'觀景台'**
  String get text_711;

  /// No description provided for @text_712.
  ///
  /// In zh, this message translates to:
  /// **'機場服務台'**
  String get text_712;

  /// No description provided for @text_713.
  ///
  /// In zh, this message translates to:
  /// **'醫療協助'**
  String get text_713;

  /// No description provided for @text_714.
  ///
  /// In zh, this message translates to:
  /// **'警察局'**
  String get text_714;

  /// No description provided for @text_715.
  ///
  /// In zh, this message translates to:
  /// **'台中清泉崗機場'**
  String get text_715;

  /// No description provided for @text_716.
  ///
  /// In zh, this message translates to:
  /// **'多線公車可達市區'**
  String get text_716;

  /// No description provided for @text_717.
  ///
  /// In zh, this message translates to:
  /// **'機場內提供'**
  String get text_717;

  /// No description provided for @text_718.
  ///
  /// In zh, this message translates to:
  /// **'哺乳室'**
  String get text_718;

  /// No description provided for @text_719.
  ///
  /// In zh, this message translates to:
  /// **'服務中心'**
  String get text_719;

  /// No description provided for @text_720.
  ///
  /// In zh, this message translates to:
  /// **'醫療站'**
  String get text_720;

  /// No description provided for @text_721.
  ///
  /// In zh, this message translates to:
  /// **'警察隊'**
  String get text_721;

  /// No description provided for @text_722.
  ///
  /// In zh, this message translates to:
  /// **'高雄國際機場'**
  String get text_722;

  /// No description provided for @text_723.
  ///
  /// In zh, this message translates to:
  /// **'高雄捷運紅線'**
  String get text_723;

  /// No description provided for @text_724.
  ///
  /// In zh, this message translates to:
  /// **'直達機場站（R4）'**
  String get text_724;

  /// No description provided for @text_725.
  ///
  /// In zh, this message translates to:
  /// **'客運/計程車'**
  String get text_725;

  /// No description provided for @text_726.
  ///
  /// In zh, this message translates to:
  /// **'多線可達市區'**
  String get text_726;

  /// No description provided for @text_727.
  ///
  /// In zh, this message translates to:
  /// **'航站提供'**
  String get text_727;

  /// No description provided for @text_728.
  ///
  /// In zh, this message translates to:
  /// **'台南機場'**
  String get text_728;

  /// No description provided for @text_729.
  ///
  /// In zh, this message translates to:
  /// **'可達台南市區'**
  String get text_729;

  /// No description provided for @text_730.
  ///
  /// In zh, this message translates to:
  /// **'機場外可搭乘'**
  String get text_730;

  /// No description provided for @text_731.
  ///
  /// In zh, this message translates to:
  /// **'花蓮機場'**
  String get text_731;

  /// No description provided for @text_732.
  ///
  /// In zh, this message translates to:
  /// **'可達花蓮市'**
  String get text_732;

  /// No description provided for @text_733.
  ///
  /// In zh, this message translates to:
  /// **'台東機場'**
  String get text_733;

  /// No description provided for @text_734.
  ///
  /// In zh, this message translates to:
  /// **'可達台東市'**
  String get text_734;

  /// No description provided for @text_735.
  ///
  /// In zh, this message translates to:
  /// **'機場外服務'**
  String get text_735;

  /// No description provided for @text_736.
  ///
  /// In zh, this message translates to:
  /// **'嘉義機場'**
  String get text_736;

  /// No description provided for @text_737.
  ///
  /// In zh, this message translates to:
  /// **'可達嘉義市區 / 火車站'**
  String get text_737;

  /// No description provided for @text_738.
  ///
  /// In zh, this message translates to:
  /// **'金門機場'**
  String get text_738;

  /// No description provided for @text_739.
  ///
  /// In zh, this message translates to:
  /// **'鄉內路線可達'**
  String get text_739;

  /// No description provided for @text_740.
  ///
  /// In zh, this message translates to:
  /// **'澎湖馬公機場'**
  String get text_740;

  /// No description provided for @text_741.
  ///
  /// In zh, this message translates to:
  /// **'連接澎湖本島各地'**
  String get text_741;

  /// No description provided for @text_742.
  ///
  /// In zh, this message translates to:
  /// **'北竿機場'**
  String get text_742;

  /// No description provided for @text_743.
  ///
  /// In zh, this message translates to:
  /// **'機場外可搭'**
  String get text_743;

  /// No description provided for @text_744.
  ///
  /// In zh, this message translates to:
  /// **'南竿機場'**
  String get text_744;

  /// No description provided for @text_745.
  ///
  /// In zh, this message translates to:
  /// **'蘭嶼機場'**
  String get text_745;

  /// No description provided for @text_746.
  ///
  /// In zh, this message translates to:
  /// **'綠島機場'**
  String get text_746;

  /// No description provided for @text_747.
  ///
  /// In zh, this message translates to:
  /// **'機場資訊'**
  String get text_747;

  /// No description provided for @text_748.
  ///
  /// In zh, this message translates to:
  /// **'入境航班'**
  String get text_748;

  /// No description provided for @text_749.
  ///
  /// In zh, this message translates to:
  /// **'出境航班'**
  String get text_749;

  /// No description provided for @text_750.
  ///
  /// In zh, this message translates to:
  /// **'航班查詢'**
  String get text_750;

  /// No description provided for @text_751.
  ///
  /// In zh, this message translates to:
  /// **'機場交通'**
  String get text_751;

  /// No description provided for @text_752.
  ///
  /// In zh, this message translates to:
  /// **'特許商店'**
  String get text_752;

  /// No description provided for @text_753.
  ///
  /// In zh, this message translates to:
  /// **'餐飲美食'**
  String get text_753;

  /// No description provided for @text_754.
  ///
  /// In zh, this message translates to:
  /// **'電子登機牌'**
  String get text_754;

  /// No description provided for @text_755.
  ///
  /// In zh, this message translates to:
  /// **'安檢安保'**
  String get text_755;

  /// No description provided for @text_756.
  ///
  /// In zh, this message translates to:
  /// **'高雄機場'**
  String get text_756;

  /// No description provided for @text_757.
  ///
  /// In zh, this message translates to:
  /// **'桃園機場'**
  String get text_757;

  /// No description provided for @text_758.
  ///
  /// In zh, this message translates to:
  /// **'澎湖機場'**
  String get text_758;

  /// No description provided for @text_759.
  ///
  /// In zh, this message translates to:
  /// **'臺中機場'**
  String get text_759;

  /// No description provided for @text_760.
  ///
  /// In zh, this message translates to:
  /// **'臺南機場'**
  String get text_760;

  /// No description provided for @text_761.
  ///
  /// In zh, this message translates to:
  /// **'臺東機場'**
  String get text_761;

  /// No description provided for @text_762.
  ///
  /// In zh, this message translates to:
  /// **'航班資訊'**
  String get text_762;

  /// No description provided for @text_763.
  ///
  /// In zh, this message translates to:
  /// **'抵達航班'**
  String get text_763;

  /// No description provided for @text_764.
  ///
  /// In zh, this message translates to:
  /// **'出發航班'**
  String get text_764;

  /// No description provided for @text_765.
  ///
  /// In zh, this message translates to:
  /// **'搜尋航班'**
  String get text_765;

  /// No description provided for @text_766.
  ///
  /// In zh, this message translates to:
  /// **'航班狀態'**
  String get text_766;

  /// No description provided for @text_767.
  ///
  /// In zh, this message translates to:
  /// **'交通資訊'**
  String get text_767;

  /// No description provided for @text_768.
  ///
  /// In zh, this message translates to:
  /// **'購物餐飲'**
  String get text_768;

  /// No description provided for @text_769.
  ///
  /// In zh, this message translates to:
  /// **'服務設施'**
  String get text_769;

  /// No description provided for @text_770.
  ///
  /// In zh, this message translates to:
  /// **'緊急資訊'**
  String get text_770;

  /// No description provided for @text_771.
  ///
  /// In zh, this message translates to:
  /// **'航班搜尋'**
  String get text_771;

  /// No description provided for @text_772.
  ///
  /// In zh, this message translates to:
  /// **'輸入航班號碼，例如：CI123'**
  String get text_772;

  /// No description provided for @text_773.
  ///
  /// In zh, this message translates to:
  /// **'查詢'**
  String get text_773;

  /// No description provided for @text_774.
  ///
  /// In zh, this message translates to:
  /// **'搜尋航班資訊'**
  String get text_774;

  /// No description provided for @text_775.
  ///
  /// In zh, this message translates to:
  /// **'輸入航班號碼查詢即時航班狀態'**
  String get text_775;

  /// No description provided for @text_776.
  ///
  /// In zh, this message translates to:
  /// **'搜尋航班中...'**
  String get text_776;

  /// No description provided for @text_777.
  ///
  /// In zh, this message translates to:
  /// **'搜尋失敗'**
  String get text_777;

  /// No description provided for @text_778.
  ///
  /// In zh, this message translates to:
  /// **'未找到航班'**
  String get text_778;

  /// No description provided for @text_779.
  ///
  /// In zh, this message translates to:
  /// **'請檢查航班號碼是否正確'**
  String get text_779;

  /// No description provided for @text_780.
  ///
  /// In zh, this message translates to:
  /// **'暫無航班資訊'**
  String get text_780;

  /// No description provided for @text_781.
  ///
  /// In zh, this message translates to:
  /// **'貨機'**
  String get text_781;

  /// No description provided for @text_782.
  ///
  /// In zh, this message translates to:
  /// **'客機'**
  String get text_782;

  /// No description provided for @text_783.
  ///
  /// In zh, this message translates to:
  /// **'計劃'**
  String get text_783;

  /// No description provided for @text_784.
  ///
  /// In zh, this message translates to:
  /// **'實際'**
  String get text_784;

  /// No description provided for @text_785.
  ///
  /// In zh, this message translates to:
  /// **'航廈'**
  String get text_785;

  /// No description provided for @text_786.
  ///
  /// In zh, this message translates to:
  /// **'行李'**
  String get text_786;

  /// No description provided for @text_787.
  ///
  /// In zh, this message translates to:
  /// **'登機門'**
  String get text_787;

  /// No description provided for @text_788.
  ///
  /// In zh, this message translates to:
  /// **'延誤'**
  String get text_788;

  /// No description provided for @text_789.
  ///
  /// In zh, this message translates to:
  /// **'準時'**
  String get text_789;

  /// No description provided for @text_790.
  ///
  /// In zh, this message translates to:
  /// **'行李轉盤'**
  String get text_790;

  /// No description provided for @text_791.
  ///
  /// In zh, this message translates to:
  /// **'報到櫃台'**
  String get text_791;

  /// No description provided for @text_792.
  ///
  /// In zh, this message translates to:
  /// **'最後更新'**
  String get text_792;

  /// No description provided for @text_793.
  ///
  /// In zh, this message translates to:
  /// **'正在查询航班信息...'**
  String get text_793;

  /// No description provided for @text_794.
  ///
  /// In zh, this message translates to:
  /// **'未找到相关航班信息'**
  String get text_794;

  /// No description provided for @text_795.
  ///
  /// In zh, this message translates to:
  /// **'重試查詢'**
  String get text_795;

  /// No description provided for @text_796.
  ///
  /// In zh, this message translates to:
  /// **'到站提醒'**
  String get text_796;

  /// No description provided for @text_797.
  ///
  /// In zh, this message translates to:
  /// **'到站提醒通知'**
  String get text_797;

  /// No description provided for @text_798.
  ///
  /// In zh, this message translates to:
  /// **'已停止所有背景任務'**
  String get text_798;

  /// No description provided for @text_799.
  ///
  /// In zh, this message translates to:
  /// **'到站提醒測試'**
  String get text_799;

  /// No description provided for @text_800.
  ///
  /// In zh, this message translates to:
  /// **'【測試類型】測試路線 即將抵達 測試站牌！'**
  String get text_800;

  /// No description provided for @text_801.
  ///
  /// In zh, this message translates to:
  /// **'測試通知已觸發'**
  String get text_801;

  /// No description provided for @text_802.
  ///
  /// In zh, this message translates to:
  /// **'當前分鐘數為奇數，未觸發通知'**
  String get text_802;

  /// No description provided for @text_803.
  ///
  /// In zh, this message translates to:
  /// **'通知發送失敗: \$e'**
  String get text_803;

  /// No description provided for @text_804.
  ///
  /// In zh, this message translates to:
  /// **'舊社站'**
  String get text_804;

  /// No description provided for @text_805.
  ///
  /// In zh, this message translates to:
  /// **'松竹站'**
  String get text_805;

  /// No description provided for @text_806.
  ///
  /// In zh, this message translates to:
  /// **'四維國小站'**
  String get text_806;

  /// No description provided for @text_807.
  ///
  /// In zh, this message translates to:
  /// **'文心崇德站'**
  String get text_807;

  /// No description provided for @text_808.
  ///
  /// In zh, this message translates to:
  /// **'文心中清站'**
  String get text_808;

  /// No description provided for @text_809.
  ///
  /// In zh, this message translates to:
  /// **'文華高中站'**
  String get text_809;

  /// No description provided for @text_810.
  ///
  /// In zh, this message translates to:
  /// **'文心櫻花站'**
  String get text_810;

  /// No description provided for @text_811.
  ///
  /// In zh, this message translates to:
  /// **'水安宮站'**
  String get text_811;

  /// No description provided for @text_812.
  ///
  /// In zh, this message translates to:
  /// **'文心森林公園站'**
  String get text_812;

  /// No description provided for @text_813.
  ///
  /// In zh, this message translates to:
  /// **'南屯站'**
  String get text_813;

  /// No description provided for @text_814.
  ///
  /// In zh, this message translates to:
  /// **'豐樂公園站'**
  String get text_814;

  /// No description provided for @text_815.
  ///
  /// In zh, this message translates to:
  /// **'大慶站'**
  String get text_815;

  /// No description provided for @text_816.
  ///
  /// In zh, this message translates to:
  /// **'九張犁站'**
  String get text_816;

  /// No description provided for @text_817.
  ///
  /// In zh, this message translates to:
  /// **'九德站'**
  String get text_817;

  /// No description provided for @text_818.
  ///
  /// In zh, this message translates to:
  /// **'烏日站'**
  String get text_818;

  /// No description provided for @text_819.
  ///
  /// In zh, this message translates to:
  /// **'高鐵台中站'**
  String get text_819;

  /// No description provided for @text_820.
  ///
  /// In zh, this message translates to:
  /// **'靜宜大學站 (B6)'**
  String get text_820;

  /// No description provided for @text_821.
  ///
  /// In zh, this message translates to:
  /// **'弘光科大站 (B7)'**
  String get text_821;

  /// No description provided for @text_822.
  ///
  /// In zh, this message translates to:
  /// **'東海別墅站 (B9)'**
  String get text_822;

  /// No description provided for @text_823.
  ///
  /// In zh, this message translates to:
  /// **'帝國製糖廠站 (B20)'**
  String get text_823;

  /// No description provided for @text_824.
  ///
  /// In zh, this message translates to:
  /// **'動態捷運路線圖'**
  String get text_824;

  /// No description provided for @text_825.
  ///
  /// In zh, this message translates to:
  /// **'未找到任何車站資訊'**
  String get text_825;

  /// No description provided for @text_826.
  ///
  /// In zh, this message translates to:
  /// **'火車查詢系統'**
  String get text_826;

  /// No description provided for @text_827.
  ///
  /// In zh, this message translates to:
  /// **'線路資訊'**
  String get text_827;

  /// No description provided for @text_828.
  ///
  /// In zh, this message translates to:
  /// **'沒有數據'**
  String get text_828;

  /// No description provided for @text_829.
  ///
  /// In zh, this message translates to:
  /// **'未知區間'**
  String get text_829;

  /// No description provided for @text_830.
  ///
  /// In zh, this message translates to:
  /// **'車次查詢'**
  String get text_830;

  /// No description provided for @text_831.
  ///
  /// In zh, this message translates to:
  /// **'輸入車次號碼查詢時刻表'**
  String get text_831;

  /// No description provided for @text_832.
  ///
  /// In zh, this message translates to:
  /// **'輸入車次號碼，例如：101'**
  String get text_832;

  /// No description provided for @text_833.
  ///
  /// In zh, this message translates to:
  /// **'請輸入車次號碼'**
  String get text_833;

  /// No description provided for @text_834.
  ///
  /// In zh, this message translates to:
  /// **'查無此車次資訊'**
  String get text_834;

  /// No description provided for @text_835.
  ///
  /// In zh, this message translates to:
  /// **'使用提示'**
  String get text_835;

  /// No description provided for @text_836.
  ///
  /// In zh, this message translates to:
  /// **'請輸入完整的車次號碼進行查詢'**
  String get text_836;

  /// No description provided for @text_837.
  ///
  /// In zh, this message translates to:
  /// **'松山車站'**
  String get text_837;

  /// No description provided for @text_838.
  ///
  /// In zh, this message translates to:
  /// **'中和車站'**
  String get text_838;

  /// No description provided for @text_839.
  ///
  /// In zh, this message translates to:
  /// **'新莊車站'**
  String get text_839;

  /// No description provided for @text_840.
  ///
  /// In zh, this message translates to:
  /// **'蘆洲車站'**
  String get text_840;

  /// No description provided for @text_841.
  ///
  /// In zh, this message translates to:
  /// **'鳳山車站'**
  String get text_841;

  /// No description provided for @text_842.
  ///
  /// In zh, this message translates to:
  /// **'新左營車站'**
  String get text_842;

  /// No description provided for @text_843.
  ///
  /// In zh, this message translates to:
  /// **'站站查詢'**
  String get text_843;

  /// No description provided for @text_844.
  ///
  /// In zh, this message translates to:
  /// **'選擇出發地、目的地與時間'**
  String get text_844;

  /// No description provided for @text_845.
  ///
  /// In zh, this message translates to:
  /// **'出發地'**
  String get text_845;

  /// No description provided for @text_846.
  ///
  /// In zh, this message translates to:
  /// **'目的地'**
  String get text_846;

  /// No description provided for @text_847.
  ///
  /// In zh, this message translates to:
  /// **'請選擇目的站'**
  String get text_847;

  /// No description provided for @text_848.
  ///
  /// In zh, this message translates to:
  /// **'請選擇出發地'**
  String get text_848;

  /// No description provided for @text_849.
  ///
  /// In zh, this message translates to:
  /// **'請選擇目的地'**
  String get text_849;

  /// No description provided for @text_850.
  ///
  /// In zh, this message translates to:
  /// **'可選擇出發時間，預設為最近班次'**
  String get text_850;

  /// No description provided for @text_851.
  ///
  /// In zh, this message translates to:
  /// **'車站查詢'**
  String get text_851;

  /// No description provided for @text_852.
  ///
  /// In zh, this message translates to:
  /// **'輸入車站名稱查詢列車時刻'**
  String get text_852;

  /// No description provided for @text_853.
  ///
  /// In zh, this message translates to:
  /// **'車站名稱'**
  String get text_853;

  /// No description provided for @text_854.
  ///
  /// In zh, this message translates to:
  /// **'查詢列車'**
  String get text_854;

  /// No description provided for @text_855.
  ///
  /// In zh, this message translates to:
  /// **'選擇車站後可設定查詢時間，預設為最近班次'**
  String get text_855;

  /// No description provided for @text_856.
  ///
  /// In zh, this message translates to:
  /// **'主頁'**
  String get text_856;

  /// No description provided for @text_857.
  ///
  /// In zh, this message translates to:
  /// **'特等站'**
  String get text_857;

  /// No description provided for @text_858.
  ///
  /// In zh, this message translates to:
  /// **'一等站'**
  String get text_858;

  /// No description provided for @text_859.
  ///
  /// In zh, this message translates to:
  /// **'二等站'**
  String get text_859;

  /// No description provided for @text_860.
  ///
  /// In zh, this message translates to:
  /// **'三等站'**
  String get text_860;

  /// No description provided for @text_861.
  ///
  /// In zh, this message translates to:
  /// **'簡易站'**
  String get text_861;

  /// No description provided for @text_862.
  ///
  /// In zh, this message translates to:
  /// **'招呼站'**
  String get text_862;

  /// No description provided for @text_863.
  ///
  /// In zh, this message translates to:
  /// **'未知等級'**
  String get text_863;

  /// No description provided for @text_864.
  ///
  /// In zh, this message translates to:
  /// **'暫無車站資訊'**
  String get text_864;

  /// No description provided for @text_865.
  ///
  /// In zh, this message translates to:
  /// **'無法取得此車站的詳細資訊'**
  String get text_865;

  /// No description provided for @text_866.
  ///
  /// In zh, this message translates to:
  /// **'車站地址'**
  String get text_866;

  /// No description provided for @text_867.
  ///
  /// In zh, this message translates to:
  /// **'未知地址'**
  String get text_867;

  /// No description provided for @text_868.
  ///
  /// In zh, this message translates to:
  /// **'車站等級'**
  String get text_868;

  /// No description provided for @text_869.
  ///
  /// In zh, this message translates to:
  /// **'車站電話'**
  String get text_869;

  /// No description provided for @text_870.
  ///
  /// In zh, this message translates to:
  /// **'未知電話'**
  String get text_870;

  /// No description provided for @text_871.
  ///
  /// In zh, this message translates to:
  /// **'車站ID'**
  String get text_871;

  /// No description provided for @text_872.
  ///
  /// In zh, this message translates to:
  /// **'未知ID'**
  String get text_872;

  /// No description provided for @text_873.
  ///
  /// In zh, this message translates to:
  /// **'無法載入地圖'**
  String get text_873;

  /// No description provided for @text_874.
  ///
  /// In zh, this message translates to:
  /// **'載入列車資訊中...'**
  String get text_874;

  /// No description provided for @text_875.
  ///
  /// In zh, this message translates to:
  /// **'加載失敗'**
  String get text_875;

  /// No description provided for @text_876.
  ///
  /// In zh, this message translates to:
  /// **'暫無列車資訊'**
  String get text_876;

  /// No description provided for @text_877.
  ///
  /// In zh, this message translates to:
  /// **'自強'**
  String get text_877;

  /// No description provided for @text_878.
  ///
  /// In zh, this message translates to:
  /// **'普悠瑪'**
  String get text_878;

  /// No description provided for @text_879.
  ///
  /// In zh, this message translates to:
  /// **'太魯閣'**
  String get text_879;

  /// No description provided for @text_880.
  ///
  /// In zh, this message translates to:
  /// **'快速'**
  String get text_880;

  /// No description provided for @text_881.
  ///
  /// In zh, this message translates to:
  /// **'準點'**
  String get text_881;

  /// No description provided for @text_882.
  ///
  /// In zh, this message translates to:
  /// **'莒光'**
  String get text_882;

  /// No description provided for @text_883.
  ///
  /// In zh, this message translates to:
  /// **'區間'**
  String get text_883;

  /// No description provided for @text_884.
  ///
  /// In zh, this message translates to:
  /// **'復興'**
  String get text_884;

  /// No description provided for @text_885.
  ///
  /// In zh, this message translates to:
  /// **'特快車'**
  String get text_885;

  /// No description provided for @text_886.
  ///
  /// In zh, this message translates to:
  /// **'快車'**
  String get text_886;

  /// No description provided for @text_887.
  ///
  /// In zh, this message translates to:
  /// **'車次'**
  String get text_887;

  /// No description provided for @text_888.
  ///
  /// In zh, this message translates to:
  /// **'發車'**
  String get text_888;

  /// No description provided for @text_889.
  ///
  /// In zh, this message translates to:
  /// **'車種'**
  String get text_889;

  /// No description provided for @text_890.
  ///
  /// In zh, this message translates to:
  /// **'狀態'**
  String get text_890;

  /// No description provided for @text_891.
  ///
  /// In zh, this message translates to:
  /// **'查詢車次詳情失敗: \$e'**
  String get text_891;

  /// No description provided for @text_892.
  ///
  /// In zh, this message translates to:
  /// **'直達'**
  String get text_892;

  /// No description provided for @text_893.
  ///
  /// In zh, this message translates to:
  /// **'轉乘時間較短，請留意'**
  String get text_893;

  /// No description provided for @text_894.
  ///
  /// In zh, this message translates to:
  /// **'查詢列車資訊中...'**
  String get text_894;

  /// No description provided for @text_895.
  ///
  /// In zh, this message translates to:
  /// **'請調整篩選條件後重新查詢'**
  String get text_895;

  /// No description provided for @text_896.
  ///
  /// In zh, this message translates to:
  /// **'新自強'**
  String get text_896;

  /// No description provided for @text_897.
  ///
  /// In zh, this message translates to:
  /// **'莒光號'**
  String get text_897;

  /// No description provided for @text_898.
  ///
  /// In zh, this message translates to:
  /// **'普快'**
  String get text_898;

  /// No description provided for @text_899.
  ///
  /// In zh, this message translates to:
  /// **'柴聯'**
  String get text_899;

  /// No description provided for @text_900.
  ///
  /// In zh, this message translates to:
  /// **'柴聯自強'**
  String get text_900;

  /// No description provided for @text_901.
  ///
  /// In zh, this message translates to:
  /// **'自強號'**
  String get text_901;

  /// No description provided for @text_902.
  ///
  /// In zh, this message translates to:
  /// **'淡水信義線'**
  String get text_902;

  /// No description provided for @text_903.
  ///
  /// In zh, this message translates to:
  /// **'松山新店線'**
  String get text_903;

  /// No description provided for @text_904.
  ///
  /// In zh, this message translates to:
  /// **'板南線'**
  String get text_904;

  /// No description provided for @text_905.
  ///
  /// In zh, this message translates to:
  /// **'中和新蘆線'**
  String get text_905;

  /// No description provided for @text_906.
  ///
  /// In zh, this message translates to:
  /// **'文湖線'**
  String get text_906;

  /// No description provided for @text_907.
  ///
  /// In zh, this message translates to:
  /// **'環狀線'**
  String get text_907;

  /// No description provided for @text_908.
  ///
  /// In zh, this message translates to:
  /// **'橘線'**
  String get text_908;

  /// No description provided for @text_909.
  ///
  /// In zh, this message translates to:
  /// **'烏日文心北屯線'**
  String get text_909;

  /// No description provided for @text_910.
  ///
  /// In zh, this message translates to:
  /// **'桃園機場捷運'**
  String get text_910;

  /// No description provided for @text_911.
  ///
  /// In zh, this message translates to:
  /// **'三鶯線'**
  String get text_911;

  /// No description provided for @text_912.
  ///
  /// In zh, this message translates to:
  /// **'無法開啟地圖連結：\$url'**
  String get text_912;

  /// No description provided for @text_913.
  ///
  /// In zh, this message translates to:
  /// **'找不到此公車路線'**
  String get text_913;

  /// No description provided for @text_914.
  ///
  /// In zh, this message translates to:
  /// **'請嘗試其他搜尋關鍵字'**
  String get text_914;

  /// No description provided for @text_915.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get text_915;

  /// No description provided for @text_916.
  ///
  /// In zh, this message translates to:
  /// **'定位服務未啟用'**
  String get text_916;

  /// No description provided for @text_917.
  ///
  /// In zh, this message translates to:
  /// **'定位权限被拒绝'**
  String get text_917;

  /// No description provided for @text_918.
  ///
  /// In zh, this message translates to:
  /// **'定位权限被永久拒绝'**
  String get text_918;

  /// No description provided for @text_919.
  ///
  /// In zh, this message translates to:
  /// **'無法取得城市'**
  String get text_919;

  /// No description provided for @text_920.
  ///
  /// In zh, this message translates to:
  /// **'選擇高鐵車站'**
  String get text_920;

  /// No description provided for @text_921.
  ///
  /// In zh, this message translates to:
  /// **'請選擇您要查詢的高鐵車站'**
  String get text_921;

  /// No description provided for @text_922.
  ///
  /// In zh, this message translates to:
  /// **'高鐵車站列表'**
  String get text_922;

  /// No description provided for @text_923.
  ///
  /// In zh, this message translates to:
  /// **'無法獲取位置: \$e'**
  String get text_923;

  /// No description provided for @text_924.
  ///
  /// In zh, this message translates to:
  /// **'新竹'**
  String get text_924;

  /// No description provided for @text_925.
  ///
  /// In zh, this message translates to:
  /// **'選擇車站'**
  String get text_925;

  /// No description provided for @text_926.
  ///
  /// In zh, this message translates to:
  /// **'類型'**
  String get text_926;

  /// No description provided for @text_927.
  ///
  /// In zh, this message translates to:
  /// **'請選擇類型'**
  String get text_927;

  /// No description provided for @text_928.
  ///
  /// In zh, this message translates to:
  /// **'座位號碼'**
  String get text_928;

  /// No description provided for @text_929.
  ///
  /// In zh, this message translates to:
  /// **'座位號碼最多 10 個字'**
  String get text_929;

  /// No description provided for @text_930.
  ///
  /// In zh, this message translates to:
  /// **'請選擇縣市及車站'**
  String get text_930;

  /// No description provided for @text_931.
  ///
  /// In zh, this message translates to:
  /// **'縣市'**
  String get text_931;

  /// No description provided for @text_932.
  ///
  /// In zh, this message translates to:
  /// **'暫無車站資料'**
  String get text_932;

  /// No description provided for @text_933.
  ///
  /// In zh, this message translates to:
  /// **'路況'**
  String get text_933;

  /// No description provided for @text_934.
  ///
  /// In zh, this message translates to:
  /// **'租車'**
  String get text_934;

  /// No description provided for @text_935.
  ///
  /// In zh, this message translates to:
  /// **'時速表'**
  String get text_935;

  /// No description provided for @text_936.
  ///
  /// In zh, this message translates to:
  /// **'臺中'**
  String get text_936;

  /// No description provided for @text_937.
  ///
  /// In zh, this message translates to:
  /// **'臺北'**
  String get text_937;

  /// No description provided for @text_938.
  ///
  /// In zh, this message translates to:
  /// **'臺南'**
  String get text_938;

  /// No description provided for @text_939.
  ///
  /// In zh, this message translates to:
  /// **'臺東'**
  String get text_939;

  /// No description provided for @text_940.
  ///
  /// In zh, this message translates to:
  /// **'市'**
  String get text_940;

  /// No description provided for @text_941.
  ///
  /// In zh, this message translates to:
  /// **'縣'**
  String get text_941;

  /// No description provided for @text_942.
  ///
  /// In zh, this message translates to:
  /// **'陰'**
  String get text_942;

  /// No description provided for @text_943.
  ///
  /// In zh, this message translates to:
  /// **'地震'**
  String get text_943;

  /// No description provided for @text_944.
  ///
  /// In zh, this message translates to:
  /// **'海嘯'**
  String get text_944;

  /// No description provided for @text_945.
  ///
  /// In zh, this message translates to:
  /// **'豪雨'**
  String get text_945;

  /// No description provided for @text_946.
  ///
  /// In zh, this message translates to:
  /// **'大雨'**
  String get text_946;

  /// No description provided for @text_947.
  ///
  /// In zh, this message translates to:
  /// **'強風'**
  String get text_947;

  /// No description provided for @text_948.
  ///
  /// In zh, this message translates to:
  /// **'低溫'**
  String get text_948;

  /// No description provided for @text_949.
  ///
  /// In zh, this message translates to:
  /// **'海嘯警報'**
  String get text_949;

  /// No description provided for @text_950.
  ///
  /// In zh, this message translates to:
  /// **'天氣警報'**
  String get text_950;

  /// No description provided for @text_951.
  ///
  /// In zh, this message translates to:
  /// **'地震時間解析錯誤: \$e'**
  String get text_951;

  /// No description provided for @text_952.
  ///
  /// In zh, this message translates to:
  /// **'目前無詳細說明。'**
  String get text_952;

  /// No description provided for @text_953.
  ///
  /// In zh, this message translates to:
  /// **'點擊查看完整警報資訊'**
  String get text_953;

  /// No description provided for @text_954.
  ///
  /// In zh, this message translates to:
  /// **'最低溫'**
  String get text_954;

  /// No description provided for @text_955.
  ///
  /// In zh, this message translates to:
  /// **'最高溫'**
  String get text_955;

  /// No description provided for @text_956.
  ///
  /// In zh, this message translates to:
  /// **'舒適度'**
  String get text_956;

  /// No description provided for @text_957.
  ///
  /// In zh, this message translates to:
  /// **'收藏路線'**
  String get text_957;

  /// No description provided for @text_958.
  ///
  /// In zh, this message translates to:
  /// **'收藏站牌'**
  String get text_958;

  /// No description provided for @text_959.
  ///
  /// In zh, this message translates to:
  /// **'規劃'**
  String get text_959;

  /// No description provided for @text_960.
  ///
  /// In zh, this message translates to:
  /// **'接駁車'**
  String get text_960;

  /// No description provided for @text_961.
  ///
  /// In zh, this message translates to:
  /// **'設定儲存失敗，請稍後再試。'**
  String get text_961;

  /// No description provided for @text_962.
  ///
  /// In zh, this message translates to:
  /// **'重新載入'**
  String get text_962;

  /// No description provided for @text_963.
  ///
  /// In zh, this message translates to:
  /// **'聯絡'**
  String get text_963;

  /// No description provided for @text_964.
  ///
  /// In zh, this message translates to:
  /// **'導航'**
  String get text_964;

  /// No description provided for @text_965.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get text_965;

  /// No description provided for @text_966.
  ///
  /// In zh, this message translates to:
  /// **'無法載入停車資訊，請稍後再試。'**
  String get text_966;

  /// No description provided for @taxiPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'Uber 計程車'**
  String get taxiPageTitle;

  /// No description provided for @taxiEstimatePending.
  ///
  /// In zh, this message translates to:
  /// **'車資預估尚未開放；需先完成 Uber API 核准及安全的後端串接。你仍可前往 Uber App 填入行程。'**
  String get taxiEstimatePending;

  /// No description provided for @taxiUseCurrentLocation.
  ///
  /// In zh, this message translates to:
  /// **'使用目前位置作為上車地點'**
  String get taxiUseCurrentLocation;

  /// No description provided for @taxiPickupLocationReady.
  ///
  /// In zh, this message translates to:
  /// **'已取得目前位置'**
  String get taxiPickupLocationReady;

  /// No description provided for @taxiDestinationLabel.
  ///
  /// In zh, this message translates to:
  /// **'目的地'**
  String get taxiDestinationLabel;

  /// No description provided for @taxiDestinationHint.
  ///
  /// In zh, this message translates to:
  /// **'輸入地址或地標'**
  String get taxiDestinationHint;

  /// No description provided for @taxiOpenUber.
  ///
  /// In zh, this message translates to:
  /// **'在 Uber 中查看行程'**
  String get taxiOpenUber;

  /// No description provided for @taxiUberClientIdInfo.
  ///
  /// In zh, this message translates to:
  /// **'需在建置時設定 Uber Developer Client ID：--dart-define=UBER_CLIENT_ID=你的ClientID。Client ID 不是密鑰；請勿將 Access Token 或 Client Secret 放入 App。'**
  String get taxiUberClientIdInfo;

  /// No description provided for @taxiLocationServicesDisabled.
  ///
  /// In zh, this message translates to:
  /// **'請先開啟裝置定位服務。'**
  String get taxiLocationServicesDisabled;

  /// No description provided for @taxiLocationPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'需要定位權限才能設定上車地點。'**
  String get taxiLocationPermissionDenied;

  /// No description provided for @taxiLocationPermissionDeniedForever.
  ///
  /// In zh, this message translates to:
  /// **'定位權限已永久拒絕，請至系統設定開啟。'**
  String get taxiLocationPermissionDeniedForever;

  /// No description provided for @taxiLocationUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'無法取得目前位置，請確認定位服務與權限後重試。'**
  String get taxiLocationUnavailable;

  /// No description provided for @taxiDestinationRequired.
  ///
  /// In zh, this message translates to:
  /// **'請輸入目的地。'**
  String get taxiDestinationRequired;

  /// No description provided for @taxiDestinationNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到目的地，請確認地址或地標。'**
  String get taxiDestinationNotFound;

  /// No description provided for @taxiClientIdNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'尚未設定 Uber Developer Client ID，暫時無法開啟行程連結。'**
  String get taxiClientIdNotConfigured;

  /// No description provided for @taxiOpenUberFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法開啟 Uber 連結，請稍後再試。'**
  String get taxiOpenUberFailed;

  /// No description provided for @authLoginTitle.
  ///
  /// In zh, this message translates to:
  /// **'登入台灣通'**
  String get authLoginTitle;

  /// No description provided for @authLoginDescription.
  ///
  /// In zh, this message translates to:
  /// **'登入以同步你的帳戶資料；你也可以繼續以訪客身分使用 App。'**
  String get authLoginDescription;

  /// No description provided for @authRegisterTitle.
  ///
  /// In zh, this message translates to:
  /// **'建立帳戶'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterDescription.
  ///
  /// In zh, this message translates to:
  /// **'使用 Email 建立台灣通帳戶。'**
  String get authRegisterDescription;

  /// No description provided for @authForgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘記密碼？'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In zh, this message translates to:
  /// **'重設密碼'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordDescription.
  ///
  /// In zh, this message translates to:
  /// **'輸入帳戶 Email，我們會寄送重設密碼連結。'**
  String get authForgotPasswordDescription;

  /// No description provided for @authEmail.
  ///
  /// In zh, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In zh, this message translates to:
  /// **'密碼'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'確認密碼'**
  String get authConfirmPassword;

  /// No description provided for @authLogin.
  ///
  /// In zh, this message translates to:
  /// **'登入'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In zh, this message translates to:
  /// **'註冊'**
  String get authRegister;

  /// No description provided for @authShowPassword.
  ///
  /// In zh, this message translates to:
  /// **'顯示密碼'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In zh, this message translates to:
  /// **'隱藏密碼'**
  String get authHidePassword;

  /// No description provided for @authLoading.
  ///
  /// In zh, this message translates to:
  /// **'處理中…'**
  String get authLoading;

  /// No description provided for @authNoAccount.
  ///
  /// In zh, this message translates to:
  /// **'還沒有帳戶？'**
  String get authNoAccount;

  /// No description provided for @authGoToRegister.
  ///
  /// In zh, this message translates to:
  /// **'立即註冊'**
  String get authGoToRegister;

  /// No description provided for @authHaveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已經有帳戶？'**
  String get authHaveAccount;

  /// No description provided for @authBackToLogin.
  ///
  /// In zh, this message translates to:
  /// **'返回登入'**
  String get authBackToLogin;

  /// No description provided for @authValidationEmail.
  ///
  /// In zh, this message translates to:
  /// **'請輸入有效的 Email 地址。'**
  String get authValidationEmail;

  /// No description provided for @authValidationPasswordRequired.
  ///
  /// In zh, this message translates to:
  /// **'請輸入密碼。'**
  String get authValidationPasswordRequired;

  /// No description provided for @authValidationPasswordLength.
  ///
  /// In zh, this message translates to:
  /// **'密碼至少需要 6 個字元。'**
  String get authValidationPasswordLength;

  /// No description provided for @authValidationPasswordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'兩次輸入的密碼不一致。'**
  String get authValidationPasswordMismatch;

  /// No description provided for @authSendResetEmail.
  ///
  /// In zh, this message translates to:
  /// **'寄送重設連結'**
  String get authSendResetEmail;

  /// No description provided for @authResetEmailSent.
  ///
  /// In zh, this message translates to:
  /// **'如果此 Email 已註冊，重設密碼信件將會寄出。請檢查收件匣。'**
  String get authResetEmailSent;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In zh, this message translates to:
  /// **'Email 格式不正確。'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In zh, this message translates to:
  /// **'此帳戶已停用，請聯絡支援人員。'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In zh, this message translates to:
  /// **'Email 或密碼不正確。'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In zh, this message translates to:
  /// **'此 Email 已註冊，請改為登入。'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In zh, this message translates to:
  /// **'密碼強度不足，請使用至少 6 個字元。'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorNotEnabled.
  ///
  /// In zh, this message translates to:
  /// **'目前尚未啟用此登入方式，請稍後再試。'**
  String get authErrorNotEnabled;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In zh, this message translates to:
  /// **'嘗試次數過多，請稍後再試。'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'網路連線失敗，請檢查連線後重試。'**
  String get authErrorNetwork;

  /// No description provided for @authErrorUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'登入服務目前無法使用，請稍後再試。'**
  String get authErrorUnavailable;

  /// No description provided for @authErrorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'無法完成要求，請稍後再試。'**
  String get authErrorUnknown;

  /// No description provided for @authErrorSignOut.
  ///
  /// In zh, this message translates to:
  /// **'登出失敗，請稍後再試。'**
  String get authErrorSignOut;

  /// No description provided for @authAccountSection.
  ///
  /// In zh, this message translates to:
  /// **'帳戶'**
  String get authAccountSection;

  /// No description provided for @authGuestAccount.
  ///
  /// In zh, this message translates to:
  /// **'訪客模式'**
  String get authGuestAccount;

  /// No description provided for @authGuestDescription.
  ///
  /// In zh, this message translates to:
  /// **'目前未登入，仍可使用台灣通的交通功能。'**
  String get authGuestDescription;

  /// No description provided for @authLoginOrRegister.
  ///
  /// In zh, this message translates to:
  /// **'登入或建立帳戶'**
  String get authLoginOrRegister;

  /// No description provided for @authSignOut.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get authSignOut;

  /// No description provided for @authEmailVerified.
  ///
  /// In zh, this message translates to:
  /// **'Email 已驗證'**
  String get authEmailVerified;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In zh, this message translates to:
  /// **'Email 尚未驗證'**
  String get authEmailNotVerified;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
