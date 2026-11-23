// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'process_list_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProcessListState {

 ProcessListStatus get status; List<ProcessEntity> get processes; String get searchQuery; bool? get activeFilter; String? get errorMessage;
/// Create a copy of ProcessListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessListStateCopyWith<ProcessListState> get copyWith => _$ProcessListStateCopyWithImpl<ProcessListState>(this as ProcessListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProcessListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessListState&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.processes, _this.processes)&&(identical(other.searchQuery, _this.searchQuery) || other.searchQuery == _this.searchQuery)&&(identical(other.activeFilter, _this.activeFilter) || other.activeFilter == _this.activeFilter)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as ProcessListState;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.processes),_this.searchQuery,_this.activeFilter,_this.errorMessage);
}

@override
String toString() {
  final _this = this as ProcessListState;
  return 'ProcessListState(status: ${_this.status}, processes: ${_this.processes}, searchQuery: ${_this.searchQuery}, activeFilter: ${_this.activeFilter}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $ProcessListStateCopyWith<$Res>  {
  factory $ProcessListStateCopyWith(ProcessListState value, $Res Function(ProcessListState) _then) = _$ProcessListStateCopyWithImpl;
@useResult
$Res call({
 ProcessListStatus status, List<ProcessEntity> processes, String searchQuery, bool? activeFilter, String? errorMessage
});




}
/// @nodoc
class _$ProcessListStateCopyWithImpl<$Res>
    implements $ProcessListStateCopyWith<$Res> {
  _$ProcessListStateCopyWithImpl(this._self, this._then);

  final ProcessListState _self;
  final $Res Function(ProcessListState) _then;

/// Create a copy of ProcessListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? processes = null,Object? searchQuery = null,Object? activeFilter = freezed,Object? errorMessage = freezed,}) {
  return _then(ProcessListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProcessListStatus,processes: null == processes ? _self.processes : processes // ignore: cast_nullable_to_non_nullable
as List<ProcessEntity>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,activeFilter: freezed == activeFilter ? _self.activeFilter : activeFilter // ignore: cast_nullable_to_non_nullable
as bool?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProcessListState].
extension ProcessListStatePatterns on ProcessListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessListState value)  $default,){
final _that = this;
switch (_that) {
case _ProcessListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessListState value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProcessListStatus status,  List<ProcessEntity> processes,  String searchQuery,  bool? activeFilter,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessListState() when $default != null:
return $default(_that.status,_that.processes,_that.searchQuery,_that.activeFilter,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProcessListStatus status,  List<ProcessEntity> processes,  String searchQuery,  bool? activeFilter,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ProcessListState():
return $default(_that.status,_that.processes,_that.searchQuery,_that.activeFilter,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProcessListStatus status,  List<ProcessEntity> processes,  String searchQuery,  bool? activeFilter,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ProcessListState() when $default != null:
return $default(_that.status,_that.processes,_that.searchQuery,_that.activeFilter,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessListState implements ProcessListState {
  const _ProcessListState({this.status = ProcessListStatus.initial,  List<ProcessEntity> processes = const [], this.searchQuery = '', this.activeFilter, this.errorMessage}): _processes = processes;
  

@override@JsonKey() final  ProcessListStatus status;
 final  List<ProcessEntity> _processes;
@override@JsonKey() List<ProcessEntity> get processes {
  if (_processes is EqualUnmodifiableListView) return _processes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_processes);
}

@override@JsonKey() final  String searchQuery;
@override final  bool? activeFilter;
@override final  String? errorMessage;

/// Create a copy of ProcessListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessListStateCopyWith<_ProcessListState> get copyWith => __$ProcessListStateCopyWithImpl<_ProcessListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessListState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.processes, _processes)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.activeFilter, activeFilter) || other.activeFilter == activeFilter)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_processes),searchQuery,activeFilter,errorMessage);
}

@override
String toString() {
    return 'ProcessListState(status: $status, processes: $processes, searchQuery: $searchQuery, activeFilter: $activeFilter, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ProcessListStateCopyWith<$Res> implements $ProcessListStateCopyWith<$Res> {
  factory _$ProcessListStateCopyWith(_ProcessListState value, $Res Function(_ProcessListState) _then) = __$ProcessListStateCopyWithImpl;
@override @useResult
$Res call({
 ProcessListStatus status, List<ProcessEntity> processes, String searchQuery, bool? activeFilter, String? errorMessage
});




}
/// @nodoc
class __$ProcessListStateCopyWithImpl<$Res>
    implements _$ProcessListStateCopyWith<$Res> {
  __$ProcessListStateCopyWithImpl(this._self, this._then);

  final _ProcessListState _self;
  final $Res Function(_ProcessListState) _then;

/// Create a copy of ProcessListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? processes = null,Object? searchQuery = null,Object? activeFilter = freezed,Object? errorMessage = freezed,}) {
  return _then(_ProcessListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProcessListStatus,processes: null == processes ? _self._processes : processes // ignore: cast_nullable_to_non_nullable
as List<ProcessEntity>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,activeFilter: freezed == activeFilter ? _self.activeFilter : activeFilter // ignore: cast_nullable_to_non_nullable
as bool?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
