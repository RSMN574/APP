import 'dart:async';

import 'package:flutter/material.dart';
import '../firebase/place_api.dart';
import '../l10n/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _routeController = TextEditingController();
  List<dynamic> _placePredictions = [];
  Completer<void>? _searchAbort;
  Object? _searchError;
  int _searchRequestId = 0;
  bool _isSearching = false;

  @override
  void dispose() {
    _cancelSearch();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0, // 去掉 AppBar 的阴影
        backgroundColor: colorScheme.surface,
        title: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 10) {
              // 向下拖动时关闭页面
              Navigator.of(context).pop();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 5.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _routeController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.text_620,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 20.0),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: colorScheme.primary),
                  onPressed: _loadPredictions, // 按钮点击事件
                ),
              ),
              onChanged: (value) {
                // 在输入内容时清空建议列表
                _cancelSearch();
                setState(() {
                  _placePredictions.clear();
                  _searchError = null;
                  _isSearching = false;
                });
              },
              onSubmitted: (value) {
                _loadPredictions(); // 按下回车键时加载建议
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 增加外边距
        child: Column(
          children: [
            const SizedBox(height: 16.0), // 搜索框和建议列表之间的间距
            if (_isSearching) const LinearProgressIndicator(),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '搜尋地點失敗：$_searchError',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            // 显示建议列表
            if (_placePredictions.isNotEmpty)
              Expanded(
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _placePredictions[index];
                        final formatting = prediction is Map
                            ? prediction['structured_formatting']
                            : null;
                        final mainText = formatting is Map
                            ? formatting['main_text']?.toString() ?? ''
                            : '';
                        final secondaryText = formatting is Map
                            ? formatting['secondary_text']?.toString() ?? ''
                            : '';

                        return ListTile(
                          leading: Icon(Icons.location_on,
                              color: colorScheme.primary),
                          title: Text(mainText,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            secondaryText,
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          onTap: () async {
                            Navigator.pushNamed(
                              context,
                              'home',
                              arguments: prediction,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPredictions() async {
    _cancelSearch();
    final requestId = ++_searchRequestId;
    final abort = Completer<void>();
    _searchAbort = abort;
    setState(() {
      _searchError = null;
      _isSearching = true;
      _placePredictions = [];
    });

    try {
      final predictions = await PlacesService().getPlaceAutocomplete(
        _routeController.text,
        context,
        abortTrigger: abort.future,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _placePredictions = predictions;
      });
    } on PlaceRequestCancelledException {
      // A newer query or page disposal superseded this request.
    } catch (error) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchError = error;
      });
    } finally {
      if (mounted && requestId == _searchRequestId) {
        _searchAbort = null;
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _cancelSearch() {
    final activeRequest = _searchAbort;
    if (activeRequest != null && !activeRequest.isCompleted) {
      activeRequest.complete();
    }
    _searchAbort = null;
    _searchRequestId++;
  }
}
