import 'dart:convert';

/// Falha ao falar com o BFF.
///
/// Quando o BFF responde com erro, o corpo segue o contrato
/// `{ statusCode, error, message, correlationId }`.
class BffException implements Exception {
  const BffException({
    required this.message,
    this.statusCode,
    this.correlationId,
  });

  factory BffException.fromResponse(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded case {'message': final Object message}) {
        return BffException(
          statusCode: statusCode,
          message: switch (message) {
            final List<Object?> parts => parts.join(', '),
            _ => message.toString(),
          },
          correlationId: switch (decoded) {
            {'correlationId': final String id} => id,
            _ => null,
          },
        );
      }
    } on FormatException {
      // Corpo fora do contrato: cai na mensagem genérica abaixo.
    }
    return BffException(
      statusCode: statusCode,
      message: 'Erro inesperado do servidor.',
    );
  }

  final String message;
  final int? statusCode;
  final String? correlationId;

  @override
  String toString() =>
      'BffException($statusCode): $message'
      '${correlationId == null ? '' : ' [correlationId: $correlationId]'}';
}
