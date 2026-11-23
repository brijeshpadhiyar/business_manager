// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rate_history_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RateHistoryState {

 RateHistoryStatus get status; WorkerEntity? get worker; List<ProcessEntity> get processes; String? get selectedProcessId; List<MemberProcessRateEntity> get rates; MemberProcessRateEntity? get currentRate; String? get errorMessage;
/// Create a copy of RateHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateHistoryStateCopyWith<RateHistoryState> get copyWith => _$RateHistoryStateCopyWithImpl<RateHistoryState>(this as RateHistoryState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RateHistoryState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RateHistoryState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.worker, _this.worker) || other.worker == _this.worker)&&const DeepCollectionEquality().equals(other.processes, _this.processes)&&(identical(other.selectedProcessId, _this.selectedProcessId) || other.selectedProcessId == _this.selectedProcessId)&&const DeepCollectionEquality().equals(other.rates, _this.rates)&&(identical(other.currentRate, _this.currentRate) || other.currentRate == _this.currentRate)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as RateHistoryState;
  return Object.hash(runtimeType,_this.status,_this.worker,const DeepCollectionEquality().hash(_this.processes),_this.selectedProcessId,const DeepCollectionEquality().hash(_this.rates),_this.currentRate,_this.errorMessage);
}

@override
String toString() {
  final _this = this as RateHistoryState;
  return 'RateHistoryState(status: ${_this.status}, worker: ${_this.worker}, processes: ${_this.processes}, selectedProcessId: ${_this.selectedProcessId}, rates: ${_this.rates}, currentRate: ${_this.currentRate}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $RateHistoryStateCopyWith<$Res>  {
  factory $RateHistoryStateCopyWith(RateHistoryState value, $Res Function(RateHistoryState) _then) = _$RateHistoryStateCopyWithImpl;
@useResult
$Res call({
 RateHistoryStatus status, WorkerEntity? worker, List<ProcessEntity> processes, String? selectedProcessId, List<MemberProcessRateEntity> rates, MemberProcessRateEntity? currentRate, String? errorMessage
});


$WorkerEntityCopyWith<$Res>? get worker;$MemberProcessRateEntityCopyWith<$Res>? get currentRate;

}
/// @nodoc
class _$RateHistoryStateCopyWithImpl<$Res>
    implements $RateHistoryStateCopyWith<$Res> {
  _$RateHistoryStateCopyWithImpl(this._self, this._then);

  final RateHistoryState _self;
  final $Res Function(RateHistoryState) _then;

/// Create a copy of RateHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? worker = freezed,Object? processes = null,Object? selectedProcessId = freezed,Object? rates = null,Object? currentRate = freezed,Object? errorMessage = freezed,}) {
  return _then(RateHistoryState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RateHistoryStatus,worker: freezed == worker ? _self.worker : worker // ignore: cast_nullable_to_non_nullable
as WorkerEntity?,processes: null == processes ? _self.processes : processes // ignore: cast_nullable_to_non_nullable
as List<ProcessEntity>,selectedProcessId: freezed == selectedProcessId ? _self.selectedProcessId : selectedProcessId // ignore: cast_nullable_to_non_nullable
as String?,rates: null == rates ? _self.rates : rates // ignore: cast_nullable_to_non_nullable
as List<MemberProcessRateEntity>,currentRate: freezed == currentRate ? _self.currentRate : currentRate // ignore: cast_nullable_to_non_nullable
as MemberProcessRateEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RateHistoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerEntityCopyWith<$Res>? get worker {
    if (_self.worker == null) {
    return null;
  }

  return $WorkerEntityCopyWith<$Res>(_self.worker!, (value) {
    return _then(_self.copyWith(worker: value));
  });
}/// Create a copy of RateHistoryState
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


/// Adds pattern-matching-related methods to [RateHistoryState].
extension RateHistoryStatePatterns on RateHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RateHistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RateHistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RateHistoryState value)  $default,){
final _that = this;
switch (_that) {
case _RateHistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RateHistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _RateHistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RateHistoryStatus status,  WorkerEntity? worker,  List<ProcessEntity> processes,  String? selectedProcessId,  List<MemberProcessRateEntity> rates,  MemberProcessRateEntity? currentRate,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RateHistoryState() when $default != null:
return $default(_that.status,_that.worker,_that.processes,_that.selectedProcessId,_that.rates,_that.currentRate,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RateHistoryStatus status,  WorkerEntity? worker,  List<ProcessEntity> processes,  String? selectedProcessId,  List<MemberProcessRateEntity> rates,  MemberProcessRateEntity? currentRate,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _RateHistoryState():
return $default(_that.status,_that.worker,_that.processes,_that.selectedProcessId,_that.rates,_that.currentRate,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RateHistoryStatus status,  WorkerEntity? worker,  List<ProcessEntity> processes,  String? selectedProcessId,  List<MemberProcessRateEntity> rates,  MemberProcessRateEntity? currentRate,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _RateHistoryState() when $default != null:
return $default(_that.status,_that.worker,_that.processes,_that.selectedProcessId,_that.rates,_that.currentRate,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _RateHistoryState implements RateHistoryState {
  const _RateHistoryState({this.status = RateHistoryStatus.initial, this.worker,  List<ProcessEntity> processes = const [], this.selectedProcessId,  List<MemberProcessRateEntity> rates = const [], this.currentRate, this.errorMessage}): _processes = processes,_rates = rates;
  

@override@JsonKey() final  RateHistoryStatus status;
@override final  WorkerEntity? worker;
 final  List<ProcessEntity> _processes;
@override@JsonKey() List<ProcessEntity> get processes {
  if (_processes is EqualUnmodifiableListView) return _processes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_processes);
}

@override final  String? selectedProcessId;
 final  List<MemberProcessRateEntity> _rates;
@override@JsonKey() List<MemberProcessRateEntity> get rates {
  if (_rates is EqualUnmodifiableListView) return _rates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rates);
}

@override final  MemberProcessRateEntity? currentRate;
@override final  String? errorMessage;

/// Create a copy of RateHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RateHistoryStateCopyWith<_RateHistoryState> get copyWith => __$RateHistoryStateCopyWithImpl<_RateHistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RateHistoryState&&(identical(other.status, status) || other.status == status)&&(identical(other.worker, worker) || other.worker == worker)&&const DeepCollectionEquality().equals(other.processes, _processes)&&(identical(other.selectedProcessId, selectedProcessId) || other.selectedProcessId == selectedProcessId)&&const DeepCollectionEquality().equals(other.rates, _rates)&&(identical(other.currentRate, currentRate) || other.currentRate == currentRate)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,worker,const DeepCollectionEquality().hash(_processes),selectedProcessId,const DeepCollectionEquality().hash(_rates),currentRate,errorMessage);
}

@override
String toString() {
    return 'RateHistoryState(status: $status, worker: $worker, processes: $processes, selectedProcessId: $selectedProcessId, rates: $rates, currentRate: $currentRate, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$RateHistoryStateCopyWith<$Res> implements $RateHistoryStateCopyWith<$Res> {
  factory _$RateHistoryStateCopyWith(_RateHistoryState value, $Res Function(_RateHistoryState) _then) = __$RateHistoryStateCopyWithImpl;
@override @useResult
$Res call({
 RateHistoryStatus status, WorkerEntity? worker, List<ProcessEntity> processes, String? selectedProcessId, List<MemberProcessRateEntity> rates, MemberProcessRateEntity? currentRate, String? errorMessage
});


@override $WorkerEntityCopyWith<$Res>? get worker;@override $MemberProcessRateEntityCopyWith<$Res>? get currentRate;

}
/// @nodoc
class __$RateHistoryStateCopyWithImpl<$Res>
    implements _$RateHistoryStateCopyWith<$Res> {
  __$RateHistoryStateCopyWithImpl(this._self, this._then);

  final _RateHistoryState _self;
  final $Res Function(_RateHistoryState) _then;

/// Create a copy of RateHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? worker = freezed,Object? processes = null,Object? selectedProcessId = freezed,Object? rates = null,Object? currentRate = freezed,Object? errorMessage = freezed,}) {
  return _then(_RateHistoryState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RateHistoryStatus,worker: freezed == worker ? _self.worker : worker // ignore: cast_nullable_to_non_nullable
as WorkerEntity?,processes: null == processes ? _self._processes : processes // ignore: cast_nullable_to_non_nullable
as List<ProcessEntity>,selectedProcessId: freezed == selectedProcessId ? _self.selectedProcessId : selectedProcessId // ignore: cast_nullable_to_non_nullable
as String?,rates: null == rates ? _self._rates : rates // ignore: cast_nullable_to_non_nullable
as List<MemberProcessRateEntity>,currentRate: freezed == currentRate ? _self.currentRate : currentRate // ignore: cast_nullable_to_non_nullable
as MemberProcessRateEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RateHistoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkerEntityCopyWith<$Res>? get worker {
    if (_self.worker == null) {
    return null;
  }

  return $WorkerEntityCopyWith<$Res>(_self.worker!, (value) {
    return _then(_self.copyWith(worker: value));
  });
}/// Create a copy of RateHistoryState
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

// dart format on
