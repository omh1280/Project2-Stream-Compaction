#include <cuda.h>
#include <cuda_runtime.h>
#include "common.h"
#include "efficient.h"

namespace StreamCompaction {
namespace Efficient {

	__global__ void kernScan(int n, int *g_odata, int*g_idata) {
		int index = (blockIdx.x * blockDim.x) + threadIdx.x;

		int offset = 1;

		for (int d = n - 1; d > 0; d--) { // build sum in place up the tree
			if (index < d) {
				int ai = offset * (2 * index + 1) - 1;
				int bi = offset * (2 * index + 2) - 1;

				g_idata[bi] += g_idata[ai];
			}
			offset *= 2;

			// clear the last element  
			if (index == 0) {
				g_idata[n - 1] = 0;
			}
		}

		// traverse down tree & build scan  
		for (int d = 1; d < n; d *= 2) {
			offset--;

			if (index < d) {

				int ai = offset*(2 * index + 1) - 1;
				int bi = offset*(2 * index + 2) - 1;


				float t = g_idata[ai];
				g_idata[ai] = g_idata[bi];
				g_idata[bi] += t;
			}
		}

		g_odata[2 * index] = g_idata[2 * index];
		g_odata[2 * index + 1] = g_idata[2 * index + 1];
	}


/**
 * Performs prefix-sum (aka scan) on idata, storing the result into odata.
 */
void scan(int n, int *odata, const int *idata) {
	dim3 fullBlocksPerGrid((n + 128 - 1) / 128);
	dim3 threadsPerBlock(128);

	int* dev_in;
	int* dev_out;

	cudaMalloc((void**)&dev_in, n * sizeof(int));
	checkCUDAError("cudaMalloc Error dev_in.");

	cudaMalloc((void**)&dev_out, n * sizeof(int));
	checkCUDAError("cudaMalloc Error dev_out.");

	cudaMemcpy(dev_in, idata, sizeof(int) * n, cudaMemcpyHostToDevice);
	
	kernScan<< <fullBlocksPerGrid, threadsPerBlock >> >(n, dev_out, dev_in);
		
	cudaMemcpy(odata, dev_out, sizeof(int) * n, cudaMemcpyDeviceToHost);
	checkCUDAError("memcpy back failed!");

	cudaFree(dev_in);
	cudaFree(dev_out);
}
/**
 * Performs stream compaction on idata, storing the result into odata.
 * All zeroes are discarded.
 *
 * @param n      The number of elements in idata.
 * @param odata  The array into which to store elements.
 * @param idata  The array of elements to compact.
 * @returns      The number of elements remaining after compaction.
 */
int compact(int n, int *odata, const int *idata) {
    // TODO
    return -1;
}

}
}
