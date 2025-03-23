import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../../constants/model_file.dart';
import '../../utils/image_utils.dart';
import '../ai_model.dart';

double euclideanDistance(Offset p1, Offset p2) {
  return sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
}

// ignore: must_be_immutable
class Hands extends AiModel {
  Interpreter? interpreter;

  Hands({this.interpreter}) {
    loadModel();
  }

  final int inputSize = 224;
  final double existThreshold = 0.1;
  final double scoreThreshold = 0.3;

  @override
  List<Object> get props => [];

  @override
  int get getAddress => interpreter!.address;

  @override
  Interpreter? get getInterpreter => interpreter;

  @override
  Future<void> loadModel() async {
    try {
      print("Starting to load interpreter for Hands model...");
      interpreter ??= await Interpreter.fromAsset(ModelFile.hands,
          options: InterpreterOptions());
      print("Interpreter loaded successfully: ${interpreter != null}");
      final outputTensors = interpreter!.getOutputTensors();
      for (var tensor in outputTensors) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
      }
    } catch (e) {
      print("Failed to load interpreter: $e");
    }
  }

  @override
  TensorImage getProcessedImage(TensorImage inputImage) {
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .add(NormalizeOp(0, 255))
        .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  @override
  @override
  Map<String, dynamic>? predict(image_lib.Image image) {
    if (interpreter == null) {
      return null;
    }

    if (Platform.isAndroid) {
      image = image_lib.copyRotate(image, -90);
      image = image_lib.flipHorizontal(image);
    }
    final tensorImage = TensorImage(TfLiteType.float32);
    tensorImage.loadImage(image);
    final inputImage = getProcessedImage(tensorImage);

    TensorBuffer outputLandmarks = TensorBufferFloat(outputShapes[0]);
    TensorBuffer outputExist = TensorBufferFloat(outputShapes[1]);
    TensorBuffer outputScores = TensorBufferFloat(outputShapes[2]);

    final inputs = <Object>[inputImage.buffer];

    final outputs = <int, Object>{
      0: outputLandmarks.buffer,
      1: outputExist.buffer,
      2: outputScores.buffer,
    };

    interpreter!.runForMultipleInputs(inputs, outputs);

    if (outputExist.getDoubleValue(0) < existThreshold ||
        outputScores.getDoubleValue(0) < scoreThreshold) {
      return null;
    }

    final landmarkPoints = outputLandmarks.getDoubleList().reshape([21, 3]);
    final landmarkResults = <Offset>[];
    for (var point in landmarkPoints) {
      landmarkResults.add(Offset(
        point[0] / inputSize * image.width,
        point[1] / inputSize * image.height,
      ));
    }

    // Get the finger states using the new function
    final fingerStates = getFingerStates(landmarkResults);
    print(fingerStates);
    // Return both the landmark points and finger states
    return {
      'point': landmarkResults,
      'fingerStates': fingerStates,
    };
  }

  Map<String, bool> getFingerStates(List<Offset> landmarks) {
    // Define the landmark indices for each finger
    final List<List<int>> fingerPoints = [
      [1, 2, 3, 4], // Thumb
      [5, 6, 7, 8], // Index
      [9, 10, 11, 12], // Middle
      [13, 14, 15, 16], // Ring
      [17, 18, 19, 20] // Pinky
    ];

    // Corresponding finger names
    final List<String> fingerNames = [
      'Thumb',
      'Index',
      'Middle',
      'Ring',
      'Pinky'
    ];

    // Threshold to determine if a finger is open (adjustable)
    const double threshold = 0.7;

    // Map to store the state of each finger
    Map<String, bool> fingerStates = {};

    // Analyze each finger
    for (int i = 0; i < fingerPoints.length; i++) {
      final points = fingerPoints[i];
      final base = landmarks[points[0]]; // Base point (e.g., MCP or CMC)
      final joint1 = landmarks[points[1]]; // First joint
      final joint2 = landmarks[points[2]]; // Second joint
      final tip = landmarks[points[3]]; // Tip of the finger

      // Calculate the maximum possible distance (sum of segment lengths)
      double maxDistance = euclideanDistance(base, joint1) +
          euclideanDistance(joint1, joint2) +
          euclideanDistance(joint2, tip);

      // Calculate the actual distance (direct from base to tip)
      double actualDistance = euclideanDistance(base, tip);

      // Compute the ratio
      double ratio = actualDistance / maxDistance;

      // Determine if the finger is open based on the threshold
      bool isOpen = fingerNames[i] == 'Thumb' ? ratio > 0.9 : ratio > threshold;

      // Store the result
      fingerStates[fingerNames[i]] = isOpen;
    }

    return fingerStates;
  }
}

Map<String, dynamic>? runHandDetector(Map<String, dynamic> params) {
  final hands =
      Hands(interpreter: Interpreter.fromAddress(params['detectorAddress']));
  final image = ImageUtils.convertCameraImage(params['cameraImage']);
  final result = hands.predict(image!);

  return result;
}
