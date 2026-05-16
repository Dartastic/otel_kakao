// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_kakao_suppression.dart';

const _tracerName = 'dartastic_otel_libs_kakao';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class KakaoResult {
  const KakaoResult({
    this.appKey,
    this.userId,
    this.loginMethod,
    this.scopesGranted,
    this.scopesRequested,
    this.accessTokenLength,
    this.refreshTokenLength,
    this.expiresInSec,
    this.shareTemplateId,
    this.shareType,
    this.feedSent,
    this.errorCode,
    this.statusCode,
  });

  /// JavaScript / native app key.
  final String? appKey;

  final String? userId;

  /// `kakao_talk`, `kakao_account` (account fallback), `kakao_sync`.
  final String? loginMethod;

  final List<String>? scopesGranted;
  final List<String>? scopesRequested;

  final int? accessTokenLength;
  final int? refreshTokenLength;
  final int? expiresInSec;

  /// Kakao Message template id.
  final int? shareTemplateId;

  /// `feed`, `list`, `location`, `commerce`, `text`, `calendar`.
  final String? shareType;

  /// `true` for sent talk message; `false` for share-link only.
  final bool? feedSent;

  /// Kakao error code (e.g. `KAE001` invalid_request, `KAE003` access_denied,
  /// `KAE004` invalid_grant, `KAE005` invalid_scope).
  final String? errorCode;
  final int? statusCode;
}

class KakaoCallResult<T> {
  const KakaoCallResult({required this.value, this.result});
  final T value;
  final KakaoResult? result;
}

/// Wraps a Kakao SDK call in a CLIENT span. [operation] is one of
/// `loginWithKakaoTalk`, `loginWithKakaoAccount`, `logout`, `unlink`,
/// `me`, `accessTokenInfo`, `sendDefaultMemo`, `sendDefaultMessage`,
/// `sendDefaultFriendsMessage`, `sendCustomMessage`,
/// `shareDefault`, `shareCustom`, `shareScrap`,
/// `registerPushToken`, `unregisterPushToken`.
Future<T> tracedKakao<T>({
  required String operation,
  required Future<KakaoCallResult<T>> Function() invoke,
}) async {
  if (kakaoInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'kakao',
    'rpc.method': operation,
    'kakao.operation': operation,
  };

  final span = _tracer().startSpan(
    'kakao $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.appKey != null) {
        extras.add(OTel.attributeString('kakao.app_key', res.appKey!));
      }
      if (res.userId != null) {
        extras.add(OTel.attributeString('kakao.user.id', res.userId!));
      }
      if (res.loginMethod != null) {
        extras.add(OTel.attributeString(
          'kakao.login.method',
          res.loginMethod!,
        ));
      }
      if (res.scopesGranted != null) {
        extras.add(OTel.attributeStringList(
          'kakao.scopes.granted',
          res.scopesGranted!,
        ));
      }
      if (res.scopesRequested != null) {
        extras.add(OTel.attributeStringList(
          'kakao.scopes.requested',
          res.scopesRequested!,
        ));
      }
      if (res.accessTokenLength != null) {
        extras.add(OTel.attributeInt(
          'kakao.access_token.length',
          res.accessTokenLength!,
        ));
      }
      if (res.refreshTokenLength != null) {
        extras.add(OTel.attributeInt(
          'kakao.refresh_token.length',
          res.refreshTokenLength!,
        ));
      }
      if (res.expiresInSec != null) {
        extras.add(OTel.attributeInt(
          'kakao.expires_in_sec',
          res.expiresInSec!,
        ));
      }
      if (res.shareTemplateId != null) {
        extras.add(OTel.attributeInt(
          'kakao.share.template_id',
          res.shareTemplateId!,
        ));
      }
      if (res.shareType != null) {
        extras.add(OTel.attributeString('kakao.share.type', res.shareType!));
      }
      if (res.feedSent != null) {
        extras.add(OTel.attributeBool('kakao.feed.sent', res.feedSent!));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString('kakao.error.code', res.errorCode!));
        if (res.errorCode != 'KAE003') {
          span.setStatus(SpanStatusCode.Error, 'Kakao ${res.errorCode}');
        }
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(SpanStatusCode.Error, 'Kakao HTTP ${res.statusCode}');
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
