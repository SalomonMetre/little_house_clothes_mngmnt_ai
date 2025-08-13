// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'package:new_project/models/cloth.dart';
import 'package:new_project/models/request.dart';
import 'package:new_project/providers/clothes_provider.dart';
import 'package:new_project/providers/request_provider.dart';

class AdminHome extends ConsumerStatefulWidget {
  const AdminHome({super.key});

  @override
  ConsumerState<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends ConsumerState<AdminHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CloudinaryPublic _cloudinary;
  final List<String> _categories = [
    'abaca',
    'camel',
    'cotton',
    'denim',
    'fur',
    'leather',
    'nylon',
    'satin',
    'silk',
    'vinyl',
    'wool',
    'yak',
  ];
  final _uploadFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedCategory = 'abaca';
  File? _pickedImageFile;
  Uint8List? _pickedImageWeb;
  String _predictedCategory = '';
  // String _selectedVisCategory = 'all';
  // String _selectedVisTimeMode = 'daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeRemoteConfig();
  }

  Future<void> _initializeRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await remoteConfig.fetchAndActivate();
      String cloudName = remoteConfig.getString('cloudinary_cloud_name');
      String uploadPreset = remoteConfig.getString('cloudinary_upload_preset');

      setState(() {
        _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
      });
    } catch (e) {
      print('Error initializing remote config: $e');
      setState(() {
        _cloudinary = CloudinaryPublic(
          'default_cloud_name',
          'default_upload_preset',
          cache: false,
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImageWeb = bytes;
          _pickedImageFile = null;
          _predictedCategory = 'Classifying...';
        });
        await _classifyImageWeb(bytes);
      } else {
        final file = File(pickedFile.path);
        setState(() {
          _pickedImageFile = file;
          _pickedImageWeb = null;
          _predictedCategory = 'Classifying...';
        });
        await _classifyImageFile(file);
      }
    }
  }

  Future<void> _classifyImageFile(File imageFile) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final classificationApiUrl = remoteConfig.getString(
        'classification_api_url',
      );

      // Read the file bytes directly
      final imageBytes = await imageFile.readAsBytes();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(classificationApiUrl),
      );
      request.files.add(
        // Use fromBytes instead of fromPath
        http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.png'),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String predictedLabel = responseData['predicted_category'];
        setState(() {
          _predictedCategory = predictedLabel;
          _selectedCategory = predictedLabel;
        });
        // Show snackbar with the predicted category
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Predicted category: $predictedLabel'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print(
          'Classification API failed with status code: ${response.statusCode}',
        );
        setState(() {
          _predictedCategory = 'Failed to classify';
          _selectedCategory = null;
        });
      }
    } catch (e) {
      print('An error occurred during classification: $e');
      setState(() {
        _predictedCategory = 'Failed to classify due to an error';
        _selectedCategory = null;
      });
    }
  }

  Future<void> _classifyImageWeb(Uint8List imageBytes) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final classificationApiUrl = remoteConfig.getString(
        'classification_api_url',
      );
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(classificationApiUrl),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.png'),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String predictedLabel = responseData['predicted_category'];
        setState(() {
          _predictedCategory = predictedLabel;
          _selectedCategory = predictedLabel;
        });
        // Show snackbar with the predicted category
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Predicted category: $predictedLabel'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print(
          'Classification API failed with status code: ${response.statusCode}',
        );
        setState(() {
          _predictedCategory = 'Failed to classify';
          _selectedCategory = null;
        });
      }
    } catch (e) {
      print('An error occurred during classification: $e');
      setState(() {
        _predictedCategory = 'Failed to classify due to an error';
        _selectedCategory = null;
      });
    }
  }

  Future<void> _uploadItem() async {
    if (_uploadFormKey.currentState!.validate() &&
        (_pickedImageFile != null || _pickedImageWeb != null)) {
      try {
        String? imageUrl;
        if (kIsWeb && _pickedImageWeb != null) {
          imageUrl = await uploadFileFromWeb(_pickedImageWeb!);
        } else if (_pickedImageFile != null) {
          imageUrl = await uploadFile(_pickedImageFile!.path);
        }

        if (imageUrl != null) {
          final currentUserEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'unknown_admin';
          final clothesService = ref.read(clothesServiceProvider);
          final newCloth = Cloth(
            id: FirebaseFirestore.instance.collection('clothes').doc().id,
            category: _selectedCategory!,
            name: _nameController.text,
            imageUrl: imageUrl,
            quantity: int.parse(_quantityController.text),
            uploadedBy: currentUserEmail,
            uploadTime: DateTime.now(),
          );
          await clothesService.addCloth(newCloth);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item uploaded successfully!')),
          );
          _uploadFormKey.currentState!.reset();
          _nameController.clear();
          _quantityController.clear();
          setState(() {
            _pickedImageFile = null;
            _pickedImageWeb = null;
            _predictedCategory = '';
          });
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Upload failed.')));
        }
      } catch (e) {
        print('Upload failed: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<String?> uploadFile(
    String filePath, {
    String folder = 'new-products',
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<String?> uploadFileFromWeb(
    Uint8List fileBytes, {
    String folder = 'new-products',
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          fileBytes,
          identifier:
              'unique_identifier_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<void> _handleRequest(Request request, String newStatus) async {
    final requestService = ref.read(requestServiceProvider);
    final clothesService = ref.read(clothesServiceProvider);
    try {
      await requestService.updateRequestStatus(request.id, newStatus);
      if (newStatus == 'approved') {
        await clothesService.updateClothQuantities(request.items);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request from ${request.userEmail} was $newStatus.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request: ${e.toString()}')),
      );
    }
  }

  Widget _buildUploadView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _uploadFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: _pickedImageFile != null
                      ? Image.file(_pickedImageFile!, fit: BoxFit.contain)
                      : _pickedImageWeb != null
                      ? Image.memory(_pickedImageWeb!, fit: BoxFit.contain)
                      : const Text('No image selected'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Image'),
            ),
            const SizedBox(height: 16),
            Text(
              'Predicted Category: $_predictedCategory',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploadItem,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Upload Item'),
            ),
          ],
        ),
      ),
    );
  }

  // Assuming this is part of a widget class where you have access to `ref` and `context`
  Future<Map<String, Cloth>> _fetchClothDetails(List<String> itemIds) async {
    final clothesService = ref.read(clothesServiceProvider);
    return await clothesService.getClothesByIds(itemIds);
  }

  Widget _buildRequestsView() {
    final requestsAsyncValue = ref.watch(requestsProvider);

    return requestsAsyncValue.when(
      data: (requests) {
        final pendingRequests = requests
            .where((req) => req.status == 'pending')
            .toList();

        if (pendingRequests.isEmpty) {
          return const Center(child: Text('No new requests.'));
        }

        return FutureBuilder<Map<String, Cloth>>(
          future: _fetchClothDetails(
            pendingRequests.expand((req) => req.items.keys).toList(),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final clothDetails = snapshot.data ?? {};

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final request = pendingRequests[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request from: ${request.userEmail}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Submitted on: ${request.createdAt.toLocal().toString().split('.')[0]}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(),
                        ...request.items.entries.map((item) {
                          final clothId = item.key;
                          final cloth = clothDetails[clothId];
                          final clothName = cloth != null
                              ? cloth.name
                              : 'Unknown Item';
                          final quantity = item.value;
                          return Text('  - $clothName, Quantity: $quantity');
                        }).toList(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _handleRequest(request, 'declined'),
                              child: const Text(
                                'Decline',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _handleRequest(request, 'approved'),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  // Enhanced beautiful visualization view
  Widget _buildVisualizationView() {
    final clothesAsyncValue = ref.watch(clothesProvider);
    final requestsAsyncValue = ref.watch(requestsProvider);

    return clothesAsyncValue.when(
      data: (clothes) {
        final Map<String, int> categoryCounts = {};
        for (var cloth in clothes) {
          categoryCounts[cloth.category] =
              (categoryCounts[cloth.category] ?? 0) + cloth.quantity;
        }

        final Map<int, int> requestsPerDay = {};
        if (requestsAsyncValue.hasValue) {
          for (var request in requestsAsyncValue.value!) {
            final day = request.createdAt.day;
            requestsPerDay[day] = (requestsPerDay[day] ?? 0) + 1;
          }
        }

        // Beautiful gradient colors for categories
        final List<Color> categoryColors = [
          const Color(0xFF6C5CE7), // Purple
          const Color(0xFF00B894), // Teal
          const Color(0xFFE17055), // Orange
          const Color(0xFF0984E3), // Blue
          const Color(0xFFE84393), // Pink
          const Color(0xFFFDCB6E), // Yellow
          const Color(0xFF6C5CE7), // Purple (repeat for more categories)
          const Color(0xFF00B894), // Teal (repeat)
        ];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[50]!, Colors.grey[100]!],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Chart Card
                Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey[50]!],
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.category,
                                color: Color(0xFF6C5CE7),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Items by Category',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 380,
                          child: BarChart(
                            BarChartData(
                              barGroups: categoryCounts.entries.map((entry) {
                                final index = _categories.indexOf(entry.key);
                                final color =
                                    categoryColors[index %
                                        categoryColors.length];

                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.toDouble(),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [color.withOpacity(0.7), color],
                                      ),
                                      width: 32,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                            show: true,
                                            toY:
                                                (categoryCounts.values.isEmpty
                                                    ? 0
                                                    : categoryCounts.values
                                                          .reduce(
                                                            (a, b) =>
                                                                a > b ? a : b,
                                                          )) *
                                                1.1,
                                            color: Colors.grey[100],
                                          ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF718096),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final categoryIndex = value.toInt();
                                      if (categoryIndex >= 0 &&
                                          categoryIndex < _categories.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12.0,
                                          ),
                                          child: Text(
                                            _categories[categoryIndex],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4A5568),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 50,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  left: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) =>
                                      const Color(0xFF2D3748),
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        final category =
                                            _categories[group.x.toInt()];
                                        return BarTooltipItem(
                                          '$category\n',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Items: ${rod.toY.toInt()}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Requests Over Time Chart Card
                Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey[50]!],
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B894).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: Color(0xFF00B894),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Requests Over Time',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 380,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: requestsPerDay.entries
                                      .map(
                                        (entry) => FlSpot(
                                          entry.key.toDouble(),
                                          entry.value.toDouble(),
                                        ),
                                      )
                                      .toList(),
                                  isCurved: true,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00B894),
                                      Color(0xFF00CEC9),
                                    ],
                                  ),
                                  barWidth: 4,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(
                                          0xFF00B894,
                                        ).withOpacity(0.3),
                                        const Color(
                                          0xFF00CEC9,
                                        ).withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, xPercentage, bar, index) =>
                                            FlDotCirclePainter(
                                              radius: 6,
                                              color: Colors.white,
                                              strokeWidth: 3,
                                              strokeColor: const Color(
                                                0xFF00B894,
                                              ),
                                            ),
                                  ),
                                  isStrokeCapRound: true,
                                  preventCurveOverShooting: true,
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF718096),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Day ${value.toInt()}',
                                        style: const TextStyle(
                                          color: Color(0xFF4A5568),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    reservedSize: 40,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: 1,
                                verticalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  );
                                },
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  left: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (touchedSpot) =>
                                      const Color(0xFF2D3748),
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((
                                      LineBarSpot touchedSpot,
                                    ) {
                                      final day = touchedSpot.x.toInt();
                                      final requests = touchedSpot.y.toInt();
                                      return LineTooltipItem(
                                        'Day $day\n',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Requests: $requests',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                ),
                                touchCallback:
                                    (
                                      FlTouchEvent event,
                                      LineTouchResponse? touchResponse,
                                    ) {
                                      // Add haptic feedback on touch
                                      if (event is FlTapUpEvent &&
                                          touchResponse
                                                  ?.lineBarSpots
                                                  ?.isNotEmpty ==
                                              true) {
                                        HapticFeedback.lightImpact();
                                      }
                                    },
                              ),
                              minX: requestsPerDay.keys.isEmpty
                                  ? 0
                                  : requestsPerDay.keys
                                        .reduce((a, b) => a < b ? a : b)
                                        .toDouble(),
                              maxX: requestsPerDay.keys.isEmpty
                                  ? 31
                                  : requestsPerDay.keys
                                        .reduce((a, b) => a > b ? a : b)
                                        .toDouble(),
                              minY: 0,
                              maxY: requestsPerDay.values.isEmpty
                                  ? 10
                                  : (requestsPerDay.values.reduce(
                                              (a, b) => a > b ? a : b,
                                            ) *
                                            1.2)
                                        .toDouble(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Summary Statistics Card
                Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey[50]!],
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary Statistics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Items',
                                categoryCounts.values
                                    .fold(0, (sum, count) => sum + count)
                                    .toString(),
                                Icons.inventory_2,
                                const Color(0xFF6C5CE7),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Categories',
                                categoryCounts.length.toString(),
                                Icons.category,
                                const Color(0xFF00B894),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Total Requests',
                                requestsPerDay.values
                                    .fold(0, (sum, count) => sum + count)
                                    .toString(),
                                Icons.analytics,
                                const Color(0xFFE17055),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF6C5CE7),
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading visualizations...',
                style: TextStyle(color: Color(0xFF718096), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      error: (e, st) => Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for summary stat cards
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClothesCRUDView() {
    final clothesAsyncValue = ref.watch(clothesProvider);

    return clothesAsyncValue.when(
      data: (clothes) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Clothes CRUD',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddClothDialog(context),
                child: const Text('Add Cloth'),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clothes.length,
                itemBuilder: (context, index) {
                  final cloth = clothes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image on the left
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 16.0),
                            child: Image.network(
                              cloth.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                            ),
                          ),
                          // Details and buttons on the right
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name: ${cloth.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Category: ${cloth.category}'),
                                const SizedBox(height: 4),
                                Text('Quantity: ${cloth.quantity}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _showEditClothDialog(context, cloth),
                                      child: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _deleteCloth(cloth.id),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddClothDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    String selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Cloth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final clothesService = ref.read(clothesServiceProvider);
                final newCloth = Cloth(
                  id: FirebaseFirestore.instance.collection('clothes').doc().id,
                  name: nameController.text,
                  category: selectedCategory,
                  quantity: int.parse(quantityController.text),
                  imageUrl: '',
                  uploadedBy:
                      FirebaseAuth.instance.currentUser?.email ??
                      'unknown_admin',
                  uploadTime: DateTime.now(),
                );
                await clothesService.addCloth(newCloth);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditClothDialog(BuildContext context, Cloth cloth) {
    final nameController = TextEditingController(text: cloth.name);
    final quantityController = TextEditingController(
      text: cloth.quantity.toString(),
    );
    String selectedCategory = cloth.category;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Cloth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final clothesService = ref.read(clothesServiceProvider);
                final updatedCloth = Cloth(
                  id: cloth.id,
                  name: nameController.text,
                  category: selectedCategory,
                  quantity: int.parse(quantityController.text),
                  imageUrl: cloth.imageUrl,
                  uploadedBy: cloth.uploadedBy,
                  uploadTime: cloth.uploadTime,
                );
                await clothesService.updateCloth(updatedCloth);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCloth(String clothId) async {
    final clothesService = ref.read(clothesServiceProvider);
    await clothesService.deleteCloth(clothId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upload Item'),
            Tab(text: 'Requests'),
            Tab(text: 'Visualization'),
            Tab(text: 'Clothes Management'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadView(),
          _buildRequestsView(),
          _buildVisualizationView(),
          _buildClothesCRUDView(),
        ],
      ),
    );
  }
}
