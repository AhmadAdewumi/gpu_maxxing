

//-- inefficient member ordering -> 24 bytes with internal and tail padding also
#include <chrono>
#include <cstddef>
#include <iomanip>
#include <ios>
#include <iostream>
#include <iterator>
#include <vector>
struct BadParticle {
  char type;
  double position;
  int velocity;
};

//-- efficient member ordering -> 16 bytes with tail padding
// (the last 3 bytes, offsets 13-15)
struct GoodParticle {
  double position;
  int velocity;
  char type;
};

template <typename T> void print_layout(const char *name) {
  const std::size_t data_bytes = sizeof(char) + sizeof(double) + sizeof(int);

  std::cout << "\n" << name << "\n";
  std::cout << "sizeof:  " << sizeof(T) << " bytes\n";
  std::cout << "alignof:  " << alignof(T) << " bytes\n";
  std::cout << "padding:  " << sizeof(T) - data_bytes
            << " bytes per particle\n";
}

void print_offsets() {
  std::cout << "\n Member offsets (bytes from the object start) \n";

  std::cout << "Bad Particle: " << "type = " << offsetof(BadParticle, type)
            << ", position= " << offsetof(BadParticle, position)
            << ", velocity=" << offsetof(BadParticle, velocity) << '\n';

  std::cout << "Good Particle: " << "type = " << offsetof(GoodParticle, type)
            << ", position= " << offsetof(GoodParticle, position)
            << ", velocity=" << offsetof(GoodParticle, velocity) << '\n';
}

// inti bothe layou with values
template <typename T> void initialize(std::vector<T> &particles) {
  for (std::size_t i{0}; i < particles.size(); ++i) {
    particles[i].position = static_cast<double>(i) * 0.01;
    particles[i].velocity = static_cast<int>(i) % 7;
    particles[i].type = (i % 2 == 0 ? 1 : 0);
  }
}

// process the same work on each particle repeatedly
template <typename T>
double benchmark(std::vector<T> &particles, int passes) {
  const auto start = std::chrono::steady_clock::now();

  for (int pass = 0; pass < passes; ++pass) {
    for (T &particle : particles) {
      // position +=  vel * 0.0000001
      particle.position += static_cast<double>(particle.velocity) * 0.0000001;

      if (particle.type == 1) {
        particle.position += 0.00001;
      }
    }
  }

  const auto finish = std::chrono::steady_clock::now();

  return std::chrono::duration<double>(finish - start).count();
}

template <typename T> double checksum(const std::vector<T> &particles) {
  double sum = 0.0;

  for (const T &particle : particles) {
    sum += particle.position;
  }

  return sum;
}

int main() {
  constexpr std::size_t count = 10'000'000;
  constexpr std::size_t passes = 5;

  std::cout << std::fixed << std::setprecision(3);

  // inspecting the layout
  print_layout<BadParticle>("Bad Paricle");
  print_layout<GoodParticle>("Good Paricle");
  print_offsets();

  std::size_t bad_bytes = sizeof(BadParticle) * count;
  std::size_t good_bytes = sizeof(GoodParticle) * count;

  constexpr double MiB = 1024 * 1024;
  std::cout << "\nStorage for " << count << " particles\n";
  std::cout << "BadParticle:  " << bad_bytes / MiB << " MiB\n";
  std::cout << "GoodParticle: " << good_bytes / MiB << " MiB\n";
  std::cout << "Saved:        " << (bad_bytes - good_bytes) / MiB << " MiB\n";
  
  // time for the workload
  std::vector<BadParticle> bad_particles(count);
  std::vector<GoodParticle> good_particles(count);
  
  initialize(bad_particles);
  initialize(good_particles);

  const double bad_particle_measurement_in_seconds =benchmark(bad_particles, passes);
  const double good_particle_measurement_in_seconds =benchmark(good_particles, passes);

  std::cout << "\n benchmark (" << passes << " passes)\n";
  std::cout << "BadParticle:  " << bad_particle_measurement_in_seconds << " seconds\n";
  std::cout << "GoodParticle: " << good_particle_measurement_in_seconds << " seconds\n";

  std::cout << "\nChecksums (should be equal)\n";
  std::cout << "BadParticle:  " << checksum(bad_particles) << '\n';
  std::cout << "GoodParticle: " << checksum(good_particles) << '\n';
}

/**
 * RESULT
 * 
 Bad Paricle
 sizeof:  24 bytes
 alignof:  8 bytes
 padding:  11 bytes per particle
 
 Good Paricle
 sizeof:  16 bytes
 alignof:  8 bytes
 padding:  3 bytes per particle
 
  Member offsets (bytes from the object start)
 Bad Particle: type = 0, position= 8, velocity=16
 Good Particle: type = 12, position= 0, velocity=8
 
 Storage for 10000000 particles
 BadParticle:  228.882 MiB
 GoodParticle: 152.588 MiB
 Saved:        76.294 MiB
 
  benchmark (5 passes)
 BadParticle:  0.101 seconds
 GoodParticle: 0.072 seconds
 
 Checksums (should be equal)
 BadParticle:  499999950264.865
 GoodParticle: 499999950264.865
 */