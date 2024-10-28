import 'package:fpdart/fpdart.dart';


/// future of either failure (F) and success (S)
typedef ResultFuture<F, S> = Future<Either<F, S>>;

/// map of string and dynamic
typedef DataMap = Map<String, dynamic>;