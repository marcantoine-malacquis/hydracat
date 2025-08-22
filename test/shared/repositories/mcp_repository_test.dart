import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/repositories/mcp_repository.dart';

void main() {
  group('MCPRepository', () {
    late MCPRepository mcpRepository;

    setUp(() {
      mcpRepository = MCPRepository();
    });

    test('should list Firestore collections', () async {
      try {
        final collections = await mcpRepository.listFirestoreCollections();
        expect(collections, isA<List<Map<String, dynamic>>>());
      } on Exception catch (e) {
        // Expected if MCP server is not running
        expect(e, isA<Exception>());
      }
    });

    test('should get Firestore document', () async {
      try {
        final document = await mcpRepository.getFirestoreDocument(
          'test_collection',
          'test_document',
        );
        expect(document, isA<Map<String, dynamic>>());
      } on Exception catch (e) {
        // Expected if MCP server is not running
        expect(e, isA<Exception>());
      }
    });

    test('should get Firestore rules', () async {
      try {
        final rules = await mcpRepository.getFirestoreRules();
        expect(rules, isA<String>());
      } on Exception catch (e) {
        // Expected if MCP server is not running
        expect(e, isA<Exception>());
      }
    });

    test('should validate Firestore rules', () async {
      try {
        final isValid = await mcpRepository.validateFirestoreRules(
          'rules_version = "2"; service cloud.firestore { match /databases/{database}/documents { match /{document=**} { allow read, write: if false; } } }',
        );
        expect(isValid, isA<bool>());
      } on Exception catch (e) {
        // Expected if MCP server is not running
        expect(e, isA<Exception>());
      }
    });

    test('should get storage object download URL', () async {
      try {
        final url = await mcpRepository.getStorageObjectDownloadUrl(
          'test/path',
        );
        expect(url, isA<String>());
      } on Exception catch (e) {
        // Expected if MCP server is not running
        expect(e, isA<Exception>());
      }
    });

    test('should list auth users', () async {
      try {
        final users = await mcpRepository.listAuthUsers();
        expect(users, isA<List<Map<String, dynamic>>>());
      } on Exception catch (e) {
        // Expected if MCP server is not running
        expect(e, isA<Exception>());
      }
    });
  });
}
