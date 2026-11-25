// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'worker_assignments_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkerAssignmentsState {

 WorkerAssignmentsStatus get status; WorkerEntity? get worker; List<WorkerProcessAssignmentEntity> get assignments; List<WorkerProcessAssignmentEntity> get inactiveAssignments; List<ProcessEntity> get activeProcesses; String? get errorMessage;
/// Create a copy of WorkerAssignmentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerAssignmentsStateCopyWith<WorkerAssignmentsState> get copyWith => _$WorkerAssignmentsStateCopyWithImpl<WorkerAssignmentsState>(this as WorkerAssignmentsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkerAssignmentsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerAssignmentsState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.worker, _this.worker) || other.worker == _this.worker)&&const DeepCollectionEquality().equals(other.assignments, _this.assignments)&&const DeepCollectionEquality().equals(other.inactiveAssignments, _this.inactiveAssignments)&&const DeepCollectionEquality().equals(other.activeProcesses, _this.activeProcesses)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as WorkerAssignmentsState;
  return Object.hash(runtimeType,_this.status,_this.worker,const DeepCollectionEquality().hash(_this.assignments),const DeepCollectionEquality().hash(_this.inactiveAssignments),const DeepCollectionEquality().hash(_this.activeProcesses),_this.errorMessage);
}

@override
String toString() {
  final _this = this as WorkerAssignmentsState;
  return 'WorkerAssignmentsState(status: ${_this.status}, worker: ${_this.worker}, assignments: ${_this.assignments}, inactiveAssignments: ${_this.inactiveAssignments}, activeProcesses: ${_this.activeProcesses}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $WorkerAssignmentsStateCopyWith<$Res>  {
  factory $WorkerAssignmentsStateCopyWith(WorkerAssignmentsState value, $Res Function(WorkerAssignmentsState) _then) = _$WorkerAssignmentsStateCopyWithImpl;
@useResult
$Res call({
 WorkerAssignmentsStatus status, WorkerEntity? worker, List<WorkerProcessAssignmentEntity> assignments, List<WorkerProcessAssignmentEntity> inactiveAssignments, List<ProcessEntity> activeProcesses, String? errorMessage
});


$WorkerEntityCopyWith<$Res>? get worker;

}
/// @nodoc
class _$WorkerAssignmentsStateCopyWithImpl<$Res>
    implements $WorkerAssignmentsStateCopyWith<$Res> {
  _$WorkerAssignmentsStateCopyWithImpl(this._self, this._then);

  final WorkerAssignmentsState _self;
  final $Res Function(WorkerAssignmentsState) _then;

/// Create a copy of WorkerAssignmentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? worker = freezed,Object? assignments = null,Object? inactiveAssignments = null,Object? activeProcesses = null,Object? errorMessage = freezed,}) {
  return _then(WorkerAssignmentsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkerAssignmentsStatus,worker: freezed == worker ? _self.worker : worker // ignore: cast_nullable_to_non_nullable
as WorkerEntity?,assignments: null == assignments ? _self.assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<WorkerProcessAssignmentEntity>,inactiveAssignments: null == inactiveAssignments ? _self.inactiveAssignments : inactiveAssignments // ignore: cast_nullable_to_non_nullable
as List<WorkerProcessAssignmentEntity>,activeProcesses: null == activeProcesses ? _self.activeProcesses : activeProcesses // ignore: cast_nullable_to_non_nullable
as List<ProcessEntity>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WorkerAssignmentsState
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
}
}


/// Adds pattern-matching-related methods to [WorkerAssignmentsState].
extension WorkerAssignmentsStatePatterns on WorkerAssignmentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerAssignmentsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerAssignmentsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerAssignmentsState value)  $default,){
final _that = this;
switch (_that) {
case _WorkerAssignmentsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerAssignmentsState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerAssignmentsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkerAssignmentsStatus status,  WorkerEntity? worker,  List<WorkerProcessAssignmentEntity> assignments,  List<WorkerProcessAssignmentEntity> inactiveAssignments,  List<ProcessEntity> activeProcesses,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerAssignmentsState() when $default != null:
return $default(_that.status,_that.worker,_that.assignments,_that.inactiveAssignments,_that.activeProcesses,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkerAssignmentsStatus status,  WorkerEntity? worker,  List<WorkerProcessAssignmentEntity> assignments,  List<WorkerProcessAssignmentEntity> inactiveAssignments,  List<ProcessEntity> activeProcesses,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _WorkerAssignmentsState():
return $default(_that.status,_that.worker,_that.assignments,_that.inactiveAssignments,_that.activeProcesses,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkerAssignmentsStatus status,  WorkerEntity? worker,  List<WorkerProcessAssignmentEntity> assignments,  List<WorkerProcessAssignmentEntity> inactiveAssignments,  List<ProcessEntity> activeProcesses,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _WorkerAssignmentsState() when $default != null:
return $default(_that.status,_that.worker,_that.assignments,_that.inactiveAssignments,_that.activeProcesses,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _WorkerAssignmentsState implements WorkerAssignmentsState {
  const _WorkerAssignmentsState({this.status = WorkerAssignmentsStatus.initial, this.worker,  List<WorkerProcessAssignmentEntity> assignments = const [],  List<WorkerProcessAssignmentEntity> inactiveAssignments = const [],  List<ProcessEntity> activeProcesses = const [], this.errorMessage}): _assignments = assignments,_inactiveAssignments = inactiveAssignments,_activeProcesses = activeProcesses;
  

@override@JsonKey() final  WorkerAssignmentsStatus status;
@override final  WorkerEntity? worker;
 final  List<WorkerProcessAssignmentEntity> _assignments;
@override@JsonKey() List<WorkerProcessAssignmentEntity> get assignments {
  if (_assignments is EqualUnmodifiableListView) return _assignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignments);
}

 final  List<WorkerProcessAssignmentEntity> _inactiveAssignments;
@override@JsonKey() List<WorkerProcessAssignmentEntity> get inactiveAssignments {
  if (_inactiveAssignments is EqualUnmodifiableListView) return _inactiveAssignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inactiveAssignments);
}

 final  List<ProcessEntity> _activeProcesses;
@override@JsonKey() List<ProcessEntity> get activeProcesses {
  if (_activeProcesses is EqualUnmodifiableListView) return _activeProcesses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeProcesses);
}

@override final  String? errorMessage;

/// Create a copy of WorkerAssignmentsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerAssignmentsStateCopyWith<_WorkerAssignmentsState> get copyWith => __$WorkerAssignmentsStateCopyWithImpl<_WorkerAssignmentsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerAssignmentsState&&(identical(other.status, status) || other.status == status)&&(identical(other.worker, worker) || other.worker == worker)&&const DeepCollectionEquality().equals(other.assignments, _assignments)&&const DeepCollectionEquality().equals(other.inactiveAssignments, _inactiveAssignments)&&const DeepCollectionEquality().equals(other.activeProcesses, _activeProcesses)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,worker,const DeepCollectionEquality().hash(_assignments),const DeepCollectionEquality().hash(_inactiveAssignments),const DeepCollectionEquality().hash(_activeProcesses),errorMessage);
}

@override
String toString() {
    return 'WorkerAssignmentsState(status: $status, worker: $worker, assignments: $assignments, inactiveAssignments: $inactiveAssignments, activeProcesses: $activeProcesses, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$WorkerAssignmentsStateCopyWith<$Res> implements $WorkerAssignmentsStateCopyWith<$Res> {
  factory _$WorkerAssignmentsStateCopyWith(_WorkerAssignmentsState value, $Res Function(_WorkerAssignmentsState) _then) = __$WorkerAssignmentsStateCopyWithImpl;
@override @useResult
$Res call({
 WorkerAssignmentsStatus status, WorkerEntity? worker, List<WorkerProcessAssignmentEntity> assignments, List<WorkerProcessAssignmentEntity> inactiveAssignments, List<ProcessEntity> activeProcesses, String? errorMessage
});


@override $WorkerEntityCopyWith<$Res>? get worker;

}
/// @nodoc
class __$WorkerAssignmentsStateCopyWithImpl<$Res>
    implements _$WorkerAssignmentsStateCopyWith<$Res> {
  __$WorkerAssignmentsStateCopyWithImpl(this._self, this._then);

  final _WorkerAssignmentsState _self;
  final $Res Function(_WorkerAssignmentsState) _then;

/// Create a copy of WorkerAssignmentsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? worker = freezed,Object? assignments = null,Object? inactiveAssignments = null,Object? activeProcesses = null,Object? errorMessage = freezed,}) {
  return _then(_WorkerAssignmentsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkerAssignmentsStatus,worker: freezed == worker ? _self.worker : worker // ignore: cast_nullable_to_non_nullable
as WorkerEntity?,assignments: null == assignments ? _self._assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<WorkerProcessAssignmentEntity>,inactiveAssignments: null == inactiveAssignments ? _self._inactiveAssignments : inactiveAssignments // ignore: cast_nullable_to_non_nullable
as List<WorkerProcessAssignmentEntity>,activeProcesses: null == activeProcesses ? _self._activeProcesses : activeProcesses // ignore: cast_nullable_to_non_nullable
as List<ProcessEntity>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WorkerAssignmentsState
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
}
}

// dart format on
