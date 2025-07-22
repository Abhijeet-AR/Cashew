import 'dart:async';
import 'package:budget/struct/driveSync.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/database/platform/shared.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:easy_localization/easy_localization.dart';

/// Extended sync client that supports both appDataFolder and shared folder storage
class SharedSyncClient {
  
  /// Toggle between appDataFolder (false) and shared folder (true)
  static bool useSharedFolder = false;

  /// Creates a backup using either appDataFolder or shared folder based on settings
  static Future<bool> createFlexibleBackup({
    bool changeMadeSync = false,
    bool changeMadeSyncWaitForDebounce = true,
  }) async {
    if (appStateSettings["hasSignedIn"] == false) return false;
    if (errorSigningInDuringCloud == true) return false;
    if (appStateSettings["backupSync"] == false) return false;
    
    // Use existing sync logic for app data folder
    if (!useSharedFolder) {
      return createSyncBackup(
        changeMadeSync: changeMadeSync,
        changeMadeSyncWaitForDebounce: changeMadeSyncWaitForDebounce,
      );
    }

    // New logic for shared folder
    try {
      print("Creating sync backup in shared folder");
      
      bool hasSignedIn = false;
      if (googleUser == null) {
        hasSignedIn = await signInGoogle(
          gMailPermissions: false,
          waitForCompletion: false,
          silentSignIn: true,
        );
      } else {
        hasSignedIn = true;
      }
      
      if (!hasSignedIn) return false;

      final authHeaders = await googleUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Get current database file
      final dbFileInfo = await getCurrentDBFileInfo();
      final media = drive.Media(
        dbFileInfo.mediaStream, 
        dbFileInfo.dbFileBytes.length
      );

      // Create backup in shared folder
      final timestamp = DateFormat("yyyy-MM-dd-HHmmss").format(DateTime.now().toUtc());
      final fileName = "cashew-backup-${getCurrentDeviceName()}-$timestamp.sqlite";
      
      await DriveSyncManager.createBackupInUserFolder(
        driveApi,
        media,
        fileName,
      );

      openSnackbar(
        SnackbarMessage(
          title: "backup-created".tr(),
          description: "Backup saved to Google Drive folder",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.backup_outlined
              : Icons.backup_rounded,
        ),
      );

      return true;
    } catch (e) {
      print("Error creating shared folder backup: $e");
      openSnackbar(
        SnackbarMessage(
          title: "Backup failed",
          description: e.toString(),
          icon: Icons.error_rounded,
        ),
      );
      return false;
    }
  }

  /// Lists backups from either location based on settings
  static Future<List<drive.File>?> listFlexibleBackups() async {
    try {
      final authHeaders = await googleUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      if (!useSharedFolder) {
        // Use existing app data folder logic
        final fileList = await driveApi.files.list(
          spaces: 'appDataFolder',
          $fields: 'files(id, name, modifiedTime, size)',
        );
        return fileList.files;
      } else {
        // Use shared folder
        return await DriveSyncManager.listFilesInCashewFolder(driveApi);
      }
    } catch (e) {
      print("Error listing backups: $e");
      return null;
    }
  }

  /// Gets the appropriate parent folder ID based on settings
  static Future<List<String>> getBackupParentFolder(drive.DriveApi driveApi) async {
    if (!useSharedFolder) {
      return ["appDataFolder"];
    } else {
      final folderId = await DriveSyncManager.getOrCreateCashewFolder(driveApi);
      return [folderId];
    }
  }
}