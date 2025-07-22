import 'package:googleapis/drive/v3.dart' as drive;
import 'package:budget/widgets/accountAndBackup.dart';

class DriveSyncManager {
  static const String CASHEW_FOLDER_NAME = "Cashew Budget Backups";
  static String? _cashewFolderId;

  /// Creates or gets the Cashew folder in the user's Google Drive
  static Future<String> getOrCreateCashewFolder(drive.DriveApi driveApi) async {
    if (_cashewFolderId != null) return _cashewFolderId!;

    try {
      // Search for existing Cashew folder
      final query = "name='$CASHEW_FOLDER_NAME' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await driveApi.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _cashewFolderId = fileList.files!.first.id;
        return _cashewFolderId!;
      }

      // Create new folder if it doesn't exist
      final folderMetadata = drive.File()
        ..name = CASHEW_FOLDER_NAME
        ..mimeType = 'application/vnd.google-apps.folder';

      final folder = await driveApi.files.create(folderMetadata);
      _cashewFolderId = folder.id;
      return _cashewFolderId!;
    } catch (e) {
      throw Exception('Failed to create/get Cashew folder: $e');
    }
  }

  /// Lists files in the Cashew folder
  static Future<List<drive.File>?> listFilesInCashewFolder(drive.DriveApi driveApi) async {
    final folderId = await getOrCreateCashewFolder(driveApi);
    
    final fileList = await driveApi.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime, size, webViewLink, webContentLink)',
      orderBy: 'modifiedTime desc',
    );

    return fileList.files;
  }

  /// Creates a backup in the user-visible Cashew folder
  static Future<void> createBackupInUserFolder(
    drive.DriveApi driveApi,
    drive.Media media,
    String fileName,
  ) async {
    final folderId = await getOrCreateCashewFolder(driveApi);

    final driveFile = drive.File()
      ..name = fileName
      ..parents = [folderId]
      ..modifiedTime = DateTime.now().toUtc();

    await driveApi.files.create(driveFile, uploadMedia: media);
  }

  /// Shares the Cashew folder with specific users (optional)
  static Future<void> shareFolderWithUser(
    drive.DriveApi driveApi,
    String email,
    {String role = 'reader'} // reader, writer, commenter
  ) async {
    final folderId = await getOrCreateCashewFolder(driveApi);

    final permission = drive.Permission()
      ..type = 'user'
      ..role = role
      ..emailAddress = email;

    await driveApi.permissions.create(permission, folderId);
  }
}