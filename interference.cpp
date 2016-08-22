#include <amp.h>

#include <atomic>
#include <chrono>
#include <numeric>
#include <iostream>
#include <thread>

struct slot {
	::std::atomic_uint test;
	uint32_t padding[15];
};

static_assert(sizeof(slot) == 64, "");

int main(int argc, const char *argv[])
{
	size_t parallel = 1;
	if (argc > 1) {
		parallel = ::std::atoi(argv[1]);
		::std::cout << "Set parallel threads to " << parallel << "\n";
	}

	size_t size = 1024*1024*1024; // 4GB by default

	::std::atomic_uint test, running;
	::std::cout << "CPU uint atomic is " << (test.is_lock_free() ? "" : "NOT ")
	            << "lock free\n";

	::std::vector<int> from(size, 0xf);
	::std::vector<int> to(size, 0x10);

	bool GPUlf = false;
	parallel_for_each(concurrency::extent<1>(1),
	                  [&](concurrency::index<1> i) restrict(amp)
	{
		GPUlf = test.is_lock_free();
	});
	::std::cout << "GPU uint atomic is " << (GPUlf ? "" : "NOT ") << "lock free\n";

	running = 0;
	::std::vector<slot> tests(parallel);
	for (auto &t : tests)
		t.test = 1;
	
	//Run unlock thread
	::std::thread unlock ([&]()
	{
		// Wait for GPU to start polling
		while (running == 0);
		auto start = ::std::chrono::high_resolution_clock::now();

		size_t copy_size = from.size() * sizeof(decltype(from)::value_type);
		::std::memcpy(from.data(), to.data(), copy_size);

		auto end = ::std::chrono::high_resolution_clock::now();
		for (auto &t : tests)
			t.test = 0;
		auto us = ::std::chrono::duration_cast<::std::chrono::microseconds>(end - start);
		::std::chrono::duration<double, ::std::ratio<1,1>> s = us;
		::std::cout << "Completed CPU memcpy in "
		            << us.count() << " microseconds." << ::std::endl;
		const double gbs = (copy_size / 1024 / 1024/ 1024);
		::std::cout << "Copied " << gbs << " GBs in " << s.count()
		            << "seconds\n";
		::std::cout << "Copy BW: "
		         << (double)(copy_size / 1024 / 1024 / 1024) / s.count()
		            << " GB/s" << ::std::endl;
	});

	::std::vector<unsigned> count(parallel, 0);
	auto start = ::std::chrono::high_resolution_clock::now();
	if (parallel == 0) {
		running = 1;
	} else {
		parallel_for_each(concurrency::extent<1>(parallel),
		                  [&](concurrency::index<1> i) restrict(amp)
		{
			running = 1;
			int local_count = 0;
			while (tests[i[0]].test == 1) { ++local_count; };
			count[i[0]] = local_count;
					
		});
	}
	auto end = ::std::chrono::high_resolution_clock::now();
	auto us = ::std::chrono::duration_cast<::std::chrono::microseconds>(end - start);

	size_t iterations = ::std::accumulate(count.begin(), count.end(), 0);
	::std::cout << "Completed " << iterations << " iterations in "
	            << us.count() << " microseconds." << ::std::endl;
	::std::cout << "Completed " << ((double)iterations * 1000000) / (double)us.count() / (double)parallel
	            << " iterations per second per thread" << ::std::endl ;
	unlock.join();
	return 0;
}
