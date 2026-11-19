import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/core/city/taiwan_city.dart';
import 'package:com.rsmn574.app/core/utils/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TaiwanCity catalog', () {
    test('contains 22 unique cities', () {
      expect(TaiwanCity.all, hasLength(22));
      expect(TaiwanCity.all.map((c) => c.tdxCode).toSet(), hasLength(22));
      expect(TaiwanCity.all.map((c) => c.authorityCode).toSet(), hasLength(22));
    });

    test('every spelling round-trips to the same city', () {
      for (final city in TaiwanCity.all) {
        for (final spelling in [
          city.zhName,
          city.zhName.replaceAll('臺', '台'),
          city.tdxCode,
          city.authorityCode,
          city.enName,
          city.enName.toUpperCase(),
          ' ${city.tdxCode} ',
        ]) {
          expect(TaiwanCity.tryParse(spelling), same(city), reason: spelling);
        }
      }
    });

    test('real TDX GeoLocating values are recognised (QA B04)', () {
      expect(TaiwanCity.tryParse('HsinchuCounty')!.zhName, '新竹縣');
      expect(TaiwanCity.tryParse('NewTaipei')!.zhName, '新北市');
      expect(TaiwanCity.tryParse('ChiayiCounty')!.zhName, '嘉義縣');
      expect(TaiwanCity.tryParse('Chiayi')!.zhName, '嘉義市');
    });

    test('invalid values return null', () {
      for (final v in [null, '', '   ', 'Unknown city', 'Tokyo', '火星市']) {
        expect(TaiwanCity.tryParse(v), isNull, reason: '$v');
      }
    });
  });

  group('legacy converters', () {
    test('cityNameConverter converts both ways', () {
      expect(cityNameConverter('臺中市'), 'Taichung');
      expect(cityNameConverter('新竹縣'), 'HsinchuCounty');
      expect(cityNameConverter('HsinchuCounty'), '新竹縣');
      expect(cityNameConverter('Hsinchu County'), '新竹縣');
      expect(cityNameConverter('New Taipei'), '新北市');
      expect(cityNameConverter('nowhere'), 'Unknown city');
    });

    test('YouBike AuthorityID is correct for every city (QA B05)', () {
      expect(convertCityCode(cityNameConverter('新北市')), 'NWT');
      expect(convertCityCode(cityNameConverter('新竹市')), 'HSZ');
      expect(convertCityCode(cityNameConverter('新竹縣')), 'HSQ');
      expect(convertCityCode(cityNameConverter('嘉義市')), 'CYI');
      expect(convertCityCode(cityNameConverter('臺中市')), 'TXG');
      expect(convertCityCode('TXG'), 'TXG');
      for (final city in TaiwanCity.all) {
        expect(
            convertCityCode(cityNameConverter(city.zhName)), city.authorityCode,
            reason: city.zhName);
      }
    });
  });

  group('CityProvider persistence', () {
    test('first launch uses the default city', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await CityProvider.load();
      expect(p.city, TaiwanCity.defaultCity.zhName);
      expect(p.hasUserSelection, isFalse);
    });

    test('restart restores the last selected city', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await CityProvider.load();
      expect(await first.setCity('臺中市'), isTrue);

      final restarted = await CityProvider.load();
      expect(restarted.city, '臺中市');
      expect(restarted.tdxCode, 'Taichung');
      expect(restarted.hasUserSelection, isTrue);
    });

    test('accepts other spellings but stores the canonical name', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await CityProvider.load();
      await p.setCity('HsinchuCounty');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(CityProvider.prefsKey), '新竹縣');
    });

    test('corrupted or unknown stored values fall back safely', () async {
      for (final bad in <Object>['Unknown city', '', 42, true]) {
        SharedPreferences.setMockInitialValues({CityProvider.prefsKey: bad});
        final p = await CityProvider.load();
        expect(p.city, TaiwanCity.defaultCity.zhName, reason: '$bad');
        expect(p.hasUserSelection, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey(CityProvider.prefsKey), isFalse,
            reason: 'corrupted value is cleared');
      }
    });

    test('cleared app data behaves like a fresh install', () async {
      SharedPreferences.setMockInitialValues({CityProvider.prefsKey: '高雄市'});
      expect((await CityProvider.load()).city, '高雄市');
      SharedPreferences.setMockInitialValues({});
      expect((await CityProvider.load()).city, TaiwanCity.defaultCity.zhName);
    });

    test('invalid selections are ignored and not persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await CityProvider.load();
      var notified = 0;
      p.addListener(() => notified++);
      expect(await p.setCity('Unknown city'), isFalse);
      expect(p.city, TaiwanCity.defaultCity.zhName);
      expect(notified, 0);
    });

    test('GPS never overrides a user choice (QA B06)', () async {
      SharedPreferences.setMockInitialValues({CityProvider.prefsKey: '臺南市'});
      final p = await CityProvider.load();
      expect(p.applyDetectedCity('Taichung'), isFalse);
      expect(p.city, '臺南市');
    });

    test('GPS applies on first use without persisting', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await CityProvider.load();
      expect(p.applyDetectedCity('HsinchuCounty'), isTrue);
      expect(p.city, '新竹縣');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(CityProvider.prefsKey), isNull);
      expect(p.applyDetectedCity('Unknown city'), isFalse);
    });
  });
}
