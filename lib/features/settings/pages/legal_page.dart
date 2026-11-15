import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({
    super.key,
    required this.section,
  });

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = section == LegalSection.privacy;
    return Scaffold(
      appBar: AppBar(
        title: Text(isPrivacy ? '隱私權政策' : '服務條款'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            isPrivacy ? '台灣通隱私權政策' : '台灣通服務條款',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '最後更新：2026 年 11 月 10 日',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (isPrivacy) ..._privacySections else ..._termsSections,
        ],
      ),
    );
  }

  static const _privacySections = <Widget>[
    _LegalSection(
      title: '我們蒐集的資料',
      body:
          '台灣通可能處理帳號資訊、裝置與應用程式診斷資訊、定位資料、交通查詢與收藏內容。定位僅在提供附近站點、路線規劃或導航功能時使用；通知僅用於交通提醒與服務通知。',
    ),
    _LegalSection(
      title: '資料用途與第三方服務',
      body:
          '資料用於提供交通查詢、同步收藏、推播通知、錯誤診斷與改善服務。部分功能使用 Firebase、Google Maps、交通資料服務及天氣服務；各服務依其隱私政策處理資料。',
    ),
    _LegalSection(
      title: '保存與刪除',
      body:
          '本機偏好與快取保存在裝置上。登入者可在個人資料頁申請刪除帳號；刪除後，與帳號相關的資料將依服務保存政策處理。你也可以在系統設定中撤銷定位、相機與通知權限。',
    ),
    _LegalSection(
      title: '聯絡方式',
      body: '若對資料處理有疑問，請透過應用程式內的問題回報管道聯絡服務維護者。',
    ),
  ];

  static const _termsSections = <Widget>[
    _LegalSection(
      title: '服務內容',
      body:
          '台灣通提供公車、捷運、鐵路、航空、公共自行車與其他交通資訊查詢。資料來自第三方資料服務，可能因來源更新、網路或系統狀態而延遲或暫時無法使用。',
    ),
    _LegalSection(
      title: '安全與責任',
      body:
          '請在安全且合法的情況下使用本 App。即時資訊與路線建議僅供參考，實際行程請以現場標示、運輸業者公告與交通法規為準；駕駛中不得操作裝置。',
    ),
    _LegalSection(
      title: '帳號與內容',
      body: '你應妥善保管帳號資訊，不得以違法、干擾服務或侵害他人權益的方式使用本 App。服務可能因維護、法規或資料來源變更而調整。',
    ),
    _LegalSection(
      title: '條款變更',
      body: '服務條款更新時，將在 App 內提供最新版本。繼續使用服務即表示你已閱讀並同意更新後的條款。',
    ),
  ];
}

enum LegalSection { privacy, terms }

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
