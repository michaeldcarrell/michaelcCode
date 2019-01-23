select i.PartNum, i.Cost, ntile(100) over (order by i.Cost) Percentile from btdata.dbo.Inventory i
order by Percentile desc