# Shared Google Drive Folder Implementation

This implementation allows users to choose between storing their backups in a regular, user-accessible folder called "Cashew Budget Backups" (current default) or in Google Drive's hidden Application Data folder.

## Key Differences

### Shared Folder (Current Default)
- **Visible**: Users can see "Cashew Budget Backups" folder in their Google Drive
- **Accessible**: Users can download, share, and manage backups directly
- **Persistent**: Backups remain even if app is uninstalled
- **Permissions**: Requires `drive.file` scope for full Drive access
- **Shareable**: Users can share backups with family members

### Application Data Folder (Alternative Option)
- **Hidden**: Not visible in user's Google Drive interface
- **App-specific**: Only your app can access this folder
- **Auto-cleanup**: Deleted when user uninstalls the app
- **Permissions**: Only requires `drive.appdata` scope
- **Security**: More secure, isolated from user interference

## Implementation Files

### Core Files Created:

1. **`budget/lib/struct/driveSync.dart`**
   - `DriveSyncManager` class with methods for shared folder operations
   - Creates/finds "Cashew Budget Backups" folder
   - Lists files in shared folder
   - Handles folder sharing permissions

2. **`budget/lib/struct/syncClientShared.dart`**
   - `SharedSyncClient` class for flexible backup operations
   - Supports both storage locations based on user preference
   - Maintains compatibility with existing sync logic

3. **`budget/lib/widgets/backupLocationSettings.dart`**
   - UI widget for users to toggle between storage locations
   - Shows confirmation dialog when switching to shared folder
   - Requests additional permissions when needed

### Modified Files:

1. **`budget/lib/widgets/accountAndBackup.dart`**
   - Updated `signInGoogle()` to request `drive.file` scope when using shared folder
   - Modified `createBackup()` to support both storage locations
   - Updated `deleteRecentBackups()` and `getDriveFiles()` for both locations

2. **`budget/lib/struct/syncClient.dart`**
   - Updated sync operations to work with both storage locations
   - Added import for `DriveSyncManager`

## Usage

### For Users:
1. Go to backup settings in the app
2. Toggle "Use Shared Google Drive Folder" option
3. Confirm the switch and grant additional permissions if prompted
4. Future backups will be saved to the visible Google Drive folder

### For Developers:

```dart
// Check current storage preference
bool usingSharedFolder = appStateSettings["useSharedDriveFolder"] ?? true;

// Create backup in appropriate location
if (usingSharedFolder) {
  final folderId = await DriveSyncManager.getOrCreateCashewFolder(driveApi);
  driveFile.parents = [folderId];
} else {
  driveFile.parents = ["appDataFolder"];
}

// List files from appropriate location
List<drive.File>? files;
if (usingSharedFolder) {
  files = await DriveSyncManager.listFilesInCashewFolder(driveApi);
} else {
  final fileList = await driveApi.files.list(spaces: 'appDataFolder');
  files = fileList.files;
}
```

## Integration Steps

1. **Add the settings widget to your backup settings page:**
```dart
import 'package:budget/widgets/backupLocationSettings.dart';

// In your settings page:
BackupLocationSettings(),
```

2. **Initialize the preference on app startup:**
```dart
SharedSyncClient.useSharedFolder = appStateSettings["useSharedDriveFolder"] ?? true;
```

3. **Optional: Add migration functionality:**
```dart
// Migrate existing backups from appDataFolder to shared folder
// (Implementation would copy files from one location to another)
```

## Permissions

The app will request these Google Drive scopes:
- `drive.appdata` - Always required for app data folder access
- `drive.file` - Required when using shared folder option

## Benefits for Users

1. **Visibility**: Users can see their backups in Google Drive
2. **Control**: Users can manually download, delete, or organize backups
3. **Sharing**: Users can share backups with family members or other devices
4. **Persistence**: Backups survive app uninstallation
5. **Accessibility**: Backups can be accessed from any device with Google Drive

## Backward Compatibility

- Existing users continue using Application Data folder by default
- No breaking changes to existing backup/sync functionality
- Users can switch between storage locations at any time
- Both storage methods can coexist (though only one is active at a time)

## Security Considerations

- Shared folder backups are visible to users and anyone they share with
- Application Data folder remains more secure and isolated
- Users should be educated about the trade-offs when switching
- Consider adding encryption for shared folder backups if handling sensitive data