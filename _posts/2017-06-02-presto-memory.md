---
title: 'Presto Memory connector'
author: pnowojski
categories: news
tags: release
---

Since couple of months there is a new highly efficient connector for Presto. It works by storing all data in memory on Presto Worker nodes, which allow for extremely fast access times with high throughput while keeping CPU overhead at bare minimum.

<!--more-->

Presto Memory works like manually controlled cache for some existing tables. It does not backup it's data in any permament storage and user has to manualy recreate tables on his own after every Presto restart. Those are serious limitations, but hey... it is something to start from, right?

To use it, you first need to install it on your cluster and then set a `memory.max-data-per-node` property, which limits how much data user will be allowed to save in Presto Memory per one node. After those steps connector is ready to use and you can use it as you would use any other conenctor. You can create a table:

~~~sql
CREATE TABLE memory.default.nation AS SELECT * from tpch.tiny.nation;
~~~

Insert data into an existing table:

~~~sql
INSERT INTO memory.default.nation SELECT * FROM tpch.tiny.nation;
~~~

Select from the Memory connector:

~~~sql
SELECT * FROM memory.default.nation;
~~~

Drop table:

~~~sql
DROP TABLE memory.default.nation;
~~~

As mentnioned earlier, any reads from and writes to memory tables are extremely fast. All of the data are stored in uncompressed way in Presto's native data structures. That means there is no IO overhead for accessing those data and CPU overhead is pretty much non existing. 

The connector has some limitations of which you can read in an [official Presto Memory documentation](https://prestodb.io/docs/current/connector/memory.html). It was developed primarily for micro benchmarking Presto's query engine, but since then it was improved to the point that it now can be used for something more. If you have some table with hot data that do not change very often or you need to query some slow external table multiple times (like single node MySQL) maybe you could give Presto Memory a try?

There are also some ideas to expand this connector in a direction of automatic tables caching, so stay tuned for more updates in this topic in the future.
