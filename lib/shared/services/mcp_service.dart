import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service for managing Model Context Protocol (MCP) connections and commands.
class MCPService {
  /// Singleton instance of MCPService.
  factory MCPService() => _instance ??= MCPService._();
  MCPService._();
  static MCPService? _instance;

  Process? _mcpProcess;
  bool _isConnected = false;

  /// Initializes the MCP server connection.
  /// Only works on web platform (not mobile).
  Future<void> initialize() async {
    // Check if platform supports MCP server
    if (!kIsWeb) {
      debugPrint('MCP server only supported on web platform');
      return;
    }

    try {
      // Start MCP server process
      _mcpProcess = await Process.start(
        'npx',
        ['-y', 'firebase-tools@latest', 'experimental:mcp'],
        workingDirectory: Directory.current.path,
      );

      _isConnected = true;
      debugPrint('MCP server initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize MCP server: $e');
      rethrow;
    }
  }

  /// Executes an MCP command with the given parameters.
  /// Returns empty result on unsupported platforms.
  Future<Map<String, dynamic>> executeCommand(
    String command,
    Map<String, dynamic> params,
  ) async {
    if (!_isConnected || _mcpProcess == null) {
      if (!kIsWeb) {
        debugPrint('MCP commands only available on web platform');
        return {'result': null, 'error': 'MCP not supported on this platform'};
      }
      throw Exception('MCP server not connected');
    }

    try {
      final request = {
        'jsonrpc': '2.0',
        'id': DateTime.now().millisecondsSinceEpoch,
        'method': command,
        'params': params,
      };

      final requestJson = jsonEncode(request);
      _mcpProcess!.stdin.writeln(requestJson);

      // Read response
      final response = await _mcpProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;

      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('MCP command execution failed: $e');
      rethrow;
    }
  }

  /// Disposes of the MCP server connection.
  void dispose() {
    _mcpProcess?.kill();
    _isConnected = false;
  }
}
