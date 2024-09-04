#include <fixedlonglong32x32.cuh>
#include <operations.cuh>

// softmax interface
void __softmaxFixedLongLong(long long *A, long long* B, int m, uint8_t* error) 
{
    long long *gpu;
    const int BLOCK_SIZE = 256;
    const int BLOCKS = (m + BLOCK_SIZE - 1) / BLOCK_SIZE;

    if (*error = (cuda_fmt_error(cudaMalloc((void**)&gpu, sizeof(long long) * m * 2)) 
        || cuda_fmt_error(cudaMemcpy(gpu, A, sizeof(long long) * m, cudaMemcpyHostToDevice))))
    {
        cudaFree(gpu);
        return;
    }

    cvt_fll2fp64<<<BLOCKS, BLOCK_SIZE>>>(gpu, (double *) gpu + m, m);
    mat_exp_fp64<<<BLOCKS, BLOCK_SIZE>>>((double *) gpu + m, (double *) gpu, m);
    double sumExp = __sumReduction_fp64_impl((double *) gpu, m, error);

    if (!*error && sumExp != 0) {
        softmaxImpl_fp64<<<BLOCKS, BLOCK_SIZE>>>((double *) gpu, (double *) gpu + m, m, sumExp);
        cvt_fp642fll<<<BLOCKS, BLOCK_SIZE>>>((double *) gpu + m, gpu, m);
        
        if (*error = cuda_fmt_error(cudaMemcpy(B, gpu, sizeof(long long) * m, cudaMemcpyDeviceToHost)))
        {
            cudaFree(gpu);
            return;
        }        
    }

    cudaFree(gpu);
}

// sigmoid interface
void __sigmoidFixedLongLong(long long *A, long long* B, int m, uint8_t* error) 
{  
    long long *gpu_a, *gpu_b;

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu_a, sizeof(long long)*m)))
    {
        cudaFree(gpu_a);
        return;
    }

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu_b, sizeof(long long)*m)))
    {
        cudaFree(gpu_a), cudaFree(gpu_b);
        return;
    }   

    const int BLOCK_SIZE = 256;
    const int BLOCKS = (m + BLOCK_SIZE - 1) / BLOCK_SIZE;
 
    if (*error = cuda_fmt_error(cudaMemcpy(gpu_a, A, sizeof(long long)*m, cudaMemcpyHostToDevice)))
    {
        cudaFree(gpu_a), cudaFree(gpu_b);
        return;
    }

    cvt_fll2fp64<<<BLOCKS, BLOCK_SIZE>>>(gpu_a, (double *) gpu_b, m);
    sigmoidImpl_fp64<<<BLOCKS, BLOCK_SIZE>>>((double *) gpu_b, (double *) gpu_a, m);
    cvt_fp642fll<<<BLOCKS, BLOCK_SIZE>>>((double *) gpu_a, gpu_b, m);

    *error = cuda_fmt_error(cudaMemcpy(B, gpu_b, sizeof(long long)*m, cudaMemcpyDeviceToHost));
    cudaFree(gpu_a), cudaFree(gpu_b);
}

// tanh interface
void __tanhFixedLongLong(long long *A, long long *B, int m, uint8_t* error) 
{
    long long *gpu_a, *gpu_b;

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu_a, sizeof(long long)*m)))
    {
        cudaFree(gpu_a);
        return;
    }

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu_b, sizeof(long long)*m)))
    {
        cudaFree(gpu_a), cudaFree(gpu_b);
        return;
    }

    const int BLOCK_SIZE = 256;
    const int BLOCKS = (m + BLOCK_SIZE - 1) / BLOCK_SIZE;

    if (*error = cuda_fmt_error(cudaMemcpy(gpu_a, A, sizeof(long long)*m, cudaMemcpyHostToDevice)))
    {
        cudaFree(gpu_a), cudaFree(gpu_b);
        return;
    }
    tanhImplFixedLongLong<<<BLOCKS, BLOCK_SIZE>>>(gpu_a, gpu_b, m);

    *error = cuda_fmt_error(cudaMemcpy(B, gpu_b, sizeof(long long)*m, cudaMemcpyDeviceToHost));
    cudaFree(gpu_a), cudaFree(gpu_b);
}

// relu interface
void __reluFixedLongLong(long long *A, long long *B, int m, uint8_t* error) 
{
    long long *gpu_a, *gpu_b;

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu_a, sizeof(long long)*m)))
    {
        cudaFree(gpu_a);
        return;
    }

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu_b, sizeof(long long)*m)))
    {
        cudaFree(gpu_a), cudaFree(gpu_b);
        return;
    }

    const int BLOCK_SIZE = 256;
    const int BLOCKS = (m + BLOCK_SIZE - 1) / BLOCK_SIZE;

    if (*error = cuda_fmt_error(cudaMemcpy(gpu_a, A, sizeof(long long)*m, cudaMemcpyHostToDevice)))
    {
        cudaFree(gpu_a), cudaFree(gpu_b);
        return;
    }
    reluImplFixedLongLong<<<BLOCKS, BLOCK_SIZE>>>(gpu_a, gpu_b, m);

    if (*error = cuda_fmt_error(cudaMemcpy(B, gpu_b, sizeof(long long)*m, cudaMemcpyDeviceToHost)))
    {
        cudaFree(gpu_a), cudaFree(gpu_b);
        return;
    }
    cudaFree(gpu_a), cudaFree(gpu_b);
}

// relu interface
void __relu3DFixedLongLong(long long *A, long long *B, int h, int w, int c, uint8_t* error) 
{
    long long* gpu;
    const int N = h * w * c;

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu, sizeof(long long) * N * 2)))
    {
        cudaFree(gpu);
        return;
    }

    if (*error = cuda_fmt_error(cudaMemcpy(gpu, A, sizeof(long long) * N, cudaMemcpyHostToDevice)))
    {
        cudaFree(gpu);
        return;
    }
    
    const dim3 BLOCK_SIZE(256);
    const dim3 BLOCKS((N + BLOCK_SIZE.x - 1) / BLOCK_SIZE.x);
    reluImplFixedLongLong<<<BLOCKS, BLOCK_SIZE>>>(gpu, gpu + N, N);

    if (*error = cuda_fmt_error(cudaMemcpy(B, gpu + N, sizeof(long long) * N, cudaMemcpyDeviceToHost)))
    {
        cudaFree(gpu);
        return;
    }
    cudaFree(gpu);
}

// relu interface
void __sigmoid3DFixedLongLong(long long *A, long long *B, int h, int w, int c, uint8_t* error) 
{
    long long* gpu;
    const int N = h * w * c;

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu, sizeof(long long) * N * 2)))
    {
        cudaFree(gpu);
        return;
    }

    if (*error = cuda_fmt_error(cudaMemcpy(gpu, A, sizeof(long long) * N, cudaMemcpyHostToDevice)))
    {
        cudaFree(gpu);
        return;
    }

    const dim3 BLOCK_SIZE(256);
    const dim3 BLOCKS((N + BLOCK_SIZE.x - 1) / BLOCK_SIZE.x);
    sigmoidImplFixedLongLong<<<BLOCKS, BLOCK_SIZE>>>(gpu, gpu + N, N);

    if (*error = cuda_fmt_error(cudaMemcpy(B, gpu + N, sizeof(long long) * N, cudaMemcpyDeviceToHost)))
    {
        cudaFree(gpu);
        return;
    }
    cudaFree(gpu);
}


// relu interface
void __tanh3DFixedLongLong(long long *A, long long *B, int h, int w, int c, uint8_t* error) 
{
    long long* gpu;
    const int N = h * w * c;

    if (*error = cuda_fmt_error(cudaMalloc((void**)&gpu, sizeof(long long) * N * 2)))
    {
        cudaFree(gpu);
        return;
    }

    if (*error = cuda_fmt_error(cudaMemcpy(gpu, A, sizeof(long long) * N, cudaMemcpyHostToDevice)))
    {
        cudaFree(gpu);
        return;
    }

    const dim3 BLOCK_SIZE(256);
    const dim3 BLOCKS((N + BLOCK_SIZE.x - 1) / BLOCK_SIZE.x);
    
    cvt_fll2fp64<<<BLOCKS, BLOCK_SIZE>>>( gpu, (double *) gpu + N, N);
    tanhImpl_fp64<<<BLOCKS, BLOCK_SIZE>>>((double *) gpu + N, (double *) gpu, N);
    cvt_fp642fll<<<BLOCKS, BLOCK_SIZE>>>((double *) gpu, gpu + N, N);

    if (*error = cuda_fmt_error(cudaMemcpy(B, gpu + N, sizeof(long long) * N, cudaMemcpyDeviceToHost)));
    cudaFree(gpu);
}

void __softmax2DFixedLongLong(long long* A, long long* B, int h, int w, int c, uint8_t* error)
{
    memset(B, 0, sizeof(long long) * h * w * c);
}