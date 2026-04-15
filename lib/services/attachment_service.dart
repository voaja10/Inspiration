import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';

class AttachmentService {
  AttachmentService();

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Future<Attachment?> pickAndCompress({
    required AttachmentType type,
    required String elementId,
    required ImageSource source,
  }) async {
    final file = await _picker.pickImage(source: source, imageQuality: 100);
    if (file == null) return null;
    final input = File(file.path);
    final appDir = await getApplicationDocumentsDirectory();
    final attachDir = Directory(p.join(appDir.path, 'attachments', type.name));
    if (!attachDir.existsSync()) attachDir.createSync(recursive: true);

    final targetPath = p.join(attachDir.path, '${_uuid.v4()}.jpg');
    final compressed = await FlutterImageCompress.compressAndGetFile(
      input.absolute.path,
      targetPath,
      quality: 78,
      minWidth: 1200,
      minHeight: 1200,
      format: CompressFormat.jpeg,
    );
    final out = File(compressed?.path ?? input.path);
    return Attachment(
      id: _uuid.v4(),
      type: type,
      elementId: elementId,
      filePath: out.path,
      fileSize: out.lengthSync(),
      createdAt: DateTime.now(),
    );
  }
}
