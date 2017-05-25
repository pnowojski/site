---
title: 'The fundamentals: MPP and data distribution'
author: kokosing
categories: internals 
tags: fundamentals execution explain
---

One can say that Presto is a [MPP (Massively Parallel Processing)](https://en.wikipedia.org/wiki/Massively_parallel) kind of
application. Well, I have never seen a data warehouse which did not follow this
approach. Teradata, Netezza, Vertica and even Hive and many many more, all of
these belong to this class of software. It is not only typical for data
warehouses, but also for any distributed application which is processing vast amount of
data, doing non-trivial and very costly computation on it.

<!--more-->

## MPP main properties

So what does it mean in practice that a particular application is a MPP one? It means
that an application in order to return a result for given task is using many
(tens, hundreds or even thousands) processors. To achieve that, the application is
distributed on several computers (typically called nodes). When a task is scheduled, 
either by requesting a SQL query or in any other form, then all the processors
on all the nodes are working collectively to compute the results.

Let's take a look at two (in my opinion) the most interesting properties of MPP application,
at least in regards to the rest of this post.
 
 - There are two levels of parallelism. Task, or work, has to be divided between
 several computational nodes and then on each such node it has to be once again
 divided between processors (threads). This could be done in described two
 stage manner or in a way where each processor is treated as an independent
 computational unit, then the application divides the task in a single leap between a
 vast number of workers (processors), skipping one level (node level) of parallelism. 
 Things are getting more complicated if you consider using GPU
 cards (see 
 [general purpose programming on GPU](https://en.wikipedia.org/wiki/General-purpose_computing_on_graphics_processing_units))
 then you might have even three level of parallelism, but this just a side note.

 - In order to utilize the cluster resources, the task has to be splittable in some way.
 The best situation is when given work can be decomposed to smaller independent tasks.
 The best example is [matrix multiplication](https://en.wikipedia.org/wiki/Matrix_multiplication), where
 each cell of result matrix can be computed independently. Such decomposition
 is not always possible. Even more, it is a very rare case. The next desired decomposition, and much more common, 
 is [DAG (Directed Acyclic Graph)](https://en.wikipedia.org/wiki/Directed_acyclic_graph). Where in order to 
 compute a given part of work, some previous (dependent) intermediate results of other part are need to be computed first.
 This kind of approach is usually called streaming. Data is streamed through the operators (workers).
 Once the operator has all the required input data, it can start its work.

There many more MPP properties, but in this article I would like to focus on these two only. Hopefully, other properties
will find a place on this blog in separate posts.

## Presto query plan

Ok, let's go back and take a look how Presto adapted this properties. When Presto receives a query,
then it generates a query plan out of it. Plan is structured in a form of a 
[tree](https://en.wikipedia.org/wiki/Tree_(graph_theory))
which is known to be a DAG. Each node in this tree represents some part of work which needs to be 
performed in order to compute the results requested in the query. 
Typically, leafs represents some table scans and root is a place where final
results will be collected. Simply, executing work related to each plan node
independently would satisfy above MPP property. However this is not an optimal
solution. Data transfer and buffering between plan nodes does not come for
free. It costs CPU time, memory and network transfer. What Presto does is it is
grouping nodes together into something called plan fragments. And then it
executes such plan fragments independently. For example when you have filter
operation on top of table scan operation, then these two operations for
sure will be grouped into a single plan fragment as the result of both is expected
to be much less than sum of table scan and filter together. I do not want to go
into the details of plan tree and plan fragments as this topic deserves a
separate blog post. I wanted just to give you a notion how Presto divides its
work, it will be needed to explain how
Presto then distributes work execution across the cluster.

In order to see what plan was generated for your query you may want to run `EXPLAIN` command:

~~~sql
presto:tiny> EXPLAIN select * from nation where nationkey > 3;
~~~

Then to see how such plan was grouped in plan fragments you can use `EXPLAIN (TYPE DISTRIBUTED)`:

~~~sql
presto:tiny> EXPLAIN (TYPE DISTRIBUTED) select * from nation where nationkey > 3;
~~~

## Data distribution

Once plan fragments are generated, they are then spread across the cluster (in
form of operators). The exact details of this are not important here, just
remember that each of the node is able to perform a work related to each
plan fragment now. 

There is also one very crucial thing here. All these plan fragments have to
be connected to each other. So every fragment knows where to put its results.
This is called data distribution and it consists of a list of nodes to which result data will be
sent and the way how that data will be distributed. Generally there three main ways how it is achieved:

 - redistributed - `BROADCAST` - all the data is sent to all the nodes

 - repartition - `HASH` - data is partitioned (on calculated hash value) and then sent to nodes associated with given hash values
 
 - spread - `ROUND ROBIN` - data is distributed across nodes with a round robin function
 
There are several variants, but the three above are the most important. For example, you may often 
spot `SINGLE` distribution, it is simply just a variant of redistributed with a single output node.

What about leaf nodes? Nobody is going to write to them so how processing is
distributed among them? Leaf nodes are called source nodes. It is a connector's
responsibility to tell how data for particular table can be read. It consists
of an instruction of where and how data is stored and divided as well as if it is
accessible remotely or from which nodes directly. This information is returned
from connector in a form of collection of splits. Single split collects all above info about a single data chunk.
For example [hive](https://prestodb.io/docs/current/connector/hive.html) data is typically stored on 
[HDFS](https://en.wikipedia.org/wiki/Apache_Hadoop#Hadoop_distributed_file_system). Table data is divided into several 
files. Each file is divided into blocks. Block typically is replicated on
several nodes (very often on 3 nodes), that means that block data can be accessed
directly from disk on these nodes or remotely from other nodes. If the connector
returns one split per HDFS block, then for each such block Presto schedules
execution of leaf (source) plan fragment for data within this block.

## Using `EXPLAIN (TYPE DISTRIBUTED)`

To check how data and so processing is distributed between plan fragments for your query, once again you can use
`EXPLAIN (TYPE DISTRIBUTED`:

~~~sql
presto:tiny> EXPLAIN (TYPE DISTRIBUTED) SELECT nationkey 
             FROM nation n, region r WHERE n.regionkey = r.regionkey;

                            Query Plan
---------------------------------------------------------------------
 Fragment 0 [SINGLE]                                                                                                                  
    ...
     - Output[nationkey] ...
         - RemoteSource[1] ...
                                                                                                                                      
 Fragment 1 [HASH]                                                                                                                    
    ...
    Output partitioning: SINGLE []
    ...
         - InnerJoin ...
              ...
                 - RemoteSource[2] ...
                 - RemoteSource[3] ...
                                                                                                                                      
 Fragment 2 [SOURCE]                                                                                                                  
    ...
    Output partitioning: HASH [regionkey][$hashvalue_10]  
    ...
         - TableScan[tpch:tpch:nation:sf0.01 ...
              ...
                                               
 Fragment 3 [SOURCE]
    ...All Presto needs to do now is to stream data through this plan fragments.
    Output partitioning: HASH [regionkey_0][$hashvalue_13]  
    ...
         - TableScan[tpch:tpch:region:sf0.01 ...
              ...
~~~

In the example above there are 4 fragments. Fragments 2 and 3 are source
fragments and fragment 1 is `HASH` which means data has to be repartitioned
before it gets to this fragment. So as you can see output data from fragments 2
and 3 is partitioned on hash calculated on `regionkey` column and then sent to
fragment 1, so that data matching to the same hash value goes to the same
worker. Then fragment 1 has output partitioning `SINGLE` that means all the
data produced by all the nodes for this fragment will be sent to the same
single node. Query result will be then accessible to be downloaded from that node.
Please notice that output partitioning matches the fragment partitioning to which
data is going to be sent. Also please notice that plan fragment knows from other plan
fragments it is going to read the data, this is shown with `RemoteSource` on the plan.

Generally using the `EXPLAIN` command should be your routine. Every time you want to know
what is happening you should use it.
There is much more information which you
can read out of it. Hopefully, I will go into details of it in separate post.
As for now, you may also want to check 
[vanilla Facebook](https://prestodb.io/docs/current/sql/explain.html)
  and 
[Teradata](http://teradata.github.io/presto/docs/current/sql/explain.html)
documentation about the `EXPLAIN` command.

## Thread level parallelism

So far we covered how query is divided into small parts of work which can be
executed independently and how data is streamed (distributed) through the
cluster nodes. What about second level of parallelism? How execution is split
across different processors on single machine? First of all, execution for different
plan fragments or for different data splits is happening independently. Depending
on how many given node has CPUs, it may execute different number of such plan
fragments at a time. We could stop here, as this could be enough to satisfy MPP properties.
However there are also one more things which can happen at this level in Presto.
For example, some query parts are very compute-bound [^compute_bound]. Then in such places in
the plan fragments you can spot `LocalExchange`. Its responsibility is to repartition data related
to a single split once again, so work which was originally scheduled for a single thread
now can be executed by many of them.

## Sum-up

We went through MPP properties about work and data partitioning. These two things 
are required in order to saturate (use efficiently) cluster resources and this is 
expected when you want your query to be executed fast. This is a very broad topic, I just wanted
to skim through it, so you have a notion what is happening and you are not overwhelmed by the details.
Once this topic got covered, I would like to go into the details and one by one explain how it works.
A single post per single detail, but for today that is all. Thank you for reaching so far! See you next time.

[^compute_bound]:
    Execution can be compute, disk, network or memory bound. This means that execution
    performance is directly limited by the performance of underlying resource: CPU,
    disk, network or memory. See wiki about [CPU-bound](https://en.wikipedia.org/wiki/CPU-bound),
    [I/O bound](https://en.wikipedia.org/wiki/I/O_bound) and 
    [memory bound](https://en.wikipedia.org/wiki/Memory_bound_function).

