import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/models.dart';
import 'api_clients.dart';

enum AuthFlowMode { login, register }

class AuthOtpChallenge {
  const AuthOtpChallenge({
    required this.mode,
    required this.phoneNumber,
    required this.codeHash,
    required this.salt,
    required this.expiresAt,
    required this.attemptsLeft,
    required this.debugCode,
    this.name,
    this.existingUser,
  });

  final AuthFlowMode mode;
  final String phoneNumber;
  final String? name;
  final UserProfile? existingUser;
  final String codeHash;
  final String salt;
  final DateTime expiresAt;
  final int attemptsLeft;
  final String debugCode;

  bool get expired => DateTime.now().isAfter(expiresAt);

  int get secondsRemaining {
    final seconds = expiresAt.difference(DateTime.now()).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  String get maskedPhone {
    if (phoneNumber.length <= 4) return phoneNumber;
    return '******${phoneNumber.substring(phoneNumber.length - 4)}';
  }

  AuthOtpChallenge copyWith({
    int? attemptsLeft,
    DateTime? expiresAt,
  }) {
    return AuthOtpChallenge(
      mode: mode,
      phoneNumber: phoneNumber,
      name: name,
      existingUser: existingUser,
      codeHash: codeHash,
      salt: salt,
      expiresAt: expiresAt ?? this.expiresAt,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      debugCode: debugCode,
    );
  }
}

class OtpValidationResult {
  const OtpValidationResult({
    required this.verified,
    required this.challenge,
    this.message,
  });

  final bool verified;
  final AuthOtpChallenge challenge;
  final String? message;
}

class AuthService {
  AuthService(this._api);

  static const otpLength = 6;
  static const otpTtl = Duration(minutes: 5);
  static const maxAttempts = 5;

  final SupabaseRestClient _api;
  final Random _random = Random.secure();

  Future<AuthOtpChallenge> requestOtp({
    required AuthFlowMode mode,
    required String phoneNumber,
    String? name,
  }) async {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    final cleanName = name?.trim() ?? '';
    if (mode == AuthFlowMode.register && cleanName.length < 2) {
      throw AuthException('Enter your full name to register.');
    }

    final existingUser = await _api.findUserByPhone(normalizedPhone);
    if (mode == AuthFlowMode.login && existingUser == null) {
      throw AuthException('No account found for this phone number.');
    }
    if (mode == AuthFlowMode.register && existingUser != null) {
      throw AuthException(
        'This phone number is already registered. Login instead.',
      );
    }

    return _newChallenge(
      mode: mode,
      phoneNumber: normalizedPhone,
      name: cleanName,
      existingUser: existingUser,
    );
  }

  Future<AuthOtpChallenge> resendOtp(AuthOtpChallenge challenge) async {
    return _newChallenge(
      mode: challenge.mode,
      phoneNumber: challenge.phoneNumber,
      name: challenge.name,
      existingUser: challenge.existingUser,
    );
  }

  OtpValidationResult validateOtp(AuthOtpChallenge challenge, String code) {
    final normalizedCode = code.replaceAll(RegExp(r'\D'), '');
    if (challenge.expired) {
      return OtpValidationResult(
        verified: false,
        challenge: challenge.copyWith(attemptsLeft: 0),
        message: 'OTP expired. Request a new code.',
      );
    }
    if (challenge.attemptsLeft <= 0) {
      return OtpValidationResult(
        verified: false,
        challenge: challenge,
        message: 'Too many wrong attempts. Request a new OTP.',
      );
    }
    if (normalizedCode.length != otpLength) {
      return OtpValidationResult(
        verified: false,
        challenge: challenge,
        message: 'Enter the 6 digit OTP.',
      );
    }

    final matches =
        _hashCode(challenge.phoneNumber, normalizedCode, challenge.salt) ==
            challenge.codeHash;
    if (matches) {
      return OtpValidationResult(verified: true, challenge: challenge);
    }

    final updated = challenge.copyWith(
      attemptsLeft: max(0, challenge.attemptsLeft - 1),
    );
    return OtpValidationResult(
      verified: false,
      challenge: updated,
      message: updated.attemptsLeft == 0
          ? 'Too many wrong attempts. Request a new OTP.'
          : 'Invalid OTP. ${updated.attemptsLeft} attempts left.',
    );
  }

  Future<UserProfile> completeVerifiedChallenge(
    AuthOtpChallenge challenge,
  ) async {
    if (challenge.mode == AuthFlowMode.login) {
      final user = challenge.existingUser ??
          await _api.findUserByPhone(challenge.phoneNumber);
      if (user == null) {
        throw AuthException('Account no longer exists. Register again.');
      }
      return user;
    }

    return _api.register(
      challenge.name ?? 'Farmer ${_takeLast(challenge.phoneNumber, 4)}',
      challenge.phoneNumber,
    );
  }

  AuthOtpChallenge _newChallenge({
    required AuthFlowMode mode,
    required String phoneNumber,
    required String? name,
    required UserProfile? existingUser,
  }) {
    final code = _generateCode();
    final salt = _generateSalt();
    return AuthOtpChallenge(
      mode: mode,
      phoneNumber: phoneNumber,
      name: name,
      existingUser: existingUser,
      codeHash: _hashCode(phoneNumber, code, salt),
      salt: salt,
      expiresAt: DateTime.now().add(otpTtl),
      attemptsLeft: maxAttempts,
      debugCode: code,
    );
  }

  String _generateCode() {
    return List.generate(otpLength, (_) => _random.nextInt(10)).join();
  }

  String _generateSalt() {
    final bytes = List.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashCode(String phoneNumber, String code, String salt) {
    return sha256.convert(utf8.encode('$phoneNumber:$salt:$code')).toString();
  }

  String _takeLast(String value, int count) {
    if (value.length <= count) return value;
    return value.substring(value.length - count);
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

String normalizePhoneNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    return digits.substring(2);
  }
  if (digits.length == 11 && digits.startsWith('0')) {
    return digits.substring(1);
  }
  if (digits.length != 10) {
    throw const AuthException('Enter a valid 10 digit mobile number.');
  }
  return digits;
}
