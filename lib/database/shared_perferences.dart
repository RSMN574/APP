import 'package:shared_preferences/shared_preferences.dart';

// 儲存項目到列表
Future<String> saveList(String name, String favoriteItems) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 載入現有的列表
    List<String>? cache = await loadList(name);

    // 如果列表為空，初始化一個新的列表
    cache ??= [];

    // 檢查是否已存在相同的項目
    if (!cache.contains(favoriteItems)) {
      // 添加新的項目
      cache.add(favoriteItems);

      // 儲存更新後的列表
      await prefs.setStringList(name, cache);
      return ("已儲存項目: $favoriteItems");
    } else {
      return ("項目 '$favoriteItems' 已存在於列表中，不會重複添加。");

    }

  } catch (e) {
    return ("儲存項目時發生錯誤: $e");
  }
}

// 從 SharedPreferences 載入列表
Future<List<String>?> loadList(String name) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 獲取已儲存的列表
    List<String>? favoriteItems = prefs.getStringList(name);

    // 返回列表
    return favoriteItems;
  } catch (e) {
    print("載入項目時發生錯誤: $e");
    return null; // 返回空列表
  }
}

// 從 SharedPreferences 中移除列表
Future<void> removeList(String name) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 移除指定的項目
    await prefs.remove(name);
    print("已移除列表: $name");
  } catch (e) {
    print("移除項目時發生錯誤: $e");
  }
}
