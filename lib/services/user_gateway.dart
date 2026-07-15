import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/google_oauth_config.dart';
import '../models/user_profile.dart';

abstract class UserGateway {
  Future<UserProfile?> getCurrentUser();
  Future<bool> login(String email, String password);
  Future<bool> register(String name, String email, String password);
  Future<bool> signInWithGoogle();
  Future<bool> signInWithFacebook();
  Future<void> updateDisplayName(String name);
  Future<void> sendPasswordReset(String email);
  Future<void> logout();
}

class FirebaseUserGateway implements UserGateway {
  FirebaseUserGateway({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _authOverride = auth,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  final FirebaseAuth? _authOverride;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;
  bool _googleInitialized = false;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _profileFromUser(_auth.currentUser);
  }

  @override
  Future<bool> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return true;
  }

  @override
  Future<bool> register(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    return true;
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});
      await _auth.signInWithPopup(provider);
      return true;
    }

    await _ensureGoogleInitialized();
    final account = await _googleSignIn.authenticate();
    final auth = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
    await _auth.signInWithCredential(credential);
    return true;
  }

  @override
  Future<bool> signInWithFacebook() async {
    final result = await _facebookAuth.login(
      permissions: const ['public_profile'],
      loginTracking: LoginTracking.enabled,
    );

    if (result.status != LoginStatus.success) {
      throw FirebaseAuthException(
        code: 'facebook-login-failed',
        message: result.message ?? 'Facebook login was cancelled.',
      );
    }

    final token = result.accessToken;

    if (token == null) {
      throw FirebaseAuthException(
        code: 'facebook-token-missing',
        message: 'Facebook did not return an access token.',
      );
    }

    final credential = FacebookAuthProvider.credential(token.tokenString);
    await _auth.signInWithCredential(credential);
    return true;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'login-required',
        message: 'Login required.',
      );
    }
    await user.updateDisplayName(name.trim());
    await user.reload();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    try {
      await _facebookAuth.logOut();
    } catch (_) {}
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }

    await _googleSignIn.initialize(
      serverClientId: GoogleOAuthConfig.serverClientId,
    );
    _googleInitialized = true;
  }

  UserProfile? _profileFromUser(User? user) {
    if (user == null) {
      return null;
    }

    return UserProfile(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      avatarUrl: user.photoURL ?? '',
    );
  }
}

final UserGateway userGateway = FirebaseUserGateway();
