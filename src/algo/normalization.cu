#include <stdio.h>
#include <cuda.h>
#include <iostream>
#include <assert.h>

#include <fixedlonglong32x32.cuh>
#include <kernels.cuh>
#include <operations.cuh>

void __layerNormalizeFixedLongLong(
    long long *X, // input of shape (m, n, c) 
    long long *Y, // output of shape (m, n, c)
    long long *ma, // moving average (c)
    long long *mv, // mong variance  (c)
    long long *gamma, // scale (c)
    long long *beta, // offset (c)
    long long epsilon, // epsilon 
    int h, int w, int c  // m, n, c 
    , bool& error
) 
{
    
}

void __batchNormalizeFixedLongLong(
    long long *X, // input of shape (m, n, c) 
    long long *Y, // output of shape (m, n, c)
    long long *ma, // moving average (c)
    long long *mv, // mong variance  (c)
    long long *gamma, // scale (c)
    long long *beta, // offset (c)
    long long epsilon, // epsilon 
    int h, int w, int c  // m, n, c 
    , bool& error
) 
{
    long long *gpu;
    cudaMalloc(&gpu, (h * w * c * 2 + 4 * c) * sizeof(long long));
    cudaMemcpy(gpu, X, h * w * c * sizeof(long long), cudaMemcpyHostToDevice);
    cudaMemcpy(gpu + h * w * c * 2, ma, c * sizeof(long long), cudaMemcpyHostToDevice);
    cudaMemcpy(gpu + h * w * c * 2 + c, mv, c * sizeof(long long), cudaMemcpyHostToDevice);
    cudaMemcpy(gpu + h * w * c * 2 + c * 2, gamma, c * sizeof(long long), cudaMemcpyHostToDevice);
    cudaMemcpy(gpu + h * w * c * 2 + c * 3, beta, c * sizeof(long long), cudaMemcpyHostToDevice);

    const dim3 BLOCK_SIZE(32, 32, 1);
    const dim3 GRID_SIZE(
        (w + BLOCK_SIZE.x - 1) / BLOCK_SIZE.x, 
        (h + BLOCK_SIZE.y - 1) / BLOCK_SIZE.y, 
        c
    );

    normalizeFixedLongLong_kernel<<<GRID_SIZE, BLOCK_SIZE>>>(
        gpu, // input of shape (m, n, c)
        gpu + h * w * c,  // output of shape (m, n, c)
        gpu + h * w * c * 2,  // moving average (c)
        gpu + h * w * c * 2 + c,  // moving variance  (c)
        gpu + h * w * c * 2 + c * 2, // gamma (c)
        gpu + h * w * c * 2 + c * 3, // beta (c)
        epsilon, 
        h, w, c
    );

    cudaMemcpy(Y, gpu + h * w * c, h * w * c * sizeof(long long), cudaMemcpyDeviceToHost);
    cudaFree(gpu);
}