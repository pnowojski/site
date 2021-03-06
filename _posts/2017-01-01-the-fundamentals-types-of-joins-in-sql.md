---
title: 'The fundamentals: types of joins in SQL'
category: internals
tags: join fundamentals
---

Joins are one of the most important parts of each database and SQL itself. So it was obvious to me that this topic is going to appear very often on this blog. 
Hovewer, I thought that my first technical article will be about something more advanced, like join reordering or at least cross join elimination. 
Although, when thinking about what I could write about I realized that I would need to explain the basic terminology, so we could find a common domain language. 
Probably, most of the things below you know already, but even so I hope this is going to help you structurize your knowledge and find the missing things.

It is the first post in the series in which I am going to explain fundamental knowledge about database and its internals. So please do not be scared that is so entry level, hopefully next posts will be more challenging for you.

I would like to start from the ANSI SQL. What do we have there in regards to joins? I am aware of four explicit and two implicit types of join, do you know more? Let me check and go through the syntax and the semantic of each of them.

* cross join - the simplest one, two tables are joined together without any condition. Every single row from the one table will be joined with every row from the other table - a cartesian pruduct [^join_syntax]:

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2) t("left"), (VALUES 3, 4) u("right");
 left | right 
------+-------
    1 |     3 
    2 |     3 
    1 |     4 
    2 |     4 
(4 rows)
~~~

* inner join - two tables are joined together under a condition. Every row from the one table will be joined with every row from the other table only when the join condition is satisfied. 

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2) t("left"), (VALUES 1, 1, 2) u("right") 
             WHERE t."left" = u."right";
 left | right 
------+-------
    1 |     1 
    1 |     1 
    2 |     2 
(3 rows)
~~~

* left outer join - like inner join, but when a pair of rows does not satisfy the join condition, the left row completed with NULL values is returned:

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2) t("left") 
             LEFT OUTER JOIN (VALUES 1, 1) u("right") 
             ON t."left" = u."right";
 left | right
------+-------
    1 |     1
    1 |     1
    2 | NULL
(3 rows)
~~~

* right outer join - like left outer join, but now the right row completed with NULL values is returned:

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2) t("left") 
             RIGHT OUTER JOIN (VALUES 1, 2, 3) u("right") 
             ON t."left" = u."right";
 left | right 
------+-------
    1 |     1 
    2 |     2 
 NULL |     3 
(3 rows)
~~~

* full outer join - when the join condition is not met, the left row completed with NULL values and the right row completed with NULL values are returned:

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2) t("left") 
             FULL OUTER JOIN (VALUES 1, 3) u("right") 
             ON t."left" = u."right";
 left | right
------+-------
    1 |     1
    2 | NULL
 NULL |     3
(3 rows)
~~~

As I said before, there are also two implicit join types. Joins which do not have such a good syntax representation in SQL:

 * semi join - a row from the one table is returned when there exists a row in the other table for which a join condition is met. 
You might think that it is not a real join, as only values the one table are returned and values from the other table are not used in results. And maybe that it is one of reasons there is no `SEMI JOIN` syntax in SQL. 
In my opinion, it is commonly called as join because it requires values from both tables to evaluate the join condition. 
There are several ways to express such join in SQL, however each of them is not direct and may depend on the data you have, so its usage could be non trivial.
The easiest way is to use `IN` predicate [^simplicity]:

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2) t(one) WHERE t.one IN (VALUES 1, 1, 3);
 one 
-----
   1 
(1 row)
~~~

 * anti join - a very similar to semi join. 
A row from the one table is returned when there are no rows in the other table for which a condition could be satisfied. 
Here, as with semi join, there are also several ways to express such join. 
The easiest is to use `NOT IN`:

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2) t(one) WHERE t.one NOT IN (VALUES 1, 1, 3);
 one 
-----
   2 
~~~

The fact that the semi and anti joins do not have a proper syntax in SQL is somehow bitter. 
This causes that only a conjunction of equality comparisons can be used as join condition, while in other cases the user does not have such limitation. 
You cannot express anything like: `SELECT * FROM t SEMI JOIN u ON t.x > u.y`, instead you need to use a correlated subquery. 
And correlated subqueries topic is so broad and interesting that it deserves an another separate post.

~~~ sql
presto:tiny> SELECT * FROM (VALUES 1, 2, 4) t(one) WHERE EXISTS(SELECT * FROM (VALUES 1, 1, 3) t(other) WHERE one > other);
 one 
-----
   2 
   4 
(2 rows)
~~~

Interesting point is that it is possible to compose one join by using other joins or another relational algebra operations.
For example, logically inner join could be build as the cross join with a filtering operation on top of it. 
In that case when you use `TRUE` as join condition then the inner join becomes a simple cross join, filter operation becomes irrelevant. 
Another option is that it is possible to create left outer join from inner join and anti join on top of it.
Maybe knowledge about join composition is not super useful while you are just using a database, but from the point of view of database engineer and database internals it is important to know such things.
Also a relational algebra is broader topic which I hope to cover in separate post.

That would be all. A nice and easy post to start the journey into the Presto internals. 
In the next post I am going to cover what are join types in the Presto execution engine. 
I will describe how all of the above joins are actually calculated.

PS: Have a good 2017 year!

[^join_syntax]:
    Notice that SQL syntax gives two possible ways to use the cross and the inner joins. One is to simply put tables separated with comas, and the other is tables are separated with `JOIN` keyword.
    In case of the inner join, join condition can be placed after `ON` (when `JOIN` separator is used) keyword or within a `WHERE` clause.
    In regards of any `OUTER` join `JOIN` followed by `ON` keywords has to be used. This is due the fact that join condition has to be explicitly pointed.

[^simplicity]:
    The easiest in this context means, that it is the easiest for the user, though it may not be the most efficient way for database to execute that.
