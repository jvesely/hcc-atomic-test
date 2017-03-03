#include <amp.h>
#include <iostream>

::std::atomic_uint sum;

int main(void)
{
	unsigned init_gpu, init_cpu = sum;
	parallel_for_each(concurrency::extent<1>(100),
	                  [&](concurrency::index<1> i) restrict (amp)
	{
	        init_gpu = sum;
	});
	sum = 1;
	parallel_for_each(concurrency::extent<1>(100),
	                  [&](concurrency::index<1> i) restrict (amp)
	{
		sum += 1;
	});
	::std::cout << "CPU: " << init_cpu << " GPU: " << init_gpu << " after: " << sum << "\n";
	return 0;
}
