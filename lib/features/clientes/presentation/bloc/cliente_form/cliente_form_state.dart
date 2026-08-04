import 'package:equatable/equatable.dart';

import '../../../domain/entities/cliente.dart';

class ClienteFormState extends Equatable {
  const ClienteFormState({
    required this.loading,
    required this.saving,
    required this.saved,
    required this.notFound,
    this.cliente,
    this.error,
  });

  factory ClienteFormState.initial({required bool isEditing}) =>
      ClienteFormState(
        loading: isEditing,
        saving: false,
        saved: false,
        notFound: false,
      );

  final bool loading;
  final bool saving;
  final bool saved;
  final bool notFound;
  final Cliente? cliente;
  final String? error;

  ClienteFormState copyWith({
    bool? loading,
    bool? saving,
    bool? saved,
    bool? notFound,
    Cliente? cliente,
    String? error,
    bool clearError = false,
  }) => ClienteFormState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    notFound: notFound ?? this.notFound,
    cliente: cliente ?? this.cliente,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [loading, saving, saved, notFound, cliente, error];
}
