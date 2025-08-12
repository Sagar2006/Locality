import 'package:firebase_auth/firebase_auth.dart';
import 'package:locality/models/user_model.dart';
import 'package:locality/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Auth change user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  // Create user in database after registration
  Future<void> createUserInDatabase(
      UserCredential credential, String name, String phone, String location) async {
    UserModel user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: credential.user!.email ?? '',
      phone: phone,
      location: location,
    );

    await _databaseService.createUser(user);
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }
}
