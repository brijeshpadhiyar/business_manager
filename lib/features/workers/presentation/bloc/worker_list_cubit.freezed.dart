// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'worker_list_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkerListState {

 WorkerListStatus get status; List<WorkerEntity> get workers; String get searchQuery; bool? get activeFilter; String? get errorMessage;
/// Create a copy of WorkerListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkerListStateCopyWith<WorkerListState> get copyWith => _$WorkerListStateCopyWithImpl<WorkerListState>(this as WorkerListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkerListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkerListState&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.workers, _this.workers)&&(identical(other.searchQuery, _this.searchQuery) || other.searchQuery == _this.searchQuery)&&(identical(other.activeFilter, _this.activeFilter) || other.activeFilter == _this.activeFilter)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as WorkerListState;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.workers),_this.searchQuery,_this.activeFilter,_this.errorMessage);
}

@override
String toString() {
  final _this = this as WorkerListState;
  return 'WorkerListState(status: ${_this.status}, workers: ${_this.workers}, searchQuery: ${_this.searchQuery}, activeFilter: ${_this.activeFilter}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $WorkerListStateCopyWith<$Res>  {
  factory $WorkerListStateCopyWith(WorkerListState value, $Res Function(WorkerListState) _then) = _$WorkerListStateCopyWithImpl;
@useResult
$Res call({
 WorkerListStatus status, List<WorkerEntity> workers, String searchQuery, bool? activeFilter, String? errorMessage
});




}
/// @nodoc
class _$WorkerListStateCopyWithImpl<$Res>
    implements $WorkerListStateCopyWith<$Res> {
  _$WorkerListStateCopyWithImpl(this._self, this._then);

  final WorkerListState _self;
  final $Res Function(WorkerListState) _then;

/// Create a copy of WorkerListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? workers = null,Object? searchQuery = null,Object? activeFilter = freezed,Object? errorMessage = freezed,}) {
  return _then(WorkerListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkerListStatus,workers: null == workers ? _self.workers : workers // ignore: cast_nullable_to_non_nullable
as List<WorkerEntity>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,activeFilter: freezed == activeFilter ? _self.activeFilter : activeFilter // ignore: cast_nullable_to_non_nullable
as bool?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkerListState].
extension WorkerListStatePatterns on WorkerListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkerListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkerListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkerListState value)  $default,){
final _that = this;
switch (_that) {
case _WorkerListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkerListState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkerListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkerListStatus status,  List<WorkerEntity> workers,  String searchQuery,  bool? activeFilter,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkerListState() when $default != null:
return $default(_that.status,_that.workers,_that.searchQuery,_that.activeFilter,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkerListStatus status,  List<WorkerEntity> workers,  String searchQuery,  bool? activeFilter,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _WorkerListState():
return $default(_that.status,_that.workers,_that.searchQuery,_that.activeFilter,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkerListStatus status,  List<WorkerEntity> workers,  String searchQuery,  bool? activeFilter,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _WorkerListState() when $default != null:
return $default(_that.status,_that.workers,_that.searchQuery,_that.activeFilter,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _WorkerListState implements WorkerListState {
  const _WorkerListState({this.status = WorkerListStatus.initial,  List<WorkerEntity> workers = const [], this.searchQuery = '', this.activeFilter, this.errorMessage}): _workers = workers;
  

@override@JsonKey() final  WorkerListStatus status;
 final  List<WorkerEntity> _workers;
@override@JsonKey() List<WorkerEntity> get workers {
  if (_workers is EqualUnmodifiableListView) return _workers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workers);
}

@override@JsonKey() final  String searchQuery;
@override final  bool? activeFilter;
@override final  String? errorMessage;

/// Create a copy of WorkerListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkerListStateCopyWith<_WorkerListState> get copyWith => __$WorkerListStateCopyWithImpl<_WorkerListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkerListState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.workers, _workers)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.activeFilter, activeFilter) || other.activeFilter == activeFilter)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_workers),searchQuery,activeFilter,errorMessage);
}

@override
String toString() {
    return 'WorkerListState(status: $status, workers: $workers, searchQuery: $searchQuery, activeFilter: $activeFilter, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$WorkerListStateCopyWith<$Res> implements $WorkerListStateCopyWith<$Res> {
  factory _$WorkerListStateCopyWith(_WorkerListState value, $Res Function(_WorkerListState) _then) = __$WorkerListStateCopyWithImpl;
@override @useResult
$Res call({
 WorkerListStatus status, List<WorkerEntity> workers, String searchQuery, bool? activeFilter, String? errorMessage
});




}
/// @nodoc
class __$WorkerListStateCopyWithImpl<$Res>
    implements _$WorkerListStateCopyWith<$Res> {
  __$WorkerListStateCopyWithImpl(this._self, this._then);

  final _WorkerListState _self;
  final $Res Function(_WorkerListState) _then;

/// Create a copy of WorkerListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? workers = null,Object? searchQuery = null,Object? activeFilter = freezed,Object? errorMessage = freezed,}) {
  return _then(_WorkerListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkerListStatus,workers: null == workers ? _self._workers : workers // ignore: cast_nullable_to_non_nullable
as List<WorkerEntity>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,activeFilter: freezed == activeFilter ? _self.activeFilter : activeFilter // ignore: cast_nullable_to_non_nullable
as bool?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
