import '../core/result.dart';
import '../core/failures.dart';
import 'user.dart';

abstract class AuthFacade {
  Future<Result<User?, AuthFailure>> getSignedInUser();
  Future<Result<User, AuthFailure>> register({
    required String name,
    required String email,
    required String password,
  });
  Future<Result<User, AuthFailure>> login({
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<Result<void, AuthFailure>> deleteAccount();
}
