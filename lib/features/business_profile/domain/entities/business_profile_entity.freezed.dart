// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_profile_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BusinessProfileEntity {

 String get id; String get nameEn; String get nameGu; String? get ownerName; String? get phone; String? get address; String? get logoAttachmentId; BillingMode get defaultBillingMode; int get createdAt; int get updatedAt;
/// Create a copy of BusinessProfileEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessProfileEntityCopyWith<BusinessProfileEntity> get copyWith => _$BusinessProfileEntityCopyWithImpl<BusinessProfileEntity>(this as BusinessProfileEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BusinessProfileEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessProfileEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nameEn, _this.nameEn) || other.nameEn == _this.nameEn)&&(identical(other.nameGu, _this.nameGu) || other.nameGu == _this.nameGu)&&(identical(other.ownerName, _this.ownerName) || other.ownerName == _this.ownerName)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.logoAttachmentId, _this.logoAttachmentId) || other.logoAttachmentId == _this.logoAttachmentId)&&(identical(other.defaultBillingMode, _this.defaultBillingMode) || other.defaultBillingMode == _this.defaultBillingMode)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as BusinessProfileEntity;
  return Object.hash(runtimeType,_this.id,_this.nameEn,_this.nameGu,_this.ownerName,_this.phone,_this.address,_this.logoAttachmentId,_this.defaultBillingMode,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as BusinessProfileEntity;
  return 'BusinessProfileEntity(id: ${_this.id}, nameEn: ${_this.nameEn}, nameGu: ${_this.nameGu}, ownerName: ${_this.ownerName}, phone: ${_this.phone}, address: ${_this.address}, logoAttachmentId: ${_this.logoAttachmentId}, defaultBillingMode: ${_this.defaultBillingMode}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $BusinessProfileEntityCopyWith<$Res>  {
  factory $BusinessProfileEntityCopyWith(BusinessProfileEntity value, $Res Function(BusinessProfileEntity) _then) = _$BusinessProfileEntityCopyWithImpl;
@useResult
$Res call({
 String id, String nameEn, String nameGu, String? ownerName, String? phone, String? address, String? logoAttachmentId, BillingMode defaultBillingMode, int createdAt, int updatedAt
});




}
/// @nodoc
class _$BusinessProfileEntityCopyWithImpl<$Res>
    implements $BusinessProfileEntityCopyWith<$Res> {
  _$BusinessProfileEntityCopyWithImpl(this._self, this._then);

  final BusinessProfileEntity _self;
  final $Res Function(BusinessProfileEntity) _then;

/// Create a copy of BusinessProfileEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameEn = null,Object? nameGu = null,Object? ownerName = freezed,Object? phone = freezed,Object? address = freezed,Object? logoAttachmentId = freezed,Object? defaultBillingMode = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(BusinessProfileEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameGu: null == nameGu ? _self.nameGu : nameGu // ignore: cast_nullable_to_non_nullable
as String,ownerName: freezed == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,logoAttachmentId: freezed == logoAttachmentId ? _self.logoAttachmentId : logoAttachmentId // ignore: cast_nullable_to_non_nullable
as String?,defaultBillingMode: null == defaultBillingMode ? _self.defaultBillingMode : defaultBillingMode // ignore: cast_nullable_to_non_nullable
as BillingMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessProfileEntity].
extension BusinessProfileEntityPatterns on BusinessProfileEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessProfileEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessProfileEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessProfileEntity value)  $default,){
final _that = this;
switch (_that) {
case _BusinessProfileEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessProfileEntity value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessProfileEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nameEn,  String nameGu,  String? ownerName,  String? phone,  String? address,  String? logoAttachmentId,  BillingMode defaultBillingMode,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessProfileEntity() when $default != null:
return $default(_that.id,_that.nameEn,_that.nameGu,_that.ownerName,_that.phone,_that.address,_that.logoAttachmentId,_that.defaultBillingMode,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nameEn,  String nameGu,  String? ownerName,  String? phone,  String? address,  String? logoAttachmentId,  BillingMode defaultBillingMode,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BusinessProfileEntity():
return $default(_that.id,_that.nameEn,_that.nameGu,_that.ownerName,_that.phone,_that.address,_that.logoAttachmentId,_that.defaultBillingMode,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nameEn,  String nameGu,  String? ownerName,  String? phone,  String? address,  String? logoAttachmentId,  BillingMode defaultBillingMode,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BusinessProfileEntity() when $default != null:
return $default(_that.id,_that.nameEn,_that.nameGu,_that.ownerName,_that.phone,_that.address,_that.logoAttachmentId,_that.defaultBillingMode,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _BusinessProfileEntity implements BusinessProfileEntity {
  const _BusinessProfileEntity({required this.id, required this.nameEn, required this.nameGu, this.ownerName, this.phone, this.address, this.logoAttachmentId, required this.defaultBillingMode, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String nameEn;
@override final  String nameGu;
@override final  String? ownerName;
@override final  String? phone;
@override final  String? address;
@override final  String? logoAttachmentId;
@override final  BillingMode defaultBillingMode;
@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of BusinessProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessProfileEntityCopyWith<_BusinessProfileEntity> get copyWith => __$BusinessProfileEntityCopyWithImpl<_BusinessProfileEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessProfileEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.nameGu, nameGu) || other.nameGu == nameGu)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address, address) || other.address == address)&&(identical(other.logoAttachmentId, logoAttachmentId) || other.logoAttachmentId == logoAttachmentId)&&(identical(other.defaultBillingMode, defaultBillingMode) || other.defaultBillingMode == defaultBillingMode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,nameEn,nameGu,ownerName,phone,address,logoAttachmentId,defaultBillingMode,createdAt,updatedAt);
}

@override
String toString() {
    return 'BusinessProfileEntity(id: $id, nameEn: $nameEn, nameGu: $nameGu, ownerName: $ownerName, phone: $phone, address: $address, logoAttachmentId: $logoAttachmentId, defaultBillingMode: $defaultBillingMode, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BusinessProfileEntityCopyWith<$Res> implements $BusinessProfileEntityCopyWith<$Res> {
  factory _$BusinessProfileEntityCopyWith(_BusinessProfileEntity value, $Res Function(_BusinessProfileEntity) _then) = __$BusinessProfileEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String nameEn, String nameGu, String? ownerName, String? phone, String? address, String? logoAttachmentId, BillingMode defaultBillingMode, int createdAt, int updatedAt
});




}
/// @nodoc
class __$BusinessProfileEntityCopyWithImpl<$Res>
    implements _$BusinessProfileEntityCopyWith<$Res> {
  __$BusinessProfileEntityCopyWithImpl(this._self, this._then);

  final _BusinessProfileEntity _self;
  final $Res Function(_BusinessProfileEntity) _then;

/// Create a copy of BusinessProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameEn = null,Object? nameGu = null,Object? ownerName = freezed,Object? phone = freezed,Object? address = freezed,Object? logoAttachmentId = freezed,Object? defaultBillingMode = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_BusinessProfileEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameGu: null == nameGu ? _self.nameGu : nameGu // ignore: cast_nullable_to_non_nullable
as String,ownerName: freezed == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,logoAttachmentId: freezed == logoAttachmentId ? _self.logoAttachmentId : logoAttachmentId // ignore: cast_nullable_to_non_nullable
as String?,defaultBillingMode: null == defaultBillingMode ? _self.defaultBillingMode : defaultBillingMode // ignore: cast_nullable_to_non_nullable
as BillingMode,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
