---
title: Projects and presto SQL query formatter
author: kokosing
---

Yay, I have added the [Projects](/projects) section to this blog. What is more,
it contains the very first project - [Presto SQL files formatter](/projects/presto-query-formatter/). 

This section is going to collect all the utility tools which can become handy in regards to work with Presto.
It is going to have things like:

 * utility tools work with Presto, like this fresh sql query formatter. Their aim is to help you work with Presto.
 
 * example implementations of things which can be injected to Presto through plugin mechanism (SPI) 
  like: connector, UDF, type, system access controller etc.  
 These will help you implement your own Plugins.
 
 * collection of useful UDFs. Maybe some machine learning algorithms or other things... 
 I am not yet sure what. Let's see what life brings.

 * collection of useful connectors. I am not going to bring you a fully-fledged connector to Oracle or anything like that. 
 I am rather focused on smaller and more hacky things, 
 like connector to REST-based service which will be able to collect some data from Twitter or Facebook.

## Motivation behind Presto SQL formatter

Once upon a time I had a task to prepare tests which would prove that
[TPC-DS](http://www.tpc.org/tpcds/) queries are supported by Presto. This
benchmark contains about 103 different queries. 
Each of them is already formatted and
requires parameter keys to be replaced with some generated values. At first that
sounds good, but it turned out that some queries were formatted differently than
others or after replacing parameters files looked ugly. 

I thought it would be nice to format them, so it will be easy to read and navigate
between them. There are plenty of online SQL query formatters, just type "sql
formmatter" into google to see how many. I used one from the top of the list
which looked as the most robust. It also provided some REST-api, so I have
written the simple bash script which formatted all my TPC-DS queries.
It worked and I was happy, until I realized that this formatter changed the semantic of some queries.
Really?! For me it is something unacceptable.

When you have a query that is so long that does not fit into a
screen then it is not an easy task to find out that there are missing
parenthesis in one of the expressions in the WHERE clause.

I understand that creation of a generic SQL formatter might be not an easy task to do.
SQL has many variants, difference between them are not trivial. 
Presto tries to follow SQL standards as much as possible, but still it may be using some
syntax that is not supported by such formmater, like [lambdas](https://prestodb.io/docs/current/functions/lambda.html). 
So what a good formatter should do in such case? As a programmer I would say the easiest, it should fail. 
To me it is better when something fails, than produces garbage, which does not look like garbage at first.

At that point, I thought that online sql formatter cannot be trusted.
I need something I can rely on, how well query would be formatted is less important than that.
So I have created a SQL formatter which is based on Presto parser. 
I took some internals, wired them together and I got working formatter.
Using parser internally has many benefits: 

 - it has to parse the query, 

 - it validates if given query is correct (without checking the semantic)

 - it makes possible to check if query after formating means the same as before.
 For me this is a crucial point.

My initial plan was to add this to Presto itself, so user could simply type:

~~~sql
FORMAT SELECT * from nation;
~~~

Then Presto would return formatted query as result. 
I have even posted this as a [pull request](https://github.com/prestodb/presto/pull/6725), but functionality 
did not fit well into Presto. Eventually, I extracted this code as separate project and here we are.

## Presto SQL query formatter usage

I invite you to visit [Presto SQL query formatter](http://prestodb.rocks/projects/presto-query-formatter/) page
in order to get to know how to use it. That page is going to cover installation details, example usages etc.
It is devoted to that project and its aim is to evolve together with
it. So when a new feature comes in, that page should be updated to reflect
that.

## Road map for Presto SQL formatter

Even though it might be now very helpful, currently it is not able to do much. 
However, I am ambitious, so here I would like to write down the initial road map of how I imagine this project is going to evolve:
 
 - make possible to configure the formatting, like indentation width, where to put new lines or parenthesis etc.

 - expose a REST service which makes possible to format query without this tool being installed

 - once a REST service is complete I can write a python client, that way it could simply be installed with [pip](https://pypi.python.org/pypi/pip)

 - create an online formatter, so you would not need to install anything

## Conclusion 

Blog is evolving which makes my happy. Projects section was on my TODO list, and I am very satisfied that
I can rule it out from the list.

SQL query formatter is nice, from time to time I find it very useful
which is for me the best proof that this project has a value. 
Recently one of Teradata customers sent me a half-screen long query, written in a single line.
He was asking why correlated subquery placed somewhere in this query does not work.
Query correlation may be tricky, but once I formatted the query everything was much easier.

I know that SQL query formatting is not a rocket-science, but please let me start with something. 
To pave the way and learn the flow of adding new project. Next project which I want to add is a
generic framework to build connectors to which can expose data from REST based
services. It will come with a bunch of example usages, like connector to twitter. 
So that would be much more interesting. 
