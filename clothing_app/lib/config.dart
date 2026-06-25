// `baseUrl` can be provided at build time with `--dart-define=BASE_URL=...`.
// Default is localhost (useful for Docker on the same host).
const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8000');

int? currentUserId;
String? currentUserName;
String? currentUserEmail;
String? currentUserRole;
