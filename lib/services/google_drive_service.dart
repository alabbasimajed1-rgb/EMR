import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

// فئة مساعدة لتمرير بيانات المصادقة (التوكين) من حساب جوجل إلى مكتبة Drive API
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  // نطلب صلاحية التعامل مع ملفات التطبيق في جوجل درايف
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // تسجيل الدخول والحصول على إمكانية الوصول لـ Drive
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // المستخدم ألغى تسجيل الدخول

      final headers = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(headers);
      return drive.DriveApi(authenticateClient);
    } catch (e) {
      print('Error authenticating with Google: $e');
      return null;
    }
  }

  // --- دالة النسخ الاحتياطي (الرفع إلى السحابة) ---
  Future<bool> backupDatabase() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // تحديد مسار قاعدة البيانات في الهاتف
      final dbPath = p.join(await getDatabasesPath(), 'emr_database.db');
      final file = File(dbPath);
      if (!await file.exists()) return false;

      // البحث عما إذا كان هناك نسخة احتياطية سابقة في السحابة
      final query = "name = 'emr_database_backup.db' and trashed = false";
      final fileList = await driveApi.files.list(q: query);
      
      final driveFile = drive.File();
      driveFile.name = 'emr_database_backup.db';

      // تجهيز الملف للرفع
      final media = drive.Media(file.openRead(), file.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // تحديث النسخة الموجودة مسبقاً
        final existingFileId = fileList.files!.first.id;
        await driveApi.files.update(driveFile, existingFileId!, uploadMedia: media);
      } else {
        // رفع نسخة جديدة لأول مرة
        await driveApi.files.create(driveFile, uploadMedia: media);
      }
      return true;
    } catch (e) {
      print('Backup error: $e');
      return false;
    }
  }

  // --- دالة الاستعادة (التنزيل من السحابة) ---
  Future<bool> restoreDatabase() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // البحث عن النسخة الاحتياطية في السحابة
      final query = "name = 'emr_database_backup.db' and trashed = false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files == null || fileList.files!.isEmpty) {
        // لا توجد نسخة احتياطية
        return false; 
      }

      final fileId = fileList.files!.first.id!;
      
      // تنزيل الملف
      final drive.Media response = await driveApi.files.get(
        fileId, 
        downloadOptions: drive.DownloadOptions.fullMedia
      ) as drive.Media;

      // حفظ الملف وتغطية قاعدة البيانات الحالية
      final dbPath = p.join(await getDatabasesPath(), 'emr_database.db');
      final file = File(dbPath);
      
      final List<int> dataStore = [];
      await for (var data in response.stream) {
        dataStore.addAll(data);
      }
      await file.writeAsBytes(dataStore);
      
      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
  
  // تسجيل الخروج من الحساب
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
