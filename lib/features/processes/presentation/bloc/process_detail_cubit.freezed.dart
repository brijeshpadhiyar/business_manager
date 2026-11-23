// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'process_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProcessDetailState {

 ProcessDetailStatus get status; ProcessDetailAggregate? get detail; String? get errorMessage;
/// Create a copy of ProcessDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessDetailStateCopyWith<ProcessDetailState> get copyWith => _$ProcessDetailStateCopyWithImpl<ProcessDetailState>(this as ProcessDetailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProcessDetailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessDetailState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as ProcessDetailState;
  return Object.hash(runtimeType,_this.status,_this.detail,_this.errorMessage);
}

@override
String toString() {
  final _this = this as ProcessDetailState;
  return 'ProcessDetailState(status: ${_this.status}, detail: ${_this.detail}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $ProcessDetailStateCopyWith<$Res>  {
  factory $ProcessDetailStateCopyWith(ProcessDetailState value, $Res Function(ProcessDetailState) _then) = _$ProcessDetailStateCopyWithImpl;
@useResult
$Res call({
 ProcessDetailStatus status, ProcessDetailAggregate? detail, String? errorMessage
});


$ProcessDetailAggregateCopyWith<$Res>? get detail;

}
/// @nodoc
class _$ProcessDetailStateCopyWithImpl<$Res>
    implements $ProcessDetailStateCopyWith<$Res> {
  _$ProcessDetailStateCopyWithImpl(this._self, this._then);

  final ProcessDetailState _self;
  final $Res Function(ProcessDetailState) _then;

/// Create a copy of ProcessDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? detail = freezed,Object? errorMessage = freezed,}) {
  return _then(ProcessDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProcessDetailStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as ProcessDetailAggregate?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProcessDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProcessDetailAggregateCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $ProcessDetailAggregateCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProcessDetailState].
extension ProcessDetailStatePatterns on ProcessDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessDetailState value)  $default,){
final _that = this;
switch (_that) {
case _ProcessDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProcessDetailStatus status,  ProcessDetailAggregate? detail,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessDetailState() when $default != null:
return $default(_that.status,_that.detail,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProcessDetailStatus status,  ProcessDetailAggregate? detail,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ProcessDetailState():
return $default(_that.status,_that.detail,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProcessDetailStatus status,  ProcessDetailAggregate? detail,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ProcessDetailState() when $default != null:
return $default(_that.status,_that.detail,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessDetailState implements ProcessDetailState {
  const _ProcessDetailState({this.status = ProcessDetailStatus.initial, this.detail, this.errorMessage});
  

@override@JsonKey() final  ProcessDetailStatus status;
@override final  ProcessDetailAggregate? detail;
@override final  String? errorMessage;

/// Create a copy of ProcessDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessDetailStateCopyWith<_ProcessDetailState> get copyWith => __$ProcessDetailStateCopyWithImpl<_ProcessDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessDetailState&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,detail,errorMessage);
}

@override
String toString() {
    return 'ProcessDetailState(status: $status, detail: $detail, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ProcessDetailStateCopyWith<$Res> implements $ProcessDetailStateCopyWith<$Res> {
  factory _$ProcessDetailStateCopyWith(_ProcessDetailState value, $Res Function(_ProcessDetailState) _then) = __$ProcessDetailStateCopyWithImpl;
@override @useResult
$Res call({
 ProcessDetailStatus status, ProcessDetailAggregate? detail, String? errorMessage
});


@override $ProcessDetailAggregateCopyWith<$Res>? get detail;

}
/// @nodoc
class __$ProcessDetailStateCopyWithImpl<$Res>
    implements _$ProcessDetailStateCopyWith<$Res> {
  __$ProcessDetailStateCopyWithImpl(this._self, this._then);

  final _ProcessDetailState _self;
  final $Res Function(_ProcessDetailState) _then;

/// Create a copy of ProcessDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? detail = freezed,Object? errorMessage = freezed,}) {
  return _then(_ProcessDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProcessDetailStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as ProcessDetailAggregate?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProcessDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProcessDetailAggregateCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $ProcessDetailAggregateCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}

// dart format on
