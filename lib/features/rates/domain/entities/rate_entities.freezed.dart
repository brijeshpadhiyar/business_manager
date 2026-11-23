// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rate_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MemberProcessRateEntity {

 String get id; String get memberId; String get processId; int get ratePaise; String get effectiveFrom; String? get effectiveTo; String? get notes; int get createdAt; int get updatedAt;
/// Create a copy of MemberProcessRateEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberProcessRateEntityCopyWith<MemberProcessRateEntity> get copyWith => _$MemberProcessRateEntityCopyWithImpl<MemberProcessRateEntity>(this as MemberProcessRateEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MemberProcessRateEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberProcessRateEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.processId, _this.processId) || other.processId == _this.processId)&&(identical(other.ratePaise, _this.ratePaise) || other.ratePaise == _this.ratePaise)&&(identical(other.effectiveFrom, _this.effectiveFrom) || other.effectiveFrom == _this.effectiveFrom)&&(identical(other.effectiveTo, _this.effectiveTo) || other.effectiveTo == _this.effectiveTo)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as MemberProcessRateEntity;
  return Object.hash(runtimeType,_this.id,_this.memberId,_this.processId,_this.ratePaise,_this.effectiveFrom,_this.effectiveTo,_this.notes,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as MemberProcessRateEntity;
  return 'MemberProcessRateEntity(id: ${_this.id}, memberId: ${_this.memberId}, processId: ${_this.processId}, ratePaise: ${_this.ratePaise}, effectiveFrom: ${_this.effectiveFrom}, effectiveTo: ${_this.effectiveTo}, notes: ${_this.notes}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $MemberProcessRateEntityCopyWith<$Res>  {
  factory $MemberProcessRateEntityCopyWith(MemberProcessRateEntity value, $Res Function(MemberProcessRateEntity) _then) = _$MemberProcessRateEntityCopyWithImpl;
@useResult
$Res call({
 String id, String memberId, String processId, int ratePaise, String effectiveFrom, String? effectiveTo, String? notes, int createdAt, int updatedAt
});




}
/// @nodoc
class _$MemberProcessRateEntityCopyWithImpl<$Res>
    implements $MemberProcessRateEntityCopyWith<$Res> {
  _$MemberProcessRateEntityCopyWithImpl(this._self, this._then);

  final MemberProcessRateEntity _self;
  final $Res Function(MemberProcessRateEntity) _then;

/// Create a copy of MemberProcessRateEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberId = null,Object? processId = null,Object? ratePaise = null,Object? effectiveFrom = null,Object? effectiveTo = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(MemberProcessRateEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,processId: null == processId ? _self.processId : processId // ignore: cast_nullable_to_non_nullable
as String,ratePaise: null == ratePaise ? _self.ratePaise : ratePaise // ignore: cast_nullable_to_non_nullable
as int,effectiveFrom: null == effectiveFrom ? _self.effectiveFrom : effectiveFrom // ignore: cast_nullable_to_non_nullable
as String,effectiveTo: freezed == effectiveTo ? _self.effectiveTo : effectiveTo // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberProcessRateEntity].
extension MemberProcessRateEntityPatterns on MemberProcessRateEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberProcessRateEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberProcessRateEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberProcessRateEntity value)  $default,){
final _that = this;
switch (_that) {
case _MemberProcessRateEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberProcessRateEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MemberProcessRateEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String memberId,  String processId,  int ratePaise,  String effectiveFrom,  String? effectiveTo,  String? notes,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberProcessRateEntity() when $default != null:
return $default(_that.id,_that.memberId,_that.processId,_that.ratePaise,_that.effectiveFrom,_that.effectiveTo,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String memberId,  String processId,  int ratePaise,  String effectiveFrom,  String? effectiveTo,  String? notes,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MemberProcessRateEntity():
return $default(_that.id,_that.memberId,_that.processId,_that.ratePaise,_that.effectiveFrom,_that.effectiveTo,_that.notes,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String memberId,  String processId,  int ratePaise,  String effectiveFrom,  String? effectiveTo,  String? notes,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MemberProcessRateEntity() when $default != null:
return $default(_that.id,_that.memberId,_that.processId,_that.ratePaise,_that.effectiveFrom,_that.effectiveTo,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MemberProcessRateEntity implements MemberProcessRateEntity {
  const _MemberProcessRateEntity({required this.id, required this.memberId, required this.processId, required this.ratePaise, required this.effectiveFrom, this.effectiveTo, this.notes, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String memberId;
@override final  String processId;
@override final  int ratePaise;
@override final  String effectiveFrom;
@override final  String? effectiveTo;
@override final  String? notes;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of MemberProcessRateEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberProcessRateEntityCopyWith<_MemberProcessRateEntity> get copyWith => __$MemberProcessRateEntityCopyWithImpl<_MemberProcessRateEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberProcessRateEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.processId, processId) || other.processId == processId)&&(identical(other.ratePaise, ratePaise) || other.ratePaise == ratePaise)&&(identical(other.effectiveFrom, effectiveFrom) || other.effectiveFrom == effectiveFrom)&&(identical(other.effectiveTo, effectiveTo) || other.effectiveTo == effectiveTo)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,memberId,processId,ratePaise,effectiveFrom,effectiveTo,notes,createdAt,updatedAt);
}

@override
String toString() {
    return 'MemberProcessRateEntity(id: $id, memberId: $memberId, processId: $processId, ratePaise: $ratePaise, effectiveFrom: $effectiveFrom, effectiveTo: $effectiveTo, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MemberProcessRateEntityCopyWith<$Res> implements $MemberProcessRateEntityCopyWith<$Res> {
  factory _$MemberProcessRateEntityCopyWith(_MemberProcessRateEntity value, $Res Function(_MemberProcessRateEntity) _then) = __$MemberProcessRateEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String memberId, String processId, int ratePaise, String effectiveFrom, String? effectiveTo, String? notes, int createdAt, int updatedAt
});




}
/// @nodoc
class __$MemberProcessRateEntityCopyWithImpl<$Res>
    implements _$MemberProcessRateEntityCopyWith<$Res> {
  __$MemberProcessRateEntityCopyWithImpl(this._self, this._then);

  final _MemberProcessRateEntity _self;
  final $Res Function(_MemberProcessRateEntity) _then;

/// Create a copy of MemberProcessRateEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberId = null,Object? processId = null,Object? ratePaise = null,Object? effectiveFrom = null,Object? effectiveTo = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_MemberProcessRateEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,processId: null == processId ? _self.processId : processId // ignore: cast_nullable_to_non_nullable
as String,ratePaise: null == ratePaise ? _self.ratePaise : ratePaise // ignore: cast_nullable_to_non_nullable
as int,effectiveFrom: null == effectiveFrom ? _self.effectiveFrom : effectiveFrom // ignore: cast_nullable_to_non_nullable
as String,effectiveTo: freezed == effectiveTo ? _self.effectiveTo : effectiveTo // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
