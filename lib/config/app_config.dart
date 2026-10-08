class AppConfig {
  const AppConfig._();

  static const databaseHost = String.fromEnvironment('DATABASE_HOST');
  static const databaseUser = String.fromEnvironment('DATABASE_USER');
  static const databasePassword = String.fromEnvironment('DATABASE_PASSWORD');
  static const databaseName = String.fromEnvironment(
    'DATABASE_NAME',
    defaultValue: 'Bus',
  );
  static const tokenServiceUrl = String.fromEnvironment('TOKEN_SERVICE_URL');
  static const tokenServiceApiKey = String.fromEnvironment(
    'TOKEN_SERVICE_API_KEY',
  );
  static const weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
  static const placesApiKey = String.fromEnvironment('PLACES_API_KEY');

  static void requireDatabaseConfig() {
    _require('DATABASE_HOST', databaseHost);
    _require('DATABASE_USER', databaseUser);
    _require('DATABASE_PASSWORD', databasePassword);
  }

  static void requireTokenServiceConfig() {
    _require('TOKEN_SERVICE_URL', tokenServiceUrl);
    _require('TOKEN_SERVICE_API_KEY', tokenServiceApiKey);
  }

  static void _require(String name, String value) {
    if (value.isEmpty) {
      throw StateError(
        '$name is not configured. Pass it with --dart-define=$name=...',
      );
    }
  }
}
