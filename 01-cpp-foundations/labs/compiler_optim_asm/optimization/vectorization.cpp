
#include <cstddef>
void add_arrays(double *a, double* b, double* c, std::size_t n){
    for(std::size_t i{0}; i < n; ++i){
        c[i] = a[i] + b[i];
    }
}
