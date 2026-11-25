import 'package:business_manager/features/lots/domain/entities/colour_master_entity.dart';

abstract interface class ColourMasterRepository {
  Future<List<ColourMasterEntity>> getAllColours({String? searchQuery});

  Future<List<ColourMasterEntity>> getRecentColours({int limit = 8});

  Future<ColourMasterEntity> createCustomColour({
    required String name,
    required String hexCode,
  });

  Future<ColourMasterEntity> updateColour({
    required String id,
    required String name,
    required String hexCode,
  });

  Future<void> markColoursUsed(List<String> colourNames);
}
