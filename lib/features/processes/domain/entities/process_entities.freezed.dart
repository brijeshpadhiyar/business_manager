// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'process_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProcessEntity {

 String get id; String get name; String? get description; bool get isActive; ProcessBillingModeOverride? get billingModeOverride; bool get includeDamagedInLabour; int get defaultRatePaise; String get defaultPricingUnit; int get createdAt; int get updatedAt;
/// Create a copy of ProcessEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessEntityCopyWith<ProcessEntity> get copyWith => _$ProcessEntityCopyWithImpl<ProcessEntity>(this as ProcessEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProcessEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.billingModeOverride, _this.billingModeOverride) || other.billingModeOverride == _this.billingModeOverride)&&(identical(other.includeDamagedInLabour, _this.includeDamagedInLabour) || other.includeDamagedInLabour == _this.includeDamagedInLabour)&&(identical(other.defaultRatePaise, _this.defaultRatePaise) || other.defaultRatePaise == _this.defaultRatePaise)&&(identical(other.defaultPricingUnit, _this.defaultPricingUnit) || other.defaultPricingUnit == _this.defaultPricingUnit)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as ProcessEntity;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.isActive,_this.billingModeOverride,_this.includeDamagedInLabour,_this.defaultRatePaise,_this.defaultPricingUnit,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as ProcessEntity;
  return 'ProcessEntity(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, isActive: ${_this.isActive}, billingModeOverride: ${_this.billingModeOverride}, includeDamagedInLabour: ${_this.includeDamagedInLabour}, defaultRatePaise: ${_this.defaultRatePaise}, defaultPricingUnit: ${_this.defaultPricingUnit}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ProcessEntityCopyWith<$Res>  {
  factory $ProcessEntityCopyWith(ProcessEntity value, $Res Function(ProcessEntity) _then) = _$ProcessEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, bool isActive, ProcessBillingModeOverride? billingModeOverride, bool includeDamagedInLabour, int defaultRatePaise, String defaultPricingUnit, int createdAt, int updatedAt
});




}
/// @nodoc
class _$ProcessEntityCopyWithImpl<$Res>
    implements $ProcessEntityCopyWith<$Res> {
  _$ProcessEntityCopyWithImpl(this._self, this._then);

  final ProcessEntity _self;
  final $Res Function(ProcessEntity) _then;

/// Create a copy of ProcessEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isActive = null,Object? billingModeOverride = freezed,Object? includeDamagedInLabour = null,Object? defaultRatePaise = null,Object? defaultPricingUnit = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(ProcessEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,billingModeOverride: freezed == billingModeOverride ? _self.billingModeOverride : billingModeOverride // ignore: cast_nullable_to_non_nullable
as ProcessBillingModeOverride?,includeDamagedInLabour: null == includeDamagedInLabour ? _self.includeDamagedInLabour : includeDamagedInLabour // ignore: cast_nullable_to_non_nullable
as bool,defaultRatePaise: null == defaultRatePaise ? _self.defaultRatePaise : defaultRatePaise // ignore: cast_nullable_to_non_nullable
as int,defaultPricingUnit: null == defaultPricingUnit ? _self.defaultPricingUnit : defaultPricingUnit // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProcessEntity].
extension ProcessEntityPatterns on ProcessEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessEntity value)  $default,){
final _that = this;
switch (_that) {
case _ProcessEntity():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  bool isActive,  ProcessBillingModeOverride? billingModeOverride,  bool includeDamagedInLabour,  int defaultRatePaise,  String defaultPricingUnit,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessEntity() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.billingModeOverride,_that.includeDamagedInLabour,_that.defaultRatePaise,_that.defaultPricingUnit,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  bool isActive,  ProcessBillingModeOverride? billingModeOverride,  bool includeDamagedInLabour,  int defaultRatePaise,  String defaultPricingUnit,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProcessEntity():
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.billingModeOverride,_that.includeDamagedInLabour,_that.defaultRatePaise,_that.defaultPricingUnit,_that.createdAt,_that.updatedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  bool isActive,  ProcessBillingModeOverride? billingModeOverride,  bool includeDamagedInLabour,  int defaultRatePaise,  String defaultPricingUnit,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProcessEntity() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.billingModeOverride,_that.includeDamagedInLabour,_that.defaultRatePaise,_that.defaultPricingUnit,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessEntity implements ProcessEntity {
  const _ProcessEntity({required this.id, required this.name, this.description, required this.isActive, this.billingModeOverride, required this.includeDamagedInLabour, this.defaultRatePaise = 0, this.defaultPricingUnit = 'PER_PIECE', required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  bool isActive;
@override final  ProcessBillingModeOverride? billingModeOverride;
@override final  bool includeDamagedInLabour;
@override@JsonKey() final  int defaultRatePaise;
@override@JsonKey() final  String defaultPricingUnit;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of ProcessEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessEntityCopyWith<_ProcessEntity> get copyWith => __$ProcessEntityCopyWithImpl<_ProcessEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.billingModeOverride, billingModeOverride) || other.billingModeOverride == billingModeOverride)&&(identical(other.includeDamagedInLabour, includeDamagedInLabour) || other.includeDamagedInLabour == includeDamagedInLabour)&&(identical(other.defaultRatePaise, defaultRatePaise) || other.defaultRatePaise == defaultRatePaise)&&(identical(other.defaultPricingUnit, defaultPricingUnit) || other.defaultPricingUnit == defaultPricingUnit)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,isActive,billingModeOverride,includeDamagedInLabour,defaultRatePaise,defaultPricingUnit,createdAt,updatedAt);
}

@override
String toString() {
    return 'ProcessEntity(id: $id, name: $name, description: $description, isActive: $isActive, billingModeOverride: $billingModeOverride, includeDamagedInLabour: $includeDamagedInLabour, defaultRatePaise: $defaultRatePaise, defaultPricingUnit: $defaultPricingUnit, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProcessEntityCopyWith<$Res> implements $ProcessEntityCopyWith<$Res> {
  factory _$ProcessEntityCopyWith(_ProcessEntity value, $Res Function(_ProcessEntity) _then) = __$ProcessEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, bool isActive, ProcessBillingModeOverride? billingModeOverride, bool includeDamagedInLabour, int defaultRatePaise, String defaultPricingUnit, int createdAt, int updatedAt
});




}
/// @nodoc
class __$ProcessEntityCopyWithImpl<$Res>
    implements _$ProcessEntityCopyWith<$Res> {
  __$ProcessEntityCopyWithImpl(this._self, this._then);

  final _ProcessEntity _self;
  final $Res Function(_ProcessEntity) _then;

/// Create a copy of ProcessEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isActive = null,Object? billingModeOverride = freezed,Object? includeDamagedInLabour = null,Object? defaultRatePaise = null,Object? defaultPricingUnit = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ProcessEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,billingModeOverride: freezed == billingModeOverride ? _self.billingModeOverride : billingModeOverride // ignore: cast_nullable_to_non_nullable
as ProcessBillingModeOverride?,includeDamagedInLabour: null == includeDamagedInLabour ? _self.includeDamagedInLabour : includeDamagedInLabour // ignore: cast_nullable_to_non_nullable
as bool,defaultRatePaise: null == defaultRatePaise ? _self.defaultRatePaise : defaultRatePaise // ignore: cast_nullable_to_non_nullable
as int,defaultPricingUnit: null == defaultPricingUnit ? _self.defaultPricingUnit : defaultPricingUnit // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ProcessAuditEntry {

 String get id; String get actionType; String? get actor; String? get previousValueJson; String? get newValueJson; int get recordedAt;
/// Create a copy of ProcessAuditEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessAuditEntryCopyWith<ProcessAuditEntry> get copyWith => _$ProcessAuditEntryCopyWithImpl<ProcessAuditEntry>(this as ProcessAuditEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProcessAuditEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessAuditEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.actionType, _this.actionType) || other.actionType == _this.actionType)&&(identical(other.actor, _this.actor) || other.actor == _this.actor)&&(identical(other.previousValueJson, _this.previousValueJson) || other.previousValueJson == _this.previousValueJson)&&(identical(other.newValueJson, _this.newValueJson) || other.newValueJson == _this.newValueJson)&&(identical(other.recordedAt, _this.recordedAt) || other.recordedAt == _this.recordedAt));
}


@override
int get hashCode {
  final _this = this as ProcessAuditEntry;
  return Object.hash(runtimeType,_this.id,_this.actionType,_this.actor,_this.previousValueJson,_this.newValueJson,_this.recordedAt);
}

@override
String toString() {
  final _this = this as ProcessAuditEntry;
  return 'ProcessAuditEntry(id: ${_this.id}, actionType: ${_this.actionType}, actor: ${_this.actor}, previousValueJson: ${_this.previousValueJson}, newValueJson: ${_this.newValueJson}, recordedAt: ${_this.recordedAt})';
}


}

/// @nodoc
abstract mixin class $ProcessAuditEntryCopyWith<$Res>  {
  factory $ProcessAuditEntryCopyWith(ProcessAuditEntry value, $Res Function(ProcessAuditEntry) _then) = _$ProcessAuditEntryCopyWithImpl;
@useResult
$Res call({
 String id, String actionType, String? actor, String? previousValueJson, String? newValueJson, int recordedAt
});




}
/// @nodoc
class _$ProcessAuditEntryCopyWithImpl<$Res>
    implements $ProcessAuditEntryCopyWith<$Res> {
  _$ProcessAuditEntryCopyWithImpl(this._self, this._then);

  final ProcessAuditEntry _self;
  final $Res Function(ProcessAuditEntry) _then;

/// Create a copy of ProcessAuditEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? actionType = null,Object? actor = freezed,Object? previousValueJson = freezed,Object? newValueJson = freezed,Object? recordedAt = null,}) {
  return _then(ProcessAuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,previousValueJson: freezed == previousValueJson ? _self.previousValueJson : previousValueJson // ignore: cast_nullable_to_non_nullable
as String?,newValueJson: freezed == newValueJson ? _self.newValueJson : newValueJson // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProcessAuditEntry].
extension ProcessAuditEntryPatterns on ProcessAuditEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessAuditEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessAuditEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessAuditEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProcessAuditEntry():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessAuditEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessAuditEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String actionType,  String? actor,  String? previousValueJson,  String? newValueJson,  int recordedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessAuditEntry() when $default != null:
return $default(_that.id,_that.actionType,_that.actor,_that.previousValueJson,_that.newValueJson,_that.recordedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String actionType,  String? actor,  String? previousValueJson,  String? newValueJson,  int recordedAt)  $default,) {final _that = this;
switch (_that) {
case _ProcessAuditEntry():
return $default(_that.id,_that.actionType,_that.actor,_that.previousValueJson,_that.newValueJson,_that.recordedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String actionType,  String? actor,  String? previousValueJson,  String? newValueJson,  int recordedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProcessAuditEntry() when $default != null:
return $default(_that.id,_that.actionType,_that.actor,_that.previousValueJson,_that.newValueJson,_that.recordedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessAuditEntry implements ProcessAuditEntry {
  const _ProcessAuditEntry({required this.id, required this.actionType, this.actor, this.previousValueJson, this.newValueJson, required this.recordedAt});
  

@override final  String id;
@override final  String actionType;
@override final  String? actor;
@override final  String? previousValueJson;
@override final  String? newValueJson;
@override final  int recordedAt;

/// Create a copy of ProcessAuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessAuditEntryCopyWith<_ProcessAuditEntry> get copyWith => __$ProcessAuditEntryCopyWithImpl<_ProcessAuditEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessAuditEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.previousValueJson, previousValueJson) || other.previousValueJson == previousValueJson)&&(identical(other.newValueJson, newValueJson) || other.newValueJson == newValueJson)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,actionType,actor,previousValueJson,newValueJson,recordedAt);
}

@override
String toString() {
    return 'ProcessAuditEntry(id: $id, actionType: $actionType, actor: $actor, previousValueJson: $previousValueJson, newValueJson: $newValueJson, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class _$ProcessAuditEntryCopyWith<$Res> implements $ProcessAuditEntryCopyWith<$Res> {
  factory _$ProcessAuditEntryCopyWith(_ProcessAuditEntry value, $Res Function(_ProcessAuditEntry) _then) = __$ProcessAuditEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String actionType, String? actor, String? previousValueJson, String? newValueJson, int recordedAt
});




}
/// @nodoc
class __$ProcessAuditEntryCopyWithImpl<$Res>
    implements _$ProcessAuditEntryCopyWith<$Res> {
  __$ProcessAuditEntryCopyWithImpl(this._self, this._then);

  final _ProcessAuditEntry _self;
  final $Res Function(_ProcessAuditEntry) _then;

/// Create a copy of ProcessAuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? actionType = null,Object? actor = freezed,Object? previousValueJson = freezed,Object? newValueJson = freezed,Object? recordedAt = null,}) {
  return _then(_ProcessAuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,previousValueJson: freezed == previousValueJson ? _self.previousValueJson : previousValueJson // ignore: cast_nullable_to_non_nullable
as String?,newValueJson: freezed == newValueJson ? _self.newValueJson : newValueJson // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ProcessAssignedWorkerSummary {

 String get workerId; String get workerName; String? get workerPhone; bool get workerIsActive; int get assignedAt;
/// Create a copy of ProcessAssignedWorkerSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessAssignedWorkerSummaryCopyWith<ProcessAssignedWorkerSummary> get copyWith => _$ProcessAssignedWorkerSummaryCopyWithImpl<ProcessAssignedWorkerSummary>(this as ProcessAssignedWorkerSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProcessAssignedWorkerSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessAssignedWorkerSummary&&(identical(other.workerId, _this.workerId) || other.workerId == _this.workerId)&&(identical(other.workerName, _this.workerName) || other.workerName == _this.workerName)&&(identical(other.workerPhone, _this.workerPhone) || other.workerPhone == _this.workerPhone)&&(identical(other.workerIsActive, _this.workerIsActive) || other.workerIsActive == _this.workerIsActive)&&(identical(other.assignedAt, _this.assignedAt) || other.assignedAt == _this.assignedAt));
}


@override
int get hashCode {
  final _this = this as ProcessAssignedWorkerSummary;
  return Object.hash(runtimeType,_this.workerId,_this.workerName,_this.workerPhone,_this.workerIsActive,_this.assignedAt);
}

@override
String toString() {
  final _this = this as ProcessAssignedWorkerSummary;
  return 'ProcessAssignedWorkerSummary(workerId: ${_this.workerId}, workerName: ${_this.workerName}, workerPhone: ${_this.workerPhone}, workerIsActive: ${_this.workerIsActive}, assignedAt: ${_this.assignedAt})';
}


}

/// @nodoc
abstract mixin class $ProcessAssignedWorkerSummaryCopyWith<$Res>  {
  factory $ProcessAssignedWorkerSummaryCopyWith(ProcessAssignedWorkerSummary value, $Res Function(ProcessAssignedWorkerSummary) _then) = _$ProcessAssignedWorkerSummaryCopyWithImpl;
@useResult
$Res call({
 String workerId, String workerName, String? workerPhone, bool workerIsActive, int assignedAt
});




}
/// @nodoc
class _$ProcessAssignedWorkerSummaryCopyWithImpl<$Res>
    implements $ProcessAssignedWorkerSummaryCopyWith<$Res> {
  _$ProcessAssignedWorkerSummaryCopyWithImpl(this._self, this._then);

  final ProcessAssignedWorkerSummary _self;
  final $Res Function(ProcessAssignedWorkerSummary) _then;

/// Create a copy of ProcessAssignedWorkerSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workerId = null,Object? workerName = null,Object? workerPhone = freezed,Object? workerIsActive = null,Object? assignedAt = null,}) {
  return _then(ProcessAssignedWorkerSummary(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,workerPhone: freezed == workerPhone ? _self.workerPhone : workerPhone // ignore: cast_nullable_to_non_nullable
as String?,workerIsActive: null == workerIsActive ? _self.workerIsActive : workerIsActive // ignore: cast_nullable_to_non_nullable
as bool,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProcessAssignedWorkerSummary].
extension ProcessAssignedWorkerSummaryPatterns on ProcessAssignedWorkerSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessAssignedWorkerSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessAssignedWorkerSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessAssignedWorkerSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProcessAssignedWorkerSummary():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessAssignedWorkerSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessAssignedWorkerSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workerId,  String workerName,  String? workerPhone,  bool workerIsActive,  int assignedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessAssignedWorkerSummary() when $default != null:
return $default(_that.workerId,_that.workerName,_that.workerPhone,_that.workerIsActive,_that.assignedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workerId,  String workerName,  String? workerPhone,  bool workerIsActive,  int assignedAt)  $default,) {final _that = this;
switch (_that) {
case _ProcessAssignedWorkerSummary():
return $default(_that.workerId,_that.workerName,_that.workerPhone,_that.workerIsActive,_that.assignedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workerId,  String workerName,  String? workerPhone,  bool workerIsActive,  int assignedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProcessAssignedWorkerSummary() when $default != null:
return $default(_that.workerId,_that.workerName,_that.workerPhone,_that.workerIsActive,_that.assignedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessAssignedWorkerSummary implements ProcessAssignedWorkerSummary {
  const _ProcessAssignedWorkerSummary({required this.workerId, required this.workerName, this.workerPhone, required this.workerIsActive, required this.assignedAt});
  

@override final  String workerId;
@override final  String workerName;
@override final  String? workerPhone;
@override final  bool workerIsActive;
@override final  int assignedAt;

/// Create a copy of ProcessAssignedWorkerSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessAssignedWorkerSummaryCopyWith<_ProcessAssignedWorkerSummary> get copyWith => __$ProcessAssignedWorkerSummaryCopyWithImpl<_ProcessAssignedWorkerSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessAssignedWorkerSummary&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.workerName, workerName) || other.workerName == workerName)&&(identical(other.workerPhone, workerPhone) || other.workerPhone == workerPhone)&&(identical(other.workerIsActive, workerIsActive) || other.workerIsActive == workerIsActive)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,workerId,workerName,workerPhone,workerIsActive,assignedAt);
}

@override
String toString() {
    return 'ProcessAssignedWorkerSummary(workerId: $workerId, workerName: $workerName, workerPhone: $workerPhone, workerIsActive: $workerIsActive, assignedAt: $assignedAt)';
}


}

/// @nodoc
abstract mixin class _$ProcessAssignedWorkerSummaryCopyWith<$Res> implements $ProcessAssignedWorkerSummaryCopyWith<$Res> {
  factory _$ProcessAssignedWorkerSummaryCopyWith(_ProcessAssignedWorkerSummary value, $Res Function(_ProcessAssignedWorkerSummary) _then) = __$ProcessAssignedWorkerSummaryCopyWithImpl;
@override @useResult
$Res call({
 String workerId, String workerName, String? workerPhone, bool workerIsActive, int assignedAt
});




}
/// @nodoc
class __$ProcessAssignedWorkerSummaryCopyWithImpl<$Res>
    implements _$ProcessAssignedWorkerSummaryCopyWith<$Res> {
  __$ProcessAssignedWorkerSummaryCopyWithImpl(this._self, this._then);

  final _ProcessAssignedWorkerSummary _self;
  final $Res Function(_ProcessAssignedWorkerSummary) _then;

/// Create a copy of ProcessAssignedWorkerSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workerId = null,Object? workerName = null,Object? workerPhone = freezed,Object? workerIsActive = null,Object? assignedAt = null,}) {
  return _then(_ProcessAssignedWorkerSummary(
workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,workerName: null == workerName ? _self.workerName : workerName // ignore: cast_nullable_to_non_nullable
as String,workerPhone: freezed == workerPhone ? _self.workerPhone : workerPhone // ignore: cast_nullable_to_non_nullable
as String?,workerIsActive: null == workerIsActive ? _self.workerIsActive : workerIsActive // ignore: cast_nullable_to_non_nullable
as bool,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ProcessDetailAggregate {

 ProcessEntity get process; List<ProcessAssignedWorkerSummary> get assignedWorkers; List<ProcessAuditEntry> get auditHistory;
/// Create a copy of ProcessDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessDetailAggregateCopyWith<ProcessDetailAggregate> get copyWith => _$ProcessDetailAggregateCopyWithImpl<ProcessDetailAggregate>(this as ProcessDetailAggregate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProcessDetailAggregate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessDetailAggregate&&(identical(other.process, _this.process) || other.process == _this.process)&&const DeepCollectionEquality().equals(other.assignedWorkers, _this.assignedWorkers)&&const DeepCollectionEquality().equals(other.auditHistory, _this.auditHistory));
}


@override
int get hashCode {
  final _this = this as ProcessDetailAggregate;
  return Object.hash(runtimeType,_this.process,const DeepCollectionEquality().hash(_this.assignedWorkers),const DeepCollectionEquality().hash(_this.auditHistory));
}

@override
String toString() {
  final _this = this as ProcessDetailAggregate;
  return 'ProcessDetailAggregate(process: ${_this.process}, assignedWorkers: ${_this.assignedWorkers}, auditHistory: ${_this.auditHistory})';
}


}

/// @nodoc
abstract mixin class $ProcessDetailAggregateCopyWith<$Res>  {
  factory $ProcessDetailAggregateCopyWith(ProcessDetailAggregate value, $Res Function(ProcessDetailAggregate) _then) = _$ProcessDetailAggregateCopyWithImpl;
@useResult
$Res call({
 ProcessEntity process, List<ProcessAssignedWorkerSummary> assignedWorkers, List<ProcessAuditEntry> auditHistory
});


$ProcessEntityCopyWith<$Res> get process;

}
/// @nodoc
class _$ProcessDetailAggregateCopyWithImpl<$Res>
    implements $ProcessDetailAggregateCopyWith<$Res> {
  _$ProcessDetailAggregateCopyWithImpl(this._self, this._then);

  final ProcessDetailAggregate _self;
  final $Res Function(ProcessDetailAggregate) _then;

/// Create a copy of ProcessDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? process = null,Object? assignedWorkers = null,Object? auditHistory = null,}) {
  return _then(ProcessDetailAggregate(
process: null == process ? _self.process : process // ignore: cast_nullable_to_non_nullable
as ProcessEntity,assignedWorkers: null == assignedWorkers ? _self.assignedWorkers : assignedWorkers // ignore: cast_nullable_to_non_nullable
as List<ProcessAssignedWorkerSummary>,auditHistory: null == auditHistory ? _self.auditHistory : auditHistory // ignore: cast_nullable_to_non_nullable
as List<ProcessAuditEntry>,
  ));
}
/// Create a copy of ProcessDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProcessEntityCopyWith<$Res> get process {
  
  return $ProcessEntityCopyWith<$Res>(_self.process, (value) {
    return _then(_self.copyWith(process: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProcessDetailAggregate].
extension ProcessDetailAggregatePatterns on ProcessDetailAggregate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessDetailAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessDetailAggregate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessDetailAggregate value)  $default,){
final _that = this;
switch (_that) {
case _ProcessDetailAggregate():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessDetailAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessDetailAggregate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProcessEntity process,  List<ProcessAssignedWorkerSummary> assignedWorkers,  List<ProcessAuditEntry> auditHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessDetailAggregate() when $default != null:
return $default(_that.process,_that.assignedWorkers,_that.auditHistory);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProcessEntity process,  List<ProcessAssignedWorkerSummary> assignedWorkers,  List<ProcessAuditEntry> auditHistory)  $default,) {final _that = this;
switch (_that) {
case _ProcessDetailAggregate():
return $default(_that.process,_that.assignedWorkers,_that.auditHistory);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProcessEntity process,  List<ProcessAssignedWorkerSummary> assignedWorkers,  List<ProcessAuditEntry> auditHistory)?  $default,) {final _that = this;
switch (_that) {
case _ProcessDetailAggregate() when $default != null:
return $default(_that.process,_that.assignedWorkers,_that.auditHistory);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessDetailAggregate implements ProcessDetailAggregate {
  const _ProcessDetailAggregate({required this.process, required  List<ProcessAssignedWorkerSummary> assignedWorkers, required  List<ProcessAuditEntry> auditHistory}): _assignedWorkers = assignedWorkers,_auditHistory = auditHistory;
  

@override final  ProcessEntity process;
 final  List<ProcessAssignedWorkerSummary> _assignedWorkers;
@override List<ProcessAssignedWorkerSummary> get assignedWorkers {
  if (_assignedWorkers is EqualUnmodifiableListView) return _assignedWorkers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignedWorkers);
}

 final  List<ProcessAuditEntry> _auditHistory;
@override List<ProcessAuditEntry> get auditHistory {
  if (_auditHistory is EqualUnmodifiableListView) return _auditHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_auditHistory);
}


/// Create a copy of ProcessDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessDetailAggregateCopyWith<_ProcessDetailAggregate> get copyWith => __$ProcessDetailAggregateCopyWithImpl<_ProcessDetailAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessDetailAggregate&&(identical(other.process, process) || other.process == process)&&const DeepCollectionEquality().equals(other.assignedWorkers, _assignedWorkers)&&const DeepCollectionEquality().equals(other.auditHistory, _auditHistory));
}


@override
int get hashCode {
    return Object.hash(runtimeType,process,const DeepCollectionEquality().hash(_assignedWorkers),const DeepCollectionEquality().hash(_auditHistory));
}

@override
String toString() {
    return 'ProcessDetailAggregate(process: $process, assignedWorkers: $assignedWorkers, auditHistory: $auditHistory)';
}


}

/// @nodoc
abstract mixin class _$ProcessDetailAggregateCopyWith<$Res> implements $ProcessDetailAggregateCopyWith<$Res> {
  factory _$ProcessDetailAggregateCopyWith(_ProcessDetailAggregate value, $Res Function(_ProcessDetailAggregate) _then) = __$ProcessDetailAggregateCopyWithImpl;
@override @useResult
$Res call({
 ProcessEntity process, List<ProcessAssignedWorkerSummary> assignedWorkers, List<ProcessAuditEntry> auditHistory
});


@override $ProcessEntityCopyWith<$Res> get process;

}
/// @nodoc
class __$ProcessDetailAggregateCopyWithImpl<$Res>
    implements _$ProcessDetailAggregateCopyWith<$Res> {
  __$ProcessDetailAggregateCopyWithImpl(this._self, this._then);

  final _ProcessDetailAggregate _self;
  final $Res Function(_ProcessDetailAggregate) _then;

/// Create a copy of ProcessDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? process = null,Object? assignedWorkers = null,Object? auditHistory = null,}) {
  return _then(_ProcessDetailAggregate(
process: null == process ? _self.process : process // ignore: cast_nullable_to_non_nullable
as ProcessEntity,assignedWorkers: null == assignedWorkers ? _self._assignedWorkers : assignedWorkers // ignore: cast_nullable_to_non_nullable
as List<ProcessAssignedWorkerSummary>,auditHistory: null == auditHistory ? _self._auditHistory : auditHistory // ignore: cast_nullable_to_non_nullable
as List<ProcessAuditEntry>,
  ));
}

/// Create a copy of ProcessDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProcessEntityCopyWith<$Res> get process {
  
  return $ProcessEntityCopyWith<$Res>(_self.process, (value) {
    return _then(_self.copyWith(process: value));
  });
}
}

// dart format on
