import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrecisionPickPage extends StatelessWidget {
  final Function(String) sendData; // Add this parameter

  PrecisionPickPage({super.key, required this.sendData});

  final List<Map<String, dynamic>> _precisionSets = [
    {
      'name': '1',
      'image': 'assets/images/01.png', // Path to the image
      'color': Colors.blue,
      'description': 'Basic precision control'
    },
    {
      'name': '2',
      'image': 'assets/images/02.png', // Path to the image
      'color': Colors.yellow,
      'description': 'Enhanced dexterity'
    },
    {
      'name': '3',
      'image': 'assets/images/03.png', // Path to the image
      'color': Colors.green,
      'description': 'Advanced grip control'
    },
    {
      'name': '4',
      'image': 'assets/images/04.png', // Path to the image
      'color': Colors.red,
      'description': 'Fine motor skills'
    },
    {
      'name': '5',
      'image': 'assets/images/05.png', // Path to the image
      'color': Colors.teal,
      'description': 'Maximum precision'
    },
    {
      'name': 'Thumbs Up',
      'image': 'assets/images/06.png', // Path to the image
      'color': Colors.orange,
      'description': 'Gesture control'
    },
    {
      'name': 'Punch',
      'image': 'assets/images/00.png', // Path to the image
      'color': Colors.teal,
      'description': 'Gesture control'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Precision Control',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.purple.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Precision Level',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose the control mode that best matches your needs',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _precisionSets.length,
                  itemBuilder: (context, index) {
                    final preset = _precisionSets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();

                          Map<String, dynamic> precisionData = {
                            "sendType": "precision",
                            "data": preset['name'], // Example: "1", "2", etc.
                          };

                          // Convert the data to a JSON string
                          String jsonData = jsonEncode(precisionData);

                          // Send the data
                          sendData(jsonData);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${preset['name']} mode selected'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: preset['color'],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: preset['color'].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.asset(
                                    preset['image'], // Load image from assets
                                    width: 40, // Adjust size as needed
                                    height: 40,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Level ${preset['name']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        preset['description'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
