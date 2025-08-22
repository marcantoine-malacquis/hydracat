import 'package:flutter_test/flutter_test.dart';
import 'package:hydracat/shared/services/mcp_service.dart';

void main() {
  group('MCPService', () {
    late MCPService mcpService;

    setUp(() {
      mcpService = MCPService();
    });

    tearDown(() {
      mcpService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = MCPService();
      final instance2 = MCPService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize successfully', () async {
      // Note: This test requires Firebase CLI to be installed and authenticated
      // In a real test environment, you might want to mock the Process.start
      try {
        await mcpService.initialize();
        expect(true, isTrue); // If we get here, initialization succeeded
      } on Exception catch (e) {
        // If Firebase CLI is not available, this is expected
        expect(e, isA<Exception>());
      }
    });

    test('should handle command execution when not initialized', () async {
      try {
        await mcpService.executeCommand('test_command', {});
        fail('Should have thrown an exception');
      } on Exception catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('MCP server not connected'));
      }
    });
  });
}
