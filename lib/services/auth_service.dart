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
    try {
      print('AuthService: Creating user in database for UID: ${credential.user!.uid}');
      
      UserModel user = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: credential.user!.email ?? '',
        phone: phone,
        location: location,
      );

      print('AuthService: User model created: ${user.toMap()}');
      await _databaseService.createUser(user);
      print('AuthService: User successfully created in database');
    } catch (e) {
      print('AuthService: Error creating user in database: $e');
      print('AuthService: Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }
  
  // Force refresh the current user
  Future<void> refreshUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        print('AuthService: Refreshing user token');
        await user.reload();
        print('AuthService: User token refreshed');
      } else {
        print('AuthService: No user to refresh');
      }
    } catch (e) {
      print('AuthService: Error refreshing user: $e');
    }
  }
}
