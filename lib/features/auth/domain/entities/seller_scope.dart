import 'package:equatable/equatable.dart';

/// Alcance que deberá aplicarse a consultas cuando exista persistencia multiusuario.
class SellerScope extends Equatable {
  const SellerScope({
    required this.organizationId,
    required this.sellerId,
    required this.includesAllSellers,
  });

  final String organizationId;
  final String? sellerId;
  final bool includesAllSellers;

  bool includes({required String organizationId, String? sellerId}) {
    if (organizationId != this.organizationId) return false;
    return includesAllSellers || sellerId == this.sellerId;
  }

  @override
  List<Object?> get props => [organizationId, sellerId, includesAllSellers];
}
