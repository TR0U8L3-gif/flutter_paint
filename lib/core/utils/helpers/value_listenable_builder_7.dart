import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ValueListenableBuilder7<A, B, C, D, E, F, G> extends StatelessWidget {
  const ValueListenableBuilder7({
    super.key,
    required this.valueListenableA,
    required this.valueListenableB,
    required this.valueListenableC,
    required this.valueListenableD,
    required this.valueListenableE,
    required this.valueListenableF,
    required this.valueListenableG,
    required this.builder,
    this.child,
  });

  final ValueListenable<A> valueListenableA;
  final ValueListenable<B> valueListenableB;
  final ValueListenable<C> valueListenableC;
  final ValueListenable<D> valueListenableD;
  final ValueListenable<E> valueListenableE;
  final ValueListenable<F> valueListenableF;
  final ValueListenable<G> valueListenableG;
  final Widget? child;
  final Widget Function(BuildContext context, A a, B b, C c, D d, E e, F f, G g, Widget? child) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
        valueListenable: valueListenableA,
        builder: (_, a, __) {
          return ValueListenableBuilder<B>(
            valueListenable: valueListenableB,
            builder: (context, b, __) {
              return ValueListenableBuilder<C>(
                valueListenable: valueListenableC,
                builder: (context, c, __) {
                  return ValueListenableBuilder<D>(
                    valueListenable: valueListenableD,
                    builder: (context, d, __) {
                      return ValueListenableBuilder<E>(
                        valueListenable: valueListenableE,
                        builder: (context, e, __) {
                          return ValueListenableBuilder<F>(
                            valueListenable: valueListenableF,
                            builder: (context, f, __) {
                              return ValueListenableBuilder<G>(
                                valueListenable: valueListenableG,
                                builder: (context, g, __) {
                                  return builder(context, a, b, c, d, e, f, g, child);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
}
