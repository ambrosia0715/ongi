import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/result.dart';

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  try {
    // Firebase가 초기화되었는지 확인
    final apps = Firebase.apps;
    if (apps.isEmpty) {
      throw Exception('Firebase is not initialized. Please wait for Firebase initialization to complete.');
    }
    return AuthRepository();
  } catch (e) {
    print('Error creating AuthRepository: $e');
    rethrow;
  }
});

/// 인증 관련 데이터 처리 클래스
class AuthRepository {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final GoogleSignIn _googleSignIn;
  
  AuthRepository() {
    try {
      // Firebase가 초기화되었는지 확인
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        throw Exception('Firebase is not initialized');
      }
      
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      
      // 웹용 클라이언트 ID 설정
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // 웹에서는 클라이언트 ID를 명시적으로 전달
        // iOS/Android에서는 GoogleService-Info.plist/google-services.json에서 자동으로 읽어옴
        clientId: kIsWeb 
            ? '687252199849-7pfpauu6vb51b696e0ie1f4r5dv6818b.apps.googleusercontent.com'
            : null,
      );
      
      print('AuthRepository initialized successfully');
    } catch (e) {
      print('Error initializing AuthRepository: $e');
      rethrow;
    }
  }
  
  /// 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// 현재 사용자
  User? get currentUser => _auth.currentUser;
  
  /// 이메일로 회원가입
  Future<Result<User>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // Firebase Auth로 계정 생성
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        return const Failure('회원가입에 실패했습니다.');
      }
      
      // Firestore에 사용자 프로필 생성 (에러가 나도 계속 진행)
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': false,
          'aiUsageCount': 0,
          'lastAiUsageDate': null,
        });
      } catch (firestoreError) {
        // Firestore 저장 실패해도 회원가입은 성공으로 처리
        print('Warning: Failed to create user profile in Firestore: $firestoreError');
      }
      
      return Success(user);
    } on FirebaseAuthException catch (e) {
      String message = '회원가입에 실패했습니다.';
      if (e.code == 'weak-password') {
        message = '비밀번호가 너무 약합니다.';
      } else if (e.code == 'email-already-in-use') {
        message = '이미 사용 중인 이메일입니다.';
      } else if (e.code == 'invalid-email') {
        message = '유효하지 않은 이메일입니다.';
      }
      return Failure(message, e);
    } catch (e) {
      return Failure('알 수 없는 오류가 발생했습니다.', e);
    }
  }
  
  /// 이메일로 로그인
  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        return const Failure('로그인에 실패했습니다.');
      }
      
      return Success(user);
    } on FirebaseAuthException catch (e) {
      String message = '로그인에 실패했습니다.';
      if (e.code == 'user-not-found') {
        message = '등록되지 않은 이메일입니다.';
      } else if (e.code == 'wrong-password') {
        message = '비밀번호가 올바르지 않습니다.';
      } else if (e.code == 'invalid-email') {
        message = '유효하지 않은 이메일입니다.';
      } else if (e.code == 'user-disabled') {
        message = '비활성화된 계정입니다.';
      }
      return Failure(message, e);
    } catch (e) {
      return Failure('알 수 없는 오류가 발생했습니다.', e);
    }
  }
  
  /// 구글 로그인
  Future<Result<User>> signInWithGoogle() async {
    try {
      print('Starting Google Sign In...');
      
      // 기존 세션 정리 (이전 로그인 세션이 남아있을 수 있음)
      try {
        await _googleSignIn.signOut();
        print('Previous session signed out');
      } catch (e) {
        print('Warning: Failed to sign out previous session: $e');
        // signOut 실패는 무시하고 계속 진행
      }
      
      // 구글 로그인 플로우 시작
      GoogleSignInAccount? googleUser;
      try {
        print('Calling GoogleSignIn.signIn()...');
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('Google Sign In timeout');
            throw TimeoutException('구글 로그인이 시간 초과되었습니다.');
          },
        );
        print('GoogleSignIn.signIn() completed, user: ${googleUser?.email ?? "null"}');
      } catch (signInError) {
        print('Error during Google Sign In: $signInError');
        print('Error type: ${signInError.runtimeType}');
        if (signInError is TimeoutException) {
          return Failure('구글 로그인이 시간 초과되었습니다. 다시 시도해주세요.', signInError);
        }
        return Failure('구글 로그인 중 오류가 발생했습니다: $signInError', signInError);
      }
      
      if (googleUser == null) {
        // 사용자가 로그인 취소
        print('Google Sign In cancelled by user');
        return const Failure('구글 로그인이 취소되었습니다.');
      }
      
      print('Google user signed in: ${googleUser.email}');
      
      // 구글 인증 정보 가져오기
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (authError) {
        print('Error getting Google auth: $authError');
        return Failure('구글 인증 정보를 가져오는데 실패했습니다: $authError', authError);
      }
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Error: Missing Google auth tokens');
        return const Failure('구글 인증 정보를 가져오는데 실패했습니다.');
      }
      
      print('Google auth tokens received');
      
      // Firebase 인증 크리덴셜 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      print('Firebase credential created, signing in...');
      
      // Firebase에 로그인
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } catch (firebaseError) {
        print('Error signing in with Firebase: $firebaseError');
        return Failure('Firebase 로그인에 실패했습니다: $firebaseError', firebaseError);
      }
      
      final user = userCredential.user;
      if (user == null) {
        print('Error: Firebase user is null');
        return const Failure('구글 로그인에 실패했습니다.');
      }
      
      print('Firebase user signed in: ${user.uid}');
      
      // Firestore에 사용자 프로필이 없으면 생성
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          try {
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email ?? '',
              'displayName': user.displayName ?? '',
              'photoURL': user.photoURL ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'isPremium': false,
              'aiUsageCount': 0,
              'lastAiUsageDate': null,
            });
            print('User profile created in Firestore');
          } catch (firestoreError) {
            print('Warning: Failed to create user profile in Firestore: $firestoreError');
          }
        } else {
          print('User profile already exists in Firestore');
        }
      } catch (firestoreError) {
        print('Warning: Firestore operation failed: $firestoreError');
        // Firestore 오류는 무시하고 로그인은 성공으로 처리
      }
      
      return Success(user);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during Google Sign In: ${e.code} - ${e.message}');
      String message = '구글 로그인에 실패했습니다.';
      if (e.code == 'account-exists-with-different-credential') {
        message = '이 이메일은 다른 로그인 방법으로 이미 등록되어 있습니다.';
      } else if (e.code == 'invalid-credential') {
        message = '유효하지 않은 인증 정보입니다.';
      } else if (e.code == 'network-request-failed') {
        message = '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.';
      } else {
        message = '구글 로그인에 실패했습니다: ${e.message ?? e.code}';
      }
      return Failure(message, e);
    } catch (e, stackTrace) {
      print('Exception during Google Sign In: $e');
      print('Stack trace: $stackTrace');
      return Failure('구글 로그인 중 오류가 발생했습니다: $e', e);
    }
  }
  
  /// 로그아웃
  Future<Result<void>> signOut() async {
    try {
      // 구글 로그인도 함께 로그아웃
      await _googleSignIn.signOut();
      await _auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure('로그아웃에 실패했습니다.', e);
    }
  }
  
  /// 사용자 프로필 가져오기
  Future<Result<Map<String, dynamic>>> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Failure('사용자 정보를 찾을 수 없습니다.');
      }
      return Success(doc.data()!);
    } catch (e) {
      return Failure('사용자 정보를 가져오는데 실패했습니다.', e);
    }
  }
  
  /// Premium 상태 확인
  Future<bool> isPremium(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      return doc.data()?['isPremium'] ?? false;
    } catch (e) {
      return false;
    }
  }
}

/// 현재 사용자 Provider
final currentUserProvider = StreamProvider<User?>((ref) {
  try {
    final authRepo = ref.watch(authRepositoryProvider);
    return authRepo.authStateChanges;
  } catch (e) {
    print('Error in currentUserProvider: $e');
    // 에러 발생 시 빈 스트림 반환
    return Stream.value(null);
  }
});

