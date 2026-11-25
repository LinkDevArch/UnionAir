import '../domain/travel.dart';

class SessionService {
  final List<({String email, String password})> _accounts = [
    (email: 'demo@unionair.com', password: 'UnionAir2026'),
  ];

  String? email;

  bool signIn(String address, String password) {
    final normalized = address.trim().toLowerCase();
    final valid = _accounts.any(
      (account) => account.email == normalized && account.password == password,
    );
    if (valid) email = normalized;
    return valid;
  }

  bool register(String address, String password) {
    final normalized = address.trim().toLowerCase();
    if (!Passenger.validEmail(normalized) ||
        password.length < 8 ||
        _accounts.any((account) => account.email == normalized)) {
      return false;
    }
    _accounts.add((email: normalized, password: password));
    return true;
  }

  bool hasAccount(String address) =>
      _accounts.any((account) => account.email == address.trim().toLowerCase());

  void signOut() => email = null;
}
