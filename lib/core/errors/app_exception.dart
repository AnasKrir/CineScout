import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException($statusCode): $message';
}

class NetworkException extends AppException {
  const NetworkException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

class ServerException extends AppException {
  const ServerException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

class UnexpectedException extends AppException {
  const UnexpectedException(String message) : super(message);
}

AppException mapDioException(DioException error) {
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const NetworkException('Délai de connexion dépassé.');
  }

  if (error.type == DioExceptionType.connectionError) {
    return const NetworkException(
      'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
    );
  }

  if (error.type == DioExceptionType.badResponse) {
    final status = error.response?.statusCode;
    if (status != null && status >= 500) {
      return ServerException('Erreur serveur (code $status).',
          statusCode: status);
    }
    if (status == 401 || status == 403) {
      return NetworkException('Accès non autorisé (code $status).',
          statusCode: status);
    }
    return NetworkException('Erreur réseau (code $status).',
        statusCode: status);
  }

  return const UnexpectedException(
      'Erreur inconnue lors de l’appel au service TMDB.');
}