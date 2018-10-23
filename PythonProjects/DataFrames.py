import numpy as np
from pandas import Series, DataFrame

ser1 = Series(np.arange(3), index=['A', 'B', 'C'])
ser1 = 2 * ser1
print(ser1)

print(ser1[ser1 > 3])


ser1[ser1 > 3] = 10
print(ser1)

dframe = DataFrame(np.arange(25).reshape((5,5)), index=['NYC', 'LA', 'SF', 'DC', 'Chi'],
                   columns=['A', 'B', 'C', 'D', 'E'])
print(dframe)
print(dframe['B'])
print(dframe[['B', 'E']])
print(dframe[dframe['C'] > 8])
