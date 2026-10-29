// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_kakao/otel_kakao.dart';

/// Traces Kakao calls with OpenTelemetry.
///
/// `otel_kakao` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Kakao call in
/// [tracedKakao]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'kakao-example');

  // Wraps a Kakao SDK call in a CLIENT span.
  final kakaoId = await tracedKakao<String>(
    operation: 'create',
    invoke: () async {
      // Make the Kakao call here, then report what it returned.
      const id = 'kakao_8f3a2c';
      return const KakaoCallResult(
          value: id,
          result: KakaoResult(
              appKey: 'orders/2026/inv-1042.pdf',
              userId: 'user_8f3a2c',
              loginMethod: 'kakao_talk',
              scopesGranted: ['example'],
              scopesRequested: ['example'],
              accessTokenLength: 128,
              refreshTokenLength: 128,
              expiresInSec: 1,
              shareTemplateId: 1,
              shareType: 'feed',
              feedSent: true,
              errorCode: 'KAE001',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedKakao create returned $kakaoId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutKakaoInstrumentationAsync.
  await runWithoutKakaoInstrumentationAsync(
    () => tracedKakao<String>(
      operation: 'create',
      invoke: () async {
        const id = 'kakao_8f3a2c';
        return const KakaoCallResult(
            value: id,
            result: KakaoResult(
                appKey: 'orders/2026/inv-1042.pdf',
                userId: 'user_8f3a2c',
                loginMethod: 'kakao_talk',
                scopesGranted: ['example'],
                scopesRequested: ['example'],
                accessTokenLength: 128,
                refreshTokenLength: 128,
                expiresInSec: 1,
                shareTemplateId: 1,
                shareType: 'feed',
                feedSent: true,
                errorCode: 'KAE001',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
