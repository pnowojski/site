---
title: 2016 Q4 Teradata Presto relase - 157t
author: kokosing
category: news
tags: release
---

Recently Teradata released the new version of Presto - 157t (Teradata’s certified version of open source Presto). 
It is based on 0.157 regular version of Presto and contains features which are not yet available there.

<!--more-->

In my opinion these are the most interesting among the new features (comparing to 0.157):

  * connector statistics - connector is now able to provide table data statistics and hive connector it has implemented. You can browse table statistics with the following:

~~~ sql
presto:tiny> show stats nation;
 column_name | row_count 
 -------------+-----------
  NULL        |      25.0 
  (1 row)
~~~

Notice that depending on the way you access table (like projection or filter predicates) the table statistics may change, so to see what statistics table has for particular usage you may want to run:

~~~ sql
presto:tiny> show stats FOR (SELECT nationkey, regionkey FROM nation WHERE nationkey > 3);
 column_name | row_count
 -------------+-----------
  NULL        |      25.0
  (1 row)
~~~

Here you could find more information about [table statistics](http://teradata.github.io/presto/docs/current/optimizer/statistics.html).

 * Automatic join distribution

This features leverages table statistics. Smaller table could be selected to be replicated automatically. Notice that this is not enabled by default, to turn it on you need to run:

~~~ sql
presto:tiny> SET SESSION join_distribution_type = 'automatic';
~~~

Go to this page to find more details about [automatic join distribution](http://teradata.github.io/presto/docs/current/optimizer/join-distribution-type.html).

 * Fast `DECIMAL` implementation
  
For example in TPC-H Q1, which is heavily using long `DECIMAL` type, this speeds up from 1.613s (on `BigDecimal` based `DECIMAL`) to 0.342s (on fast `DECIMAL`) - this is 4.7x speedup! 
Why fast `DECIMAL` is fast is so fast? I hope that answer to this will find a place on this blog in the near future.

 * LDAP authentication

Presto can be configured to enable frontend LDAP authentication over HTTPS for clients, such as the Presto CLI, or the JDBC and ODBC drivers. More details can be found here - [LDAP authentication](http://teradata.github.io/presto/docs/current/security/ldap.html).
 
 * Broader SQL coverage 

Well known benchmarks like TPC-H and TPC-DS are eligible to be executed without any major (disallowed by benchmark specification) query modification.

  * For more, please see the links at the bottom

### References:

 * If you are interested in downloading binary files, please visit this page - [teradata.com/presto](http://www.teradata.com/presto).

 * Release notes can be found here - [release notes](http://teradata.github.io/presto/docs/current/release/release-0.157.1-t.html)

 * Source code can be found on [github](https://github.com/Teradata/presto/tree/release-0.157.1-t)
