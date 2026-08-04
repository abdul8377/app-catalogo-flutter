import 'package:flutter/foundation.dart';

enum PriceConfigurationType { fixed, quantity, quote, unconfigured }

@immutable
class SellablePriceCombination {
  const SellablePriceCombination({
    required this.variantId,
    required this.variantLabel,
    required this.presentationId,
    required this.presentationLabel,
    required this.baseUnit,
    required this.equivalentToBaseUnit,
    this.minimumOrder = 1,
    this.purchaseIncrement = 1,
  });

  final String variantId;
  final String variantLabel;
  final String presentationId;
  final String presentationLabel;
  final String baseUnit;
  final double equivalentToBaseUnit;
  final double minimumOrder;
  final double purchaseIncrement;

  String get sourceKey => '$variantId::$presentationId';
}

@immutable
class PriceListDraft {
  const PriceListDraft({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.includesIgv,
    required this.validFrom,
    this.validUntil,
  });

  final String id;
  final String name;
  final String currencyCode;
  final bool includesIgv;
  final DateTime validFrom;
  final DateTime? validUntil;

  PriceListDraft copyWith({
    String? name,
    String? currencyCode,
    bool? includesIgv,
    DateTime? validFrom,
    DateTime? validUntil,
    bool clearValidUntil = false,
  }) {
    return PriceListDraft(
      id: id,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      includesIgv: includesIgv ?? this.includesIgv,
      validFrom: validFrom ?? this.validFrom,
      validUntil: clearValidUntil ? null : validUntil ?? this.validUntil,
    );
  }
}

@immutable
class QuantityPriceRange {
  const QuantityPriceRange({
    required this.from,
    required this.until,
    required this.pricePerPresentation,
  });

  final double from;
  final double? until;
  final double pricePerPresentation;
}

@immutable
class ProductPriceDraft {
  const ProductPriceDraft({
    required this.listId,
    required this.variantId,
    required this.presentationId,
    required this.configuration,
    this.fixedPrice,
    this.ranges = const [],
  });

  final String listId;
  final String variantId;
  final String presentationId;
  final PriceConfigurationType configuration;
  final double? fixedPrice;
  final List<QuantityPriceRange> ranges;

  String get key => '$listId::$variantId::$presentationId';

  bool get isReady {
    switch (configuration) {
      case PriceConfigurationType.fixed:
        return fixedPrice != null;
      case PriceConfigurationType.quantity:
        return ranges.isNotEmpty;
      case PriceConfigurationType.quote:
        return true;
      case PriceConfigurationType.unconfigured:
        return false;
    }
  }

  bool get hasNumericPrice => fixedPrice != null || ranges.isNotEmpty;

  ProductPriceDraft copyWith({
    PriceConfigurationType? configuration,
    double? fixedPrice,
    bool clearFixedPrice = false,
    List<QuantityPriceRange>? ranges,
  }) {
    return ProductPriceDraft(
      listId: listId,
      variantId: variantId,
      presentationId: presentationId,
      configuration: configuration ?? this.configuration,
      fixedPrice: clearFixedPrice ? null : fixedPrice ?? this.fixedPrice,
      ranges: ranges ?? this.ranges,
    );
  }
}

@immutable
class PricingStep5Draft {
  const PricingStep5Draft({
    required this.lists,
    required this.prices,
    required this.sellableCombinations,
  });

  final List<PriceListDraft> lists;
  final List<ProductPriceDraft> prices;
  final List<SellablePriceCombination> sellableCombinations;

  int pendingForList(String listId) {
    return prices
        .where((item) => item.listId == listId && !item.isReady)
        .length;
  }

  bool canActivate(String listId) => pendingForList(listId) == 0;
}

Map<String, dynamic> step5PricingDraftToMap(PricingStep5Draft draft) {
  return {
    'lists': draft.lists.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'currency_code': item.currencyCode,
        'includes_igv': item.includesIgv,
        'valid_from': item.validFrom.toIso8601String(),
        'valid_until': item.validUntil?.toIso8601String(),
      };
    }).toList(),
    'prices': draft.prices.map((item) {
      return {
        'list_id': item.listId,
        'variant_id': item.variantId,
        'presentation_id': item.presentationId,
        'configuration': item.configuration.name,
        'fixed_price': item.fixedPrice,
        'ranges': item.ranges.map((range) {
          return {
            'from': range.from,
            'until': range.until,
            'price_per_presentation': range.pricePerPresentation,
          };
        }).toList(),
      };
    }).toList(),
    'sellable_combinations': draft.sellableCombinations.map((item) {
      return {
        'variant_id': item.variantId,
        'variant_label': item.variantLabel,
        'presentation_id': item.presentationId,
        'presentation_label': item.presentationLabel,
        'base_unit': item.baseUnit,
        'equivalent_to_base_unit': item.equivalentToBaseUnit,
        'minimum_order': item.minimumOrder,
        'purchase_increment': item.purchaseIncrement,
      };
    }).toList(),
  };
}

PricingStep5Draft? step5PricingDraftFromMap(Map<String, dynamic>? map) {
  if (map == null || map.isEmpty) {
    return null;
  }

  DateTime safeDate(Object? value, {DateTime? fallback}) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        fallback ??
        DateTime.now();
  }

  PriceConfigurationType configurationFrom(Object? value) {
    return PriceConfigurationType.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => PriceConfigurationType.unconfigured,
    );
  }

  final lists = (map['lists'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return PriceListDraft(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          currencyCode: item['currency_code']?.toString() ?? 'USD',
          includesIgv: item['includes_igv'] as bool? ?? true,
          validFrom: safeDate(item['valid_from']),
          validUntil: item['valid_until'] == null
              ? null
              : DateTime.tryParse(item['valid_until'].toString()),
        );
      })
      .where((item) => item.id.isNotEmpty)
      .toList();

  final prices = (map['prices'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        final ranges = (item['ranges'] as List? ?? const [])
            .whereType<Map>()
            .map((rawRange) {
              final range = Map<String, dynamic>.from(rawRange);
              return QuantityPriceRange(
                from: (range['from'] as num?)?.toDouble() ?? 0,
                until: (range['until'] as num?)?.toDouble(),
                pricePerPresentation:
                    (range['price_per_presentation'] as num?)?.toDouble() ?? 0,
              );
            })
            .toList();
        return ProductPriceDraft(
          listId: item['list_id']?.toString() ?? '',
          variantId: item['variant_id']?.toString() ?? '',
          presentationId: item['presentation_id']?.toString() ?? '',
          configuration: configurationFrom(item['configuration']),
          fixedPrice: (item['fixed_price'] as num?)?.toDouble(),
          ranges: ranges,
        );
      })
      .where(
        (item) =>
            item.listId.isNotEmpty &&
            item.variantId.isNotEmpty &&
            item.presentationId.isNotEmpty,
      )
      .toList();

  final combinations = (map['sellable_combinations'] as List? ?? const [])
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return SellablePriceCombination(
          variantId: item['variant_id']?.toString() ?? '',
          variantLabel: item['variant_label']?.toString() ?? '',
          presentationId: item['presentation_id']?.toString() ?? '',
          presentationLabel: item['presentation_label']?.toString() ?? '',
          baseUnit: item['base_unit']?.toString() ?? 'PZA',
          equivalentToBaseUnit:
              (item['equivalent_to_base_unit'] as num?)?.toDouble() ?? 1,
          minimumOrder: (item['minimum_order'] as num?)?.toDouble() ?? 1,
          purchaseIncrement:
              (item['purchase_increment'] as num?)?.toDouble() ?? 1,
        );
      })
      .where(
        (item) => item.variantId.isNotEmpty && item.presentationId.isNotEmpty,
      )
      .toList();

  if (lists.isEmpty && prices.isEmpty && combinations.isEmpty) {
    return null;
  }

  return PricingStep5Draft(
    lists: lists,
    prices: prices,
    sellableCombinations: combinations,
  );
}
