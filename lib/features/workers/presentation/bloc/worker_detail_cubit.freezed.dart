// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'worker_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkerDetailState {

 WorkerDetailStatus get status; WorkerDetailAggregate? get detail; WorkerLedgerDetail? get ledgerDetail; List<OpenIssueSummary> get openIssues; String? get errorMessage;
/// Create a copy of WorkerDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerDetailStateCopyWith<WorkerDetailState> get copyWith => _$WorkerDetailStateCopyWithImpl<WorkerDetailState>(this as WorkerDetailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkerDetailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerDetailState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.ledgerDetail, _this.ledgerDetail) || other.ledgerDetail == _this.ledgerDetail)&&const DeepCollectionEquality().equals(other.openIssues, _this.openIssues)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as WorkerDetailState;
  return Object.hash(runtimeType,_this.status,_this.detail,_this.ledgerDetail,const DeepCollectionEquality().hash(_this.openIssues),_this.errorMessage);
}

@override
String toString() {
  final _this = this as WorkerDetailState;
  return 'WorkerDetailState(status: ${_this.status}, detail: ${_this.detail}, ledgerDetail: ${_this.ledgerDetail}, openIssues: ${_this.openIssues}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $WorkerDetailStateCopyWith<$Res>  {
  factory $WorkerDetailStateCopyWith(WorkerDetailState value, $Res Function(WorkerDetailState) _then) = _$WorkerDetailStateCopyWithImpl;
@useResult
$Res call({
 WorkerDetailStatus status, WorkerDetailAggregate? detail, WorkerLedgerDetail? ledgerDetail, List<OpenIssueSummary> openIssues, String? errorMessage
});


$WorkerDetailAggregateCopyWith<$Res>? get detail;

}
/// @nodoc
class _$WorkerDetailStateCopyWithImpl<$Res>
    implements $WorkerDetailStateCopyWith<$Res> {
  _$WorkerDetailStateCopyWithImpl(this._self, this._then);

  final WorkerDetailState _self;
  final $Res Function(WorkerDetailState) _then;

/// Create a copy of WorkerDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? detail = freezed,Object? ledgerDetail = freezed,Object? openIssues = null,Object? errorMessage = freezed,}) {
  return _then(WorkerDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkerDetailStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as WorkerDetailAggregate?,ledgerDetail: freezed == ledgerDetail ? _self.ledgerDetail : ledgerDetail // ignore: cast_nullable_to_non_nullable
as WorkerLedgerDetail?,openIssues: null == openIssues ? _self.openIssues : openIssues // ignore: cast_nullable_to_non_nullable
as List<OpenIssueSummary>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WorkerDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerDetailAggregateCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $WorkerDetailAggregateCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkerDetailState].
extension WorkerDetailStatePatterns on WorkerDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerDetailState value)  $default,){
final _that = this;
switch (_that) {
case _WorkerDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkerDetailStatus status,  WorkerDetailAggregate? detail,  WorkerLedgerDetail? ledgerDetail,  List<OpenIssueSummary> openIssues,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerDetailState() when $default != null:
return $default(_that.status,_that.detail,_that.ledgerDetail,_that.openIssues,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkerDetailStatus status,  WorkerDetailAggregate? detail,  WorkerLedgerDetail? ledgerDetail,  List<OpenIssueSummary> openIssues,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _WorkerDetailState():
return $default(_that.status,_that.detail,_that.ledgerDetail,_that.openIssues,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkerDetailStatus status,  WorkerDetailAggregate? detail,  WorkerLedgerDetail? ledgerDetail,  List<OpenIssueSummary> openIssues,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _WorkerDetailState() when $default != null:
return $default(_that.status,_that.detail,_that.ledgerDetail,_that.openIssues,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _WorkerDetailState implements WorkerDetailState {
  const _WorkerDetailState({this.status = WorkerDetailStatus.initial, this.detail, this.ledgerDetail,  List<OpenIssueSummary> openIssues = const [], this.errorMessage}): _openIssues = openIssues;
  

@override@JsonKey() final  WorkerDetailStatus status;
@override final  WorkerDetailAggregate? detail;
@override final  WorkerLedgerDetail? ledgerDetail;
 final  List<OpenIssueSummary> _openIssues;
@override@JsonKey() List<OpenIssueSummary> get openIssues {
  if (_openIssues is EqualUnmodifiableListView) return _openIssues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openIssues);
}

@override final  String? errorMessage;

/// Create a copy of WorkerDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerDetailStateCopyWith<_WorkerDetailState> get copyWith => __$WorkerDetailStateCopyWithImpl<_WorkerDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerDetailState&&(identical(other.status, status) || other.status == status)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.ledgerDetail, ledgerDetail) || other.ledgerDetail == ledgerDetail)&&const DeepCollectionEquality().equals(other.openIssues, _openIssues)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,detail,ledgerDetail,const DeepCollectionEquality().hash(_openIssues),errorMessage);
}

@override
String toString() {
    return 'WorkerDetailState(status: $status, detail: $detail, ledgerDetail: $ledgerDetail, openIssues: $openIssues, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$WorkerDetailStateCopyWith<$Res> implements $WorkerDetailStateCopyWith<$Res> {
  factory _$WorkerDetailStateCopyWith(_WorkerDetailState value, $Res Function(_WorkerDetailState) _then) = __$WorkerDetailStateCopyWithImpl;
@override @useResult
$Res call({
 WorkerDetailStatus status, WorkerDetailAggregate? detail, WorkerLedgerDetail? ledgerDetail, List<OpenIssueSummary> openIssues, String? errorMessage
});


@override $WorkerDetailAggregateCopyWith<$Res>? get detail;

}
/// @nodoc
class __$WorkerDetailStateCopyWithImpl<$Res>
    implements _$WorkerDetailStateCopyWith<$Res> {
  __$WorkerDetailStateCopyWithImpl(this._self, this._then);

  final _WorkerDetailState _self;
  final $Res Function(_WorkerDetailState) _then;

/// Create a copy of WorkerDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? detail = freezed,Object? ledgerDetail = freezed,Object? openIssues = null,Object? errorMessage = freezed,}) {
  return _then(_WorkerDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkerDetailStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as WorkerDetailAggregate?,ledgerDetail: freezed == ledgerDetail ? _self.ledgerDetail : ledgerDetail // ignore: cast_nullable_to_non_nullable
as WorkerLedgerDetail?,openIssues: null == openIssues ? _self._openIssues : openIssues // ignore: cast_nullable_to_non_nullable
as List<OpenIssueSummary>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WorkerDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerDetailAggregateCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $WorkerDetailAggregateCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}

// dart format on
