import numpy as np
from concurrent.futures import ProcessPoolExecutor
from tqdm import tqdm
import random
from tensor import Tensor
from utils import absolute_or_relative_error, log as wrap_log
from op import Operation, execute 
from .test_registry import wrap_test


@wrap_test(
    name='matmul test',
    repeat=1000,
    meta={
        'description': 'Test matmul operation',
        'accepted_error': 1e-4
    }
)
def matul_test(*args): 
    eps = 1e-4

    h1, w1, w2 = random.randint(1, 256), random.randint(1, 256), random.randint(1, 256)
    t1 = Tensor.random_tensor([h1, w1])
    t2 = Tensor.random_tensor([w1, w2])

    t1_data = t1.data.reshape(t1.shape)
    t2_data = t2.data.reshape(t2.shape)
    np_result = np.matmul(t1_data, t2_data)
    
    out = execute(Operation.MATMUL, [], [t1, t2])
    diff = absolute_or_relative_error(out.data, np_result.flatten()).mean()

    return diff < eps
