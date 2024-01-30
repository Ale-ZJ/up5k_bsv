
#include <iostream>
#include <chrono>


#define ITERATIONS 10000

class LinearCongruentialPRNG {
private:
	uint32_t current_value;
public:
	LinearCongruentialPRNG(int seed) : current_value(seed) {}


	uint32_t generate() {
		current_value = current_value * 22695477 + 1;
		return current_value;
	}
};

static inline uint32_t evil_log(float x) {
	return ((reinterpret_cast<int &>(x) & 0x7F800000) >> 23) - 127;
}

static inline float to_float(uint32_t x) {
   const union { uint32_t i; float d; } u = { .i = UINT32_C(0x3FF) << 23 | x >> 9 };
   return u.d - 1.0;
}

int main() {

	LinearCongruentialPRNG prng = LinearCongruentialPRNG(7);

	for(int i = 0; i < ITERATIONS; i++) { 

		auto start = std::chrono::steady_clock::now();

		unsigned rand_int = prng.generate();

		float f1 = to_float(rand_int);

		rand_int = prng.generate();

		float f2 = to_float(rand_int);


		
		float noise = static_cast<float>(evil_log(f1) - evil_log(f2));

		auto end = std::chrono::steady_clock::now();
	}


	return 1;
}