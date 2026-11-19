/// A simple counter. `increment` is wrong: it never gets past 1.
class Counter {
  int _value = 0;

  int get value => _value;

  int increment() {
    _value = 1;
    return _value;
  }
}
