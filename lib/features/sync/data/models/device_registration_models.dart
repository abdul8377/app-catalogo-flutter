class DeviceRegistrationRequestModel {
  const DeviceRegistrationRequestModel({
    required this.name,
    required this.pairingCode,
  });

  final String name;
  final String pairingCode;

  Map<String, Object?> toJson({required String apiContractVersion}) => {
    'name': name,
    'platform': 'ANDROID',
    'pairingCode': pairingCode,
    'appVersion': '1.0.0',
    'apiContractVersion': apiContractVersion,
  };
}

class DeviceRegistrationResponseModel {
  const DeviceRegistrationResponseModel({
    required this.deviceId,
    required this.token,
    required this.apiContractVersion,
    required this.bootstrapStatus,
    required this.registeredAt,
  });

  factory DeviceRegistrationResponseModel.fromJson(Map<String, Object?> json) =>
      DeviceRegistrationResponseModel(
        deviceId: json['deviceId'] as String? ?? '',
        token: json['token'] as String? ?? '',
        apiContractVersion: json['apiContractVersion'] as String? ?? '',
        bootstrapStatus: json['bootstrapStatus'] as String? ?? '',
        registeredAt: json['registeredAt'] as String? ?? '',
      );

  final String deviceId;
  final String token;
  final String apiContractVersion;
  final String bootstrapStatus;
  final String registeredAt;
}

class DeviceStatusModel {
  const DeviceStatusModel({
    required this.deviceId,
    required this.apiContractVersion,
    required this.status,
    required this.lastDeliveredCursor,
    required this.lastAcknowledgedCursor,
  });

  factory DeviceStatusModel.fromJson(Map<String, Object?> json) =>
      DeviceStatusModel(
        deviceId: json['deviceId'] as String? ?? '',
        apiContractVersion: json['apiContractVersion'] as String? ?? '',
        status: json['status'] as String? ?? '',
        lastDeliveredCursor: (json['lastDeliveredCursor'] as num? ?? 0).toInt(),
        lastAcknowledgedCursor: (json['lastAcknowledgedCursor'] as num? ?? 0)
            .toInt(),
      );

  final String deviceId;
  final String apiContractVersion;
  final String status;
  final int lastDeliveredCursor;
  final int lastAcknowledgedCursor;
}
