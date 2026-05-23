abstract class CoreFailure {
  final String message;
  const CoreFailure(this.message);
}

class ServerFailure extends CoreFailure {
  const ServerFailure([super.message = 'Server Error']);
}

class CacheFailure extends CoreFailure {
  const CacheFailure([super.message = 'Cache Error']);
}

class AuthFailure extends CoreFailure {
  const AuthFailure([super.message = 'Authentication Error']);
}
