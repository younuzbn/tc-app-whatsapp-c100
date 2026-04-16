class CounterService {
  int _counter = 0;

  int get counter => _counter;

  int increment() {
    _counter++;
    return _counter;
  }
}
