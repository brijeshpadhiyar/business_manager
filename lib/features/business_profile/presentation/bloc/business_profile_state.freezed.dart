// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BusinessProfileState {

 BusinessProfileStatus get status; BusinessProfileEntity? get profile; String? get errorMessage;
/// Create a copy of BusinessProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessProfileStateCopyWith<BusinessProfileState> get copyWith => _$BusinessProfileStateCopyWithImpl<BusinessProfileState>(this as BusinessProfileState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BusinessProfileState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessProfileState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.profile, _this.profile) || other.profile == _this.profile)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as BusinessProfileState;
  return Object.hash(runtimeType,_this.status,_this.profile,_this.errorMessage);
}

@override
String toString() {
  final _this = this as BusinessProfileState;
  return 'BusinessProfileState(status: ${_this.status}, profile: ${_this.profile}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $BusinessProfileStateCopyWith<$Res>  {
  factory $BusinessProfileStateCopyWith(BusinessProfileState value, $Res Function(BusinessProfileState) _then) = _$BusinessProfileStateCopyWithImpl;
@useResult
$Res call({
 BusinessProfileStatus status, BusinessProfileEntity? profile, String? errorMessage
});


$BusinessProfileEntityCopyWith<$Res>? get profile;

}
/// @nodoc
class _$BusinessProfileStateCopyWithImpl<$Res>
    implements $BusinessProfileStateCopyWith<$Res> {
  _$BusinessProfileStateCopyWithImpl(this._self, this._then);

  final BusinessProfileState _self;
  final $Res Function(BusinessProfileState) _then;

/// Create a copy of BusinessProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? profile = freezed,Object? errorMessage = freezed,}) {
  return _then(BusinessProfileState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BusinessProfileStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BusinessProfileEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BusinessProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessProfileEntityCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $BusinessProfileEntityCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [BusinessProfileState].
extension BusinessProfileStatePatterns on BusinessProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessProfileState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessProfileState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessProfileState value)  $default,){
final _that = this;
switch (_that) {
case _BusinessProfileState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessProfileState value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessProfileState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BusinessProfileStatus status,  BusinessProfileEntity? profile,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessProfileState() when $default != null:
return $default(_that.status,_that.profile,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BusinessProfileStatus status,  BusinessProfileEntity? profile,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _BusinessProfileState():
return $default(_that.status,_that.profile,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BusinessProfileStatus status,  BusinessProfileEntity? profile,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _BusinessProfileState() when $default != null:
return $default(_that.status,_that.profile,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _BusinessProfileState implements BusinessProfileState {
  const _BusinessProfileState({this.status = BusinessProfileStatus.initial, this.profile, this.errorMessage});
  

@override@JsonKey() final  BusinessProfileStatus status;
@override final  BusinessProfileEntity? profile;
@override final  String? errorMessage;

/// Create a copy of BusinessProfileState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessProfileStateCopyWith<_BusinessProfileState> get copyWith => __$BusinessProfileStateCopyWithImpl<_BusinessProfileState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessProfileState&&(identical(other.status, status) || other.status == status)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,profile,errorMessage);
}

@override
String toString() {
    return 'BusinessProfileState(status: $status, profile: $profile, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$BusinessProfileStateCopyWith<$Res> implements $BusinessProfileStateCopyWith<$Res> {
  factory _$BusinessProfileStateCopyWith(_BusinessProfileState value, $Res Function(_BusinessProfileState) _then) = __$BusinessProfileStateCopyWithImpl;
@override @useResult
$Res call({
 BusinessProfileStatus status, BusinessProfileEntity? profile, String? errorMessage
});


@override $BusinessProfileEntityCopyWith<$Res>? get profile;

}
/// @nodoc
class __$BusinessProfileStateCopyWithImpl<$Res>
    implements _$BusinessProfileStateCopyWith<$Res> {
  __$BusinessProfileStateCopyWithImpl(this._self, this._then);

  final _BusinessProfileState _self;
  final $Res Function(_BusinessProfileState) _then;

/// Create a copy of BusinessProfileState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? profile = freezed,Object? errorMessage = freezed,}) {
  return _then(_BusinessProfileState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BusinessProfileStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BusinessProfileEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BusinessProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessProfileEntityCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $BusinessProfileEntityCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
