
#include <iostream>
#include <chrono>
#include <fstream>
#include <cmath>
#define ITERATIONS 10000

// class LinearCongruentialPRNG {
// private:
// 	uint32_t current_value;
// public:
// 	LinearCongruentialPRNG(int seed) : current_value(seed) {}


// 	uint32_t generate() {
// 		current_value = current_value * 22695477 + 1;
// 		return current_value;
// 	}
// };

class TausworthePRNG { 
private:
	uint32_t lsfr0 = 0x2a85eacf; //actually 30 bits
	uint32_t lsfr1 = 0x5de46c20; //actually 31 bits
	uint32_t lsfr2 = 0x884c2686; //actually 32 bits

	uint32_t const0 = 4294967294;
	uint32_t const1 = 4294967288;
	uint32_t const2 = 4294967280;

public:	
	void seed(uint32_t seed0, uint32_t seed1, uint32_t seed2) {
		lsfr0 = seed0, lsfr1 = seed1, lsfr2 = seed2;
	}
	void step() {
		lsfr0 = (((lsfr0 << 13)^lsfr0) >> 19)^((lsfr0 & const0) << 12);
		lsfr1 = (((lsfr1 << 2) ^lsfr1) >> 25)^((lsfr1 & const1) << 4);
		lsfr2 = (((lsfr2 << 3) ^lsfr2) >> 11)^((lsfr2 & const2) << 17);
	}
	// uint32_t get_bit() {
	// 	return (lsfr0 & 1) ^ (lsfr1 & 1);
	// }

	uint32_t generate() {
		step();
		return (lsfr0 ^ lsfr1 ^ lsfr2);
	}
};

static inline uint32_t evil_log(float x) {
	return ((reinterpret_cast<int &>(x) & 0x7F800000) >> 23) - 127;
}

static inline float less_evil_log(float x) {
	float integer_part = static_cast<float>(((reinterpret_cast<int &>(x) & 0x7F800000) >> 23) - 127);
	float mantissa_part = + static_cast<float>(reinterpret_cast<int &>(x) & 0x007fffff)*(std::pow(2.0, -23)) + (0.03125);
	// std::cout << integer_part << "," << mantissa_part << std::endl;
	return (integer_part + mantissa_part);
}

static inline float to_float(uint32_t x) {
   const union { uint32_t i; float d; } u = { .i = UINT32_C(0x3FF) << 23 | x >> 9 };
   return u.d - 1.0;
}

int main() {

	TausworthePRNG prng0 = TausworthePRNG();
	prng0.seed(0x2facf7c9, 0xe445afa9, 0x844d1d3b);
	TausworthePRNG prng1 = TausworthePRNG();
	prng1.seed(0xe74f2c5a, 0x38e112c8, 0x8699361b);

	std::ofstream stats_file("timing.log");

	for(int i = 0; i < ITERATIONS; i++) { 

		auto start = std::chrono::steady_clock::now();

		uint32_t rand_int0 = prng0.generate();
		uint32_t rand_int1 = prng1.generate();
		// float f1 = to_float(rand_int0);
		// float f2 = to_float(rand_int1);


		
		float noise = static_cast<float>(less_evil_log(rand_int0) - less_evil_log(rand_int1));
		std::cout << noise << std::endl;

		auto end = std::chrono::steady_clock::now();

		stats_file << std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count() << std::endl;

	}


	return 1;
}