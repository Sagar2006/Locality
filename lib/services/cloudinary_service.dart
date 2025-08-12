import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = 'dg3a49swx';
  final String apiKey = '159495941479792';
  final String apiSecret = 'gmT5J1DZue0GhFbCZTQEz8ZJbXY';
  final String uploadPreset = 'locality_preset'; // Make sure this preset exists in your Cloudinary console

  Future<String?> uploadImage(File image) async {
    try {
      // Check if file exists and is readable
      if (!await image.exists()) {
        print('Image file does not exist: ${image.path}');
        return null;
      }

      // Use unsigned upload with upload preset instead of signed upload
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      print('Uploading image: ${image.path}');
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      
      try {
        final jsonData = json.decode(responseString);
        print('Cloudinary response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          print('Upload successful: ${jsonData['secure_url']}');
          return jsonData['secure_url'];
        } else {
          print('Failed to upload image. Status code: ${response.statusCode}');
          print('Response body: $responseString');
          return null;
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        print('Raw response: $responseString');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> images) async {
    List<String> imageUrls = [];
    
    if (images.isEmpty) {
      print('No images to upload');
      return imageUrls;
    }
    
    print('Attempting to upload ${images.length} images');
    
    for (var i = 0; i < images.length; i++) {
      print('Uploading image ${i+1}/${images.length}');
      final url = await uploadImage(images[i]);
      if (url != null) {
        imageUrls.add(url);
        print('Successfully uploaded image ${i+1}');
      } else {
        print('Failed to upload image ${i+1}');
      }
    }
    
    print('Successfully uploaded ${imageUrls.length}/${images.length} images');
    
    if (imageUrls.isEmpty && images.isNotEmpty) {
      throw Exception('Failed to upload any images. Please check your internet connection and Cloudinary configuration.');
    }
    
    return imageUrls;
  }
}
