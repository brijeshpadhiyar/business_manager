import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Declarative RBAC UI guard that checks [RbacPolicy.can] against the current
/// signed-in (or offline guest -> Owner) role from [AuthCubit].
final class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final AppPermission permission;
  final Widget child;
  final Widget fallback;

  static bool hasPermission(BuildContext context, AppPermission permission) {
    final authCubit = context.read<AuthCubit?>();
    if (authCubit == null) return true;
    final role = RbacPolicy.effectiveRole(authCubit.state);
    return RbacPolicy.can(role, permission);
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit?>();
    if (authCubit == null) return child;
    return BlocSelector<AuthCubit, AuthState, bool>(
      selector: (state) =>
          RbacPolicy.can(RbacPolicy.effectiveRole(state), permission),
      builder: (context, allowed) => allowed ? child : fallback,
    );
  }
}
