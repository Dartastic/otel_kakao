// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_kakao/otel_kakao.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(serviceName: 'otel_kakao-test');
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('loginWithKakaoTalk records method + scopes', () async {
    await tracedKakao<String>(
      operation: 'loginWithKakaoTalk',
      invoke: () async => const KakaoCallResult(
        value: 'ok',
        result: KakaoResult(
          appKey: 'app_1',
          userId: 'u_1',
          loginMethod: 'kakao_talk',
          scopesGranted: ['profile_nickname', 'account_email'],
          expiresInSec: 43199,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('kakao loginWithKakaoTalk')!);
    expect(a['kakao.login.method'], 'kakao_talk');
    expect(a['kakao.expires_in_sec'], 43199);
  });

  test('invalid_grant (KAE004) sets span error', () async {
    await tracedKakao<String>(
      operation: 'loginWithKakaoAccount',
      invoke: () async => const KakaoCallResult(
        value: 'ok',
        result: KakaoResult(errorCode: 'KAE004', statusCode: 400),
      ),
    );
    expect(
      spans.findSpanByName('kakao loginWithKakaoAccount')!.status,
      SpanStatusCode.Error,
    );
  });

  test('access_denied (KAE003) does NOT set span error', () async {
    await tracedKakao<String>(
      operation: 'loginWithKakaoTalk',
      invoke: () async => const KakaoCallResult(
        value: 'ok',
        result: KakaoResult(errorCode: 'KAE003'),
      ),
    );
    expect(
      spans.findSpanByName('kakao loginWithKakaoTalk')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutKakaoInstrumentationAsync(() async {
      await tracedKakao<String>(
        operation: 'logout',
        invoke: () async => const KakaoCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('kakao '), isEmpty);
  });
}
