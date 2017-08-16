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
	unsigned count = 0;
	::std::cout << "Beginning: Value of tests: " << test << ::std::endl;
	//Run unlock thread
	::std::thread unlock ([&]()
	{
		while (test == 1) {++count;};
		::std::cout << "Thread: Value of tests: " << test << ::std::endl;
	});

	parallel_for_each(concurrency::extent<1>(1),
	                  [&](concurrency::index<1> i) restrict(amp)
	{
		test = 0;
	});

	::std::cout << "Prejoin: Value of tests: " << test << ::std::endl;
	unlock.join();
	::std::cout << "Completed in " << count << " iterations" << ::std::endl;
	::std::cout << "Postjoin: Value of tests: " << test << ::std::endl;
	return 0;
}
