library;

import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'app.dart';
import 'pages/date.dart';
import 'pages/exception.dart';
import 'pages/hidden.dart';
import 'pages/library.dart';
import 'main.server.options.dart';

void main() async {
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  final cacheHeader = Platform.environment['OPEN_RUNTIMES_CACHE_HEADER'] ?? 'CDN-Cache-Control';

  final router = Router();
  router.mount('/date', serveApp((request, render) => render(Document(title: 'jaspr_app', body: const DatePage()))));
  router.mount(
    '/exception',
    serveApp((request, render) => render(Document(title: 'jaspr_app', body: const ExceptionPage()))),
  );
  router.mount(
    '/library',
    serveApp((request, render) => render(Document(title: 'jaspr_app', body: const LibraryPage()))),
  );
  router.mount('/hidden', serveApp((request, render) => render(Document(title: 'jaspr_app', body: const HiddenPage()))));
  router.mount('/', serveApp((request, render) => render(Document(title: 'jaspr_app', body: App()))));

  final cacheMiddleware = createMiddleware(
    responseHandler: (response) {
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.startsWith('text/html')) {
        return response;
      }
      return response.change(headers: {cacheHeader: 'public, max-age=36000'});
    },
  );

  final handler = const Pipeline().addMiddleware(cacheMiddleware).addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port, shared: true);

  print('Serving at http://${server.address.host}:${server.port}');
}
