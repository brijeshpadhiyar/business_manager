// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lot_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LotEntity {

 String get id; String get lotNumber; String? get title; String? get notes; LotStatus get status; int get transactionAt; int get recordedAt; int get createdAt; int get updatedAt;
/// Create a copy of LotEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotEntityCopyWith<LotEntity> get copyWith => _$LotEntityCopyWithImpl<LotEntity>(this as LotEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LotEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LotEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.lotNumber, _this.lotNumber) || other.lotNumber == _this.lotNumber)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.transactionAt, _this.transactionAt) || other.transactionAt == _this.transactionAt)&&(identical(other.recordedAt, _this.recordedAt) || other.recordedAt == _this.recordedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as LotEntity;
  return Object.hash(runtimeType,_this.id,_this.lotNumber,_this.title,_this.notes,_this.status,_this.transactionAt,_this.recordedAt,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as LotEntity;
  return 'LotEntity(id: ${_this.id}, lotNumber: ${_this.lotNumber}, title: ${_this.title}, notes: ${_this.notes}, status: ${_this.status}, transactionAt: ${_this.transactionAt}, recordedAt: ${_this.recordedAt}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $LotEntityCopyWith<$Res>  {
  factory $LotEntityCopyWith(LotEntity value, $Res Function(LotEntity) _then) = _$LotEntityCopyWithImpl;
@useResult
$Res call({
 String id, String lotNumber, String? title, String? notes, LotStatus status, int transactionAt, int recordedAt, int createdAt, int updatedAt
});




}
/// @nodoc
class _$LotEntityCopyWithImpl<$Res>
    implements $LotEntityCopyWith<$Res> {
  _$LotEntityCopyWithImpl(this._self, this._then);

  final LotEntity _self;
  final $Res Function(LotEntity) _then;

/// Create a copy of LotEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lotNumber = null,Object? title = freezed,Object? notes = freezed,Object? status = null,Object? transactionAt = null,Object? recordedAt = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(LotEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotNumber: null == lotNumber ? _self.lotNumber : lotNumber // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LotStatus,transactionAt: null == transactionAt ? _self.transactionAt : transactionAt // ignore: cast_nullable_to_non_nullable
as int,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LotEntity].
extension LotEntityPatterns on LotEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LotEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LotEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LotEntity value)  $default,){
final _that = this;
switch (_that) {
case _LotEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LotEntity value)?  $default,){
final _that = this;
switch (_that) {
case _LotEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String lotNumber,  String? title,  String? notes,  LotStatus status,  int transactionAt,  int recordedAt,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LotEntity() when $default != null:
return $default(_that.id,_that.lotNumber,_that.title,_that.notes,_that.status,_that.transactionAt,_that.recordedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String lotNumber,  String? title,  String? notes,  LotStatus status,  int transactionAt,  int recordedAt,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LotEntity():
return $default(_that.id,_that.lotNumber,_that.title,_that.notes,_that.status,_that.transactionAt,_that.recordedAt,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String lotNumber,  String? title,  String? notes,  LotStatus status,  int transactionAt,  int recordedAt,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LotEntity() when $default != null:
return $default(_that.id,_that.lotNumber,_that.title,_that.notes,_that.status,_that.transactionAt,_that.recordedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _LotEntity implements LotEntity {
  const _LotEntity({required this.id, required this.lotNumber, this.title, this.notes, required this.status, required this.transactionAt, required this.recordedAt, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String lotNumber;
@override final  String? title;
@override final  String? notes;
@override final  LotStatus status;
@override final  int transactionAt;
@override final  int recordedAt;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of LotEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotEntityCopyWith<_LotEntity> get copyWith => __$LotEntityCopyWithImpl<_LotEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LotEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.lotNumber, lotNumber) || other.lotNumber == lotNumber)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.transactionAt, transactionAt) || other.transactionAt == transactionAt)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,lotNumber,title,notes,status,transactionAt,recordedAt,createdAt,updatedAt);
}

@override
String toString() {
    return 'LotEntity(id: $id, lotNumber: $lotNumber, title: $title, notes: $notes, status: $status, transactionAt: $transactionAt, recordedAt: $recordedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LotEntityCopyWith<$Res> implements $LotEntityCopyWith<$Res> {
  factory _$LotEntityCopyWith(_LotEntity value, $Res Function(_LotEntity) _then) = __$LotEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String lotNumber, String? title, String? notes, LotStatus status, int transactionAt, int recordedAt, int createdAt, int updatedAt
});




}
/// @nodoc
class __$LotEntityCopyWithImpl<$Res>
    implements _$LotEntityCopyWith<$Res> {
  __$LotEntityCopyWithImpl(this._self, this._then);

  final _LotEntity _self;
  final $Res Function(_LotEntity) _then;

/// Create a copy of LotEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lotNumber = null,Object? title = freezed,Object? notes = freezed,Object? status = null,Object? transactionAt = null,Object? recordedAt = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_LotEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotNumber: null == lotNumber ? _self.lotNumber : lotNumber // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LotStatus,transactionAt: null == transactionAt ? _self.transactionAt : transactionAt // ignore: cast_nullable_to_non_nullable
as int,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$LotDesignEntity {

 String get id; String get lotId; String get designName; String? get notes; int get createdAt; int get updatedAt;
/// Create a copy of LotDesignEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotDesignEntityCopyWith<LotDesignEntity> get copyWith => _$LotDesignEntityCopyWithImpl<LotDesignEntity>(this as LotDesignEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LotDesignEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LotDesignEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.lotId, _this.lotId) || other.lotId == _this.lotId)&&(identical(other.designName, _this.designName) || other.designName == _this.designName)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as LotDesignEntity;
  return Object.hash(runtimeType,_this.id,_this.lotId,_this.designName,_this.notes,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as LotDesignEntity;
  return 'LotDesignEntity(id: ${_this.id}, lotId: ${_this.lotId}, designName: ${_this.designName}, notes: ${_this.notes}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $LotDesignEntityCopyWith<$Res>  {
  factory $LotDesignEntityCopyWith(LotDesignEntity value, $Res Function(LotDesignEntity) _then) = _$LotDesignEntityCopyWithImpl;
@useResult
$Res call({
 String id, String lotId, String designName, String? notes, int createdAt, int updatedAt
});




}
/// @nodoc
class _$LotDesignEntityCopyWithImpl<$Res>
    implements $LotDesignEntityCopyWith<$Res> {
  _$LotDesignEntityCopyWithImpl(this._self, this._then);

  final LotDesignEntity _self;
  final $Res Function(LotDesignEntity) _then;

/// Create a copy of LotDesignEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lotId = null,Object? designName = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(LotDesignEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotId: null == lotId ? _self.lotId : lotId // ignore: cast_nullable_to_non_nullable
as String,designName: null == designName ? _self.designName : designName // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LotDesignEntity].
extension LotDesignEntityPatterns on LotDesignEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LotDesignEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LotDesignEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LotDesignEntity value)  $default,){
final _that = this;
switch (_that) {
case _LotDesignEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LotDesignEntity value)?  $default,){
final _that = this;
switch (_that) {
case _LotDesignEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String lotId,  String designName,  String? notes,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LotDesignEntity() when $default != null:
return $default(_that.id,_that.lotId,_that.designName,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String lotId,  String designName,  String? notes,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LotDesignEntity():
return $default(_that.id,_that.lotId,_that.designName,_that.notes,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String lotId,  String designName,  String? notes,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LotDesignEntity() when $default != null:
return $default(_that.id,_that.lotId,_that.designName,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _LotDesignEntity implements LotDesignEntity {
  const _LotDesignEntity({required this.id, required this.lotId, required this.designName, this.notes, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String lotId;
@override final  String designName;
@override final  String? notes;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of LotDesignEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotDesignEntityCopyWith<_LotDesignEntity> get copyWith => __$LotDesignEntityCopyWithImpl<_LotDesignEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LotDesignEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.lotId, lotId) || other.lotId == lotId)&&(identical(other.designName, designName) || other.designName == designName)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,lotId,designName,notes,createdAt,updatedAt);
}

@override
String toString() {
    return 'LotDesignEntity(id: $id, lotId: $lotId, designName: $designName, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LotDesignEntityCopyWith<$Res> implements $LotDesignEntityCopyWith<$Res> {
  factory _$LotDesignEntityCopyWith(_LotDesignEntity value, $Res Function(_LotDesignEntity) _then) = __$LotDesignEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String lotId, String designName, String? notes, int createdAt, int updatedAt
});




}
/// @nodoc
class __$LotDesignEntityCopyWithImpl<$Res>
    implements _$LotDesignEntityCopyWith<$Res> {
  __$LotDesignEntityCopyWithImpl(this._self, this._then);

  final _LotDesignEntity _self;
  final $Res Function(_LotDesignEntity) _then;

/// Create a copy of LotDesignEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lotId = null,Object? designName = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_LotDesignEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotId: null == lotId ? _self.lotId : lotId // ignore: cast_nullable_to_non_nullable
as String,designName: null == designName ? _self.designName : designName // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$DesignColourEntity {

 String get id; String get lotDesignId; String get colourName; String? get colourHex; int get initialQuantity; int get unitPricePaise; String? get notes; int get createdAt; int get updatedAt;
/// Create a copy of DesignColourEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignColourEntityCopyWith<DesignColourEntity> get copyWith => _$DesignColourEntityCopyWithImpl<DesignColourEntity>(this as DesignColourEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DesignColourEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignColourEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.lotDesignId, _this.lotDesignId) || other.lotDesignId == _this.lotDesignId)&&(identical(other.colourName, _this.colourName) || other.colourName == _this.colourName)&&(identical(other.colourHex, _this.colourHex) || other.colourHex == _this.colourHex)&&(identical(other.initialQuantity, _this.initialQuantity) || other.initialQuantity == _this.initialQuantity)&&(identical(other.unitPricePaise, _this.unitPricePaise) || other.unitPricePaise == _this.unitPricePaise)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as DesignColourEntity;
  return Object.hash(runtimeType,_this.id,_this.lotDesignId,_this.colourName,_this.colourHex,_this.initialQuantity,_this.unitPricePaise,_this.notes,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as DesignColourEntity;
  return 'DesignColourEntity(id: ${_this.id}, lotDesignId: ${_this.lotDesignId}, colourName: ${_this.colourName}, colourHex: ${_this.colourHex}, initialQuantity: ${_this.initialQuantity}, unitPricePaise: ${_this.unitPricePaise}, notes: ${_this.notes}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $DesignColourEntityCopyWith<$Res>  {
  factory $DesignColourEntityCopyWith(DesignColourEntity value, $Res Function(DesignColourEntity) _then) = _$DesignColourEntityCopyWithImpl;
@useResult
$Res call({
 String id, String lotDesignId, String colourName, String? colourHex, int initialQuantity, int unitPricePaise, String? notes, int createdAt, int updatedAt
});




}
/// @nodoc
class _$DesignColourEntityCopyWithImpl<$Res>
    implements $DesignColourEntityCopyWith<$Res> {
  _$DesignColourEntityCopyWithImpl(this._self, this._then);

  final DesignColourEntity _self;
  final $Res Function(DesignColourEntity) _then;

/// Create a copy of DesignColourEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lotDesignId = null,Object? colourName = null,Object? colourHex = freezed,Object? initialQuantity = null,Object? unitPricePaise = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(DesignColourEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotDesignId: null == lotDesignId ? _self.lotDesignId : lotDesignId // ignore: cast_nullable_to_non_nullable
as String,colourName: null == colourName ? _self.colourName : colourName // ignore: cast_nullable_to_non_nullable
as String,colourHex: freezed == colourHex ? _self.colourHex : colourHex // ignore: cast_nullable_to_non_nullable
as String?,initialQuantity: null == initialQuantity ? _self.initialQuantity : initialQuantity // ignore: cast_nullable_to_non_nullable
as int,unitPricePaise: null == unitPricePaise ? _self.unitPricePaise : unitPricePaise // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignColourEntity].
extension DesignColourEntityPatterns on DesignColourEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignColourEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignColourEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignColourEntity value)  $default,){
final _that = this;
switch (_that) {
case _DesignColourEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignColourEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DesignColourEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String lotDesignId,  String colourName,  String? colourHex,  int initialQuantity,  int unitPricePaise,  String? notes,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignColourEntity() when $default != null:
return $default(_that.id,_that.lotDesignId,_that.colourName,_that.colourHex,_that.initialQuantity,_that.unitPricePaise,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String lotDesignId,  String colourName,  String? colourHex,  int initialQuantity,  int unitPricePaise,  String? notes,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DesignColourEntity():
return $default(_that.id,_that.lotDesignId,_that.colourName,_that.colourHex,_that.initialQuantity,_that.unitPricePaise,_that.notes,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String lotDesignId,  String colourName,  String? colourHex,  int initialQuantity,  int unitPricePaise,  String? notes,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DesignColourEntity() when $default != null:
return $default(_that.id,_that.lotDesignId,_that.colourName,_that.colourHex,_that.initialQuantity,_that.unitPricePaise,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _DesignColourEntity implements DesignColourEntity {
  const _DesignColourEntity({required this.id, required this.lotDesignId, required this.colourName, this.colourHex, required this.initialQuantity, required this.unitPricePaise, this.notes, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String lotDesignId;
@override final  String colourName;
@override final  String? colourHex;
@override final  int initialQuantity;
@override final  int unitPricePaise;
@override final  String? notes;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of DesignColourEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignColourEntityCopyWith<_DesignColourEntity> get copyWith => __$DesignColourEntityCopyWithImpl<_DesignColourEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignColourEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.lotDesignId, lotDesignId) || other.lotDesignId == lotDesignId)&&(identical(other.colourName, colourName) || other.colourName == colourName)&&(identical(other.colourHex, colourHex) || other.colourHex == colourHex)&&(identical(other.initialQuantity, initialQuantity) || other.initialQuantity == initialQuantity)&&(identical(other.unitPricePaise, unitPricePaise) || other.unitPricePaise == unitPricePaise)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,lotDesignId,colourName,colourHex,initialQuantity,unitPricePaise,notes,createdAt,updatedAt);
}

@override
String toString() {
    return 'DesignColourEntity(id: $id, lotDesignId: $lotDesignId, colourName: $colourName, colourHex: $colourHex, initialQuantity: $initialQuantity, unitPricePaise: $unitPricePaise, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DesignColourEntityCopyWith<$Res> implements $DesignColourEntityCopyWith<$Res> {
  factory _$DesignColourEntityCopyWith(_DesignColourEntity value, $Res Function(_DesignColourEntity) _then) = __$DesignColourEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String lotDesignId, String colourName, String? colourHex, int initialQuantity, int unitPricePaise, String? notes, int createdAt, int updatedAt
});




}
/// @nodoc
class __$DesignColourEntityCopyWithImpl<$Res>
    implements _$DesignColourEntityCopyWith<$Res> {
  __$DesignColourEntityCopyWithImpl(this._self, this._then);

  final _DesignColourEntity _self;
  final $Res Function(_DesignColourEntity) _then;

/// Create a copy of DesignColourEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lotDesignId = null,Object? colourName = null,Object? colourHex = freezed,Object? initialQuantity = null,Object? unitPricePaise = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_DesignColourEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotDesignId: null == lotDesignId ? _self.lotDesignId : lotDesignId // ignore: cast_nullable_to_non_nullable
as String,colourName: null == colourName ? _self.colourName : colourName // ignore: cast_nullable_to_non_nullable
as String,colourHex: freezed == colourHex ? _self.colourHex : colourHex // ignore: cast_nullable_to_non_nullable
as String?,initialQuantity: null == initialQuantity ? _self.initialQuantity : initialQuantity // ignore: cast_nullable_to_non_nullable
as int,unitPricePaise: null == unitPricePaise ? _self.unitPricePaise : unitPricePaise // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$LotAttachmentEntity {

 String get id; String get lotId; String get relativePath; String get mimeType; int get fileSizeBytes; String get sha256; String? get caption; int get createdAt;
/// Create a copy of LotAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotAttachmentEntityCopyWith<LotAttachmentEntity> get copyWith => _$LotAttachmentEntityCopyWithImpl<LotAttachmentEntity>(this as LotAttachmentEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LotAttachmentEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LotAttachmentEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.lotId, _this.lotId) || other.lotId == _this.lotId)&&(identical(other.relativePath, _this.relativePath) || other.relativePath == _this.relativePath)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.fileSizeBytes, _this.fileSizeBytes) || other.fileSizeBytes == _this.fileSizeBytes)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.caption, _this.caption) || other.caption == _this.caption)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as LotAttachmentEntity;
  return Object.hash(runtimeType,_this.id,_this.lotId,_this.relativePath,_this.mimeType,_this.fileSizeBytes,_this.sha256,_this.caption,_this.createdAt);
}

@override
String toString() {
  final _this = this as LotAttachmentEntity;
  return 'LotAttachmentEntity(id: ${_this.id}, lotId: ${_this.lotId}, relativePath: ${_this.relativePath}, mimeType: ${_this.mimeType}, fileSizeBytes: ${_this.fileSizeBytes}, sha256: ${_this.sha256}, caption: ${_this.caption}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $LotAttachmentEntityCopyWith<$Res>  {
  factory $LotAttachmentEntityCopyWith(LotAttachmentEntity value, $Res Function(LotAttachmentEntity) _then) = _$LotAttachmentEntityCopyWithImpl;
@useResult
$Res call({
 String id, String lotId, String relativePath, String mimeType, int fileSizeBytes, String sha256, String? caption, int createdAt
});




}
/// @nodoc
class _$LotAttachmentEntityCopyWithImpl<$Res>
    implements $LotAttachmentEntityCopyWith<$Res> {
  _$LotAttachmentEntityCopyWithImpl(this._self, this._then);

  final LotAttachmentEntity _self;
  final $Res Function(LotAttachmentEntity) _then;

/// Create a copy of LotAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lotId = null,Object? relativePath = null,Object? mimeType = null,Object? fileSizeBytes = null,Object? sha256 = null,Object? caption = freezed,Object? createdAt = null,}) {
  return _then(LotAttachmentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotId: null == lotId ? _self.lotId : lotId // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileSizeBytes: null == fileSizeBytes ? _self.fileSizeBytes : fileSizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LotAttachmentEntity].
extension LotAttachmentEntityPatterns on LotAttachmentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LotAttachmentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LotAttachmentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LotAttachmentEntity value)  $default,){
final _that = this;
switch (_that) {
case _LotAttachmentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LotAttachmentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _LotAttachmentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String lotId,  String relativePath,  String mimeType,  int fileSizeBytes,  String sha256,  String? caption,  int createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LotAttachmentEntity() when $default != null:
return $default(_that.id,_that.lotId,_that.relativePath,_that.mimeType,_that.fileSizeBytes,_that.sha256,_that.caption,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String lotId,  String relativePath,  String mimeType,  int fileSizeBytes,  String sha256,  String? caption,  int createdAt)  $default,) {final _that = this;
switch (_that) {
case _LotAttachmentEntity():
return $default(_that.id,_that.lotId,_that.relativePath,_that.mimeType,_that.fileSizeBytes,_that.sha256,_that.caption,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String lotId,  String relativePath,  String mimeType,  int fileSizeBytes,  String sha256,  String? caption,  int createdAt)?  $default,) {final _that = this;
switch (_that) {
case _LotAttachmentEntity() when $default != null:
return $default(_that.id,_that.lotId,_that.relativePath,_that.mimeType,_that.fileSizeBytes,_that.sha256,_that.caption,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _LotAttachmentEntity implements LotAttachmentEntity {
  const _LotAttachmentEntity({required this.id, required this.lotId, required this.relativePath, required this.mimeType, required this.fileSizeBytes, required this.sha256, this.caption, required this.createdAt});
  

@override final  String id;
@override final  String lotId;
@override final  String relativePath;
@override final  String mimeType;
@override final  int fileSizeBytes;
@override final  String sha256;
@override final  String? caption;
@override final  int createdAt;

/// Create a copy of LotAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotAttachmentEntityCopyWith<_LotAttachmentEntity> get copyWith => __$LotAttachmentEntityCopyWithImpl<_LotAttachmentEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LotAttachmentEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.lotId, lotId) || other.lotId == lotId)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSizeBytes, fileSizeBytes) || other.fileSizeBytes == fileSizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,lotId,relativePath,mimeType,fileSizeBytes,sha256,caption,createdAt);
}

@override
String toString() {
    return 'LotAttachmentEntity(id: $id, lotId: $lotId, relativePath: $relativePath, mimeType: $mimeType, fileSizeBytes: $fileSizeBytes, sha256: $sha256, caption: $caption, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$LotAttachmentEntityCopyWith<$Res> implements $LotAttachmentEntityCopyWith<$Res> {
  factory _$LotAttachmentEntityCopyWith(_LotAttachmentEntity value, $Res Function(_LotAttachmentEntity) _then) = __$LotAttachmentEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String lotId, String relativePath, String mimeType, int fileSizeBytes, String sha256, String? caption, int createdAt
});




}
/// @nodoc
class __$LotAttachmentEntityCopyWithImpl<$Res>
    implements _$LotAttachmentEntityCopyWith<$Res> {
  __$LotAttachmentEntityCopyWithImpl(this._self, this._then);

  final _LotAttachmentEntity _self;
  final $Res Function(_LotAttachmentEntity) _then;

/// Create a copy of LotAttachmentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lotId = null,Object? relativePath = null,Object? mimeType = null,Object? fileSizeBytes = null,Object? sha256 = null,Object? caption = freezed,Object? createdAt = null,}) {
  return _then(_LotAttachmentEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lotId: null == lotId ? _self.lotId : lotId // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileSizeBytes: null == fileSizeBytes ? _self.fileSizeBytes : fileSizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$DesignWithColours {

 LotDesignEntity get design; List<DesignColourEntity> get colours;
/// Create a copy of DesignWithColours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignWithColoursCopyWith<DesignWithColours> get copyWith => _$DesignWithColoursCopyWithImpl<DesignWithColours>(this as DesignWithColours, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DesignWithColours;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignWithColours&&(identical(other.design, _this.design) || other.design == _this.design)&&const DeepCollectionEquality().equals(other.colours, _this.colours));
}


@override
int get hashCode {
  final _this = this as DesignWithColours;
  return Object.hash(runtimeType,_this.design,const DeepCollectionEquality().hash(_this.colours));
}

@override
String toString() {
  final _this = this as DesignWithColours;
  return 'DesignWithColours(design: ${_this.design}, colours: ${_this.colours})';
}


}

/// @nodoc
abstract mixin class $DesignWithColoursCopyWith<$Res>  {
  factory $DesignWithColoursCopyWith(DesignWithColours value, $Res Function(DesignWithColours) _then) = _$DesignWithColoursCopyWithImpl;
@useResult
$Res call({
 LotDesignEntity design, List<DesignColourEntity> colours
});


$LotDesignEntityCopyWith<$Res> get design;

}
/// @nodoc
class _$DesignWithColoursCopyWithImpl<$Res>
    implements $DesignWithColoursCopyWith<$Res> {
  _$DesignWithColoursCopyWithImpl(this._self, this._then);

  final DesignWithColours _self;
  final $Res Function(DesignWithColours) _then;

/// Create a copy of DesignWithColours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? design = null,Object? colours = null,}) {
  return _then(DesignWithColours(
design: null == design ? _self.design : design // ignore: cast_nullable_to_non_nullable
as LotDesignEntity,colours: null == colours ? _self.colours : colours // ignore: cast_nullable_to_non_nullable
as List<DesignColourEntity>,
  ));
}
/// Create a copy of DesignWithColours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LotDesignEntityCopyWith<$Res> get design {
  
  return $LotDesignEntityCopyWith<$Res>(_self.design, (value) {
    return _then(_self.copyWith(design: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignWithColours].
extension DesignWithColoursPatterns on DesignWithColours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignWithColours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignWithColours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignWithColours value)  $default,){
final _that = this;
switch (_that) {
case _DesignWithColours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignWithColours value)?  $default,){
final _that = this;
switch (_that) {
case _DesignWithColours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LotDesignEntity design,  List<DesignColourEntity> colours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignWithColours() when $default != null:
return $default(_that.design,_that.colours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LotDesignEntity design,  List<DesignColourEntity> colours)  $default,) {final _that = this;
switch (_that) {
case _DesignWithColours():
return $default(_that.design,_that.colours);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LotDesignEntity design,  List<DesignColourEntity> colours)?  $default,) {final _that = this;
switch (_that) {
case _DesignWithColours() when $default != null:
return $default(_that.design,_that.colours);case _:
  return null;

}
}

}

/// @nodoc


class _DesignWithColours implements DesignWithColours {
  const _DesignWithColours({required this.design, required  List<DesignColourEntity> colours}): _colours = colours;
  

@override final  LotDesignEntity design;
 final  List<DesignColourEntity> _colours;
@override List<DesignColourEntity> get colours {
  if (_colours is EqualUnmodifiableListView) return _colours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colours);
}


/// Create a copy of DesignWithColours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignWithColoursCopyWith<_DesignWithColours> get copyWith => __$DesignWithColoursCopyWithImpl<_DesignWithColours>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignWithColours&&(identical(other.design, design) || other.design == design)&&const DeepCollectionEquality().equals(other.colours, _colours));
}


@override
int get hashCode {
    return Object.hash(runtimeType,design,const DeepCollectionEquality().hash(_colours));
}

@override
String toString() {
    return 'DesignWithColours(design: $design, colours: $colours)';
}


}

/// @nodoc
abstract mixin class _$DesignWithColoursCopyWith<$Res> implements $DesignWithColoursCopyWith<$Res> {
  factory _$DesignWithColoursCopyWith(_DesignWithColours value, $Res Function(_DesignWithColours) _then) = __$DesignWithColoursCopyWithImpl;
@override @useResult
$Res call({
 LotDesignEntity design, List<DesignColourEntity> colours
});


@override $LotDesignEntityCopyWith<$Res> get design;

}
/// @nodoc
class __$DesignWithColoursCopyWithImpl<$Res>
    implements _$DesignWithColoursCopyWith<$Res> {
  __$DesignWithColoursCopyWithImpl(this._self, this._then);

  final _DesignWithColours _self;
  final $Res Function(_DesignWithColours) _then;

/// Create a copy of DesignWithColours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? design = null,Object? colours = null,}) {
  return _then(_DesignWithColours(
design: null == design ? _self.design : design // ignore: cast_nullable_to_non_nullable
as LotDesignEntity,colours: null == colours ? _self._colours : colours // ignore: cast_nullable_to_non_nullable
as List<DesignColourEntity>,
  ));
}

/// Create a copy of DesignWithColours
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LotDesignEntityCopyWith<$Res> get design {
  
  return $LotDesignEntityCopyWith<$Res>(_self.design, (value) {
    return _then(_self.copyWith(design: value));
  });
}
}

/// @nodoc
mixin _$LotDetailAggregate {

 LotEntity get lot; List<DesignWithColours> get designs; List<LotAttachmentEntity> get photos;
/// Create a copy of LotDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotDetailAggregateCopyWith<LotDetailAggregate> get copyWith => _$LotDetailAggregateCopyWithImpl<LotDetailAggregate>(this as LotDetailAggregate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LotDetailAggregate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LotDetailAggregate&&(identical(other.lot, _this.lot) || other.lot == _this.lot)&&const DeepCollectionEquality().equals(other.designs, _this.designs)&&const DeepCollectionEquality().equals(other.photos, _this.photos));
}


@override
int get hashCode {
  final _this = this as LotDetailAggregate;
  return Object.hash(runtimeType,_this.lot,const DeepCollectionEquality().hash(_this.designs),const DeepCollectionEquality().hash(_this.photos));
}

@override
String toString() {
  final _this = this as LotDetailAggregate;
  return 'LotDetailAggregate(lot: ${_this.lot}, designs: ${_this.designs}, photos: ${_this.photos})';
}


}

/// @nodoc
abstract mixin class $LotDetailAggregateCopyWith<$Res>  {
  factory $LotDetailAggregateCopyWith(LotDetailAggregate value, $Res Function(LotDetailAggregate) _then) = _$LotDetailAggregateCopyWithImpl;
@useResult
$Res call({
 LotEntity lot, List<DesignWithColours> designs, List<LotAttachmentEntity> photos
});


$LotEntityCopyWith<$Res> get lot;

}
/// @nodoc
class _$LotDetailAggregateCopyWithImpl<$Res>
    implements $LotDetailAggregateCopyWith<$Res> {
  _$LotDetailAggregateCopyWithImpl(this._self, this._then);

  final LotDetailAggregate _self;
  final $Res Function(LotDetailAggregate) _then;

/// Create a copy of LotDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lot = null,Object? designs = null,Object? photos = null,}) {
  return _then(LotDetailAggregate(
lot: null == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as LotEntity,designs: null == designs ? _self.designs : designs // ignore: cast_nullable_to_non_nullable
as List<DesignWithColours>,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<LotAttachmentEntity>,
  ));
}
/// Create a copy of LotDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LotEntityCopyWith<$Res> get lot {
  
  return $LotEntityCopyWith<$Res>(_self.lot, (value) {
    return _then(_self.copyWith(lot: value));
  });
}
}


/// Adds pattern-matching-related methods to [LotDetailAggregate].
extension LotDetailAggregatePatterns on LotDetailAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LotDetailAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LotDetailAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LotDetailAggregate value)  $default,){
final _that = this;
switch (_that) {
case _LotDetailAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LotDetailAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _LotDetailAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LotEntity lot,  List<DesignWithColours> designs,  List<LotAttachmentEntity> photos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LotDetailAggregate() when $default != null:
return $default(_that.lot,_that.designs,_that.photos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LotEntity lot,  List<DesignWithColours> designs,  List<LotAttachmentEntity> photos)  $default,) {final _that = this;
switch (_that) {
case _LotDetailAggregate():
return $default(_that.lot,_that.designs,_that.photos);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LotEntity lot,  List<DesignWithColours> designs,  List<LotAttachmentEntity> photos)?  $default,) {final _that = this;
switch (_that) {
case _LotDetailAggregate() when $default != null:
return $default(_that.lot,_that.designs,_that.photos);case _:
  return null;

}
}

}

/// @nodoc


class _LotDetailAggregate implements LotDetailAggregate {
  const _LotDetailAggregate({required this.lot, required  List<DesignWithColours> designs, required  List<LotAttachmentEntity> photos}): _designs = designs,_photos = photos;
  

@override final  LotEntity lot;
 final  List<DesignWithColours> _designs;
@override List<DesignWithColours> get designs {
  if (_designs is EqualUnmodifiableListView) return _designs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designs);
}

 final  List<LotAttachmentEntity> _photos;
@override List<LotAttachmentEntity> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}


/// Create a copy of LotDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotDetailAggregateCopyWith<_LotDetailAggregate> get copyWith => __$LotDetailAggregateCopyWithImpl<_LotDetailAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LotDetailAggregate&&(identical(other.lot, lot) || other.lot == lot)&&const DeepCollectionEquality().equals(other.designs, _designs)&&const DeepCollectionEquality().equals(other.photos, _photos));
}


@override
int get hashCode {
    return Object.hash(runtimeType,lot,const DeepCollectionEquality().hash(_designs),const DeepCollectionEquality().hash(_photos));
}

@override
String toString() {
    return 'LotDetailAggregate(lot: $lot, designs: $designs, photos: $photos)';
}


}

/// @nodoc
abstract mixin class _$LotDetailAggregateCopyWith<$Res> implements $LotDetailAggregateCopyWith<$Res> {
  factory _$LotDetailAggregateCopyWith(_LotDetailAggregate value, $Res Function(_LotDetailAggregate) _then) = __$LotDetailAggregateCopyWithImpl;
@override @useResult
$Res call({
 LotEntity lot, List<DesignWithColours> designs, List<LotAttachmentEntity> photos
});


@override $LotEntityCopyWith<$Res> get lot;

}
/// @nodoc
class __$LotDetailAggregateCopyWithImpl<$Res>
    implements _$LotDetailAggregateCopyWith<$Res> {
  __$LotDetailAggregateCopyWithImpl(this._self, this._then);

  final _LotDetailAggregate _self;
  final $Res Function(_LotDetailAggregate) _then;

/// Create a copy of LotDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lot = null,Object? designs = null,Object? photos = null,}) {
  return _then(_LotDetailAggregate(
lot: null == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as LotEntity,designs: null == designs ? _self._designs : designs // ignore: cast_nullable_to_non_nullable
as List<DesignWithColours>,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<LotAttachmentEntity>,
  ));
}

/// Create a copy of LotDetailAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LotEntityCopyWith<$Res> get lot {
  
  return $LotEntityCopyWith<$Res>(_self.lot, (value) {
    return _then(_self.copyWith(lot: value));
  });
}
}

// dart format on
