import 'dart:convert';

class Guardian {
  final String name;
  final String phoneNumber;

  Guardian({required this.name, required this.phoneNumber});

  // Convertir un objeto Guardian a un Mapa (JSON)
  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneNumber': phoneNumber,
  };

  // Crear un objeto Guardian desde un Mapa (JSON)
  factory Guardian.fromJson(Map<String, dynamic> json) => Guardian(
    name: json['name'],
    phoneNumber: json['phoneNumber'],
  );
}