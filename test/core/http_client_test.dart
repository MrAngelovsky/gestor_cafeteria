import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Parte 1: Pruebas del cliente', () {
    test('1. Éxito: responde 200 con JSON válido y devuelve el JSON decodificado', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'customer': 'Ana', 'drink': 'latte', 'size': 'M'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'https://api.cafeteria.com');

      final resultado = await api.get('/orders');

      expect(resultado, isA<List>());
      expect(
        resultado,
        equals([
          {'id': 1, 'customer': 'Ana', 'drink': 'latte', 'size': 'M'},
        ]),
      );
    });

    test('2. No encontrado: responde 404 con detail y lanza NotFoundFailure', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Order 9 not found'}),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'https://api.cafeteria.com');

      expect(
        api.get('/orders/9'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Order 9 not found',
          ),
        ),
      );
    });

    test('3. Conflicto: responde 409 con detail de texto y lanza ConflictFailure', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Cannot change status from pending to delivered'}),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'https://api.cafeteria.com');

      expect(
        api.patch('/orders/1', {'status': 'delivered'}),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Cannot change status from pending to delivered',
          ),
        ),
      );
    });

    test('4. Validación: responde 422 con lista en detail y lanza ValidationFailure con fields', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'customer'],
                'msg': 'Must be 1-50 characters',
              },
            ],
          }),
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'https://api.cafeteria.com');

      expect(
        api.post('/orders', {'customer': ''}),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.fields,
            'fields',
            {'customer': 'Must be 1-50 characters'},
          ),
        ),
      );
    });

    test('5. Servidor: responde 503 y lanza ServerFailure con statusCode 503', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Simulated failure'}),
          503,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'https://api.cafeteria.com');

      expect(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('6. Sin conexión: manejador lanza ClientException y cliente lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        throw http.ClientException('sin red');
      });
      final api = ApiClient(client: mock, baseUrl: 'https://api.cafeteria.com');

      expect(
        api.get('/orders'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('6b. Tiempo agotado: excede timeout configurado y lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('[]', 200);
      });
      final api = ApiClient(
        client: mock,
        baseUrl: 'https://api.cafeteria.com',
        timeout: const Duration(milliseconds: 50),
      );

      expect(
        api.get('/orders'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('7. Código 300 no es éxito y lanza UnexpectedFailure', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Multiple Choices'}),
          300,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'https://api.cafeteria.com');

      expect(
        api.get('/orders'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            300,
          ),
        ),
      );
    });
  });
}
