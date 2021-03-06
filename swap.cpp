#include <amp.h>

#include <atomic>
#include <chrono>
#include <iostream>
#include <thread>

int main(void)
{
	::std::atomic_uint test;
#if __hcc_major__ < 1
	::std::cout << "CPU uint atomic is " << (test.is_lock_free() ? "" : "NOT ")
	            << "lock free\n";

	bool GPUlf = false;
	parallel_for_each(concurrency::extent<1>(1),
	                  [&](concurrency::index<1> i) restrict(amp)
	{
		GPUlf = test.is_lock_free();
	});
	::std::cout << "GPU uint atomic is " << (GPUlf ? "" : "NOT ") << "lock free\n";
#endif

	test = 1;
	::std::cout << "Beginning: Value of tests: " << test << ::std::endl;
	//Run unlock thread
	::std::thread unlock ([&]()
	{
		::std::this_thread::sleep_for(::std::chrono::seconds(1));
		test = 0;
		::std::cout << "Thread: Value of tests: " << test << ::std::endl;
	});

	unsigned count = 0;
	auto start = ::std::chrono::high_resolution_clock::now();
	parallel_for_each(concurrency::extent<1>(1),
	                  [&](concurrency::index<1> i) restrict(amp)
	{
		int local_count = 0;
		while (test.exchange(1) == 1) {++local_count;};
		count = local_count;
	});
	auto end = ::std::chrono::high_resolution_clock::now();
	auto us = ::std::chrono::duration_cast<::std::chrono::microseconds>(end - start);

	::std::cout << "Completed " << count << " iterations in "
	            << us.count() << " microseconds." << ::std::endl;

	::std::cout << "Completed in " << count << " iterations" << ::std::endl;
	::std::cout << "Prejoin: Value of tests: " << test << ::std::endl;
	unlock.join();
	::std::cout << "Postjoin: Value of tests: " << test << ::std::endl;
	return 0;
}
