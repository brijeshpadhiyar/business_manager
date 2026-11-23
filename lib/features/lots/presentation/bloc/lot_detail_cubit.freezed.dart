// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lot_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LotDetailState {

 LotDetailStatus get status; LotDetailAggregate? get detail; String get designSearchQuery; String? get errorMessage;
/// Create a copy of LotDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotDetailStateCopyWith<LotDetailState> get copyWith => _$LotDetailStateCopyWithImpl<LotDetailState>(this as LotDetailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LotDetailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LotDetailState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.designSearchQuery, _this.designSearchQuery) || other.designSearchQuery == _this.designSearchQuery)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as LotDetailState;
  return Object.hash(runtimeType,_this.status,_this.detail,_this.designSearchQuery,_this.errorMessage);
}

@override
String toString() {
  final _this = this as LotDetailState;
  return 'LotDetailState(status: ${_this.status}, detail: ${_this.detail}, designSearchQuery: ${_this.designSearchQuery}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $LotDetailStateCopyWith<$Res>  {
  factory $LotDetailStateCopyWith(LotDetailState value, $Res Function(LotDetailState) _then) = _$LotDetailStateCopyWithImpl;
@useResult
$Res call({
 LotDetailStatus status, LotDetailAggregate? detail, String designSearchQuery, String? errorMessage
});


$LotDetailAggregateCopyWith<$Res>? get detail;

}
/// @nodoc
class _$LotDetailStateCopyWithImpl<$Res>
    implements $LotDetailStateCopyWith<$Res> {
  _$LotDetailStateCopyWithImpl(this._self, this._then);

  final LotDetailState _self;
  final $Res Function(LotDetailState) _then;

/// Create a copy of LotDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? detail = freezed,Object? designSearchQuery = null,Object? errorMessage = freezed,}) {
  return _then(LotDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LotDetailStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as LotDetailAggregate?,designSearchQuery: null == designSearchQuery ? _self.designSearchQuery : designSearchQuery // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of LotDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LotDetailAggregateCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $LotDetailAggregateCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}


/// Adds pattern-matching-related methods to [LotDetailState].
extension LotDetailStatePatterns on LotDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LotDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LotDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LotDetailState value)  $default,){
final _that = this;
switch (_that) {
case _LotDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LotDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _LotDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LotDetailStatus status,  LotDetailAggregate? detail,  String designSearchQuery,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LotDetailState() when $default != null:
return $default(_that.status,_that.detail,_that.designSearchQuery,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LotDetailStatus status,  LotDetailAggregate? detail,  String designSearchQuery,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _LotDetailState():
return $default(_that.status,_that.detail,_that.designSearchQuery,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LotDetailStatus status,  LotDetailAggregate? detail,  String designSearchQuery,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _LotDetailState() when $default != null:
return $default(_that.status,_that.detail,_that.designSearchQuery,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _LotDetailState implements LotDetailState {
  const _LotDetailState({this.status = LotDetailStatus.initial, this.detail, this.designSearchQuery = '', this.errorMessage});
  

@override@JsonKey() final  LotDetailStatus status;
@override final  LotDetailAggregate? detail;
@override@JsonKey() final  String designSearchQuery;
@override final  String? errorMessage;

/// Create a copy of LotDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotDetailStateCopyWith<_LotDetailState> get copyWith => __$LotDetailStateCopyWithImpl<_LotDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LotDetailState&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.designSearchQuery, designSearchQuery) || other.designSearchQuery == designSearchQuery)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,detail,designSearchQuery,errorMessage);
}

@override
String toString() {
    return 'LotDetailState(status: $status, detail: $detail, designSearchQuery: $designSearchQuery, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$LotDetailStateCopyWith<$Res> implements $LotDetailStateCopyWith<$Res> {
  factory _$LotDetailStateCopyWith(_LotDetailState value, $Res Function(_LotDetailState) _then) = __$LotDetailStateCopyWithImpl;
@override @useResult
$Res call({
 LotDetailStatus status, LotDetailAggregate? detail, String designSearchQuery, String? errorMessage
});


@override $LotDetailAggregateCopyWith<$Res>? get detail;

}
/// @nodoc
class __$LotDetailStateCopyWithImpl<$Res>
    implements _$LotDetailStateCopyWith<$Res> {
  __$LotDetailStateCopyWithImpl(this._self, this._then);

  final _LotDetailState _self;
  final $Res Function(_LotDetailState) _then;

/// Create a copy of LotDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? detail = freezed,Object? designSearchQuery = null,Object? errorMessage = freezed,}) {
  return _then(_LotDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LotDetailStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as LotDetailAggregate?,designSearchQuery: null == designSearchQuery ? _self.designSearchQuery : designSearchQuery // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of LotDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LotDetailAggregateCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $LotDetailAggregateCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}

// dart format on
