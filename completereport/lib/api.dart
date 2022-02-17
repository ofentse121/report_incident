import 'dart:io';
import 'dart:typed_data';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:gcloud/storage.dart';

class CloudApi {
  final auth.ServiceAccountCredentials _credentials;
  auth.AutoRefreshingAuthClient? _client;
  CloudApi(String json)
      : _credentials = auth.ServiceAccountCredentials.fromJson(json);

  Future<ObjectInfo> save(String name, Uint8List imageBytes) async {
    //create a client
    if (_client == null)
      _client =
          await auth.clientViaServiceAccount(_credentials, Storage.SCOPES);
    //create storage object
    var storage = Storage(_client!, 'image upload google storage');
    //connect to bucket
    var bucket = storage.bucket('bucket_for_img');
    // save to bucket
    return await bucket.writeBytes(name, imageBytes);
  }
}
