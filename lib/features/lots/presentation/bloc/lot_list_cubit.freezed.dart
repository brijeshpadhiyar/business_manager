// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lot_list_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LotListState {

 LotListStatus get status; List<LotEntity> get lots; String get searchQuery; LotStatus? get statusFilter; String? get errorMessage;
/// Create a copy of LotListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotListStateCopyWith<LotListState> get copyWith => _$LotListStateCopyWithImpl<LotListState>(this as LotListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LotListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LotListState&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.lots, _this.lots)&&(identical(other.searchQuery, _this.searchQuery) || other.searchQuery == _this.searchQuery)&&(identical(other.statusFilter, _this.statusFilter) || other.statusFilter == _this.statusFilter)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as LotListState;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.lots),_this.searchQuery,_this.statusFilter,_this.errorMessage);
}

@override
String toString() {
  final _this = this as LotListState;
  return 'LotListState(status: ${_this.status}, lots: ${_this.lots}, searchQuery: ${_this.searchQuery}, statusFilter: ${_this.statusFilter}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $LotListStateCopyWith<$Res>  {
  factory $LotListStateCopyWith(LotListState value, $Res Function(LotListState) _then) = _$LotListStateCopyWithImpl;
@useResult
$Res call({
 LotListStatus status, List<LotEntity> lots, String searchQuery, LotStatus? statusFilter, String? errorMessage
});




}
/// @nodoc
class _$LotListStateCopyWithImpl<$Res>
    implements $LotListStateCopyWith<$Res> {
  _$LotListStateCopyWithImpl(this._self, this._then);

  final LotListState _self;
  final $Res Function(LotListState) _then;

/// Create a copy of LotListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? lots = null,Object? searchQuery = null,Object? statusFilter = freezed,Object? errorMessage = freezed,}) {
  return _then(LotListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LotListStatus,lots: null == lots ? _self.lots : lots // ignore: cast_nullable_to_non_nullable
as List<LotEntity>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as LotStatus?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LotListState].
extension LotListStatePatterns on LotListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LotListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LotListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LotListState value)  $default,){
final _that = this;
switch (_that) {
case _LotListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LotListState value)?  $default,){
final _that = this;
switch (_that) {
case _LotListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LotListStatus status,  List<LotEntity> lots,  String searchQuery,  LotStatus? statusFilter,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LotListState() when $default != null:
return $default(_that.status,_that.lots,_that.searchQuery,_that.statusFilter,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LotListStatus status,  List<LotEntity> lots,  String searchQuery,  LotStatus? statusFilter,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _LotListState():
return $default(_that.status,_that.lots,_that.searchQuery,_that.statusFilter,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LotListStatus status,  List<LotEntity> lots,  String searchQuery,  LotStatus? statusFilter,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _LotListState() when $default != null:
return $default(_that.status,_that.lots,_that.searchQuery,_that.statusFilter,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _LotListState implements LotListState {
  const _LotListState({this.status = LotListStatus.initial,  List<LotEntity> lots = const [], this.searchQuery = '', this.statusFilter, this.errorMessage}): _lots = lots;
  

@override@JsonKey() final  LotListStatus status;
 final  List<LotEntity> _lots;
@override@JsonKey() List<LotEntity> get lots {
  if (_lots is EqualUnmodifiableListView) return _lots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lots);
}

@override@JsonKey() final  String searchQuery;
@override final  LotStatus? statusFilter;
@override final  String? errorMessage;

/// Create a copy of LotListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotListStateCopyWith<_LotListState> get copyWith => __$LotListStateCopyWithImpl<_LotListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LotListState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.lots, _lots)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_lots),searchQuery,statusFilter,errorMessage);
}

@override
String toString() {
    return 'LotListState(status: $status, lots: $lots, searchQuery: $searchQuery, statusFilter: $statusFilter, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$LotListStateCopyWith<$Res> implements $LotListStateCopyWith<$Res> {
  factory _$LotListStateCopyWith(_LotListState value, $Res Function(_LotListState) _then) = __$LotListStateCopyWithImpl;
@override @useResult
$Res call({
 LotListStatus status, List<LotEntity> lots, String searchQuery, LotStatus? statusFilter, String? errorMessage
});




}
/// @nodoc
class __$LotListStateCopyWithImpl<$Res>
    implements _$LotListStateCopyWith<$Res> {
  __$LotListStateCopyWithImpl(this._self, this._then);

  final _LotListState _self;
  final $Res Function(_LotListState) _then;

/// Create a copy of LotListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? lots = null,Object? searchQuery = null,Object? statusFilter = freezed,Object? errorMessage = freezed,}) {
  return _then(_LotListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LotListStatus,lots: null == lots ? _self._lots : lots // ignore: cast_nullable_to_non_nullable
as List<LotEntity>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as LotStatus?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
