select i.PartNum,
       i.Cost,
       i.SupplierID,
       dense_rank() over (partition by i.SupplierID order by i.Cost) SupplierRank
from btdata.dbo.Inventory i
