# Firebase MCP Server Setup Guide

This guide explains how to set up and use the Firebase MCP (Model Context Protocol) server integration in the HydraCat project.

## What is Firebase MCP Server?

The Firebase MCP server enables AI-powered development tools to work directly with your Firebase projects. It provides capabilities for:
- Project management
- Firestore data operations
- Security rules management
- Authentication user management
- Storage operations
- And more

**⚠️ Platform Limitation**: MCP server only works on **web platform**. It does **NOT** work on mobile devices (iOS, Android) or desktop apps due to platform restrictions. This is designed for web-based development and CI/CD operations.

## Prerequisites

1. **Node.js and npm**: Ensure you have Node.js 18+ and npm installed
2. **Firebase CLI**: Install the latest Firebase CLI
3. **Firebase Project**: Have an active Firebase project

## Installation Steps

### Step 1: Install Firebase CLI with MCP Support

```bash
# Install the latest Firebase CLI globally
npm install -g firebase-tools@latest

# Verify installation
firebase --version
```

### Step 2: Authenticate with Firebase

```bash
# Login to Firebase (this will open a browser window)
firebase login --reauth

# Verify authentication
firebase projects:list
```

### Step 3: Configure MCP Server

The MCP server configuration is already set up in `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "firebase": {
      "command": "npx",
      "args": ["-y", "firebase-tools@latest", "experimental:mcp"]
    }
  }
}
```

## Usage

### In Your Flutter App

The MCP service is automatically initialized when the Firebase service starts:

```dart
import 'package:hydracat/shared/services/firebase_service.dart';

final firebaseService = FirebaseService();
await firebaseService.initialize();

// Access MCP service
final mcpService = firebaseService.mcp;
```

### Using MCP Repository

The MCP repository provides high-level methods for Firebase operations:

```dart
import 'package:hydracat/shared/repositories/mcp_repository.dart';

final mcpRepo = MCPRepository();

// List Firestore collections
final collections = await mcpRepo.listFirestoreCollections();

// Get security rules
final rules = await mcpRepo.getFirestoreRules();

// Validate rules
final isValid = await mcpRepo.validateFirestoreRules(rules);

// List auth users
final users = await mcpRepo.listAuthUsers();
```

### Development & CI Usage

The MCP service is designed for development and CI/CD operations, not for end-user admin functions. For production administration, use the [Firebase Console](https://console.firebase.google.com/) which provides:

- **Secure Access Control**: Role-based permissions and authentication
- **Audit Logging**: Complete history of all administrative actions
- **Advanced Features**: Full Firebase management capabilities
- **Enterprise Security**: SOC compliance and security best practices

## Available MCP Commands

### Firestore Operations
- `firestore_list_collections` - List all collections
- `firestore_get_document` - Get a specific document
- `firestore_get_rules` - Get security rules
- `firestore_validate_rules` - Validate security rules

### Authentication Operations
- `auth_list_users` - List all users
- `auth_get_user` - Get user details
- `auth_create_user` - Create new user
- `auth_delete_user` - Delete user

### Storage Operations
- `storage_get_object_download_url` - Get download URL
- `storage_list_objects` - List storage objects

### Project Management
- `projects_list` - List all projects
- `projects_get` - Get project details

## Testing

Run the MCP service tests:

```bash
flutter test test/shared/services/mcp_service_test.dart
flutter test test/shared/repositories/mcp_repository_test.dart
```

## Troubleshooting

### Common Issues

1. **"ProcessException: Starting new processes is not supported on iOS"**
   - **This is normal on mobile devices!** MCP server only works on web platform
   - The app will still work normally, just without MCP features
   - Use web browser for development with MCP features

2. **"MCP server not connected"**
   - Ensure Firebase CLI is installed and authenticated
   - Check if the MCP server process is running
   - Verify you're on web platform (MCP only works in web browsers)

3. **"Command not found"**
   - Verify Firebase CLI version supports MCP
   - Update to latest version: `npm install -g firebase-tools@latest`

4. **Authentication errors**
   - Re-authenticate: `firebase login --reauth`
   - Check project permissions

5. **Process start failures**
   - Ensure Node.js is properly installed
   - Check working directory permissions
   - Verify you're on web platform (MCP only works in web browsers)

### Debug Mode

Enable debug logging in the MCP service:

```dart
// In mcp_service.dart, add more detailed logging
debugPrint('Starting MCP server process...');
debugPrint('Working directory: ${Directory.current.path}');
```

## Security Considerations

### **IMPORTANT: No Client-Side Admin Functions**

The MCP service is designed for **development and CI/CD operations only**. It does NOT provide admin functions for end users.

### **Why No Admin Panel?**

1. **Security Risk**: Client-side admin panels expose sensitive operations to all app users
2. **Data Privacy**: Could violate privacy laws (HIPAA, GDPR) by exposing user data
3. **Access Control**: No way to restrict admin functions to authorized personnel only
4. **Audit Trail**: No logging of administrative actions

### **Safe Usage Guidelines**

1. **Development Only**: Use MCP for debugging and development assistance
2. **CI/CD Operations**: Use for automated testing and deployment
3. **AI Assistance**: Enable AI tools to help with Firebase development
4. **Production Admin**: Use Firebase Console for all production administration

### **Environment Isolation**

1. **Separate Projects**: Use different Firebase projects for dev/staging/prod
2. **Access Control**: Limit MCP operations to development environments
3. **Credential Management**: Never commit Firebase credentials to version control
4. **Audit Logging**: Monitor MCP operations for security

## Advanced Configuration

### Custom MCP Server

You can configure a custom MCP server:

```json
{
  "mcpServers": {
    "firebase": {
      "command": "path/to/custom/mcp/server",
      "args": ["--config", "custom-config.json"]
    }
  }
}
```

### Environment-Specific Settings

Create different configurations for different environments:

```bash
# Development
.cursor/mcp.dev.json

# Production  
.cursor/mcp.prod.json
```

## Support

For issues with the Firebase MCP server:
- [Firebase MCP Documentation](https://firebase.google.com/docs/cli/mcp-server)
- [Firebase CLI GitHub](https://github.com/firebase/firebase-tools)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)

## Contributing

When adding new MCP capabilities:
1. Update the `MCPService` class
2. Add corresponding methods to `MCPRepository`
3. Create appropriate tests
4. Update this documentation
5. Follow the project's coding standards
