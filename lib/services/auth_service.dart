import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    return Amplify.Auth.signIn(
      username: email,
      password: password,
    );
  }

  Future<SignInResult> confirmMfa({required String code}) async {
    return Amplify.Auth.confirmSignIn(confirmationValue: code);
  }

  Future<TotpSetupDetails> setUpTotp() async {
    return Amplify.Auth.setUpTotp();
  }

  Future<void> verifyTotpSetup(String code) async {
    await Amplify.Auth.verifyTotpSetup(code);
  }

  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  Future<AuthUser> getCurrentUser() async {
    return Amplify.Auth.getCurrentUser();
  }

  Future<bool> isSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  }

  Future<List<String>> getUserGroups() async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session.userPoolTokensResult.value.idToken.groups;
  }
}
