// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'worker_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkerEntity {

 String get id; String get name; String? get phone; String? get address; String? get notes; bool get isActive; int get createdAt; int get updatedAt;
/// Create a copy of WorkerEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerEntityCopyWith<WorkerEntity> get copyWith => _$WorkerEntityCopyWithImpl<WorkerEntity>(this as WorkerEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkerEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as WorkerEntity;
  return Object.hash(runtimeType,_this.id,_this.name,_this.phone,_this.address,_this.notes,_this.isActive,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as WorkerEntity;
  return 'WorkerEntity(id: ${_this.id}, name: ${_this.name}, phone: ${_this.phone}, address: ${_this.address}, notes: ${_this.notes}, isActive: ${_this.isActive}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $WorkerEntityCopyWith<$Res>  {
  factory $WorkerEntityCopyWith(WorkerEntity value, $Res Function(WorkerEntity) _then) = _$WorkerEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? phone, String? address, String? notes, bool isActive, int createdAt, int updatedAt
});




}
/// @nodoc
class _$WorkerEntityCopyWithImpl<$Res>
    implements $WorkerEntityCopyWith<$Res> {
  _$WorkerEntityCopyWithImpl(this._self, this._then);

  final WorkerEntity _self;
  final $Res Function(WorkerEntity) _then;

/// Create a copy of WorkerEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = freezed,Object? address = freezed,Object? notes = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(WorkerEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkerEntity].
extension WorkerEntityPatterns on WorkerEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerEntity value)  $default,){
final _that = this;
switch (_that) {
case _WorkerEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? phone,  String? address,  String? notes,  bool isActive,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerEntity() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.address,_that.notes,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? phone,  String? address,  String? notes,  bool isActive,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkerEntity():
return $default(_that.id,_that.name,_that.phone,_that.address,_that.notes,_that.isActive,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? phone,  String? address,  String? notes,  bool isActive,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkerEntity() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.address,_that.notes,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _WorkerEntity implements WorkerEntity {
  const _WorkerEntity({required this.id, required this.name, this.phone, this.address, this.notes, required this.isActive, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String name;
@override final  String? phone;
@override final  String? address;
@override final  String? notes;
@override final  bool isActive;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of WorkerEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerEntityCopyWith<_WorkerEntity> get copyWith => __$WorkerEntityCopyWithImpl<_WorkerEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,phone,address,notes,isActive,createdAt,updatedAt);
}

@override
String toString() {
    return 'WorkerEntity(id: $id, name: $name, phone: $phone, address: $address, notes: $notes, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkerEntityCopyWith<$Res> implements $WorkerEntityCopyWith<$Res> {
  factory _$WorkerEntityCopyWith(_WorkerEntity value, $Res Function(_WorkerEntity) _then) = __$WorkerEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? phone, String? address, String? notes, bool isActive, int createdAt, int updatedAt
});




}
/// @nodoc
class __$WorkerEntityCopyWithImpl<$Res>
    implements _$WorkerEntityCopyWith<$Res> {
  __$WorkerEntityCopyWithImpl(this._self, this._then);

  final _WorkerEntity _self;
  final $Res Function(_WorkerEntity) _then;

/// Create a copy of WorkerEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = freezed,Object? address = freezed,Object? notes = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_WorkerEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$WorkerProcessAssignmentEntity {

 String get id; String get workerId; String get processId; String get processName; bool get processIsActive; bool get isActive; int get createdAt; int get updatedAt;
/// Create a copy of WorkerProcessAssignmentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerProcessAssignmentEntityCopyWith<WorkerProcessAssignmentEntity> get copyWith => _$WorkerProcessAssignmentEntityCopyWithImpl<WorkerProcessAssignmentEntity>(this as WorkerProcessAssignmentEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkerProcessAssignmentEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerProcessAssignmentEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.workerId, _this.workerId) || other.workerId == _this.workerId)&&(identical(other.processId, _this.processId) || other.processId == _this.processId)&&(identical(other.processName, _this.processName) || other.processName == _this.processName)&&(identical(other.processIsActive, _this.processIsActive) || other.processIsActive == _this.processIsActive)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as WorkerProcessAssignmentEntity;
  return Object.hash(runtimeType,_this.id,_this.workerId,_this.processId,_this.processName,_this.processIsActive,_this.isActive,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as WorkerProcessAssignmentEntity;
  return 'WorkerProcessAssignmentEntity(id: ${_this.id}, workerId: ${_this.workerId}, processId: ${_this.processId}, processName: ${_this.processName}, processIsActive: ${_this.processIsActive}, isActive: ${_this.isActive}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $WorkerProcessAssignmentEntityCopyWith<$Res>  {
  factory $WorkerProcessAssignmentEntityCopyWith(WorkerProcessAssignmentEntity value, $Res Function(WorkerProcessAssignmentEntity) _then) = _$WorkerProcessAssignmentEntityCopyWithImpl;
@useResult
$Res call({
 String id, String workerId, String processId, String processName, bool processIsActive, bool isActive, int createdAt, int updatedAt
});




}
/// @nodoc
class _$WorkerProcessAssignmentEntityCopyWithImpl<$Res>
    implements $WorkerProcessAssignmentEntityCopyWith<$Res> {
  _$WorkerProcessAssignmentEntityCopyWithImpl(this._self, this._then);

  final WorkerProcessAssignmentEntity _self;
  final $Res Function(WorkerProcessAssignmentEntity) _then;

/// Create a copy of WorkerProcessAssignmentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workerId = null,Object? processId = null,Object? processName = null,Object? processIsActive = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(WorkerProcessAssignmentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,processId: null == processId ? _self.processId : processId // ignore: cast_nullable_to_non_nullable
as String,processName: null == processName ? _self.processName : processName // ignore: cast_nullable_to_non_nullable
as String,processIsActive: null == processIsActive ? _self.processIsActive : processIsActive // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkerProcessAssignmentEntity].
extension WorkerProcessAssignmentEntityPatterns on WorkerProcessAssignmentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerProcessAssignmentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerProcessAssignmentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerProcessAssignmentEntity value)  $default,){
final _that = this;
switch (_that) {
case _WorkerProcessAssignmentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerProcessAssignmentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerProcessAssignmentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workerId,  String processId,  String processName,  bool processIsActive,  bool isActive,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerProcessAssignmentEntity() when $default != null:
return $default(_that.id,_that.workerId,_that.processId,_that.processName,_that.processIsActive,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workerId,  String processId,  String processName,  bool processIsActive,  bool isActive,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkerProcessAssignmentEntity():
return $default(_that.id,_that.workerId,_that.processId,_that.processName,_that.processIsActive,_that.isActive,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workerId,  String processId,  String processName,  bool processIsActive,  bool isActive,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkerProcessAssignmentEntity() when $default != null:
return $default(_that.id,_that.workerId,_that.processId,_that.processName,_that.processIsActive,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _WorkerProcessAssignmentEntity implements WorkerProcessAssignmentEntity {
  const _WorkerProcessAssignmentEntity({required this.id, required this.workerId, required this.processId, required this.processName, required this.processIsActive, required this.isActive, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String workerId;
@override final  String processId;
@override final  String processName;
@override final  bool processIsActive;
@override final  bool isActive;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of WorkerProcessAssignmentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerProcessAssignmentEntityCopyWith<_WorkerProcessAssignmentEntity> get copyWith => __$WorkerProcessAssignmentEntityCopyWithImpl<_WorkerProcessAssignmentEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerProcessAssignmentEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.workerId, workerId) || other.workerId == workerId)&&(identical(other.processId, processId) || other.processId == processId)&&(identical(other.processName, processName) || other.processName == processName)&&(identical(other.processIsActive, processIsActive) || other.processIsActive == processIsActive)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,workerId,processId,processName,processIsActive,isActive,createdAt,updatedAt);
}

@override
String toString() {
    return 'WorkerProcessAssignmentEntity(id: $id, workerId: $workerId, processId: $processId, processName: $processName, processIsActive: $processIsActive, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkerProcessAssignmentEntityCopyWith<$Res> implements $WorkerProcessAssignmentEntityCopyWith<$Res> {
  factory _$WorkerProcessAssignmentEntityCopyWith(_WorkerProcessAssignmentEntity value, $Res Function(_WorkerProcessAssignmentEntity) _then) = __$WorkerProcessAssignmentEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String workerId, String processId, String processName, bool processIsActive, bool isActive, int createdAt, int updatedAt
});




}
/// @nodoc
class __$WorkerProcessAssignmentEntityCopyWithImpl<$Res>
    implements _$WorkerProcessAssignmentEntityCopyWith<$Res> {
  __$WorkerProcessAssignmentEntityCopyWithImpl(this._self, this._then);

  final _WorkerProcessAssignmentEntity _self;
  final $Res Function(_WorkerProcessAssignmentEntity) _then;

/// Create a copy of WorkerProcessAssignmentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workerId = null,Object? processId = null,Object? processName = null,Object? processIsActive = null,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_WorkerProcessAssignmentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workerId: null == workerId ? _self.workerId : workerId // ignore: cast_nullable_to_non_nullable
as String,processId: null == processId ? _self.processId : processId // ignore: cast_nullable_to_non_nullable
as String,processName: null == processName ? _self.processName : processName // ignore: cast_nullable_to_non_nullable
as String,processIsActive: null == processIsActive ? _self.processIsActive : processIsActive // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$WorkerProcessRateSummary {

 WorkerProcessAssignmentEntity get assignment; MemberProcessRateEntity? get currentRate; int get totalRateHistoryCount;
/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerProcessRateSummaryCopyWith<WorkerProcessRateSummary> get copyWith => _$WorkerProcessRateSummaryCopyWithImpl<WorkerProcessRateSummary>(this as WorkerProcessRateSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkerProcessRateSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerProcessRateSummary&&(identical(other.assignment, _this.assignment) || other.assignment == _this.assignment)&&(identical(other.currentRate, _this.currentRate) || other.currentRate == _this.currentRate)&&(identical(other.totalRateHistoryCount, _this.totalRateHistoryCount) || other.totalRateHistoryCount == _this.totalRateHistoryCount));
}


@override
int get hashCode {
  final _this = this as WorkerProcessRateSummary;
  return Object.hash(runtimeType,_this.assignment,_this.currentRate,_this.totalRateHistoryCount);
}

@override
String toString() {
  final _this = this as WorkerProcessRateSummary;
  return 'WorkerProcessRateSummary(assignment: ${_this.assignment}, currentRate: ${_this.currentRate}, totalRateHistoryCount: ${_this.totalRateHistoryCount})';
}


}

/// @nodoc
abstract mixin class $WorkerProcessRateSummaryCopyWith<$Res>  {
  factory $WorkerProcessRateSummaryCopyWith(WorkerProcessRateSummary value, $Res Function(WorkerProcessRateSummary) _then) = _$WorkerProcessRateSummaryCopyWithImpl;
@useResult
$Res call({
 WorkerProcessAssignmentEntity assignment, MemberProcessRateEntity? currentRate, int totalRateHistoryCount
});


$WorkerProcessAssignmentEntityCopyWith<$Res> get assignment;$MemberProcessRateEntityCopyWith<$Res>? get currentRate;

}
/// @nodoc
class _$WorkerProcessRateSummaryCopyWithImpl<$Res>
    implements $WorkerProcessRateSummaryCopyWith<$Res> {
  _$WorkerProcessRateSummaryCopyWithImpl(this._self, this._then);

  final WorkerProcessRateSummary _self;
  final $Res Function(WorkerProcessRateSummary) _then;

/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assignment = null,Object? currentRate = freezed,Object? totalRateHistoryCount = null,}) {
  return _then(WorkerProcessRateSummary(
assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as WorkerProcessAssignmentEntity,currentRate: freezed == currentRate ? _self.currentRate : currentRate // ignore: cast_nullable_to_non_nullable
as MemberProcessRateEntity?,totalRateHistoryCount: null == totalRateHistoryCount ? _self.totalRateHistoryCount : totalRateHistoryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerProcessAssignmentEntityCopyWith<$Res> get assignment {
  
  return $WorkerProcessAssignmentEntityCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberProcessRateEntityCopyWith<$Res>? get currentRate {
    if (_self.currentRate == null) {
    return null;
  }

  return $MemberProcessRateEntityCopyWith<$Res>(_self.currentRate!, (value) {
    return _then(_self.copyWith(currentRate: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkerProcessRateSummary].
extension WorkerProcessRateSummaryPatterns on WorkerProcessRateSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerProcessRateSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerProcessRateSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerProcessRateSummary value)  $default,){
final _that = this;
switch (_that) {
case _WorkerProcessRateSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerProcessRateSummary value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerProcessRateSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkerProcessAssignmentEntity assignment,  MemberProcessRateEntity? currentRate,  int totalRateHistoryCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerProcessRateSummary() when $default != null:
return $default(_that.assignment,_that.currentRate,_that.totalRateHistoryCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkerProcessAssignmentEntity assignment,  MemberProcessRateEntity? currentRate,  int totalRateHistoryCount)  $default,) {final _that = this;
switch (_that) {
case _WorkerProcessRateSummary():
return $default(_that.assignment,_that.currentRate,_that.totalRateHistoryCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkerProcessAssignmentEntity assignment,  MemberProcessRateEntity? currentRate,  int totalRateHistoryCount)?  $default,) {final _that = this;
switch (_that) {
case _WorkerProcessRateSummary() when $default != null:
return $default(_that.assignment,_that.currentRate,_that.totalRateHistoryCount);case _:
  return null;

}
}

}

/// @nodoc


class _WorkerProcessRateSummary implements WorkerProcessRateSummary {
  const _WorkerProcessRateSummary({required this.assignment, this.currentRate, required this.totalRateHistoryCount});
  

@override final  WorkerProcessAssignmentEntity assignment;
@override final  MemberProcessRateEntity? currentRate;
@override final  int totalRateHistoryCount;

/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerProcessRateSummaryCopyWith<_WorkerProcessRateSummary> get copyWith => __$WorkerProcessRateSummaryCopyWithImpl<_WorkerProcessRateSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerProcessRateSummary&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.currentRate, currentRate) || other.currentRate == currentRate)&&(identical(other.totalRateHistoryCount, totalRateHistoryCount) || other.totalRateHistoryCount == totalRateHistoryCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,assignment,currentRate,totalRateHistoryCount);
}

@override
String toString() {
    return 'WorkerProcessRateSummary(assignment: $assignment, currentRate: $currentRate, totalRateHistoryCount: $totalRateHistoryCount)';
}


}

/// @nodoc
abstract mixin class _$WorkerProcessRateSummaryCopyWith<$Res> implements $WorkerProcessRateSummaryCopyWith<$Res> {
  factory _$WorkerProcessRateSummaryCopyWith(_WorkerProcessRateSummary value, $Res Function(_WorkerProcessRateSummary) _then) = __$WorkerProcessRateSummaryCopyWithImpl;
@override @useResult
$Res call({
 WorkerProcessAssignmentEntity assignment, MemberProcessRateEntity? currentRate, int totalRateHistoryCount
});


@override $WorkerProcessAssignmentEntityCopyWith<$Res> get assignment;@override $MemberProcessRateEntityCopyWith<$Res>? get currentRate;

}
/// @nodoc
class __$WorkerProcessRateSummaryCopyWithImpl<$Res>
    implements _$WorkerProcessRateSummaryCopyWith<$Res> {
  __$WorkerProcessRateSummaryCopyWithImpl(this._self, this._then);

  final _WorkerProcessRateSummary _self;
  final $Res Function(_WorkerProcessRateSummary) _then;

/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assignment = null,Object? currentRate = freezed,Object? totalRateHistoryCount = null,}) {
  return _then(_WorkerProcessRateSummary(
assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as WorkerProcessAssignmentEntity,currentRate: freezed == currentRate ? _self.currentRate : currentRate // ignore: cast_nullable_to_non_nullable
as MemberProcessRateEntity?,totalRateHistoryCount: null == totalRateHistoryCount ? _self.totalRateHistoryCount : totalRateHistoryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerProcessAssignmentEntityCopyWith<$Res> get assignment {
  
  return $WorkerProcessAssignmentEntityCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of WorkerProcessRateSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MemberProcessRateEntityCopyWith<$Res>? get currentRate {
    if (_self.currentRate == null) {
    return null;
  }

  return $MemberProcessRateEntityCopyWith<$Res>(_self.currentRate!, (value) {
    return _then(_self.copyWith(currentRate: value));
  });
}
}

/// @nodoc
mixin _$WorkerDetailAggregate {

 WorkerEntity get worker; List<WorkerProcessRateSummary> get assignedProcesses; List<MemberProcessRateEntity> get allRates;
/// Create a copy of WorkerDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerDetailAggregateCopyWith<WorkerDetailAggregate> get copyWith => _$WorkerDetailAggregateCopyWithImpl<WorkerDetailAggregate>(this as WorkerDetailAggregate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkerDetailAggregate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerDetailAggregate&&(identical(other.worker, _this.worker) || other.worker == _this.worker)&&const DeepCollectionEquality().equals(other.assignedProcesses, _this.assignedProcesses)&&const DeepCollectionEquality().equals(other.allRates, _this.allRates));
}


@override
int get hashCode {
  final _this = this as WorkerDetailAggregate;
  return Object.hash(runtimeType,_this.worker,const DeepCollectionEquality().hash(_this.assignedProcesses),const DeepCollectionEquality().hash(_this.allRates));
}

@override
String toString() {
  final _this = this as WorkerDetailAggregate;
  return 'WorkerDetailAggregate(worker: ${_this.worker}, assignedProcesses: ${_this.assignedProcesses}, allRates: ${_this.allRates})';
}


}

/// @nodoc
abstract mixin class $WorkerDetailAggregateCopyWith<$Res>  {
  factory $WorkerDetailAggregateCopyWith(WorkerDetailAggregate value, $Res Function(WorkerDetailAggregate) _then) = _$WorkerDetailAggregateCopyWithImpl;
@useResult
$Res call({
 WorkerEntity worker, List<WorkerProcessRateSummary> assignedProcesses, List<MemberProcessRateEntity> allRates
});


$WorkerEntityCopyWith<$Res> get worker;

}
/// @nodoc
class _$WorkerDetailAggregateCopyWithImpl<$Res>
    implements $WorkerDetailAggregateCopyWith<$Res> {
  _$WorkerDetailAggregateCopyWithImpl(this._self, this._then);

  final WorkerDetailAggregate _self;
  final $Res Function(WorkerDetailAggregate) _then;

/// Create a copy of WorkerDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? worker = null,Object? assignedProcesses = null,Object? allRates = null,}) {
  return _then(WorkerDetailAggregate(
worker: null == worker ? _self.worker : worker // ignore: cast_nullable_to_non_nullable
as WorkerEntity,assignedProcesses: null == assignedProcesses ? _self.assignedProcesses : assignedProcesses // ignore: cast_nullable_to_non_nullable
as List<WorkerProcessRateSummary>,allRates: null == allRates ? _self.allRates : allRates // ignore: cast_nullable_to_non_nullable
as List<MemberProcessRateEntity>,
  ));
}
/// Create a copy of WorkerDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerEntityCopyWith<$Res> get worker {
  
  return $WorkerEntityCopyWith<$Res>(_self.worker, (value) {
    return _then(_self.copyWith(worker: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkerDetailAggregate].
extension WorkerDetailAggregatePatterns on WorkerDetailAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerDetailAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerDetailAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerDetailAggregate value)  $default,){
final _that = this;
switch (_that) {
case _WorkerDetailAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerDetailAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerDetailAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkerEntity worker,  List<WorkerProcessRateSummary> assignedProcesses,  List<MemberProcessRateEntity> allRates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerDetailAggregate() when $default != null:
return $default(_that.worker,_that.assignedProcesses,_that.allRates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkerEntity worker,  List<WorkerProcessRateSummary> assignedProcesses,  List<MemberProcessRateEntity> allRates)  $default,) {final _that = this;
switch (_that) {
case _WorkerDetailAggregate():
return $default(_that.worker,_that.assignedProcesses,_that.allRates);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkerEntity worker,  List<WorkerProcessRateSummary> assignedProcesses,  List<MemberProcessRateEntity> allRates)?  $default,) {final _that = this;
switch (_that) {
case _WorkerDetailAggregate() when $default != null:
return $default(_that.worker,_that.assignedProcesses,_that.allRates);case _:
  return null;

}
}

}

/// @nodoc


class _WorkerDetailAggregate implements WorkerDetailAggregate {
  const _WorkerDetailAggregate({required this.worker, required  List<WorkerProcessRateSummary> assignedProcesses, required  List<MemberProcessRateEntity> allRates}): _assignedProcesses = assignedProcesses,_allRates = allRates;
  

@override final  WorkerEntity worker;
 final  List<WorkerProcessRateSummary> _assignedProcesses;
@override List<WorkerProcessRateSummary> get assignedProcesses {
  if (_assignedProcesses is EqualUnmodifiableListView) return _assignedProcesses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignedProcesses);
}

 final  List<MemberProcessRateEntity> _allRates;
@override List<MemberProcessRateEntity> get allRates {
  if (_allRates is EqualUnmodifiableListView) return _allRates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allRates);
}


/// Create a copy of WorkerDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerDetailAggregateCopyWith<_WorkerDetailAggregate> get copyWith => __$WorkerDetailAggregateCopyWithImpl<_WorkerDetailAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerDetailAggregate&&(identical(other.worker, worker) || other.worker == worker)&&const DeepCollectionEquality().equals(other.assignedProcesses, _assignedProcesses)&&const DeepCollectionEquality().equals(other.allRates, _allRates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,worker,const DeepCollectionEquality().hash(_assignedProcesses),const DeepCollectionEquality().hash(_allRates));
}

@override
String toString() {
    return 'WorkerDetailAggregate(worker: $worker, assignedProcesses: $assignedProcesses, allRates: $allRates)';
}


}

/// @nodoc
abstract mixin class _$WorkerDetailAggregateCopyWith<$Res> implements $WorkerDetailAggregateCopyWith<$Res> {
  factory _$WorkerDetailAggregateCopyWith(_WorkerDetailAggregate value, $Res Function(_WorkerDetailAggregate) _then) = __$WorkerDetailAggregateCopyWithImpl;
@override @useResult
$Res call({
 WorkerEntity worker, List<WorkerProcessRateSummary> assignedProcesses, List<MemberProcessRateEntity> allRates
});


@override $WorkerEntityCopyWith<$Res> get worker;

}
/// @nodoc
class __$WorkerDetailAggregateCopyWithImpl<$Res>
    implements _$WorkerDetailAggregateCopyWith<$Res> {
  __$WorkerDetailAggregateCopyWithImpl(this._self, this._then);

  final _WorkerDetailAggregate _self;
  final $Res Function(_WorkerDetailAggregate) _then;

/// Create a copy of WorkerDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? worker = null,Object? assignedProcesses = null,Object? allRates = null,}) {
  return _then(_WorkerDetailAggregate(
worker: null == worker ? _self.worker : worker // ignore: cast_nullable_to_non_nullable
as WorkerEntity,assignedProcesses: null == assignedProcesses ? _self._assignedProcesses : assignedProcesses // ignore: cast_nullable_to_non_nullable
as List<WorkerProcessRateSummary>,allRates: null == allRates ? _self._allRates : allRates // ignore: cast_nullable_to_non_nullable
as List<MemberProcessRateEntity>,
  ));
}

/// Create a copy of WorkerDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerEntityCopyWith<$Res> get worker {
  
  return $WorkerEntityCopyWith<$Res>(_self.worker, (value) {
    return _then(_self.copyWith(worker: value));
  });
}
}

// dart format on
