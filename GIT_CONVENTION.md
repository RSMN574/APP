# 台灣通 Git 開發與分支規範

> TaiwanPass / 台灣通\
> Flutter・Dart・TDX API・Firebase・Node.js・MySQL

本文件定義「台灣通」專案的 Git、Branch、Commit、Tag、Release、Worktree 與 AI 開發規範。

目標：

- 保護 `master`
- 保持 Git 歷史清楚
- 減少不必要的 Branch
- 功能開發彼此隔離
- 避免未提交程式碼遺失
- 避免 Worktree 衝突
- 讓 Commit 可以清楚追蹤
- 方便未來開源與團隊協作

---

# 1. Branch 架構

台灣通只使用以下 Branch 類型：

```text
master
develop
feature/*
fix/*
refactor/*
```

不建立過多用途的 Branch。

例如 Firebase、UI、API、Android、l10n、效能等修改，都依照「這次修改的主要目的」歸入：

```text
feature/*
fix/*
refactor/*
```

---

# 2. `master`

`master` 是正式穩定版本。

用途：

- 正式版本
- Release
- GitHub 公開版本
- 穩定版本保存

一般開發**禁止直接修改 `master`**。

正常情況：

```text
feature/*
    ↓
develop
    ↓
master
```

除非是正式 Release 或緊急 Hotfix，不應直接對 `master` Commit。

---

# 3. `develop`

`develop` 是主要開發整合分支。

用途：

- 整合完成的功能
- 測試新功能
- Release 前整合

正常流程：

```text
feature/*
    ↓
develop
    ↓
測試
    ↓
master
```

---

# 4. `feature/*`

所有「新增功能」使用：

```text
feature/<功能名稱>
```

例如：

```text
feature/metro-map
feature/firebase-auth
feature/rail-qr
feature/youbike
feature/airport
feature/notification-center
```

即使是 Firebase、UI、API 等新功能，只要主要目的是「新增功能」，就使用 `feature/*`。

例如：

```text
feature/firebase-auth
feature/tdx-route-api
feature/dark-mode
```

不需要建立：

```text
firebase/*
api/*
ui/*
```

---

# 5. `fix/*`

所有 Bug 修正使用：

```text
fix/<問題>
```

例如：

```text
fix/bus-shape
fix/android-16-network
fix/app-localizations
fix/firebase-login
fix/metro-overflow
```

如果是修正 Android、Firebase、API、UI 等問題，也統一使用 `fix/*`。

---

# 6. `refactor/*`

架構重構、程式整理、結構改善使用：

```text
refactor/<內容>
```

例如：

```text
refactor/lib-architecture
refactor/state-management
refactor/bus-repository
refactor/theme
```

如果主要目的不是新增功能，也不是修 Bug，而是改善既有架構，就使用 `refactor/*`。

---

# 7. Branch 命名規則

Branch 必須：

- 使用英文
- 使用小寫
- 使用 `-` 分隔單字
- 不使用空格
- 不使用中文
- 不使用底線
- 不使用不必要的特殊符號

推薦：

```text
feature/metro-map
feature/firebase-auth
fix/bus-shape
refactor/lib-architecture
```

不推薦：

```text
Feature/NewMetro
修正公車問題
new branch
test_branch
feature/New_Metro
```

---

# 8. 如何選擇 Branch

按照修改目的判斷：

### 新增功能

```text
feature/*
```

例如：

```text
feature/metro-map
```

### 修 Bug

```text
fix/*
```

例如：

```text
fix/bus-shape
```

### 架構重構

```text
refactor/*
```

例如：

```text
refactor/lib-architecture
```

---

# 9. Branch 建立

先確認目前狀態：

```bash
git status
git branch --show-current
git worktree list
```

切換到 `develop`：

```bash
git switch develop
git pull
```

建立新的 Feature：

```bash
git switch -c feature/metro-map
```

確認：

```bash
git branch --show-current
```

---

# 10. Commit 規範

使用 Conventional Commits。

格式：

```text
<type>: <description>
```

例如：

```text
feat: add interactive metro map
```

Commit 必須簡短、清楚描述修改內容。

---

# 11. Commit Type

## `feat`

新增功能：

```text
feat: add interactive metro map
feat: add Firebase authentication
feat: add railway QR scanner
```

## `fix`

修正 Bug：

```text
fix: resolve bus shape loading
fix: resolve Android 16 network issue
fix: resolve AppLocalizations import
```

## `refactor`

程式重構：

```text
refactor: reorganize lib architecture
refactor: simplify bus repository
refactor: improve state management
```

## `ui`

UI 修改：

```text
ui: improve notification center
ui: improve dark mode
ui: redesign bus route page
```

`ui` 是 **Commit Type，不是 Branch Type**。

---

## `perf`

效能最佳化：

```text
perf: optimize bus stop list
perf: improve map rendering
```

## `docs`

文件：

```text
docs: add Git development guide
docs: update architecture documentation
```

## `test`

測試：

```text
test: add bus repository tests
```

## `build`

建置系統：

```text
build: upgrade Android Gradle Plugin
```

## `chore`

一般維護：

```text
chore: update Flutter dependencies
```

---

# 12. Commit 原則

一個 Commit 應該代表一個明確的修改。

推薦：

```text
feat: add metro map
fix: resolve metro overflow
ui: improve metro station card
```

不推薦：

```text
update
fix
test
change something
final
final2
final-final
```

不要使用沒有意義的 Commit 名稱。

---

# 13. Commit 前檢查

執行：

```bash
git status
```

查看詳細修改：

```bash
git diff
```

確認：

- 沒有不相關修改
- 沒有敏感資料
- 沒有 API Secret
- 沒有 Password
- 沒有 Token
- 沒有 Private Key
- 沒有 Debug 暫存檔
- 沒有意外加入其他功能的檔案

---

# 14. Flutter Commit 前檢查

一般修改至少執行：

```bash
flutter analyze
```

需要測試時：

```bash
flutter test
```

Debug Build：

```bash
flutter build apk --debug
```

正式 Release：

```bash
flutter build apk --release
```

如果測試因環境因素無法執行，Commit 前應記錄原因。

---

# 15. Commit

確認檔案：

```bash
git status
```

加入指定檔案：

```bash
git add lib
```

或加入指定檔案：

```bash
git add lib/pages/example.dart
```

再 Commit：

```bash
git commit -m "refactor: reorganize lib architecture"
```

如果要使用：

```bash
git add .
```

必須先確認：

```bash
git status
```

避免把不相關檔案加入 Commit。

---

# 16. Push

第一次 Push：

```bash
git push -u origin feature/metro-map
```

之後：

```bash
git push
```

禁止未確認直接使用：

```bash
git push --force
```

---

# 17. Pull Request

功能完成後：

```text
feature/*
    ↓
develop
```

Pull Request 應包含：

- 修改原因
- 修改內容
- 測試方式
- 是否有 Breaking Change
- 是否需要額外設定

例如：

```text
Title:
feat: add interactive metro map
```

---

# 18. Merge 流程

正常流程：

```text
feature/*
     ↓
develop
     ↓
測試
     ↓
master
     ↓
Release
```

一般不要：

```text
feature/*
     ↓
master
```

---

# 19. Hotfix

正式版本發生重大問題時，可以建立：

```text
fix/<問題>
```

例如：

```text
fix/app-startup
fix/firebase-crash
```

不另外建立 `hotfix/*` Branch 類型，以保持 Branch 規則簡單。

必要時：

```text
master
   ↓
fix/*
   ↓
master
   ↓
develop
```

修正完成後必須同步回 `develop`，避免之後再次發生相同問題。

---

# 20. Worktree

查看所有 Worktree：

```bash
git worktree list
```

例如：

```text
C:/untitled
    master

C:/Users/.../copilot-worktrees/untitled/metro
    feature/metro-map
```

Git Worktree 可以讓不同 Branch 同時存在不同資料夾。

---

# 21. Worktree 重要規則

同一個 Branch **不能同時被兩個 Worktree checkout**。

例如：

```text
C:/untitled
    master

C:/worktree/metro
    feature/metro-map
```

此時不能再於另一個 Worktree：

```bash
git switch feature/metro-map
```

如果遇到：

```text
fatal: 'xxx' is already used by worktree
```

不要刪除 Worktree。

先：

```bash
git worktree list
```

確認該 Branch 目前在哪個 Worktree。

---

# 22. 禁止隨意刪除 Worktree

沒有明確確認時禁止：

```bash
git worktree remove
```

特別是 Worktree 可能存在未提交修改時。

先：

```bash
git worktree list
```

再進入對應資料夾：

```bash
git status
```

確認內容後才能處理。

---

# 23. 禁止危險 Git 操作

沒有明確確認時禁止：

```bash
git reset --hard
git clean -fd
git push --force
git branch -D
git worktree remove
```

這些操作可能造成：

- 未提交程式碼遺失
- Branch 遺失
- Worktree 遺失
- Git 歷史被覆蓋

---

# 24. Untracked Files

看到：

```text
Untracked files:
```

不要直接刪除。

先：

```bash
git status
```

確認檔案用途。

例如：

```text
android/app/google-services.json
```

可能是 Firebase 本機設定。

不要未確認就執行：

```bash
git clean -fd
```

---

# 25. `.gitignore`

通常不應提交：

```text
.dart_tool/
build/
.gradle/
.idea/
*.iml
android/.cxx/
```

Firebase 設定檔依專案安全策略決定。

任何包含：

```text
API Key
Token
Password
Secret
Private Key
```

的檔案，都必須先確認是否可以提交。

---

# 26. Firebase 規則

Firebase 修改不需要建立 `firebase/*` Branch。

例如新增 Firebase 登入：

```text
feature/firebase-auth
```

修正 Firebase Crash：

```text
fix/firebase-crash
```

Firebase App Check：

```text
feature/firebase-app-check
```

---

# 27. API / TDX 規則

API 修改不需要建立 `api/*` Branch。

新增 TDX 功能：

```text
feature/tdx-route
```

修正 TDX：

```text
fix/tdx-route
```

重構 Repository：

```text
refactor/bus-repository
```

---

# 28. Android 規則

Android 修改不需要建立 `android/*` Branch。

新增 Android 功能：

```text
feature/android-notification
```

修正 Android：

```text
fix/android-16-network
```

Android Gradle 更新：

```text
chore/android-gradle
```

---

# 29. Localization 規則

多語系修改不需要建立 `l10n/*` Branch。

新增語言：

```text
feature/localization
```

修正語系：

```text
fix/app-localizations
```

---

# 30. AI 開發規則

AI 修改程式碼前必須：

```bash
git status
git branch --show-current
git worktree list
```

AI 必須先了解目前 Git 狀態。

不得：

- 覆蓋使用者未提交的修改
- 自行刪除檔案
- 自行刪除 Worktree
- 自行執行 `reset --hard`
- 自行執行 `clean -fd`
- 自行 Force Push
- 任意修改與任務無關的程式碼

---

# 31. AI 建立新 Branch

如果使用者要求：

> 修改後提交到新 Branch

AI 應：

```bash
git status
git branch --show-current
git worktree list
```

確認沒有 Branch / Worktree 衝突後：

```bash
git switch -c feature/<name>
```

如果是 Bug：

```bash
git switch -c fix/<name>
```

如果是架構重構：

```bash
git switch -c refactor/<name>
```

---

# 32. AI 修改流程

標準流程：

```text
確認 Git 狀態
      ↓
確認 Branch
      ↓
建立新 Branch
      ↓
分析程式碼
      ↓
修改
      ↓
flutter analyze
      ↓
flutter test
      ↓
flutter build apk --debug
      ↓
git status
      ↓
git diff
      ↓
git add
      ↓
git commit
      ↓
git push
```

---

# 33. AI 修改 `lib/` 規則

如果 AI 被要求直接修改：

```text
lib/
```

必須先了解目前架構。

例如：

```text
lib/
├── pages/
├── widgets/
├── models/
├── repositories/
├── services/
├── state/
├── theme/
├── utils/
├── database/
└── l10n/
```

實際目錄以專案目前結構為準。

AI 不應因為單一問題就重新建立整套架構。

---

# 34. Android 原生保護

如果任務只是修改 Flutter `lib/`：

除非必要，不修改：

```text
android/
ios/
windows/
macos/
linux/
web/
```

特別注意：

```text
android/app/src/main/kotlin/
android/app/src/main/AndroidManifest.xml
android/app/build.gradle
```

不要任意修改：

```text
MainActivity
package
namespace
applicationId
```

如果確實需要修改，必須先確認原因並檢查：

```text
package
namespace
applicationId
AndroidManifest.xml
MainActivity
```

是否一致。

---

# 35. API 保護

修改 UI 時，不應任意修改：

```text
TDX API
Firebase
MySQL
Node.js Server
Token
Repository
```

如果需要修改 API 或資料層，必須確認這是任務必要的一部分。

---

# 36. Tag 規則

正式版本使用 Semantic Versioning：

```text
vMAJOR.MINOR.PATCH
```

例如：

```text
v1.0.0
v1.1.0
v1.1.1
v2.0.0
```

---

# 37. Version 定義

### MAJOR

重大 Breaking Change：

```text
v2.0.0
```

### MINOR

新增向後相容功能：

```text
v1.2.0
```

### PATCH

Bug 修正：

```text
v1.2.1
```

---

# 38. Release

Release 前確認：

```bash
flutter analyze
flutter test
flutter build apk --release
```

並確認：

- App 可以正常啟動
- Firebase 正常
- TDX 正常
- 地圖正常
- 公車正常
- 捷運正常
- YouBike 正常
- 台鐵正常
- QR Code 正常
- Dark Mode 正常
- Localization 正常

---

# 39. Release Tag

建立 Tag：

```bash
git tag -a v1.0.0 -m "TaiwanPass v1.0.0"
```

Push：

```bash
git push origin v1.0.0
```

---

# 40. Git 歷史查看

最近 Commit：

```bash
git log --oneline --decorate -10
```

完整歷史：

```bash
git log --oneline --decorate --all --graph
```

查看 Commit：

```bash
git show <commit>
```

查看 Commit 修改檔案：

```bash
git show --stat <commit>
```

---

# 41. Git 狀態查看

目前 Branch：

```bash
git branch --show-current
```

所有 Branch：

```bash
git branch -a
```

Worktree：

```bash
git worktree list
```

遠端：

```bash
git remote -v
```

目前修改：

```bash
git status
```

詳細差異：

```bash
git diff
```

---

# 42. 標準開發流程

台灣通一般功能：

```text
1. git status
       ↓
2. git worktree list
       ↓
3. git switch develop
       ↓
4. git pull
       ↓
5. git switch -c feature/xxx
       ↓
6. 開發
       ↓
7. flutter analyze
       ↓
8. flutter test
       ↓
9. flutter build apk --debug
       ↓
10. git status
       ↓
11. git diff
       ↓
12. git add
       ↓
13. git commit
       ↓
14. git push
       ↓
15. Pull Request
       ↓
16. develop
       ↓
17. 測試
       ↓
18. master
       ↓
19. Tag
       ↓
20. Release
```

---

# 43. 台灣通推薦 Branch

最常使用：

```text
master
develop
```

功能：

```text
feature/metro-map
feature/firebase-auth
feature/rail-qr
feature/youbike
feature/airport
feature/notification-center
```

Bug：

```text
fix/bus-shape
fix/android-16-network
fix/app-localizations
fix/firebase-crash
fix/metro-overflow
```

重構：

```text
refactor/lib-architecture
refactor/state-management
refactor/theme
refactor/bus-repository
```

不再建立：

```text
ui/*
firebase/*
api/*
android/*
l10n/*
perf/*
docs/*
chore/*
```

這些用途改由 Commit Type 表達。

---

# 44. Commit 範例

```text
feat: add interactive metro map
feat: add Firebase authentication
feat: add railway QR scanner

fix: resolve bus route shape loading
fix: resolve AppLocalizations import
fix: resolve Android 16 network issue

refactor: reorganize lib architecture
refactor: simplify bus repository
refactor: improve state management

ui: update notification center
ui: improve dark mode
ui: redesign bus route page

perf: optimize bus stop list

docs: add Git development guide

test: add bus repository tests

build: upgrade Android Gradle Plugin

chore: update Flutter dependencies
```

---

# 45. 最重要規則

任何修改之前：

```bash
git status
git branch --show-current
git worktree list
```

任何危險操作之前：

**先確認，再執行。**

任何新功能：

```text
feature/*
    ↓
Commit
    ↓
Push
    ↓
Pull Request
    ↓
develop
    ↓
Test
    ↓
master
    ↓
Tag
    ↓
Release
```

任何 Bug：

```text
fix/*
    ↓
Commit
    ↓
Push
    ↓
Pull Request
    ↓
develop
```

任何架構重構：

```text
refactor/*
    ↓
Commit
    ↓
Push
    ↓
Pull Request
    ↓
develop
```

---

# 46. 專案核心原則

「台灣通」是一個長期開發的 Flutter 專案。

Git 管理應該：

- 簡單
- 清楚
- 可追蹤
- 不過度拆分
- 不破壞既有程式碼
- 不遺失使用者修改
- 不任意刪除 Worktree
- 不任意覆蓋 Git 歷史

Branch 負責：

> **區分工作。**

Commit 負責：

> **描述修改。**

Tag 負責：

> **標記版本。**

因此台灣通只需要：

```text
master
develop
feature/*
fix/*
refactor/*
```

其餘分類交由 Commit Type 處理。

這套規則以「少 Branch、清楚 Commit、安全開發」為核心。
