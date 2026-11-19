// QA C7：捷運快取改用全專案共用的 ApiCache / CachedEntry，
// 不再維護一份同名但不同欄位的 CachedEntry 與獨立的檔案快取實作。
// 以 typedef 保留原名稱，讓 MetroDataRepository 與既有呼叫端不需修改。
import '../../../core/cache/api_cache.dart';

export '../../../core/cache/api_cache.dart'
    show ApiCache, FileApiCache, MemoryApiCache;
export '../../../core/cache/cached_entry.dart';

typedef MetroCache = ApiCache;
typedef FileMetroCache = FileApiCache;
typedef MemoryMetroCache = MemoryApiCache;
