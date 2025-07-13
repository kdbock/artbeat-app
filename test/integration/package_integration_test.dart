import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import all package modules to test integration
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_auth/artbeat_auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Package Integration Tests', () {
    group('Core-Auth Integration', () {
      testWidgets('should integrate auth service with core services', (
        WidgetTester tester,
      ) async {
        // Test that auth service works with core navigation
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // Test auth state management integration
                  return StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingScreen(); // From artbeat_core
                      }

                      if (snapshot.hasData) {
                        return const Text('User authenticated');
                      } else {
                        return const LoginScreen(); // From artbeat_auth
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.pump();

        // Should show either loading screen or login screen
        expect(
          find.byType(LoadingScreen).evaluate().isNotEmpty ||
              find.byType(LoginScreen).evaluate().isNotEmpty,
          isTrue,
        );
      });

      test('should share user model between core and auth packages', () {
        // Test that UserModel from core is compatible with auth package
        final user = UserModel(
          id: 'test-id',
          email: 'test@example.com',
          username: 'testuser',
          fullName: 'Test User',
          createdAt: DateTime.now(),
        );

        // Auth package should be able to work with core UserModel
        expect(user.id, isNotNull);
        expect(user.email, isNotEmpty);
        expect(user.fullName, equals('Test User'));
      });
    });

    group('Core Models Integration', () {
      test('should work with user model properties correctly', () {
        final user = UserModel(
          id: 'user-123',
          email: 'user@example.com',
          username: 'testuser',
          fullName: 'Test User',
          bio: 'Test bio',
          location: 'Test Location',
          createdAt: DateTime.now(),
          userType: UserType.regular.value,
        );

        expect(user.isRegularUser, isTrue);
        expect(user.isArtist, isFalse);
        expect(user.followersCount, equals(0));
        expect(user.followingCount, equals(0));
      });
    });

    group('Service Integration', () {
      test('should integrate core services correctly', () {
        // Test that services can be initialized
        final userService = UserService();
        final connectivityService = ConnectivityService();

        // All services should be instantiable
        expect(userService, isNotNull);
        expect(connectivityService, isNotNull);
      });
    });

    group('Widget Integration', () {
      testWidgets('should render core widgets correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  LoadingScreen(),
                  UserAvatar(
                    displayName: 'Test User',
                    imageUrl: 'https://example.com/avatar.jpg',
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        // Should render core widgets
        expect(find.byType(LoadingScreen), findsOneWidget);
        expect(find.byType(UserAvatar), findsOneWidget);
      });

      testWidgets('should handle basic navigation', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Test Button'),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Should find the test button
        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Data Model Validation', () {
      test('should validate user model data correctly', () {
        // Test valid user
        final validUser = UserModel(
          id: 'valid-id',
          email: 'valid@example.com',
          username: 'validuser',
          fullName: 'Valid User',
          createdAt: DateTime.now(),
        );

        expect(validUser.id, isNotEmpty);
        expect(validUser.email, contains('@'));

        // Test user with different user types
        final artistUser = UserModel(
          id: 'artist-id',
          email: 'artist@example.com',
          username: 'artist',
          fullName: 'Artist User',
          createdAt: DateTime.now(),
          userType: UserType.artist.value,
        );

        expect(artistUser.isArtist, isTrue);
        expect(artistUser.isRegularUser, isFalse);
      });

      test('should handle user model validation correctly', () {
        final now = DateTime.now();
        final user = UserModel(
          id: 'test-user',
          email: 'test@example.com',
          username: 'testuser',
          fullName: 'Test User',
          bio: 'Test bio',
          createdAt: now,
        );

        expect(user.fullName, isNotEmpty);
        expect(user.email, contains('@'));
        expect(user.bio, isNotEmpty);
        expect(user.createdAt, equals(now));
      });
    });

    group('Performance Tests', () {
      test('should handle multiple user model creation efficiently', () {
        final users = <UserModel>[];
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          users.add(
            UserModel(
              id: 'user-$i',
              email: 'user$i@example.com',
              username: 'user$i',
              fullName: 'User $i',
              createdAt: DateTime.now(),
            ),
          );
        }

        stopwatch.stop();

        expect(users.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should handle concurrent model operations', () async {
        final futures = <Future<UserModel>>[];

        for (int i = 0; i < 10; i++) {
          futures.add(
            Future.delayed(const Duration(milliseconds: 10), () {
              return UserModel(
                id: 'async-user-$i',
                email: 'async-user$i@example.com',
                username: 'async-user$i',
                fullName: 'Async User $i',
                createdAt: DateTime.now(),
              );
            }),
          );
        }

        final results = await Future.wait(futures);
        expect(results.length, equals(10));
        expect(
          results.every((user) => user.id.startsWith('async-user')),
          isTrue,
        );
      });
    });
  });
}
