import 'package:equatable/equatable.dart';

/// Identidad autenticada independiente del proveedor de autenticación futuro.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.organizationId,
    required this.displayName,
    this.sellerId,
    this.active = true,
  });

  final String id;
  final String organizationId;
  final String displayName;
  final String? sellerId;
  final bool active;

  @override
  List<Object?> get props => [
    id,
    organizationId,
    displayName,
    sellerId,
    active,
  ];
}
