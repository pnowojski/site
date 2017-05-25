---
title: Unnecessary cross join elimination
author: kokosing
tags: optimizer join
category: internals
---

Cross join has a bad reputation. It is not that nobody likes it all the time. For example 
It is OK to use it from time to time. There are even some queries where there is no other
way. All of it is totally acceptable, and nobody would complain if it would be only like
that. However, cross join has a habit to occur at the least appropriate moment.
And once it comes, nothing remains the same. Query usually becomes an order of
magnitude slower, and this not something any of you would like to dream of.

Since the 0.162 and 0.157t (Teradata) version of Presto, there is a feature
called unnecessary cross join elimination. Simply, it does what it says: if it
is possible to reorder joins in a way to eliminate cross joins without
sacrificing the correctness, it will happen. This post is going to uncover the details of it.

To see why cross join is so bad you may want to read my previous articles about joins:

 * [types of joins in SQL](/internals/the-fundamentals-types-of-joins-in-sql/)

 * [join algorithms](/internals/the-fundamentals-join-algorithms/)

### How to use it?

This feature is turned off by default and can be enabled via session or
configuration properties. In order to use it, let's see how to check if it
is enabled already. You may achieve that by running `SHOW SESSION` command and see
configuration for `reoder_joins` property, like below:

~~~sql
presto:tiny> show session;

 Name          | Value | Default |  Type   | Description  
---------------+-------+---------+---------+-------------------------------------------------
 ...
 reorder_joins | false | false   | boolean | Experimental: Reorder joins to optimize plan
 ...
~~~

In the above example `reorder_joins` feature toggle is disabled.

There are two ways to turn it on:
 
 * The easiest way is to use session properties (aka `SET SESSION`). Please,
notice that below command will only affect the current session:

~~~sql
presto:tiny> set session reorder_joins = true;
SET SESSION
~~~

 * The other way, more difficult, but permanent is to set it via configuration
property files, in this case put into 
[config.properties](https://prestodb.io/docs/current/installation/deployment.html#config-properties)
following content and restart the server:

~~~
reorder-joins=true
~~~

### Why is it not turned on by default?

Unnecessary cross elimination sounds like a great thing to be enabled by
default, so you may want to ask why it has to be enabled to take the advantage
of it. I think there are three reasons behind that:

 * As you noticed above, `SHOW SESSION` says it is an experimental feature. 
It is a quite recent feature so there is a slight possibility that it may generate wrong
plan for query that may cause wrong results. However, it is tested quite
vastly and no such thing should happen (although you never know). Anyway,
anything could have a BUG, so should everything be behind the feature toggle?
Exactly, this reason is not enough to explain why it needs this here.

 * This property may enable other join ordering related optimization which you
may not want to have. As far I recall there are no such optimization added yet,
but in the near future it is expected to change.

 * Generally join reordering is tricky. There are queries for which turning on
this feature may cause the performance degradation.

### When does cross join happen uninvited? (the use case)

Let's take a look at the below query and see how it is planned without this great feature:

~~~sql
presto:tiny> EXPLAIN SELECT * FROM part p, orders o, lineitem l 
             WHERE p.partkey = l.partkey AND l.orderkey = o.orderkey;

...
 - InnerJoin[("orderkey" = "orderkey_2") AND ("partkey" = "partkey_3")...
    - ...
      - CrossJoin ...
        - TableScan[tpch:tpch:part:sf0.01, originalConstraint = true] ...
          - ...
            - TableScan[tpch:tpch:orders:sf0.01, originalConstraint = true] ...
      - ...
        - ScanProject[table = tpch:tpch:lineitem:sf0.01, originalConstraint = true] ...
~~~

As you can see, there are three tables joins together with two conditions. By
default planner joins them in the order given in the query, so `part` is joined
with `orders` and then that is joined with `lineitem`, at the beginning all of these
joins are cross joins. Then, at the top of them there is `Filter` added with
the conditions from `WHERE` clause (you would not see this from the `EXPLAIN`
output). Now optimizer comes in, it notices that there is a `Filter` on top of
`CrossJoin`. It tries to push its predicates down, thanks to which the first join becomes the `InnerJoin` with two equality conditions. 
This is all what happened above.

The question is why the optimizer was not able to push down the join conditions any
further so the other `CrossJoin` remained? Please notice that there are two
predicates, one joins `lineitem` with `part` (`p.partkey = l.partkey`) and the other joins `lineitem`
with `orders` (`l.orderkey = o.orderkey`). As you can see are no condition  between `part` and `orders` and
so this join remain as `CrossJoin`.

### How does it work?

Let's enable `reorder_joins` and see what happens.

~~~sql
presto:tiny> set session reorder_joins = true;
SET SESSION
presto:tiny> EXPLAIN SELECT * FROM part p, orders o, lineitem l 
             WHERE p.partkey = l.partkey AND l.orderkey = o.orderkey;

- ...
  - InnerJoin[("orderkey_2" = "orderkey") ...
   - ...
     - InnerJoin[("partkey" = "partkey_3") ...
       - ...
         - ScanProject[table = tpch:tpch:part:sf0.01, originalConstraint = true] ...
       - ...
           - ScanProject[table = tpch:tpch:lineitem:sf0.01, originalConstraint = true] ...
   - ...
     - ScanProject[table = tpch:tpch:orders:sf0.01, originalConstraint = true] ...
~~~

The most important fact is that join order changed. Now `part` is joined with
`lineitem` and then this is joined with `orders`. Please notice it matches the
predicates available in `WHERE` clause, so this time optimizer was able to push
them dowm and make all the joins to be `InnerJoin`.

Nice, isn't it? But how optimizer knew how to order tables in this triple join? 
It is handled by the one of its rules which creates a join graph. Tables are
represented by vertices and join conditions are represented by edges.

~~~
         part p
           +
           |
           |
 p.partkey = l.partkey
           |
           |
           +
       lineitem l
           +
           |
           |
l.orderkey = o.orderkey
           |
           |
           +
        orders o
~~~

Now this rule takes the table which appeared on SQL query as first (in this
example `part`) and sees what tables are connected to it. Among the connected
tables, it chooses the table which appeared on SQL query as first and does the join
of them. In this example only `lineitem` is connected so the decision is simple.
This is repeated until no more tables can be joined. If some tables
remain, then it is known that there is no connection to them (no join
condition) thus in such case there is no way to eliminate all cross joins 
with this algorithm.

### Summary

This is a nice feature, which in my opinion you should turn on if you have
not done it already. I have heard that some databases display a warning (or
even raise an error if you configure such option) when a cross join is used,
that way users have a better notion when cross join was used. 
Here you can eliminate them, if possible. I think that way is better ;)

### References

 * [Teradata documentation about cross join elimination and join reordering](http://teradata.github.io/presto/docs/current/optimizer/reorder-joins.html)

 * [Pull request which added unnecessary cross join elimination to Presto](https://github.com/prestodb/presto/pull/6395)
