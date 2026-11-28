// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ThemeState {

 AppThemePreference get preference; AppSurfaceStyle get surfaceStyle; AppThemePreset get preset;
/// Create a copy of ThemeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThemeStateCopyWith<ThemeState> get copyWith => _$ThemeStateCopyWithImpl<ThemeState>(this as ThemeState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ThemeState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThemeState&&(identical(other.preference, _this.preference) || other.preference == _this.preference)&&(identical(other.surfaceStyle, _this.surfaceStyle) || other.surfaceStyle == _this.surfaceStyle)&&(identical(other.preset, _this.preset) || other.preset == _this.preset));
}


@override
int get hashCode {
  final _this = this as ThemeState;
  return Object.hash(runtimeType,_this.preference,_this.surfaceStyle,_this.preset);
}

@override
String toString() {
  final _this = this as ThemeState;
  return 'ThemeState(preference: ${_this.preference}, surfaceStyle: ${_this.surfaceStyle}, preset: ${_this.preset})';
}


}

/// @nodoc
abstract mixin class $ThemeStateCopyWith<$Res>  {
  factory $ThemeStateCopyWith(ThemeState value, $Res Function(ThemeState) _then) = _$ThemeStateCopyWithImpl;
@useResult
$Res call({
 AppThemePreference preference, AppSurfaceStyle surfaceStyle, AppThemePreset preset
});




}
/// @nodoc
class _$ThemeStateCopyWithImpl<$Res>
    implements $ThemeStateCopyWith<$Res> {
  _$ThemeStateCopyWithImpl(this._self, this._then);

  final ThemeState _self;
  final $Res Function(ThemeState) _then;

/// Create a copy of ThemeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preference = null,Object? surfaceStyle = null,Object? preset = null,}) {
  return _then(ThemeState(
preference: null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as AppThemePreference,surfaceStyle: null == surfaceStyle ? _self.surfaceStyle : surfaceStyle // ignore: cast_nullable_to_non_nullable
as AppSurfaceStyle,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as AppThemePreset,
  ));
}

}


/// Adds pattern-matching-related methods to [ThemeState].
extension ThemeStatePatterns on ThemeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThemeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThemeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThemeState value)  $default,){
final _that = this;
switch (_that) {
case _ThemeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThemeState value)?  $default,){
final _that = this;
switch (_that) {
case _ThemeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemePreference preference,  AppSurfaceStyle surfaceStyle,  AppThemePreset preset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThemeState() when $default != null:
return $default(_that.preference,_that.surfaceStyle,_that.preset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemePreference preference,  AppSurfaceStyle surfaceStyle,  AppThemePreset preset)  $default,) {final _that = this;
switch (_that) {
case _ThemeState():
return $default(_that.preference,_that.surfaceStyle,_that.preset);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemePreference preference,  AppSurfaceStyle surfaceStyle,  AppThemePreset preset)?  $default,) {final _that = this;
switch (_that) {
case _ThemeState() when $default != null:
return $default(_that.preference,_that.surfaceStyle,_that.preset);case _:
  return null;

}
}

}

/// @nodoc


class _ThemeState implements ThemeState {
  const _ThemeState({this.preference = AppThemePreference.system, this.surfaceStyle = AppSurfaceStyle.modernGlass, this.preset = AppThemePreset.indigoThread});
  

@override@JsonKey() final  AppThemePreference preference;
@override@JsonKey() final  AppSurfaceStyle surfaceStyle;
@override@JsonKey() final  AppThemePreset preset;

/// Create a copy of ThemeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThemeStateCopyWith<_ThemeState> get copyWith => __$ThemeStateCopyWithImpl<_ThemeState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThemeState&&(identical(other.preference, preference) || other.preference == preference)&&(identical(other.surfaceStyle, surfaceStyle) || other.surfaceStyle == surfaceStyle)&&(identical(other.preset, preset) || other.preset == preset));
}


@override
int get hashCode {
    return Object.hash(runtimeType,preference,surfaceStyle,preset);
}

@override
String toString() {
    return 'ThemeState(preference: $preference, surfaceStyle: $surfaceStyle, preset: $preset)';
}


}

/// @nodoc
abstract mixin class _$ThemeStateCopyWith<$Res> implements $ThemeStateCopyWith<$Res> {
  factory _$ThemeStateCopyWith(_ThemeState value, $Res Function(_ThemeState) _then) = __$ThemeStateCopyWithImpl;
@override @useResult
$Res call({
 AppThemePreference preference, AppSurfaceStyle surfaceStyle, AppThemePreset preset
});




}
/// @nodoc
class __$ThemeStateCopyWithImpl<$Res>
    implements _$ThemeStateCopyWith<$Res> {
  __$ThemeStateCopyWithImpl(this._self, this._then);

  final _ThemeState _self;
  final $Res Function(_ThemeState) _then;

/// Create a copy of ThemeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preference = null,Object? surfaceStyle = null,Object? preset = null,}) {
  return _then(_ThemeState(
preference: null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as AppThemePreference,surfaceStyle: null == surfaceStyle ? _self.surfaceStyle : surfaceStyle // ignore: cast_nullable_to_non_nullable
as AppSurfaceStyle,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as AppThemePreset,
  ));
}


}

// dart format on
