
double multiply(double a, double b) { return a * b; }

int main() {
  // volatile doesn't optimize read or write to this variable,
  // it is always directly access from the memory
  volatile double input = 3.0;
  double result = multiply(input, 4.0);
  return result == 12.0 ? 0 : 1;
}
