// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_overview_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InventoryOverviewState {

 InventoryOverviewStatus get status; InventoryOverview? get overview; String? get errorMessage;
/// Create a copy of InventoryOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryOverviewStateCopyWith<InventoryOverviewState> get copyWith => _$InventoryOverviewStateCopyWithImpl<InventoryOverviewState>(this as InventoryOverviewState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InventoryOverviewState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryOverviewState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.overview, _this.overview) || other.overview == _this.overview)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as InventoryOverviewState;
  return Object.hash(runtimeType,_this.status,_this.overview,_this.errorMessage);
}

@override
String toString() {
  final _this = this as InventoryOverviewState;
  return 'InventoryOverviewState(status: ${_this.status}, overview: ${_this.overview}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $InventoryOverviewStateCopyWith<$Res>  {
  factory $InventoryOverviewStateCopyWith(InventoryOverviewState value, $Res Function(InventoryOverviewState) _then) = _$InventoryOverviewStateCopyWithImpl;
@useResult
$Res call({
 InventoryOverviewStatus status, InventoryOverview? overview, String? errorMessage
});




}
/// @nodoc
class _$InventoryOverviewStateCopyWithImpl<$Res>
    implements $InventoryOverviewStateCopyWith<$Res> {
  _$InventoryOverviewStateCopyWithImpl(this._self, this._then);

  final InventoryOverviewState _self;
  final $Res Function(InventoryOverviewState) _then;

/// Create a copy of InventoryOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? overview = freezed,Object? errorMessage = freezed,}) {
  return _then(InventoryOverviewState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InventoryOverviewStatus,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as InventoryOverview?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryOverviewState].
extension InventoryOverviewStatePatterns on InventoryOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryOverviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryOverviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryOverviewState value)  $default,){
final _that = this;
switch (_that) {
case _InventoryOverviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryOverviewState value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryOverviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InventoryOverviewStatus status,  InventoryOverview? overview,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryOverviewState() when $default != null:
return $default(_that.status,_that.overview,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InventoryOverviewStatus status,  InventoryOverview? overview,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _InventoryOverviewState():
return $default(_that.status,_that.overview,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InventoryOverviewStatus status,  InventoryOverview? overview,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _InventoryOverviewState() when $default != null:
return $default(_that.status,_that.overview,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _InventoryOverviewState implements InventoryOverviewState {
  const _InventoryOverviewState({this.status = InventoryOverviewStatus.initial, this.overview, this.errorMessage});
  

@override@JsonKey() final  InventoryOverviewStatus status;
@override final  InventoryOverview? overview;
@override final  String? errorMessage;

/// Create a copy of InventoryOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryOverviewStateCopyWith<_InventoryOverviewState> get copyWith => __$InventoryOverviewStateCopyWithImpl<_InventoryOverviewState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryOverviewState&&(identical(other.status, status) || other.status == status)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,overview,errorMessage);
}

@override
String toString() {
    return 'InventoryOverviewState(status: $status, overview: $overview, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$InventoryOverviewStateCopyWith<$Res> implements $InventoryOverviewStateCopyWith<$Res> {
  factory _$InventoryOverviewStateCopyWith(_InventoryOverviewState value, $Res Function(_InventoryOverviewState) _then) = __$InventoryOverviewStateCopyWithImpl;
@override @useResult
$Res call({
 InventoryOverviewStatus status, InventoryOverview? overview, String? errorMessage
});




}
/// @nodoc
class __$InventoryOverviewStateCopyWithImpl<$Res>
    implements _$InventoryOverviewStateCopyWith<$Res> {
  __$InventoryOverviewStateCopyWithImpl(this._self, this._then);

  final _InventoryOverviewState _self;
  final $Res Function(_InventoryOverviewState) _then;

/// Create a copy of InventoryOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? overview = freezed,Object? errorMessage = freezed,}) {
  return _then(_InventoryOverviewState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InventoryOverviewStatus,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as InventoryOverview?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
