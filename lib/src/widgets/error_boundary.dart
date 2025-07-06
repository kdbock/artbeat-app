import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that catches and handles errors to prevent app crashes
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.fallback,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;
  FlutterExceptionHandler? _previousOnError;

  @override
  void initState() {
    super.initState();
    // Save the previous error handler
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('❌ Flutter Error caught by ErrorBoundary: ${details.exception}');
        print('❌ Stack trace: ${details.stack}');
      }
      if (widget.onError != null) {
        widget.onError!(details.exception, details.stack ?? StackTrace.current);
      }
      // Defer setState until after build phase
      if (mounted && !_hasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _error = details.exception;
              _stackTrace = details.stack;
            });
          }
        });
      }
      // Optionally call the previous handler
      _previousOnError?.call(details);
    };
  }

  @override
  void dispose() {
    // Restore the previous error handler
    FlutterError.onError = _previousOnError;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildDefaultErrorWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() {
    // Always wrap in Directionality and Material
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error?.toString() ?? 'Unknown error',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _error = null;
                    _stackTrace = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A more specific error boundary for network-related errors
class NetworkErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const NetworkErrorBoundary({Key? key, required this.child, this.onRetry})
    : super(key: key);

  @override
  State<NetworkErrorBoundary> createState() => _NetworkErrorBoundaryState();
}

class _NetworkErrorBoundaryState extends State<NetworkErrorBoundary> {
  bool _hasNetworkError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasNetworkError) {
      return _buildNetworkErrorWidget();
    }

    return widget.child;
  }

  Widget _buildNetworkErrorWidget() {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Network Connection Lost',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasNetworkError = false;
                });
                if (widget.onRetry != null) {
                  widget.onRetry!();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void showNetworkError() {
    if (mounted) {
      setState(() {
        _hasNetworkError = true;
      });
    }
  }
}
