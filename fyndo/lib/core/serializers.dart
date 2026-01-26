// ═══════════════════════════════════════════════════════════════════════════
// FYNDO - Zero-Trust Notes OS
// Built Value Serializers
// ═══════════════════════════════════════════════════════════════════════════

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:fyndo_app/features/notes/models/note.dart';
import 'package:fyndo_app/features/notes/models/notebook.dart';

part 'serializers.g.dart';

/// Collection of serializers for all built_value types.
@SerializersFor([Note, NoteMetadata, Notebook])
final Serializers serializers = _$serializers;

/// Serializers with StandardJsonPlugin for JSON compatibility.
final Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
