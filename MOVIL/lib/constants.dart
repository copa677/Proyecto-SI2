// lib/constants.dart
// CONFIGURACIÓN DE PRODUCCIÓN
const String baseUrl =
    "http://ec2-18-116-35-65.us-east-2.compute.amazonaws.com:8000";

// URLs de desarrollo local (comentadas para producción)
//const String baseUrl = "http://10.0.2.2:8000"; // Emulador Android
//const String baseUrl = "http://192.168.0.14:8000"; // Red local

// Configuración para producción: usar API real
const bool debugUseMockApi = false;

// Configuración adicional para producción
const bool isProduction = true;
const bool enableDebugLogs = false;
