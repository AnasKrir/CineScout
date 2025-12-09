import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cinescout/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cinescout/features/auth/presentation/bloc/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  bool _minDurationPassed = false;
  bool _authResolved = false;
  String? _targetRoute;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Durée minimale d’affichage du splash
    Future.delayed(const Duration(milliseconds: 1800), () {
      _minDurationPassed = true;
      _tryNavigate();
    });
  }

  void _tryNavigate() {
    if (_navigated || !_minDurationPassed || !_authResolved || _targetRoute == null) {
      return;
    }
    _navigated = true;
    if (mounted) {
      context.go(_targetRoute!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is Authenticated || current is Unauthenticated,
      listener: (context, state) {
        if (state is Authenticated) {
          _targetRoute = '/home';
        } else if (state is Unauthenticated) {
          _targetRoute = '/login';
        }
        _authResolved = true;
        _tryNavigate();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CineScout',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Films & séries',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 3,
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        backgroundColor:
                            colorScheme.onSurface.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
