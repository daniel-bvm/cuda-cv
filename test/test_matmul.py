import numpy as np
from concurrent.futures import ProcessPoolExecutor
from tqdm import tqdm
import random
from tensor import Tensor
from utils import absolute_or_relative_error
from op import Operation, execute 

def run_case(*args): 
    eps = 1e-4

    h1, w1, w2 = random.randint(1, 1000), random.randint(1, 1000), random.randint(1, 1000)
    t1 = Tensor.random_tensor([h1, w1])
    t2 = Tensor.random_tensor([w1, w2])

    t1_data = t1.data.reshape(t1.shape)
    t2_data = t2.data.reshape(t2.shape)
    np_result = np.matmul(t1_data, t2_data)
    
    out = execute(Operation.MATMUL, [], [t1, t2])
    diff = absolute_or_relative_error(out.data, np_result.flatten()).mean()

    return diff < eps

def benchmark_matmul():
    n_cases = 10

    futures = []
    
    try:
        for _ in tqdm(range(n_cases), total=n_cases, desc='Running test cases'):
            futures.append(run_case())
    except KeyboardInterrupt:
        print('Interrupted')

    fails = sum([f == False for f in tqdm(futures, total=len(futures), desc='Processing results')])
    success = len(futures) - fails

    print(f'Success: {success}/{len(futures)}')
    print(f'Fails: {fails}/{len(futures)}')

    if fails > 0:
        raise ValueError('Some test cases failed')

if __name__ == '__main__':
    benchmark_matmul()