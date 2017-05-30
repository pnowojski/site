---
title: 'Fast inequality joins'
author: pnowojski
categories: internals
tags: join execution performance
---
 
There is a new cool feature in Presto that will speed up some inequality joins.
 
<!--more-->
 
Inequality join conditions are all conjunctions that are not equality comparisons. For example in query like this:
 
~~~sql
SELECT * FROM t1, t2 WHERE t1.bucket = t2.bucket AND t1.val1 < t2.val2;
~~~
 
This `t1.val1 < t2.val2` is an inequality join condition that we will be talking about. In Presto such joins previously would be executed as normal inner joins with only equality conditions (using hash tables) and result of such joins would be filtered out using inequality join conditions. Lets take a look at an extreme example where this is clearly an issue and define tables `t1` and `t2` using Presto Memory connector as follows:
 
~~~sql
CREATE TABLE memory.default.t1 (bucket bigint, val1 bigint);
CREATE TABLE memory.default.t2 (bucket bigint, val2 bigint);
~~~
 
and fill those tables with some random data:
 
~~~sql
INSERT INTO t1 SELECT orderkey % 10000, (orderkey * 13) % 1000 FROM tpch.sf1.lineitem;
INSERT INTO t2 SELECT orderkey % 10000, (orderkey * 379) % 10 FROM tpch.sf1.lineitem;
~~~
 
Basically `bucket` will be in range from 0 to 10000, `val1` in range 0 to 1000, `val2` in range 0 to 10 and both tables will have 6,001,215 rows. Now what is going on is that following query:
 
~~~sql
SELECT count(*) FROM t1, t2 WHERE t1.bucket = t2.bucket;
~~~
 
Has to produce 720 million of rows. After adding `t1.val1 < t2.val2` most of them must be filtered out so query:
 
~~~sql
SELECT count(*) FROM t1, t2 WHERE t1.bucket = t2.bucket AND t1.val1 < t2.val2;
~~~
 
returns only 29,120,090. The issue here is that for each row from the `t1` table, there are around 600 rows in `t2` that have same `bucket` value. Before Presto 0.174, all of those 600 rows had to be traversed and each row had to be filtered one by one. This was a huge inefficiency.
 
Since version 0.174 Presto has an option that addresses this particular issue. There is a session property called `fast_inequality_join` (enabled by default). When enabled, Presto will use `t2.val2` value to sort all rows from `t2` table that fall into the same `bucket`. Thanks to that, when there is an incoming row from `t1` table, Presto can reach into matching `bucket` and instead of iterating over all 600 rows, perform a binary search for `t1.val1` value. 
 
For example if we have following rows in `t2` table:
 
~~~
 bucket | val2 
--------+------
     42 |    0 
     42 |    5 
     42 |    2 
     42 |    9 
     42 |    7 
     42 |    8 
     42 |    1 
     42 |    4 
     42 |    3 
     42 |    6 
~~~
 
and we want to match row from table `t1`:
 
~~~
 bucket | val1
--------+------
     42 |    7 
~~~
 
Previously Presto had to iterate over `t2.val2` values: 
 
~~~
0, 5, 2, 9, 7, 8, 1, 4, 3, 6
~~~
 
and filter out each on a case by case basis for matching to the predicate `t1.val1 < t2.val2`. Now Presto will sort them: 
 
~~~
0, 1, 2, 3, 4, 5, 6, 7, 8, 9
~~~
 
quickly perform binary search of value `7` and iterate only over remaining matching values (`7, 8, 9`). This reduces time complexity of such joins from:
 
~~~
O(size(t1) * bucket_size)
~~~
 
down to:
 
~~~
O(size(t1) * (log(bucket_size) + number_of_matching_rows_in_bucket))
~~~
 
Where `bucket_size` is average number of rows from `t2` table that have same `t2.bucket` value. When `number_of_matching_rows_in_bucket` is much smaller compared to `bucket_size`, we can simplify this to:
 
~~~
O(size(t1) * log(bucket_size))
~~~
 
## Results
 
This of course has tremendous effect on query times. Optimization enabled:
 
~~~
presto:default> set session fast_inequality_join=true;
SET SESSION
presto:default> SELECT count(*) FROM t1, t2 WHERE t1.bucket = t2.bucket AND t1.val1 < t2.val2;
  _col0   
----------
 29120090 
(1 row)
 
Query 20170530_085758_00130_asrts, FINISHED, 8 nodes
Splits: 849 total, 849 done (100.00%)
0:01 [12M rows, 206MB] [13.9M rows/s, 238MB/s]
~~~
 
Optimization disabled:
 
~~~
presto:default> set session fast_inequality_join=false;
SET SESSION
presto:default> SELECT count(*) FROM t1, t2 WHERE t1.bucket = t2.bucket AND t1.val1 < t2.val2;
  _col0   
----------
 29120090 
(1 row)
 
Query 20170530_072421_00115_asrts, FINISHED, 7 nodes
Splits: 801 total, 801 done (100.00%)
0:08 [12M rows, 206MB] [1.51M rows/s, 26MB/s]
~~~
 
As we can see query completed 8 times faster with this optimization enabled! Of course speed up largely depends on your query shape and your data. The more selective is your inequality join condition the better case for this optimization.
 
## Limitations
 
Currently code in Presto that looks for the expression on which right table should be sorted is somehow limited and can resolve only simple inequality join conditions. Since Presto 0.177 you can check whether this optimization was triggered in the explain output:
 
~~~
presto:tiny> explain SELECT o.orderkey, o.orderdate, l.shipdate FROM orders o JOIN lineitem l ON l.orderkey = o.orderkey AND l.shipdate < o.orderdate + INTERVAL '10' DAY;
 - Output[orderkey, orderdate, shipdate] => [orderkey:bigint, orderdate:date, shipdate:date]                                             
     - RemoteExchange[GATHER] => orderkey:bigint, orderdate:date, shipdate:date                                                          
         - InnerJoin[("orderkey" = "orderkey_0") AND ("expr_3" > "shipdate")] => [orderkey:bigint, orderdate:date, shipdate:date]        
                 SortExpression["shipdate"]                                                                                              
             - ScanProject[table = tpch:tpch:orders:sf0.01, originalConstraint = true] => [expr_3:date, orderkey:bigint, orderdate:date] 
                     expr_3 := ("orderdate" + "$literal$interval day to second"(BIGINT '864000000'))                                     
                     orderkey := tpch:orderkey                                                                                           
                     orderdate := tpch:orderdate                                                                                         
             - LocalExchange[HASH] ("orderkey_0") => orderkey_0:bigint, shipdate:date                                                    
                 - RemoteExchange[REPARTITION] => orderkey_0:bigint, shipdate:date                                                       
                     - TableScan[tpch:tpch:lineitem:sf0.01, originalConstraint = true] => [orderkey_0:bigint, shipdate:date]             
                             orderkey_0 := tpch:orderkey                                                                                 
                             shipdate := tpch:shipdate
~~~
 
As you can see, in the above example `shipdate` was chosen as a sorting expression. If Presto fail to determine sorting expression it will be also missing in explain output. Sometimes you might have to change your condition a bit. Although expressions `l.shipdate - INTERVAL '5' DAY < o.orderdate - INTERVAL '5' DAY` and `l.shipdate < o.orderdate + INTERVAL '10' DAY` are equivalent, the first one will currently not work with this optimization. 
 
Next time when you stumble across query with inequality join condition keep in mind about this new feature.
