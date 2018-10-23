import numpy as np
import pandas as pd
from pandas import Series, DataFrame


ser = pd.Series(np.random.randn(6),
                index=[[1, 1, 1, 2, 2, 2], list('ab')*3])  # each list in the list of index will create a new hirearchy

print(ser)
